Hey everyone, welcome to tutorial number 9. Here I'll show you the basics of getting SuperCollider to communicate with other MIDI devices.

Just a few words before we begin. If you're watching this video, then I'm assuming you've already got a general understanding of what MIDI is, so I'm not gonna go into a ton of depth here. But, if you don't know much about MIDI, then in short, MIDI, which stands for Musical Instrument Digital Interface, is a communication protocol for allowing musical devices, such as synthesizers, computers, etc, to talk to each other.

I suggest taking a look at the guide called "Using MIDI", which gives a very broad overview of the MIDI classes in the SuperCollider library. There's also a guide simply titled "MIDI", which gives an overview from a slightly different perspective.

So how do we use MIDI in SuperCollider? Well, first things first, SuperCollider needs to connect with the MIDI functionality of your operating system, and this is done with

MIDIClient.init;

In doing so, SC touches base with your operating system and its knowledge of available MIDI devices, and comes back with a list of MIDI sources and destinations. Right now, as you can see, I don't have any. So I'm going to plug in my audio MIDI interface...clear the post window...and run this line again.

MIDIClient.init;

and now you can see that SuperCollider has detected my interface. For this tutorial, I've got a Yamaha PSR 620 keyboard, which is sending MIDI to the interface.

After detecting MIDI devices, the next step is to connect SuperCollider with a MIDI device. The easiest way to do this is to just connect with all available devices, using

MIDIIn.connectAll;

And I find there's no disadvantage to doing it like this. However, if you have multiple devices, but for some reason don't want to connect with all of them, you can first get an array of available source devices, with

MIDIClient.sources;

Of course in this case I just have one source. And then use

MIDIIn.connect();

And then specify the device by its index in the source array.

MIDIIn.connect(0);
MIDIIn.connect(1);
MIDIIn.connect(2);

But, just to reiterate, I find that there's absolutely no problem with just using MIDIIn.connectAll.

So what's next? Let's now get some MIDI data into the language. To actually interact with MIDI data, you'll use one of two very similar classes. There's

MIDIFunc

and

MIDIdef

These two classes have a slightly different syntax, but they perform the same function. In fact, MIDIdef is a subclass of MIDIFunc. They both allow you to register an action to be taken when a certain type of MIDI message is received. It would actually be fairly redundant to demonstrate both classes, since they really are quite similar, so for the purposes of this video, I'm going to use MIDIdef. Now I like MIDIdef, because there are several "def" type classes in SuperCollider, most prominently SynthDef, but also Tdef, Pdef, Ndef, and so forth, so there's a certain homogeneity of syntax with MIDIdef that I find very appealing.

Since I'm using a keyboard controller, then I'm probably going to be dealing with note-on and note-off messages. So, to start, I'll create a MIDIdef to respond to note-ons, with MIDIdef.noteOn, and remember that capitalization does matter.

MIDIdef.noteOn();

At minimum, MIDIdef expects two things: a symbol, which serves as the name of the def, and a function to be evaluated when a note-on message is received. In this case I'll just print the words "key down" every time a note-on message is received.

MIDIdef.noteOn(\noteOnTest, {"key down".postln});

Once created, you can temporarily deactivate a MIDIdef with the 'disable' message

MIDIdef.noteOn(\noteOnTest).disable;

Andy you can re-activate with 'enable'

MIDIdef.noteOn(\noteOnTest).enable;

To destroy a MIDIdef, we use the free message, just like we do with Synths and Groups.

MIDIdef.noteOn(\noteOnTest).free;

And finally, if you have multiple MIDIdefs floating around, rather than free them individually, you can destroy them all at once using the class method 'freeAll'

MIDIdef.freeAll;

I also want to point out that by default, a MIDIdef will be destroyed by pressing command-period. This can be specified explicitly by spetting the MIDIdef's permament attribute to true or false. If true, when I hit command preiod, the MIDIdef persists.

MIDIdef.noteOn(\noteOnTest, {"key down".postln}).permanent_(true);

If permanent is set to false, then command period will remove the MIDIdef.

MIDIdef.noteOn(\noteOnTest).permanent_(false);

Ok, so with that out of the way, let's acknowledge that printing the text "key down" is not particularly useful. So instead, let's use MIDIdef to print the actual incoming MIDI data. Here I'm talking about things like note number, velocity, MIDI channel, and so forth. This is done by declaring arguments within the MIDIdef function. The number of arguments and what they represent varies, depending on which type of MIDI message you're dealing with. In the MIDIdef help file, we can read about this in detail. under the new method, in the description of the function, we can read about the types of expected arguments. When evaluated for note on, note off, control, and poloyhponic aftertouch messages, the function will be passed the arguments val, num, chan, and source, in that order. So in our case, dealing with note on mesages, these arguments represent note velocity, note number, MIDI channel, and and identifying number associated with the source device.

Aftertouch, program change, and pitch bend messages are different. In this case the funciton is passed only three arguments: value, channel, and source. So, since we're dealing with note on, I'll declare four arguments in the MIDIdef function. I can't change the order in which the function expects these vaules, but I can call them whahtever I want. 'vel' for velocity, 'nn' for note number, 'chan', and 'src'. And in this case I'll simply print an array of these four values.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn, chan, src].postln;
});
)

And in the post window, here's the data for these five notes I've just played, each starting with velocity, followed by note number. And then third we have MIDI channel, which is zero. So just a quick note about how SC interprets MIDI channels: you proably already know that one MIDI cable accommodates 16 unique MIDI channels, and that MIDI messages are sent and received on one or more of these channels. Most MIDI software, and perhaps, most human beings, think of these channels as 1 through 16. However, by convention of other programming languages, and for the sake of consistency with other indexing methods, SuperCollider understands these channels as 0 through 15. You can see how this might be a point of confusion if you're not expecting it. But the point is, this numbering convention is very impontant to keep in mind if you're going to be dealing with multiple channels, or if you're transferring MIDI between SuperCollider and some other software. Last is source ID, and I don't really ever use this number, but I guess it can be useful to distinguish identical data coming from two different devices.

Let's say in this case we don't actually care about channel and source ID. The nice thing about MIDIdef is that you can change the function, but keep the same symbolic name, re-evaluate, and the def is overwritten.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
});
)

And now we only see velocity and note number.

So, now that we have the basic syntax and functionality out of the way, let's use this MIDI data to make some sound. probably the quickest and easiest way is to just put a UGen function within the MIDIdef function. And I'm gonna go real simple here.

For the source sound, I'll use a sine wave, making sure to convert MIDI note numbers into cycles per second for the frequency argument. Exclam 2 to create a stereo output signal. Since I'm not incorporating note off messages, I should make sure that the sine waves will turn themselves off somehow. I'll use a default percusisve envelope for this, with doneAction:2. Of course, this means I'll have no way of sustaining the sound, but like I said, we're starting simple. I'm gonna use velocity in the traditional sense, to control amplitude. Of course, we're going to have to convert velocity numbers to a reasonable range, since we don't want a sine wave with an amplitude of 127, that would be...unpleasasnt. So I'm gonna use a method called 'linexp'. linexp is one of several methods which maps a number from one range to another, in this case a linear range to an exponential range. So, we provide the input range, in this case, 1 to 127...and the output range, and since we're talking about raw amplitude here, I'll say a minimum of 0.01 and a maximum of 0.3. And while I could go with a maximum of 1, we'd probably end up clipping the output signal if we play multiple notes simultaneously. You can read more about linexp and similar mapping methods in the help file for SimpleNumber. Make sure to add '.play' at the end of the sound funtion, boot the audio server, and we should be good to go. I'm also going ot turn down the volume on my synthesizer, because synthesis is now being handled by SuperCollider instead.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	{
		var sig, env;
		sig = SinOsc.ar(nn.midicps)!2;
		env = EnvGen.kr(Env.perc, doneAction:2);
		sig = sig * env * vel.linexp(1,127,0.01,0.3);
	}.play;
});
)

s.boot;

Changing the type of sound simply amounts to changing the UGen function, and then re-evaluating the MIDIdef. For example, here's a triangle wave.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	{
		var sig, env;
		sig = LFTri.ar(nn.midicps)!2;
		env = EnvGen.kr(Env.perc, doneAction:2);
		sig = sig * env * vel.linexp(1,127,0.01,0.3);
	}.play;
});
)

Like I said, this is the quick and easy way of using MIDI to generate sound. If you want to get more complex, like maybe using note-off to release a sustained note, or maybe incorporating pitch bend, then this approach is probably not going to cut it. You'll remember from tutorial number 3 that the more formal and flexible way of making sound is to create a SynthDef. So, let's do that. I'll copy and paste, and make the necessary changes...

(
SynthDef.new(\tone, {
	arg freq=440, amp=0.3;
	var sig, env;
	sig = LFTri.ar(freq)!2;
	env = EnvGen.kr(Env.perc, doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add;
)

...and there we go. Let's quickly test to make sure this works.

Synth.new(\tone, [\freq, 700, \amp, 0.5])

For starters, we can now simplify our MIDIdef function. Instead of playing a UGen function, we can just instantiate a Synth with the correct parameters.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	Synth.new(\tone, [\freq, nn.midicps, \amp, vel.linexp(1,127,0.01,0.3)]);
});
)

Let's do away with this percussive envelope, and instead use an ADSR envelope, so that we can initiate and sustain a pitch with a note-on, and then release the note with a corresponding note-off. First things first, we need to make a few changes to our SynthDef. I'm just gonna keep things simple and go with the default ADSR envelope. Since ADSR is a sustaining envelope, we need a gate argument. The attack phase is triggered when gate = 1, and the release phase is triggered when gate = 0.

(
SynthDef.new(\tone, {
	arg freq=440, amp=0.3, gate=0;
	var sig, env;
	sig = LFTri.ar(freq)!2;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add;
)

And again, I'm just gonna do a quick test to make sure it works.

x = Synth.new(\tone, [\gate, 1])

x.set(\gate, 0);

Perfect. But, we're not quite done yet. We can't just put x = Synth.new into our note-on MIDIdef function, because *if* we play a second note, while the first note is being sustained, then x will be overwritten with a new Synth, and we'll have no way of communicating with the old one. This means we'll have no way of releasing the note, and we'll get a whole bunch of stuck notes. So, the way I like to deal with MIDI polyphony is to create an empty array of size 128, since there are 128 possible note numbers. When I play a note, I create a Synth, and store that Synth in the array, at an index equal to the incoming note number. When I release a note, I free the Synth at the index equal to the incoming note number. In this way, I'm visualizing the piano keyboard as an array of possible notes, and I think, conceptually, this works very well.

So, here's our initial empty array of size 128.

~notes = Array.newClear(128);

Next, I'll modify the MIDIdef for note-on messages. Instead of just creating a Synth, I'm also going to store the Synth in the global array of notes, at the index determined by the incoming note number.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});
)

Ok, so that's that. And, if we were to play any notes right now, they get stuck...totally stuck. So, I'm just gonna hit command-period, which also removes the MIDIdef, so I'm gonna re-evaluate that.

Ok so what we've gotta do is make another MIDIdef to handle note-off messages. In this function, I'll address the Synth at the correct index, corresponding to its note number, and set the gate argument of that Synth to zero, then replace the Synth with a nil value, so that it's like the Synth was never there.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});
)

And just like that, we've got a polyphonic synthesizer. As a finishing touch, let's incorporate pitch bend. And this means we've gotta make a third MIDIdef. I always like to start by just printing the incoming values, to make sure we know exactly what kind of numbers we're getting.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
});
)

Create the MIDIdef, and adjusting the pitch wheel on my keyboard, we can see that the values range from 0 to 16383, and that its 8192 at rest position.

Uh, ok, this is interesting. Take a look at this. My Yamaha seems to be sending out three identical messages on channels 0, 10 and 1...for some reason. This just goes to show that it's always good to check your data before you start using it. You know, this might actually cause some problems, so what I'm gonna do is only pay attention to pitch wheel messages coming in on channel 0. In the help file for MIDIdef, you can see that it has an argument called 'chan', which is nil by default, and this means the def will respond to messages on any channel. But, if we specify an integer instead of nil, then the MIDIdef will only respond to messages on that particular channel.

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
}, chan:0);
)

And now, you can see we only get pitch messages on channel zero. And this looks much better.

Let's use the pitch wheel in its most traditional sense: to bend the pitch. First, we need to change our SynthDef again, in particular we need to add a new argument for pitch bend. I'm going to conceive of bend as a number of semitones, so it's zero by default. But to use this with a frequency measured in cycles per second, I need to use the midiratio method to convert from semitones to a frequency ratio.

(
SynthDef.new(\tone, {
	arg freq=440, amp=0.3, gate=0, bend=0;
	var sig, env;
	sig = LFTri.ar(freq * bend.midiratio)!2;
	env = EnvGen.kr(Env.adsr, gate, doneAction:2);
	sig = sig * env * amp;
	Out.ar(0, sig);
}).add;
)

And now, I'll change the MIDIdef receiving pitch bend messages. On synthesizers, the pitch wheel usually acts globally, on all notes, so it might be wise to use a global variable to keep track of the pitch wheel position. I'll initialize this variable to 8192, and have the MIDIdef update this value every time the pitch wheel is moved.

(
~bend = 8192;

MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
	~bend = val;
}, chan:0);
)

So, if I move the pitch wheel away from rest position...and then check the global bend value...

~bend;

...you can see that the MIDIdef is keeping track of it. But this MIDIdef also needs to update any notes which might currently be playing. So I'm going to use 'do', as we saw in tutorial number 6 on iteration, to iterate over the ~notes array and update the ~bend argument for each Synth. I'm going to map the raw bend value onto a transposition value ranging from down a whole step (-2) to up a whole step (+2). I'm using linlin, since both of these ranges are distributed linearly.

(
~bend = 8192;

MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
	~bend = val;
	~notes.do{arg synth; synth.set(\bend, val.linlin(0,16383,-2,2))};
}, chan:0);
)

You might be thinking: "Well...hold on. Aren't many of the items in the ~notes array nil?" And, you'd be right. At any given point, ~notes contains some mixture of nils and Synths. But, fortunately for us, nil understands the 'set' message, and responds to it by doing nothing, which is exactly what we want it to do. Here's your proof:

nil.set(\freq, 880);

We're almost done, but there's one last thing. What happens if we move the pitch wheel away from rest, and *then* strike a key on the synthesizer?

You can see and hear that even though I'm moving the pitch wheel away from rest position, the initial frequency of the tone is not being affected. To fix this, the note-on MIDIdef needs to acknowledge the global position of the pitch wheel, and apply that position to the initial frequency of the tone. Fortunately, this is as simple as just adding one last argument to the code where the Synth is instantiated.

(
~bend = 8192;

MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn, chan, src;
	[vel, nn].postln;
	~notes[nn] = Synth.new(
		\tone,
		[
			\freq, nn.midicps,
			\amp, vel.linexp(1,127,0.01,0.3),
			\bend, ~bend.linlin(0,16383,-2,2),
			\gate, 1
		]
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	[vel, nn].postln;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});

MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	[val, chan, src].postln;
	~bend = val;
	~notes.do{arg synth; synth.set(\bend, val.linlin(0,16383,-2,2))};
}, chan:0);
)

And that's really all there is to it. There are so many directions you can go from here. For example, you might try redefining your SynthDef and MIDIdefs so that the pitch wheel creates some other effect, like stereo beating, amplitude modulation...of course you can also change your sound source to be something other than a triangle wave...you could also create more MIDIdef, such as MIDIdef.cc, to respond to continuous controller messages. And this would enable the use of knobs, buttons, faders, a sustain pedal, an expression pedal, really all sorts of things.

Anyway, that's it for tutorial number 9. I hope this has been helpful, and I hope you have some fun with this. Please leave any comments or questions on YouTube, and thanks for watching.