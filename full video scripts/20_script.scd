Hey everyone, welcome to Tutorial number 20. In this video we'll talk about the basics of getting SuperCollider to read a live signal from a microphone, and a few ways of processing that signal and sending it out to your speakers.

First things first: let's talk about feedback. This is probably obvious to many of you, but just in case, whenever you've got a situation with a live mic being sent to loudspeakers, there's always a risk of acoustic feedback, which most of the time is screechy and horrible, depending on the mic and speakers you're using, where they're located, and what kind of room you're in. It's kind of gross to listen to, and probably not very good for hardware. So, before you even boot the server, unless you want to live dangerously or you're really sure you know what you're doing, I strongly recommend you plug in a pair of headphones, which I'm going to do right now. And, also, if you rummage though SuperCollider code examples that involve microphones, you will very likely see some comments that suggest the exact same precaution.

So, with headphones in, let's boot the server.

s.boot;

Note in the post window, SuperCollider is currently using my laptop's built-in sound card for input and output. For now, this is fine, but later in the video we'll switch to a more professional set up with a cardioid condenser mic and an external audio interface.

The best and easiest way to pull a microphone signal into SuperCollider involves a UGen called SoundIn. The first argument for SoundIn is the index, or array of indices, corresponding to the hardware input or inputs that you want to use. In most cases this is probably just going to be the number zero. So, if we were to put this UGen in curly braces and play it, we'd be creating a simple microphone pass-thru, so it plays right to our speakers. And with headphones plugged in, you're probably safe, but still it's a good idea to start with a low system volume, or just be ready to hit command-period in case something weird happens, because there might be behavioral discrepancies between different computers, different operating systems, different sound cards, etc. So, run this line,

x = {SoundIn.ar(0)}.play;

And you should be able to hear your own voice, coming through your headphones. You will probably notice that the sound is monophonic, only coming through the left side, but as we saw in Tutorial 5, this is consistent with the fact that almost all UGens are monophonic by default, because this allows for multichannel expansion to be applied in a very predictable way. Also, the quality of the sound is obvious not very good, and that's usually what you can expect from a built-in laptop mic.

x.free;

If you're like me, then you probably don't find it very enjoyable to have sound in only one ear, while wearing headphone. So, if you want to make a two-channel signal from a single microphone, we can invoke multichannel expansion, by providing the array [0, 0] as the bus argument for SoundIn,

x = {SoundIn.ar([0,0])}.play;

and remember that as an alternative we have the syntax shortcut exclamation point two at our disposal, which I prefer.

x = {SoundIn.ar(0!2)}.play;

And now we have the same mic signal in both speakers, which is considerably nicer to listen to you, especially if you're on headphones. And again, check out Tutorial 5 if this multichannel exclamation point stuff is unfamiliar you.

A key point to remember is that a signal is a signal is a signal, even though we're bringing a microphone into the equation, we're still just dealing with a sequence of numbers — of digital audio samples — which we can freely process and do calculations with, so in many respects you could just treat SoundIn just like you'd treat a generative UGen, like SinOsc, or PinkNoise, or a UGen that reads a sound file from a buffer, like PlayBuf.

So, just to get the ball rolling with some signal processing, let's expand this function a bit and create a ring modulation effect. Ring modulation involves multiplying some signal by usually a sign wave, which is what I'm doing here, and then we'll use addition to mix the original signal with the modulated version, and we'll also reduce the amplitude by half to compensate.

(
x = {
	var sig, rmod;
	sig = SoundIn.ar(0!2);
	rmod = sig * SinOsc.ar(700);
	(sig + rmod) * 0.5;
}.play;
)

Ring modulation sounds like this. I'm intentionally avoiding some details here but ring modulatiotn basically takes the frquent components iw the spcetrum and shifts them around by addition and subtraction, based on the frequency of the sine wave. The main reason I'm mixing the processed and unprocessed signals together, is to take it a little bit easier to understand what I'm saying.

x.free;

But of course, you can listen to the modulated signal by itself,

(
x = {
	var sig, rmod;
	sig = SoundIn.ar(0!2);
	rmod = sig * SinOsc.ar(700);
	//(sig + rmod) * 0.5;
}.play;
)

and that sounds like this. Probably a little harder to understand, but also, maybe, a more interseting sound.

x.free;

Anyway, we'll do some more fun signal processing later in this video, but for now, in terms of the basics of just pulling a mic signal into SuperCollider, it really doesn't get any more complicated than this. But, I do want to take a few steps back and have a closer look at what's actually going on here.

In previous videos, we've used Out.ar to write an audio signal to a bus, and we've used In.ar to read an audio signal from a bus. Originally we did this in Tutorial 7, and also a few other videos beyond that. And recall, that when the audio server boots, it allocates a number of audio busses, and the lowest numbered busses are associated with hardware outputs and inputs (in that order), and beyond those are "private" busses, which are used for internally passing signals between Synths. At the time of making this video, the default server configuration is two hardware output busses and two hardware input busses, as we can see on the level meters.

s.meter;

Outputs 0 and 1 correspond to my two laptop speakers, and even though the inputs are also labeled 0 and 1, they technically correspond to audio busses 2 and 3. And this is the live microphone signal.

Now, the first thing I want to address is: Why do we see identical activity on both input channels? The answer, I'm fairly certain, is that it's just a quirk of my sound card — there's only one physical microphone in my computer, so it would certainly make more sense to see activity on only one input bus. But my guess is that as a matter of convenience for other softwares that use input audio, the sound card just copies of mic to both channels. It's not too important right now, it's not really something worth worrying about, so what I'm going to do is just use the lowest index input signal, and just pretend the other one isn't there.

But the main point I want to make is that it's technically possible to use regular old In.ar to capture microphone input, if we specifiy bus 2, like this. And, we're going to invoke multichannel expansion, just so we can listen with both ears. And, to be extra explicit for a moment, let's also specify where the signal should go, by including an Out UGen and sending to bus 0. Technically this is going to bus 0 and 1 because it's a two-channel signal.

(
x = {
	var sig;
	sig = In.ar(2!2);
	Out.ar(0, sig);
}.play;
)

And just to be clear, this Out statement is not actually necessary, because function-dot-play is a shortcut that automatically creates Out UGen for us, as we can see in that Function help file, under the 'play' message.

x.free;

And if we open a parenthetical after play and choose function, we can see in the pop-up text that 0 is the default output bus. So we could comment out this line, or just delete it,

(
x = {
	var sig;
	sig = In.ar(2!2);
}.play;
)

and the result is exactly the same.

x.free;

However, it's better to use SoundIn instead of In for grabbing a microphone signal and the reason for this is because 'In' is less likely to be consistent across different computers. For example, let's say you write some microphone code and send it to someone else, and that person has a different default server configuration — let's say, eight hardware outputs and eight hardware inputs. To demonstrate, let's make that change ourselves, and reboot the server,

(
s.options.numOutputBusChannels = 8;
s.options.numInputBusChannels = 8;
s.reboot;
)

and that would look like this on the level meters.

s.meter;

Maybe this person is using an external sound card with eight channels, and in fact is some older versions of SuperCollider have this eight-in-eight-out setting by default. So, in this case, our previous example with In.ar(2)

(
x = {
	var sig;
	sig = In.ar(2!2);
}.play;
)

does not work.

x.free;

Audio bus 2 corresponds to this third output channel here, and first of all, there's no signal on that channel, and frankly, I'm also not sure it makes a lot of sense to read from a hardware output bus, seems like kind of a weird thing to do, so, to actually grab this mic signal using In.ar, in this case, we would need to change 2 to 8 because buses zero through seven are hardware outputs and eight through fifteen are now the hardware input buses.

(
x = {
	var sig;
	sig = In.ar(8!2);
}.play;
)

And now we have our microphone monitoring Synth once again. But,

x.free;

having to dive into your finished code and change numbers around in order to get it to work properly is annoying, and kind of stupid, and this is exactly what SoundIn avoids. And, to explain how, we're going to do something we haven't actually done before in this tutorial series: we are going to take a quick look at the source code for SoundIn, which we can do by first clicking on SoundIn (or any object class name for that matter), and then in the language menu, choosing "look up implementations for cursor" — you can also use the hotkey command-i. And then, when this window appears, press return.

SoundIn has a class method called 'channel offset' (chanOffset), which is simply the number of hardware output busses currently allocated. And when you call SoundIn.ar, SuperCollider secretly creates an instance of In.ar, and offsets the bus number that you provide by adding the number of hardware output busses. So, if you have two output busses with indices 0 and 1, SoundIn at 0 actually begins counting at index 2, or, if you have eight hardware output busses, SoundIn at 0 begins counting at index 8, and so forth.

So, ultimately, the point here (which is actually very nicely summed up in the description in the SoundIn help file) is that SoundIn is simply a convenience UGen (also called a wrapper UGen) that uses In.ar and offsets the index so that zero always corresponds to your first hardware audio input.

So here's the next point I want to make: at some point during your SuperCollider travels, you might encounter a UGen called 'AudioIn,' which at first glance looks like a doppelganger of SoundIn, or something. Well, AudioIn is actually a much older UGen, dating all the way back to SuperCollider version 2, as you can see in the help file. The only difference is that it starts counting indices at 1 instead of 0, but the bottom line is — don't use AudioIn. It is a deprecated UGen, which means it's technically usable, but it's considered to be obsolete and only exists for backward compatibility. So, the best course of action for you: avoid it altogether and just use SoundIn instead.

Ok, so I wanna get back to some more microphone signal processing effects, but no matter how fancy your algorithms are, the quality of your sound is only going to be as good as the quality of the microphone you're using. And my laptop mic is just...not really up to the task. As they say, 'garbage in, garbage out.' So, we're going to switch to a more professional set up, which involves a digital audio interface and a good quality microphone. For output monitoring, the safe thing to do is just continue to use headphones, but if you got a pair of studio monitors that you wanna use, that's fine too. Just make sure the mic you're using is positioned so that will pick up the sound from the speakers as little as possible, to avoid feedback.

So I'm assuming that, for most viewers, this is probably not your first time connecting a microphone to your computer — so I'm going to try to keep things brief. In this video, for my audio interface, I'm using the very minimal Focusrite Scarlett 2i2. This is a class-compliant USB interface, which means it's plug-and-play, so you don't need to install any software drivers to get your computer to recognize it. Keep in mind there are lots of audio interfaces out there and they're all different, so you might need to read the manual in order to get familiar with how yours works.

So I'm going to connect the 2i2 to my computer via USB, and also confirm that it shows up as an available device in my System Preferences...and there it is. And, for my microphone I've got a Røde NT1-A, it's a large diaphragm condenser, so just take my XLR cable, plug it into the mic, and the other end goes into the first input on the Focusrite. This mic needs phantom power, so make sure that's on, and then set the pre-amplifier gain to an appropriate level. I know from experience that does knob needs to be set around 1 or 2 o'clock, sort of right here. I'm also gonna use this interface for output monitoring, so I'm just gonna add my quarter inch adapter to my headphones, plug into the headphones jack and adjust the output level. This particular interface has a direct monitoring switch, and I want this feature to be off because, in this case, I don't want to automatically hear the mic through the headphones all the time. Instead I want the mic signal to go through SuperCollider before going to headphones.

Ok, so, back in SuperCollider, let's re-configure and reboot the audio server. First, if we evaluate ServerOptions.devices,

ServerOptions.devices; //will not work if using JACK, which is the default on Linux. See the ServerOptions help file for more information

we get an array of the names of available audio devices. So, here is the name of the interface I'm using, I'll just copy this text straight from the post window, and in a separate parenthetical block, we can set the input device and output device like this, with s.options.inDevice and .outDevice.

(
s.options.inDevice = "Scarlett 2i2 USB";
s.options.outDevice = "Scarlett 2i2 USB";
)

Using two separate lines for input and output is useful, particularly if you want to use one device for input, but a different device for output. But, if you're using the same device for both, like we are here, as a shorter alternative you can just type s.options.device equals whatever the name of your device is.

(
s.options.device = "Scarlett 2i2 USB";
)

And because my interface has two ins and two outs, it's probably a good idea to mirror this configuration on the audio server, like this.

(
s.options.device = "Scarlett 2i2 USB";
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
)

And finally, for these changes to take effect, we need to reboot the server.

(
s.options.device = "Scarlett 2i2 USB";
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.reboot;
)

On the level meters, we can see we're back to our original two-in-two-out configuration, and also note that, unlike when we were using the laptop sound card, we now have meter activity on only the lowest numbered input bus, which is nice because it's consistent with our single microphone set up.

Alright, and now we're ready to get back to some signal processing. So, I'll make a SynthDef using SoundIn that simply reads mic signal, duplicates it to a stereo array, and sends it out.

(
SynthDef.new(\mic, {
	var sig;
	sig = SoundIn.ar(0!2);
	Out.ar(0, sig);
}).add;
)

Now, although it is possible (and maybe even tempting) to hardwire some numbers in here for bus indices, I think it is always a good idea to declare arguments for these values, so that we have the option for flexibility with signal routing, and we're at it let's also add an amplitude argument. We might use it, we might not, but again it's there just in case.

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in!2) * amp;
	Out.ar(out, sig);
}).add;
)

With these initial argument values for in and out, this SynthDef is, by default, just a simple direct monitoring Synth, so we can instantiate it like this.

x = Synth(\mic);

And this...*is* actually working — the reason it doesn't sound any different is because this mic that I'm using for demonstration is the exact same mic that I use to record my voice for these tutorials. But, that's ok, we can make it sound different by adding an effect. Instead of ring modulation again, let's add a delay, because that's a fairly standard and fun thing to do (especially with voice) so first, let's declare a second variable, so we can more easily keep the processed and unprocessed signals separate.

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	Out.ar(out, sig);
}).add;
)

One of the most basic ways to delay a signal in SuperCollider is using a UGen called DelayL. It's actually part of a family of three UGens which includes DelayN and also DelayC. The letters stand for non-interpolating, linear interpolation, and cubic interpolation. With no interpolation, the assumption is that your delay time will be a fixed value, so if you want to have a delay time that changes dynamically, you should go with L or C. And DelayL uses a bit less CPU power, so I'm gonna go with that. We need to provide a few inputs, the first is the audio signal that we want to delay, which we've called 'sig,' and next is the maximum delay time, in seconds, which determines how much memory the server needs to allocate for this delay. I'll go with a half second. And third is the actual delay time, and this third value must not exceed the second value. I'm not exactly sure what happens if you do exceed the maximum delay time — possibly nothing disastrous — but certainly nothing good happens, so I don't recommend it.

(
SynthDef.new(\mic, {
	arg in=0, out=0, deltime=0.3, amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	delay = DelayL.ar(sig, 0.5, deltime);
	Out.ar(out, sig);
}).add;
)

In order to mix the unprocessed and processed signals together, instead of just adding them together, like we did with ring modulation, I often like to use a UGen called XFade2, which does an equal-power crossfade between two signals, based on a pan argument. I don't really like the use of the term 'pan' here, because it sort of implies a left/right thing, and that's not really what's going on here. Personally, I think the term 'mix' makes more sense, because when its value is -1, we hear only the first input. When it's +1 we hear only the second input, and with a value of zero, we hear a mix of both signals equally. I'm going to initialize this mix value to -0.5, so that we hear the delay just a little bit less than the original sound.

(
SynthDef.new(\mic, {
	arg in=0, out=0, deltime=0.3, mix=(-0.5), amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	delay = DelayL.ar(sig, 0.5, deltime);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

x = Synth(\mic);

And now, you can hear that there's a 0.3-second delay on my voice. The mix value of -0.5 makes that delayed signal just a little bit quieter than the direct sound, so it sort of simulates a real-world echo.

x.free;

But if we want even more of an echo effect, we can use a UGen called CombL, which is similar to DelayL (actually has the same N-L-C) family, but Comb is a delay that feeds back into itself and therefore has an additional argument for decay time. This is a value in seconds, and determines how long it takes for the echo to decay by 60 dB. So we'll initialize this value at three seconds.

(
SynthDef.new(\mic, {
	arg in=0, out=0, deltime=0.3, mix=(-0.5), decay=3, amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	delay = CombL.ar(sig, 0.5, deltime, decay);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

x = Synth(\mic);

So, by replacing a simple delay line with a feedback delay, we’ve created a sort of even more realistic echo effect.

x.free;

But, there’s no reason we need to keep things confined on the plane of reality. Currently, our delay time remains fixed, so instead, let's use a sine wave to control the delay time, fluctuating between, let's say, 0.1 and 0.4 seconds.

(
SynthDef.new(\mic, {
	arg in=0, out=0, mix=(-0.5), decay=3, amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	delay = CombL.ar(sig, 0.5, SinOsc.kr(0.3).exprange(0.1,0.4), decay);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

x = Synth(\mic);

So now, things are starting to get a little more interesting. In addition to the echo effect, the variations in the delay time create a pitch-shifting effect, so that my voice has a sense of periodically speeding up and slowing down.

x.free;

And let's not forget about multichannel expansion (which is a fun ingredient) by expanding this SinOsc to have an array of two frequencies. The speed at which the delay time changes is slightly different between the left and right speakers.

(
SynthDef.new(\mic, {
	arg in=0, out=0, mix=(-0.5), decay=3, amp=1;
	var sig, delay;
	sig = SoundIn.ar(in!2) * amp;
	delay = CombL.ar(sig, 0.5, SinOsc.kr([0.32,0.3]).exprange(0.1,0.4), decay);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

x = Synth(\mic);

And this gives us a somewhat more interesting stereophonic effect, in which the pattern of speeding up and slowing down gradually drifts out of phase between the two ears.

So if we let ourselves get carried away (which is very tempting), what's likely to happen is that this SynthDef will sort of get bigger and more complex, and maybe spiral out of control, with the different kinds of effects we use, and then it'll become kind of difficult to debug problems and more difficult to visualize what's going on in terms of signal flow... so, generally speaking, rather than having one big SynthDef that does everything, it's a good idea to modularize your signal flow, and this is especially true here, because we have two distinct things. We have the act of capturing the mic signal, and the application of a delay effect. So, the right thing to do is separate this code into two SynthDefs, and that would look something like this:

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in!2) * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\delay, {
	arg in=0, out=0, mix=(-0.5), decay=3, amp=1;
	var sig, delay;
	sig = In.ar(in, 2) * amp;
	delay = CombL.ar(
		sig,
		0.5,
		SinOsc.kr([0.32,0.3]).exprange(0.1,0.4),
		decay
	);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

The mic SynthDef grabs mic signal, and simply writes it to an arbitrary bus. And, the delay SynthDef (which, of course, needs a different name) reads from an arbitrary bus using In.ar, and we have to make sure to read two consecutive channels because that's with the mic SynthDef is sending, and this delay SynthDef applies the comb delay effect. And, you know, let's add a few arguments so we're not always stuck with these fixed values in CombL:

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in!2) * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\delay, {
	arg in=0, out=0, mix=(-0.5), decay=3, amp=1, delHz=0.25, delMin=0.1, delMax=0.4;
	var sig, delay;
	sig = In.ar(in, 2) * amp;
	delay = CombL.ar(
		sig,
		0.5,
		SinOsc.kr([delHz, delHz*0.9]).exprange(delMin,delMax),
		decay
	);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

Ok, so because we've split the work into two SynthDefs, we're going to be passing a two-channel audio signal between these two Synths, so we should allocate a two-channel private bus for this purpose, like this:

~delBus = Bus.audio(s, 2);

And it wouldn't be a bad idea to also make some Groups on the server, to manage the Synth order-of-execution more cleanly. And then, to re-create the previous sound, we create one of each Synth, taking advantage of our allocated delay bus, and making sure to place each Synth in its corresponding Group.

(
~micGrp = Group.new;
~delGrp = Group.after(~micGrp);

~micSynth = Synth(\mic, [\in, 0, \out, ~delBus], ~micGrp);
~delSynth = Synth(\delay, [\in, ~delBus, \out, 0], ~delGrp);
)

And now, we've got exact same sound that we had previously. But wait! There’s more.

s.freeAll;

Because we've modularized our code into discrete tasks, we now have a lot more flexibility. So, for example, let's say we wanted to create six unique delay lines, all processing the same mic signal slightly differently. Now, before, when we had one single SynthDef containing SoundIn and the delay effect, our only option would've been to create six of those Synths and that means we have six SoundIn UGens running simultaneously, which is not only redundant, but also has the side effect of making the mic signal amplitude six times bigger.

But now that we have two separate SynthDefs, we can achieve this much more efficiently. So, here's what I would do: First, create a mic Synth that goes directly to speakers, and this is going to be our dry, unprocessed sound, bypassing the delay effect completely. Then, a second mic Synth, in the same Group, but this signal is going to go to the delay bus for processing. And for our six delay lines, we'll use the iterative construction 6.do to create six Synths, all reading from the delay bus, all going to speakers.

Now, because we already have the mic signal that goes directly out, we don't need to hear any of that direct signal through the delay Synths, so it makes sense here to set the mix argument to one. And, because we have six Synths, we should scale the amplitude argument down to compensate. 1/6 is probably fine, maybe a little lower wouldn't be a bad idea, but to start, this is probably gonna be fine. And for the delay and decay parameters, I'm gonna use some randomness so that each of these six delay Synths is a slightly different, but of course we want to make sure that we don't exceed the maximum delay time of 0.5 seconds.

(
~micGrp = Group.new;
~delGrp = Group.after(~micGrp);

~micSynthDirect = Synth(\mic, [\in, 0, \out, 0], ~micGrp);
~micSynthEffect = Synth(\mic, [\in, 0, \out, ~delBus], ~micGrp);
6.do({
	Synth(\delay, [
		\in, ~delBus,
		\out, 0,
		\mix, 1,
		\amp, 1/6,
		\delHz, exprand(0.02,0.08),
		\delMin, exprand(0.05,0.1),
		\delMax, exprand(0.101,0.2),
		\decay, rrand(3.0,6.0),
	], ~delGrp);
});
)

And, this is the effect that we've created. It sounds like this. If we were to try to categorize it, I guess we'd call it a reverb effect. But, it's also got this sort of weird, swirling, pitch-shifting effect. Or something. I dunno. Anyway,

s.freeAll;

yeah, so I'm doing s.freeAll, because I'm lazy, but if we wanted to fade the effect out more graciously, then we'd add a gated amplitude envelope to the delay SynthDef, so that we could fade it out, but I think I'm gonna leave it here, and let you continue experimenting with microphone signal processing on your own.

Oh! But actually, before we finish, while we're on the topic of delays, there is one thing I definitely should mention. So, it's probably tempting to increase 6.do to some bigger number to make even more delays, because that's fun, why wouldn't you do that? But, if you do that there's a very good chance that the server will grind to a dead stop, and you'll get these "memory allocation failure" messages in the post window...

(
~micGrp = Group.new;
~delGrp = Group.after(~micGrp);

~micSynthDirect = Synth(\mic, [\in, 0, \out, 0], ~micGrp);
~micSynthEffect = Synth(\mic, [\in, 0, \out, ~delBus], ~micGrp);
20.do({ //will fail if numberIsTooBig.do({ })
	Synth(\delay, [
		\in, ~delBus,
		\out, 0,
		\mix, 1,
		\amp, 1/6,
		\delHz, exprand(0.02,0.08),
		\delMin, exprand(0.05,0.1),
		\delMax, exprand(0.101,0.2),
		\decay, rrand(3.0,6.0),
	], ~delGrp);
});
)

and I think I actually have to force quit SuperCollider here, so... the reason this happens, is that... ok first of all, for a digital delay line to function it needs a buffer an allocated block of memory in which to store incoming audio samples, so that they can be played back some amount of time later, because that's how a delay line works. And the necessary buffer can be allocated manually (by the user) or dynamically (by the computer), depending on how the algorithm is designed. So, for the delay UGens that we looked at (the delay family and the comb family), the required memory space is allocated dynamically, and this is nice because we, the user, don't have to worry about manually providing the correct number of buffers with the correct sizes. But the audio server has a limit to the amount of memory that can be dynamically allocated, and this is determined by a ServerOptions attribute called memSize. This is a value in kilobytes, and it's kind of on the low side by default — only 8192 — so whenever I'm dealing with these specific delay UGens, I will usually increase the memSize as part of my server setup. So, that code would go up here along with using the audio device and setting a number of hardware channels. I've gotten in the habit of going with two to the power of 20.

Now, I don't know if this is the *optimal* number to go with, I mean there's obviously a limit here, probably related to how much RAM your computer has, I guess, I dunno. But this value comes out to be approximately 1 GB (I think) and it's been very consistent at avoiding these memory allocation failure messages. I'm not even sure it has to be a power of two, frankly, but I just do a power of two anyway, because computers love powers of two, it's like their favorite thing.

So, reconfigure and reboot,

(
s.options.device = "Scarlett 2i2 USB";
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.options.memSize = 2.pow(20);
s.reboot;
)

//also add SynthDefs and create audio Bus again:

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in!2) * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\delay, {
	arg in=0, out=0, mix=(-0.5), decay=3, amp=1, delHz=0.25, delMin=0.1, delMax=0.4;
	var sig, delay;
	sig = In.ar(in, 2) * amp;
	delay = CombL.ar(
		sig,
		0.5,
		SinOsc.kr([delHz, delHz*0.9]).exprange(delMin,delMax),
		decay
	);
	sig = XFade2.ar(sig, delay, mix);
	Out.ar(out, sig);
}).add;
)

~delBus = Bus.audio(s, 2);

and now we can be much more liberal with how many delay Synths we want to make, although I am going to scale the amplitude down even further. 1/20 is probably overcompensating but I'm just being safe.

(
~micGrp = Group.new;
~delGrp = Group.after(~micGrp);

~micSynthDirect = Synth(\mic, [\in, 0, \out, 0], ~micGrp);
~micSynthEffect = Synth(\mic, [\in, 0, \out, ~delBus], ~micGrp);
20.do({ //will fail if numberIsTooBig.do({ })
	Synth(\delay, [
		\in, ~delBus,
		\out, 0,
		\mix, 1,
		\amp, 1/20,
		\delHz, exprand(0.02,0.08),
		\delMin, exprand(0.05,0.1),
		\delMax, exprand(0.101,0.2),
		\decay, rrand(3.0,6.0),
	], ~delGrp);
});
)

So, here's the effect with twenty comb delays, instead of six. I'm not sure it actually sounds that much more interesting, actually, and it probably ought to go through a low-pass filter to shave away some of these sizzly high frequencies. I bet we could make more than twenty, but of course there’s going to be an upper limit somewhere, I don’t know exactly where, I guess we could do the math and figure it out.

s.freeAll;

But the point is, with this more generous memSize, we have significantly more freedom with using these delay UGens.

So, that's it for Tutorial 20. I know this was supposed to be a microphone tutorial, and it is, but I guess I kind of also turned into a delay tutorial toward the end. But, you know, you could argue that microphone signals aren't really very interesting unless you do stuff to them, and delays (I think) are one of the more fun and interesting things you can do.

So, in previous videos, we've done a fair bit with synthesis, and we've done some sampling, but this is really the first time we've dealt with the idea of a live signal, and so I hope this tutorial puts you on a good path where you can start exploring and experimenting on your own, and of course there's tons of cool stuff you can do with mic signal processing, especially if you really try to think outside the box. Just make sure that you're always mindful of feedback, and don't put your ears in a dangerous situation. I don't exactly know what the next tutorial will cover, but I do have some ideas, including FM synthesis, waveshaping, granular synthesis, and also adding your own methods and classes to the SuperCollider library. So, if you have any thoughts about what you'd like to see next, feel free to leave a comment below. Or, if you just enjoyed this tutorial and want to say so, or give a thumbs up, that's cool too. So, thank you all very much for watching, and see you next time.