Hey everyone, welcome to tutorial 29. In this video, we'll look at some intermediate pattern techniques meant to help you use SuperCollider's pattern library more modularly, concisely, and hopefully, in more ways that are musically interesting and exciting. This is Patterns Part 2, so the assumption is that you know how to use Pbind on a very basic level, and should also be familiar with a handful of patterns commonly used for generating values, like Pwhite, Pseries, Pseq, Prand, etc. If patterns are totally new to you, I recommend watching tutorial 10 before this one.

Specifically, in this video, I'm gonna discuss the following six things. Tempo/Quantization, the sustain and legato parameters, Pfunc and its related function-based patterns, constraint patterns, modular composition of patterns, and finally, sharing data across several different Pbinds.

So, let's do this. To give ourselves some sound to work with, here's a simple SynthDef that plays a triangle wave, with a stereo panner, and an ADSR envelope. And a Pbind that defines a sequence. We play pattern p, and it returns the EventStreamPlayer that performs the sequence.

s.boot;

(
SynthDef(\tone, {
	var sig, env;
	env = Env.adsr(
		\atk.ir(0.001), \dec.ir(0.2), \slev.ir(0.4), \rel.ir(0.3)
	).ar(Done.freeSelf, \gate.kr(1));
	sig = LFTri.ar(\freq.kr(880));
	sig = Pan2.ar(sig, \pan.kr(0), \amp.kr(0.3));
	sig = sig * env;
	Out.ar(\out.kr(0), sig);
}).add;
)

x = Synth(\tone);

x.set(\gate, 0);

And a Pbind that defines a sequence. We play pattern p, it returns the EventStreamPlayer that performs the sequence.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

x = p.play;
)

x.stop;

And it is very boring, but — trying to keep it simple to help us focus on understanding technique and avoid cluttering up the teaching space with extra stuff. So first, let's talk about tempo and rhythmic quantization. Now, I have covered this topic in some livestreams and classroom lecture videos, and in fact I included this topic in tutorial 10, but, looking back on that video, which I made, uh, almost ten years ago, my approach to tempo and quantization technically worked, but it was messy, and it was musically unintelligent and unintuitive. In Part 1, I was scheduling patterns on the default TempoClock, which runs at 60 beats per minute, but then doing all this manual calculation to provide values for quant and stretch in order to basically trick the patterns into playing at a different tempo. It's not a good way to do things, don't do what I did in that video, so at the cost of revisiting a topic, I just want to set the record straight.

Let's say, we want this Pbind to produce eighth notes at 112 beats per minute. Step one, don't do a bunch of random math, instead, make a TempoClock running at the desired tempo, remember that it expects a value in beats per second, so if you want to do beats per minute, just divide that value by 60. I usually like my TempoClocks permanent so that pressing command period doesn't destroy them.

t = TempoClock(112/60).permanent_(true);

Run this, and not that this is super important or useful, but you can visually confirm the clock is running if you type t.beats on a separate line, and then just spam shift-enter, to see the current beat count.

t.beats;

Run t.nextBar several times and you'll notice that a TempoClock isn't just a pure beat counter, but also conceptualizes beats as being grouped together as bars, by default with four beats per bar. Lots of music in the world can be rhythmically represented on a grid like this, so obviously this is a useful design.

t.nextBar;

t.beatsPerBar;

Now, let's imagine for a moment, you're making music that has three beats per bar, or sever or whatever. If it's something other than four, it's a good idea to configure the clock consistently, and though it's tempting to just set beatsPerBar to that value, this doesn't work, because we're only allowed to make changes that affect clock timing within the context of the clock's scheduling mechanism.

t.beatsPerBar_(3);

So, if you want to start a TempoClock with a custom number of beats per bar, well, first let's stop this clock to get rid of it, then reuse this TempoClock creation line, and chain onto the end of it a schedAbs message, which says, at time zero, in other words, the instant this clock comes into existence, set beats per bar to three. Run this, and we see nextBar returns multiples of three instead of four.

t.stop;

t = TempoClock(112/60).permanent_(true).schedAbs(0, {t.beatsPerBar_(3)});

t.nextBar;

If we want to change beatsPerBar mid-performance, like, switch back to four beats per bar, we use basically the same technique, t.schedAbs, except we want this change to occur on the next bar, not time zero, which is in the past, and provide a function that does the change,

t.schedAbs(t.nextBar, { t.beatsPerBar_(4) });

t.nextBar;

wait a second or two just to make sure the next downbeat happens, and now we can see the interval between downbeats is four instead of three. Now, these numbers might be multiples of four, they might not be, depending on when the time signature change happened, but if they're not multiples of four, don't panic, it's totally fine, the clock knows what it's doing, it knows how to find the downbeat, it basically exists so that you can just set it and forget it.

So, to play a pattern on a clock, we provide the clock when calling play. Importantly, these dur values represent beats, not seconds, so if we arbitrarily say one beat at 112 beats per minute is a quarter note, then 0.5 is half of that, which is an eighth note.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

x = p.play(t);
)

x.stop;

Playing a pattern on a clock guarantees it'll use that clock's tempo, but it doesn't guarantee the pattern will start on any particular beat, in fact it starts pretty much immediately, and this makes it virtually impossible to get a second pattern to sync up with the one that's already playing. So, here's a second pattern, same rhythm, different pitches. If you've never seen this 3s, it means three sharp, it evaluates to its receiver plus 0.1, which degree interprets as instruction to raise pitch by a half step. Lowercase b instead of s means flat, which does the same thing but in the other direction. Anyway, if we play p first, and then try to manually get q to line up...yeah, ok, that was way off.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

x = p.play(t);
)

(
q = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([0, 1, 3s, 4], inf),
);

y = q.play(t);
)

Quantizing the patterns is the solution here, and we provide that information along with the clock. We'll skip over the second argument, which is protoEvent, it's a way for us to override the default Event, which, we don't care about right now, we want the third argument, "quant," and the most formal approach is the Quant class, which has three components: quant, phase, and timing offset. The first of these represents precisely how fine or coarse you want your quantization grid to be, this is usually called quantization "granularity," so one means schedule on the next available beat, four means schedule on the next downbeat, assuming four beats per bar, and so on. The second value is called phase, and this is a beat offset relative to the target determined by quant granularity, positive phase means later, negative phase means earlier. So, for example, quant four phase one means start playing one beat after the next downbeat, and phase negative one is a one-beat pickup right before the next downbeat. So, to demonstrate, we can play pattern p starting on the next downbeat, and then whenever we feel like it, schedule q with the same quant but -0.25 phase, it'll come in one quarter of a beat early, and these half-beat patterns will interlock perfectly. And I do recommend playing around with these numbers on your own as a way to better understand how they work.

x = p.play(t, quant: Quant(4));

y = q.play(t, quant: Quant(4, -0.25));

x.stop;

y.stop;

The third argument, timingOffset, is...not of interest at the moment, but let's bookmark that because we'll come back to it later in the video. A quick syntax note about Quant, instead of typing out capital Q-u-a-n-t, an array of numbers has the same effect, and if we're only interested in specifying quant granularity, without phase or timing offset, we can just provide that number by itself.

What about tempo changes? Instantaneous tempo changes are easy, we rely on the same technique we used earlier, to change beats per bar. So, for example, this line prepares a change to 80 beats per minute. So, play pattern p on clock t, and then evaluate the tempo change line.

x = p.play(t, quant: Quant(4));

t.schedAbs(t.nextBar, { t.tempo_(80/60) });

x.stop;

An obvious follow-up question here is: Ok, how do you do a gradual tempo change? Now, this is a little trickier, but not difficult. Conceptually, I guess we'd like to be able to specify a target tempo, and a duration, measured in beats, over which that tempo change should gradually occur. So, let's write a function that takes these two parameters as inputs. In addition to the target tempo and number of beats, we'll also give ourselves the ability to apply this change to an arbitrary clock. Now, right now we just have the one clock, but maybe in the future we might have multiple clocks going at the same time, with different tempos, and generally it's good practice to avoid hard-coding things into a function.

Animation, in the context of TV and film, is not actually smooth motion, it's a sequence of static images which, when presented with the right timing, creates the illusion of motion. And we're gonna do something similar here, specifically, apply an incremental tempo change on each beat until we arrive at the target tempo. So we'll need a couple variables here, first an integer counter, lowercase i, because we're gonna be doing some sort of incremental process. And another variable called tempoArray, which will contain an incremented set of numbers that represent tempo values, and Array.interpolation is a nice option here, which creates an array of arbitrary size, filled with linearly-interpolated values from min to max, for example, here's an array of 17 numbers that linearly increment from zero to two.

Array.interpolation(17, 0, 2);

In our function, the array size is the number of beats, starting at the current tempo, ending at the target tempo, dividing by 60 where appropriate. And then, the actual scheduling process. So, a schedAbs for the following to occur on the next bar. We set the clock tempo to the item in tempoArray at index i. Then, increment that counter, and then a conditional check to see if we've arrived at the target tempo. If i is less than numBeats, we're not done yet, so return the number one. If we have arrived at the end of the tempo change, print the symbol 'done.' Now, here's the subtle reason why this conditional logic is important and why we're returning these specific things: when we schedule a function on a clock, if that function returns a number, the function is automatically rescheduled that many beats later. If the function returns something that isn't a number, like, a symbol, then no rescheduling happens.

So, build the function, and for a little extra clarity, I'll also make a short additional function called "post", which when evaluated prints the current beat and returns one so that it's rescheduled for every beat, and schedule this on the clock to see beat numbers in the post window.

(
~tempoChange = {
	arg clock, newTempo, numBeats;
	var tempoArray, i = 0;
	tempoArray = Array.interpolation(numBeats, clock.tempo, newTempo/60);
	clock.schedAbs(clock.nextBar, {
		clock.tempo_(tempoArray[i]);
		i = i + 1;
		if(i < numBeats) {1} {\done.postln};
	});
};
)

(
~post = { t.beats.postln; 1; };
t.schedAbs(t.nextBar, { ~post.() });
)

So now, all we have to do is call this tempoChange function with appropriate input values, Let's play pattern p so that we're listening to something. And let's ramp up to 160 bpm over eight beats. And ramp back down to 112 beats per minute over twelve beats. To disable this beat posting behavior, we just redefine the post function to be empty, which has the effect of disabling the rescheduling mechanism.

x = p.play(t, quant: Quant(4));

~tempoChange.(t, 160, 8);

~tempoChange.(t, 112, 12);

x.stop;

~post = { };

So, that's tempo and quantization in a nutshell, often a crucial and extremely helpful first step whenever you're doing any sort of rhythmic sequencing or tempo-based music.

// (2) sustain and legato

Ok, moving on, let's talk about the "sustain" key, which is part of the internal structure of the default note event. You'll notice if we audition our SynthDef using a Synth, we have to manually zero the gate to release the sound.

x = Synth(\tone);

x.set(\gate, 0);

This is because we have an ADSR envelope that will hold at its sustain level indefinitely until we tell it to stop. But instad, if we audition the sound by playing an event, the release happens automatically, how convenient.

(instrument: \tone).play;

This is because in the default note event, there is a \sustain key, which corresponds to a value that represents the number of beats to wait before automatically sending a release message. And obviously the default note Event has other consequences as well, like the pitch is different here, and it's a little quieter, so, there's a lot going on under the hood, but for now we're just gonna focus on this sustaining behavior. The auto-release message is nothing fancy, it's just a regular set-gate-zero thing, but it's important to recognize that this sustain functionality assumes there is a SynthDef argument named "gate," being used to release an amplitude envelope, and if you don't have a gate argument, or you're using your gate argument differently, then the sustain key won't do anything or it won't work correctly.

It's possible, though not particularly easy or intuitive, to pop the hood and kind of dig around in the Event infrastructure to kind of see what's going on back there. So the following expression, Event dot partialEvents dot durEvent at sustain, this thing, which is a function, determines the sustain value of a note.

Event.partialEvents.durEvent[\sustain];

And there's a nice little trick that lets us peek inside of a function inside using dot postcs, short for post compile string.

Event.partialEvents.durEvent[\sustain].postcs;

So, if sustain is not provided explicitly by the user, it'll be calculated by multiplying together dur, legato, and stretch. Side note, if this digging around is something that catches your attention, here are the expressions for freq and amp.

Event.partialEvents.pitchEvent[\freq].postcs;
Event.partialEvents.ampEvent[\amp].postcs;

But, anyway, back to our pattern p from earlier, we've provided the dur values ourselves, 0.5, and poking around a little more, we can see that legato has a default value of 0.8, and stretch is 1.

Event.partialEvents.durEvent[\legato].postcs;
Event.partialEvents.durEvent[\stretch].postcs;

So, in this specific case, sustain is 0.5 times 0.8 times 1 which is 0.4, which means each Synth generated by this EventStreamPlayer automatically receives a release message 0.4 beats after it comes into existence.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

x = p.play(t);
)

x.stop;

So, this means, in addition to, or perhaps as an alternative to, messing around with envelope segment durations to adjust note length, we have the option of adjusting sustain values, so if sustain is a tenth of a beat, the notes get released earlier.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
	\sustain, 0.1,
);

x = p.play(t);
)

x.stop;

Or, we can adjust sustain values indirectly by working with the legato key. Legato is a musical term that describes a phrase in which all the notes are all smoothly connected from one to the next so that there are no breaks or bits of silence between them. In the context of code, I suppose we're meant to conceptualize legato as existing on a scale between zero and one where one means fully legato and the notes get shorter as we get closer to zero. So legato 1 sounds like this.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
	\legato, 1
);

x = p.play(t);
)

x.stop;

Values bigger than one are fine, they won't break anything, it just means that the notes are gonna sustain for even longer and overlap with neighboring notes even more, and this might be desirable or it might not be, but you don't want sustain or legato values to get too close to zero, because the timing interval between note start and note release gets so small that it starts to do weird stuff. Here's an interesting example, with a legato value of one millibeat.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
	\legato, 0.001
);

x = p.play(t);
)

x.stop;

We only hear like 15 or 20 percent of the notes, but, oh no, the problem is actually even worse than that, because if we check the node tree after stopping the pattern, oh look, we have some visitors, a bunch of silent stuck notes that are taking up space and eating up CPU. What's happening here, I think, is that the release messages are generated so quickly after note onset, that they actually arrive within the same control block as the creation of the Synth they're supposed to target, or maybe even slightly before, I'm not totally clear on the specifics, but it's definitely a language-server timing issue. The bottom line is, you don't want sustain or legato too close to zero, otherwise this kinda stuff starts happening. And I don't have a good answer for exactly how close is too close to zero, I don't know if you actually need to know, but at least in this case, a value of 0.01, for example, seems to work fine, and it's hard to imagine needing anything shorter than this.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
	\legato, 0.01,
);

x = p.play(t);
)

x.stop;

Keep in mind that sustain and legato don't necessarily create short notes, they only govern the timing of release messages, so, if you want super short notes, you may actually need to get in there and shorten the envelope segments themselves.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
	\legato, 0.01,
	\rel, 0.02
);

x = p.play(t);
)

x.stop;

So that's basically how sustain and legato work, they are good options for handling note timing, sometimes can be a bit easier than micromanaging envelope segment durations, and definitely in the category of things I wish I had understood a little bit better when I was just getting started with SuperCollider.

// (3) Pfunc/Plazy

Alright, switching gears, moving on to the third topic, I want to turn our attention to a family of "function-driven patterns," or as I sometimes call them, "choose-your-own-adventure" patterns. These are patterns that don't follow some predetermined mathematical formula, but instead, evaluate some user-defined function to determine their next value. Common examples include Pfunc, also Prout, and Plazy, the full collection is in Browse, Streams-Patterns-Events, Patterns, and Function. Because these patterns rely on user-defined functions, they are inherently open-ended, and this can make it difficult at first to understand precisely how to use these patterns, and why they can be so useful.

So, let's look at Pfunc, which does something extremely simple. When asked for its next value, Pfunc evaluates its function and returns the result. To demonstrate, let's grab the Pbind from earlier, make a few small changes, and instead of using Pseq for scale degrees, we'll use Pfunc, and do the simplest thing imaginable, and just use a function that always returns five.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Pfunc({ 5 }),
);

x = p.play(t);
)

x.stop;

Obviously the result would be the same if this Pfunc were just the number five instead, so, Pfunc isn't doing anything special, at least not yet, but you can start developing this function into something more interesting, like having the function start with degree five, but then randomly transpose the pitch.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Pfunc({
		var deg = 5;
		deg + [-7, 0, 2].choose;
	}),
);

x = p.play(t);
)

x.stop;

And, still this isn't like a super-complicated algorithm, we could do the same thing with Prand, but hopefully you can see where this is going. We could continue developing this function in all sorts of ways, and it's all nicely contained in a single pattern. So, if you ever find yourself banging your head against the wall trying to find the right combination or nesting structure of several different patterns, Pfunc can be a good option if you want to just express your algorithm using normal everyday code.

But, Pfunc has many other tricks up its sleeve. Let's say we want to be able to change the degree information dynamically, while the sequence is playing. And maybe at some point in the past, you tried something like this. We give ourselves an environment variable, plug it in for degree, and then try to change it mid-stream.

(
~deg = 5;

p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, ~deg,
);

x = p.play(t);
)

~deg = 9;

x.stop;

But this doesn't work, because the value of 'deg' is checked only once, when the Pbind is created, and, with this approach, there's no way to make Pbind, or the EventStreamPlayer, aware of any changes to this variable. So, here's a situation where the function-evaluation aspect of Pfunc really shines. If we wrap the variable inside of a Pfunc, all of a sudden, we have dynamic control.

(
~deg = 5;

p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Pfunc({ ~deg }),
);

x = p.play(t);
)

~deg = 9;

x.stop;

This works because every time we request the next value from Pfunc, it re-evaluates its function and therefore tracks any changes that might have occurred. For some of you, this behavior might remind you of a class called Pdefn, which is a pattern from SuperCollider's live coding toolset designed to do basically the same sort of thing, as we can very quickly demonstrate.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Pdefn(\deg, 5)
);

x = p.play(t);
)

Pdefn(\deg, 9);

x.stop;

Pdefn is, of course, a fine choice for this sort of thing as well, but I think it's just kind of interesting and cool that Pfunc provides access to basically the same live coding technique without actually having to use any live coding classes. Now, if we wanted to quantize a Pfunc change, we would need to schedule that change using the clock scheduling mechanism, like we did earlier. And to make this extra clear, I'm gonna add an amplitude pattern that emphasizes the downbeat, and quantize the initial play message. Then, we set up a scheduling call, to happen on the next downbeat, and a function that updates the environment variable. We do need to be careful to make sure that this function doesn't return a number, otherwise it'll automatically reschedule the change that many beats later, so ending the function with a non-number is the general solution to that problem.

(
~deg = 5;

p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\amp, Pseq([0.5] ++ (0.1 ! 7), inf),
	\degree, Pfunc({ ~deg }),
);

x = p.play(t, quant: 4);
)

t.schedAbs(t.nextBar, { ~deg = 9; nil; });

x.stop;

This approach seems to work consistently, but I think it's the case that SC doesn't have an mechanism for specifying order of execution of things scheduled to occur at the exact same time on a clock, so if you get unexpected results here, or if you just want a little bit more certainty, you can subtract a tiny amount from t.nextBar, to guarantee that the change to the variable will occur just slightly ahead of the EventStreamPlayer.

t.schedAbs(t.nextBar - 0.01, { ~deg = 9; nil; });

And there's even more that Pfunc can do. When Pfunc is used as a value generator inside of a Pbind, you can declare an argument which will represent the current Event that Pbind is in the process of building. So, to demonstrate, we're gonna have the Pfunc just post the event, and then because an Event is not a suitable item for a scale degree, we need to return something that is, so we'll return the number five again. And now when we play the Pbind, we're not actually interested in the sound at the moment, instead, watch the post window:

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\amp, Pseq([0.5] ++ (0.1 ! 7), inf),
	\degree, Pfunc({ |ev| ev.postln; 5; }),
);

x = p.play(t, quant: 4);
)

x.stop;

You can see ~ev is the current Event, and each one contains instrument name, dur value, amplitude, and sustain. More importantly, having access to this information can be super useful, because it gives us the ability to make one parameter dependent on the value of another, or even dependent on multiple other parameters. For example, let's randomize the amplitude, and suppose we want lower scale degrees to be louder, and higher scale degrees to be quieter. In the Pfunc, in addition to the event argument, we'll declare variables for an array of scale degrees and an index. We calculate the index by mapping the current amplitude onto a new range, so basically, a lower amplitude means a higher index, and vice-versa. Then, simply retrieve the degree value stored at that index.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\amp, Pexprand(0.03, 0.6, inf),
	\degree, Pfunc({ |ev|
		var degrees = [5, 7, 8, 9, 10s, 11, 12], index;
		index = ev[\amp].explin(0.03, 0.6, 6, 0).round;
		degrees[index];
	}),
);

x = p.play(t, quant: 4);
)

x.stop;

I did something similar in tutorial 10 using Pkey, and that's a totally legitimate approach as well, but whereas Pkey only gives us access to one key at a time, Pfunc lets us access the entire Event, or at least, everything that the Pbind has put into the current Event so far. Which actually brings us to another potential pitfall concerning the order of key-value pairs inside a Pbind. Now, normally, the order of key-value pairs is inconsequential, but each Event is populated with values in the order they appear, so order does matter if one parameter is gonna depend on another. So if amp appeared after degree, then playing the Pbind just fails because ~ev at amp doesn't have a concrete value at this point in the process.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Pfunc({ |ev|
		var degrees = [5, 7, 8, 9, 10s, 11, 12], index;
		index = ev[\amp].explin(0.03, 0.6, 6, 0).round;
		degrees[index];
	}),
	\amp, Pexprand(0.03, 0.6, inf),
);

x = p.play(t, quant: 4);
)

x.stop;

One more trick involving Pfunc, similar to this previous example in that it involves essentially locking two parameters together, but we'll consider it from sort of a different angle. Imagine a situation where you're randomly selecting values for one parameter, like amplitude, and also selecting random pitch values, but suppose you want these two random processes to be correlated, so that scale degree 5 always has amplitude 0.75, 9 with 0.25, and 12 with 0.08. In this version, amp and degree are completely independent and uncorrelated.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\amp, Prand([0.75, 0.25, 0.08], inf),
	\degree, Prand([5, 9, 12], inf),
);

x = p.play(t);
)

x.stop;

So here's the trick: we can lock two parameters together by expressing them as an array of two keys, like this. Then, we just need to make sure Pfunc returns an array of two values, in the correct order, and Pbind will automatically assign them. We'll also trace this Pfunc so that we can clearly see what's going on.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	[\amp, \degree], Pfunc({
		[ [0.75, 5], [0.25, 9], [0.08, 12] ].choose;
	}).trace
);

x = p.play(t, quant: 4);
)

x.stop;

You might encounter examples of this in which the array of keys is without slashes and preceded by a hash symbol. This creates what's called a literal array, documented in the help file for Literals in the section on Arrays. My incomplete understanding is that using a literal array is computationally faster, so it's basically a minor optimization.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	#[amp, degree], Pfunc({
		[ [0.75, 5], [0.25, 9], [0.08, 12] ].choose;
	}).trace
);

x = p.play(t);
)

x.stop;

It's worth pointing out that this array-of-keys trick is not specific to Pfunc. In this particular case, we could use Prand to get the same results, doing something like this.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	#[amp, degree], Prand([ [0.75, 5], [0.25, 9], [0.08, 12] ], inf).trace
);

x = p.play(t);
)

x.stop;

Ultimately, the thing I'm trying to emphasize with these Pfunc examples is its flexibility, and that it's sort of like a chameleon pattern that can emulate other value patterns, like Prand and many others, but also, if you have some complex idea and don't quite know how to put it together using math-based patterns, you can just create it yourself with Pfunc.

Ok, so Prout is another function-driven pattern that's a little bit different but ultimately very similar to Pfunc. We provide a function that would ordinarily appear inside of a Routine, which is a special type of state-aware function that can pause and return values partway through. This means we can put one or more "yield" calls inside Prout, and those yielded values are the ones that Pbind actually uses to build Events. So let's do the same thing we did with Pfunc, and use Prout to yield the number five.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, Prout({ 5.yield })
);

x = p.play(t);
)

Prout doesn't automatically repeat itself. By contrast, when a Pfunc is asked for its next value, it doesn't really know anything about before or after, it just evaluates its function again and again, each time the next value is demanded. But a Prout, like a Routine, remembers where it left off, and so after we yield five and play a note, and then ask Prout for the next value, it says, "I'm done, I've got nothing else," and the EventStreamPlayer ends. Now, if we want to repeat this process, we need to explicitly say so, for example, wrapping 5.yield in a 3.do will produce exactly three notes, and inf.do, or just loop will make an infinite stream. There's even a single-character method for creating a Prout, by putting dot-p after the function, or even simpler, a single lowercase p immediately before.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, p{ loop{ 5.yield } },
);

x = p.play(t);
)

x.stop;

A slightly more complex use of Prout might look like this. We yield five, then flip a coin for a 50% chance that we'll yield seven, and if we've yielded seven, then there's another coin flip for a 40% chance to yield a chromatic sequence of three notes.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\sustain, 0.1,
	\degree, p{ loop{
		5.yield;
		if(0.5.coin) {
			7.yield;
			if(0.4.coin) { [12, 12s, 13].do({ |n| n.yield }) }
		};
	} },
);

x = p.play(t);
)

x.stop;

Basically, Prout can do all the same things Pfunc can do, but gives us even more options by allowing us to build and customize what is essentially a multi-stage function.

And finally we have Plazy, which is a lot like Pfunc, except that its function should return a pattern instead of a value. Here's an example: let's say we want to sequence through these scale degrees, in order, but on each seqeunce, start at the beginning and output a random number of them. The "keep" method is a convenient way to hack off a random chunk from the end of the array.

[-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8))

But if we plug this into a Pseq....

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), inf),
);

x = p.play(t);
)

x.stop;

the keep operation only happens once when the Pbind is created, so we get the exact same trucated sequence forever. So, Plazy to the rescue. Now, just wrapping Pseq in a Plazy isn't necessarily enough, because this Pseq has an infinite length. So, Plazy will return and embed this Pseq, with a randomly truncated array, but because the Pseq is infinite, the Plazy will never be asked to re-evaluate its function.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), inf)
	})
);

x = p.play(t);
)

x.stop;

So the adjustment we need to make involves two steps. First, set Pseq or whatever internal pattern you're using, to do its thing only once. Now, this alone isn't enough, because Plazy does not have a parameter for the number of repeats, and instead only calls its function once. I'm actually not totally sure why Pfunc doesn't also have have this problem, but, doesn't really matter, because there's an easy solution, which is to wrap the Plazy in a Pn, a pattern that repeats another pattern an arbitrary number of times, and we'll make Pn repeat the Plazy infinitely.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = p.play(t);
)

x.stop;

Many times, I've encountered a situation, like this, where I want a pattern to exhibit some dynamic behavior that's sort of outside the boundaries of what it normally does, and often you can engineer a solution that involves wrapping the pattern in this Pn Plazy combo in order to force that pattern to be created anew over and over again. So, that's Plazy, Prount, and Pfunc, and hopefully this sheds some light on the usefulness and adaptability of these function-driven patterns.

// (4) Pfin/Pfindur

Moving on to topic number four, I want to talk about patterns that constrain the output of other patterns, and this is is a pretty straightforward concept, but nevertheless a useful one. I want to highlight two patterns in particular, named Pfin, and Pfindur. Both are used by enclosing them around some other pattern, and as a result, they prevent the output of that internal pattern from exceeding a certain length. So let's look at Pfin first, which limits the number of values a pattern will output when performed as a stream. So, simple example first, suppose we have an infinite Pwhite. Convert to a stream, and we can sit here and call next, next, next, next, next all day long, we will never run out of values.

(
p = Pwhite(0, 9, inf);
x = p.asStream;
)

x.next;

To use Pfin, we provide a numerical limit, and the pattern to be constrained.

(
p = Pfin(5, Pwhite(0, 9, inf));
x = p.asStream;
)

And we have some stylistic options here, like, we could modify the Pwhite on a separate line after creating it.

(
p = Pwhite(0, 9, inf);
p = Pfin(5, p);
x = p.asStream;
)

But usually what makes the most sense to me is to apply Pfin when the stream is created, like this.

(
p = Pwhite(0, 9, inf);
x = Pfin(5, p).asStream;
)

x.next;

And so now, calling next on the stream returns five values, and then it starts returning nil to indicate that it's done. The reason I think it makes sense to apply Pfin as part of the stream creation process is because the stateless pattern p then retains its infinite characteristic, and can easily be reused to generate a different stream that outputs exactly one value, or twelve values, or whatever. Now, if it's exactly five values we want, why don't we just tell that to Pwhite and forget about using Pfin?

(
p = Pwhite(0, 9, 5);
x = p.asStream;
)

x.next;

It's a totally reasonable question, so, it's maybe not completely clear just yet why Pfin is advantageous, so let's look at an example involving an Event stream instead of a value stream, and in fact, let's just reuse the most recent Pbind example from our discussion about Plazy.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = p.play(t);
)

x.stop;

This EventStreamPlayer x is infinite, because all the keys in the Pbind are paired with patterns or values that are interpreted to be infinite. So, suppose we want this EventStreamPlayer to output exactly 16 notes. As an exercise, let's think about how we might do this without using Pfin. What about changing this inf to be 16? Well, that won't work, because that means Plazy will embed this Pseq 16 times, and each time it does that, Pseq produces a random amount of values, so this is not gonna be a guarantee of anything.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = p.play(t);
)

Another option that doesn't rely on Pfin would be to wrap one of these other values in a Pseq that's limited to 16 repeats, or we could even use Pn which is a little bit shorter.

(
p = Pbind(
	\instrument, \tone,
	\dur, Pn(0.25, 16),
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = p.play(t);
)

And although this does give us the result we want, it just feels kind of messy to me, like, why are the dur values the ones that are constrained, instead of instrument or sustain? And, even more problematically, if you were to like, glance at this Pbind for the first time, it is not visually obvious whether this is a finite or infinite pattern, you really have to comb through the numbers to figure that out, and this would be made considerably more difficult if the Pbind had like 20 or 30 key-value pairs instead of just four. And another problem is that, if we constrain the length using this Pn approach, then we've basically hard-coded this pattern to have a finite length, and to undo that choice, we'd either have to repeat this finite Pbind an infinite number of times (which is not the same thing as the pattern itself being infinite), or we'd just have to go in and change the code. So, I think Pfin becomes a very clean solution, which is to conceptualize all your Pbinds and value patterns as infinite up front, but then use Pfin as needed to make your performance streams the correct length.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = Pfin(16, p).play(t);
)

When using Pfin this way, the Pbind retains its ability to produce a stream of arbitrary length, and we only need to change this one value. Plus, in terms of readability, I think it becomes a lot more obvious what's going on at a glance. Pfindur, on the other hand, is conceptually similar to Pfin. We give it a constraint value and a pattern to be constrained, but instead of interpreting its constraint value as a quantity of output values, Pfindur treats this value as a duration measured in beats. So, remember, we're at 112 beats per minute, and in this pattern, every note Event has a dur value of a quarter-beat, so, four notes per beat. So, if we use Pfindur to limit the stream to two beats, we should hear exactly eight notes:

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.25,
	\sustain, 0.1,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = Pfindur(2, p).play(t);
)

Because Pfindur limits based on a duration measured in beats, it really only makes sense to use Pfindur with Event patterns, like Pbind, which are played on a clock and have an inherent sense of musical timing. I don't think it really makes sense to use Pfindur with value patterns like Pwhite, for example.

x = Pfindur(2, Pwhite(0.2, 0.5)).asStream;

x.next;

I mean, technically Pfindur is doing something here, it's like treating these numbers as rest durations, and maybe there's some context where this is useful, I'm just not sure what that would be. But anyway, back to using Pfindur with Pbind, if you have a musical pattern that's strictly rhythmic and deterministic, you can generally use either Pfindur or Pfin, it just depends on whether you prefer to think in terms of beat duration or number of events. But for irregular rhythms, Pfindur can be really useful in making sure that a stream occupies a very specific amount of musical time. This one, for example, is an arrhythmic variation that produces more of a continuous texture, but we can easily use Pfindur to make it last for exactly four beats.

(
p = Pbind(
	\instrument, \tone,
	\dur, Pexprand(0.1, 0.5),
	\sustain, 0.1,
	\atk, 0.2,
	\rel, 2,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = Pfindur(4, p).play(t);
)

For a little more clarity, I'll play a second Pbind at the same time as the first, and this second pattern is just going to count four beats like a metronome.

(
p = Pbind(
	\instrument, \tone,
	\dur, Pexprand(0.1, 0.5),
	\sustain, 0.1,
	\atk, 0.2,
	\rel, 2,
	\degree, Pn(Plazy({
		Pseq([-2, 0, 1, 2, 3s, 4, 5, 7].keep(rrand(2, 8)), 1)
	}), inf)
);

x = Pfindur(4, p).play(t);

Pfin(4, Pbind(\instrument, \tone, \dur, 1, \freq, 1000, \slev, 0)).play(t);
)

Just keep in mind that the constraint parameter in Pfin and Pfindur is an upper limit, so it will limit patterns that are too long, but it will not automatically extend patterns that are too short. So, that's how these constraint pattenrns work, they can be super helpful in transforming infinite patterns into finite streams that occupy specific amounts of musical time.

// (5) Modular approaches - Pbindf, Pchain

For the next topic, I want to talk about the general idea of modular pattern composition, now, I don't mean composition in the traditional musical sense, instead, I'm more talking about functional composition, in other words, we start with a bunch of simple patterns or maybe even incomplete parts of patterns, treat thehse things as modular building blocks, and then freely assemble and combine them to create complex blended variations. Two classes come to mind here, which are Pbindf, and Pchain. So, we'll start with Pbindf, which has the dubious distinction of being named almost identically to another mostly unrelated class called Pbindef, with an "ef" at the end instead of just "f." The latter is a live coding class, while the former, on the other hand, is an object that lets us add or modify key-values pairs in an existing Pbind. One of the main applications of Pbindf, as far as I can tell, is to take some Pbind as a starting point, and then easily generate variations on that Pbind, instead of having to manually type each variation in its entirety. Earlier in this video, I used these two Pbinds to demonstrate pattern synchronization. And, at a glance, it's very easy to see that q is a variation on p, with degree being the only difference between them.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

q = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([0, 1, 3s, 4], inf),
);

p.play(t);
q.play(t);
)

Here's how we can rewrite this example using Pbindf. For pattern q, instead of Pbind, we'll use Pbindf, using p as a starting point, and all we need to do is provide the degree information.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

q = Pbindf(p, \degree, Pseq([0, 1, 3s, 4], inf));

p.play(t);
q.play(t);
)

The result of Pbindf is that the degree pattern in p gets overwritten by this new information, and we end up with the same result, using less code. From here, you could make additional variations on p, like, here's a version that produces shorter triplet notes one octave higher:

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

q = Pbindf(p, \degree, Pseq([0, 1, 3s, 4], inf));
r = Pbindf(p, \dur, 1/3, \slev, 0, \mtranspose, 7);

p.play(t);
q.play(t);
r.play(t);
)

And it's good to keep in mind that once you create a Pbindf variation, you can then use it as a starting point for even more variations, basically branching your variations out in multiple directions. So, replace p with q in this second variation, and then this triplet idea is applied to the sequence that has the other four pitches instead.

[p to q in r-line above]

And, another thing to observe here is that we're allowed to supply multiple key-values pairs in a single Pbindf expression. The ones that already exist get replaced, and the ones that don't already exist get added. And, kind of a side note here, if you don't like the idea of several independent play messages, you can bundle them together in a Ppar, which is a pattern that takes an array of several Event patterns, and returns a new, singular Event pattern which is the result of superimposing the individual patterns in parallel with each other. And, to revisit a concept from earlier, we can use Pfindur to make sure this otherwise infinite parallel stream lasts exactly eight beats.

(
p = Pbind(
	\instrument, \tone,
	\dur, 0.5,
	\degree, Pseq([5, 7, 8, 9], inf),
);

q = Pbindf(p, \degree, Pseq([0, 1, 3s, 4], inf));
r = Pbindf(q, \dur, 1/3, \slev, 0, \mtranspose, 7);

x = Pfindur(8, Ppar([p, q, r])).play(t);
)

x.stop;

Pchain is sort of the same idea, except instead of blending a Pbind with one or more key-value pairs, we instead blend a Pbind with another Pbind. To start, we'll do a totally abstract example, just to explain the mechanics, and then follow it up with a more musical example. Let's say we have Pbind p, which has two key-value pairs, a3, b5. And then, Pbind q, which has b6, c8:

(
p = Pbind(\a, 3, \b, 5);
q = Pbind(\b, 6, \c, 8);
)

Pchain can take these two Pbinds, and combine them into a single pattern, which will contain a3, and c8, but we can't have two identically-named keys, so the question is, is b going to be 5 or 6 in the combined pattern? The answer depends on the order of the chain. If we say Pchain p, q,

x = Pchain(p, q).asStream;
x.next(());

then b is five. And if we swap p and q,

x = Pchain(q, p).asStream;
x.next(());

then b is 6. And just a side, note, when manually extracting events from an Event stream, we need to pass in a starting event, which is why we have this extra set of inner parentheses. But anyway, conceptually, the idea is that Pchain actually starts with the last item in its argument list, in this case, p, and then takes the pattern immediately to the left of that, and sort of, you know, places it on top, and as a result adds any new keys and overwrites any shared keys. So, in other words, q, being to the left of p, is the dominant one of the two, so that's why b ends up being 6, because it overwrites the value of 5 in the starting pattern. And it's useful to know that there's a symbolic shortcut for this Pchain operation, which for this example here will look like q less-than-greater-than p.

x = (q <> p).asStream;
x.next(());

And keep in mind you can chain more than 2 patterns, for example p chain q chain r, would start with r, and then add key-value pairs from q and overwrite shared keys in the process, and then overlay p on top of that result. Chapter 06c in James Harkins' practical guide talks about Pbindf and Pchain, and also gives a good explanation of why this operation happens from right to left.

p <> q <> r

So, I spent some time thinking about what an instructive musical example might look like, and one thing that occurred to me is that it can often be tedious to type envelope timing information again and again for every Pbind, because, you know, we do have a decent handful of parameters we have to deal with: attack, decay, sustain level, release, maybe also sustain or legato. So, I figured let's make a Pbind that contains only information that's essential to create short notes, temporarily forgetting about things like pitch, loudness, etc. This one here, like an example we saw recently, zeroes the sustain level so that our ADSR envelope basically becomes an AD envelope, with just a short attack and a short decay down to zero. And, since we're doing this, let's also make a Pbind that specifies long notes. And, further still, why don't we also make a Pbind that specifies which SynthDef to use.

(
~short = Pbind(\atk, 0.001, \dec, 0.08, \slev, 0, \rel, 0, \sustain, 0.2);
~long = Pbind(\atk, 2, \dec, 0, \slev, 1, \rel, 3, \sustain, Pwhite(2.0, 9.0));
~tone = Pbind(\instrument, \tone);
)

Now, these Pbinds are technically playable, and you can try this yourself, nothing bad's gonna happen. But, that's not really why we created them, rather the point is to treat them like the modular building blocks that they are, and assemble them together with other patterns to create the results that we actually want. So here's a fourth Pbind, named p, which has pitch information and a dur key for note onset timing.

(
~short = Pbind(\atk, 0.001, \dec, 0.08, \slev, 0, \rel, 0, \sustain, 0.2);
~long = Pbind(\atk, 2, \dec, 0, \slev, 1, \rel, 3, \sustain, Pwhite(2.0, 9.0));
~tone = Pbind(\instrument, \tone);
p = Pbind(
	\degree, Pwhite(-7, 7),
	\dur, Pexprand(0.2, 1),
);
)

If we assemble these patterns as ~short chain ~tone chain p, we start with pattern p, we tag our SynthDef name onto that, and then we tag our short envelope parameters onto that. If we replace ~short with ~long, then all of a sudden, we produce long notes instead.

x = (~short <> ~tone <> p).play(t);

x.stop;

x = (~long <> ~tone <> p).play(t);

x.stop;

So, hopefully that's a good summary of Pbindf and Pchain, it's good to keep these in mind anytime you want to take a more modular approach to building musical patterns, because they have the potential to streamline and really cut down on the amount of code you need to type. And there might be other interesting ways to use these classes that I'm not aware of, so if you've got a clever trick that I'm not addressing, let me know in the comments.

// (6) Sharing Data across multiple patterns

So, finally, the last topic in this video is a response to a question that comes up very often in slightly different forms, but always something along the lines of: "How do I get a Pbind to communicate with another Pbind?" or more simply, "How do I share data across multiple Pbinds?" This is a great question, and the solution isn't complicated or difficult, you just have to know a few things. Now, first of all, it should come as no surprise that James Harkins' practical guide includes a chapter on this very topic, 06g, so definitely give that a read, particularly the section titled "Communicating values between separate event patterns." There are all sorts of reasons you might want to share data across multiple patterns, but one of the most obvious applications I can think of is, let's say you have one pattern producing chords, and you want to have another pattern that plays a melody on top, based on pitches from those chords. So, being able to share data across two Pbinds is especially important if your chord pattern is random or just otherwise unpredictable in some way.

As we approach this solution, there's an analogy that comes to mind, which is the idea of audio rate UGens versus control rate UGens. Now, audio rate UGens are kind of the frontrunners, they're the ones that produce audio signals that get routed to loudspeakers and become sound. And even though control rate UGens don't make sound, they're still important because they generate data that shapes and influences the audio signals. So I think it makes sense to envision a similar approach with patterns, specifically, having some patterns that generate audio, and other patterns that generate what is essentially control data that audio patterns will use.

So first, let's make a data-generating Pbind, keeping things as simple as possible so that the essential concepts are clear. This data Pbind will generate rest events, which guarantees it'll never make any sound. We'll put it on an 8-beat cycle, and I'm going to use a Prand to randomly pick one of two arrays that each contain scale information and a chromatic transposition value. This first one is a major pentatonic scale with no transposition, that's gonna default to C major pentatonic, which contains C-D-E-G-A, and this is a minor pentatonic scale up three chromatic steps, and E-flat minor contains E-flat, G-flat, A-flat, B-flat, and D-flat. I'm picking these two pitch collections not necessarily because I think they'll sound good, but because the first is all white keys on the piano, and this one is all black keys, so there's no pitch overlap, which means it should be really easy to hear the difference.

(
~data = Pbind(
	\type, \rest,
	\dur, 8,
	#[scale, ctranspose], Prand([
		[Scale.majorPentatonic, 0],
		[Scale.minorPentatonic, 3],
	], inf),
);
)

Now, before we get to the trick that allows us to share data across multiple Pbinds, I want to start with some context. So, with value patterns, like this Pseq, you're allowed to apply math operations, as if we were just dealing with regular numbers, like adding seven, or squaring, or whatever.

(
x = Pseq([1, 20, 300], inf);
x.asStream.nextN(10);
)

(
x = Pseq([1, 20, 300], inf) + 7;
x.asStream.nextN(10);
)

(
x = Pseq([1, 20, 300], inf).squared;
x.asStream.nextN(10);
)

And when we do operations like this, the pattern becomes either a P-binary-operation or P-unary-operation, these are special types of patterns that generally we don't create ourselves, but which are created automatically in the background, and the purpose of these patterns is to defer calculation until we convert to a stream and actually request tangible values. Along these lines, you can also use collect to iterate over a pattern, as if we were dealing with an array or some other type of collection. When you collect over a pattern, it returns a Pcollect, a pattern that takes the values of the starting pattern and further processes them according to some function that we provide. In this case, it squares each value and adds one.

(
x = Pseq([1, 20, 300], inf).collect({ |n| n.squared + 1 });
x.asStream.nextN(10);
)

Collect can also be used on Event patterns, like Pbind. And in this case, the argument declared in the collect function represents each Event generated by Pbind, just like we saw with Pfunc. So, here's the trick: Within the collect function, we can intercept the current Event and assign it to an environment variable, thereby giving ourselves access to this data outside the boudaries of the Pbind.

(
~data = Pbind(
	\type, \rest,
	\dur, 8,
	#[scale, ctranspose], Prand([
		[Scale.majorPentatonic, 0],
		[Scale.minorPentatonic, 3],
	], inf),
).collect({ |ev| ~ev = ev; });
)

So then, if we run this, convert to a stream, and check the environment variable ~ev, initially it's nil, because, you know, we haven't done anything with it yet.

x = ~data.asStream;

~ev;

But then, as soon as we extract our first Event from the stream, we see that not only does the stream produce the expected results, but as a side effect, it also captures the most recent Event in the environment variable ~ev, which of course, is ours to use however we want.


x.next(());

~ev;

So, the hard part's pretty much over. Now we can start building musical patterns for generating chords and melody. For the chord pattern, to extract the stored data, we'll use Pfunc and just return an array containing these two pieces of data. And, we want the chords to be generated on the same timing cycle as the chord data, so we'll set dur to be eight beats. Plug in some envelope values that'll fade the chords in and out relatively slowly. For the degree key, this is where we have the option to get creative with how we actually voice the chords, so this is something you can experiment with on your own. I'm gonna do something pretty boring here and just use the array [0, 1, 2, 3, 4], which is gonna produce a five-note chord in root position, all notes in the same default octave, clustered together. You could certainly use Pfunc to maniuplate these degree values with, you know, random octave transpositions, or maybe randomly omitting one or two notes per chord, whatever. And we'll set the decibel level to be minus 30 which'll be quiet enough to just let these chords kind of hang out in the background.

(
~chd = Pbind(
	\instrument, \tone,
	#[scale, ctranspose], Pfunc({ [ ~ev[\scale], ~ev[\ctranspose] ] }),
	\dur, 8,
	\atk, 1,
	\dec, 0,
	\slev, 1,
	\rel, 2,
	\degree, (0..4),
	\db, -30,
);
)

Now, for the melody, same idea, different musical parameters. We extract the data using the same technique. For the dur values, we don't want to do eight again because that would just give us one note per every eight beats, that's pretty sparse, so we'll use a rounded Pexprand to produce shorter values that are all, you know, a little random, but which still get locked onto a grid of half-beats. Shorter envelope values, and for the degree pattern, Pbrown might be a nice choice so that the melody kind of wanders around in semi-stepwise fashion but with occasional jumps of up to three scale degrees. The zero and ten here are arbitrary, you can adjust these boundaries if you want the melody to have a range that's, like, higher or lower or bigger or smaller. And we'll make these notes minus fifteen decibels, considerably louder than the chords so that they'll be more present in the foreground.

(
~mel = Pbind(
	\instrument, \tone,
	#[scale, ctranspose], Pfunc({ [ ~ev[\scale], ~ev[\ctranspose] ] }),
	\dur, Pexprand(0.5, 3).round(0.5),
	\atk, 0.005,
	\dec, 0.2,
	\slev, 0,
	\rel, 0,
	\degree, Pbrown(0, 10, 3),
	\db, -15,
);
)

Finally, we want to play these three Pbinds together, and you might be tempted to just dump them into a Ppar, call it a day, and this might work, but there's a definite chance it won't.

~player = Ppar([~data, ~chd, ~mel]).play;

The Quant help file, in the section titled "Timing offset in Patterns," it says, "you might want two patterns that are sounding at the same time to evaluate in a specific order -- for instance, the second pattern might depend upon data calculated by the first. If they are scheduled on the clock for exactly the same time, you have no control over the order of execution." Now, way back in this video, I said we'd eventually come back to timingOffset in the context of Quant, and, here we are. Timing offset is a value that allows a pattern to perform its language-side calculations slightly earlier than it otherwise would, but any messages to the server are delayed by this amount, in order to compensate for the timing shift. So, timingOffset is almost always some small positive value, like 0.05 means the data calculation will happen 0.05 beats before the sound is produced. So, play the data pattern quantized to 8 beats with a timing offset, and play the two music patterns in parallel, with the same quant granularity, but without the timing offset.

(
~dataPlayer = ~data.play(t, quant: [8, 0, 0.05]);
~musicPlayer = Ppar([~mel, ~chd], inf).play(t, quant: 8);
)

~dataPlayer.stop;
~musicPlayer.stop;

And there you have it, chords and melody using the same pitch information generated by a third data pattern, so we are officially passing information from one Pbind to another. One slight musical improvement that occurs to me here, which conveniently allows us to reinforce a topic from earlier in the video, is that we can use Pn and Pfindur, to shorten the melody to be eight beats long, and then force it to repeat itself. This has the effect of making sure the melody pattern always produces a note on the downbeat every eight beats, which sort of helps us "feel" the downbeat a little bit more.

(
~dataPlayer = ~data.play(t, quant: [8, 0, 0.05]);
~musicPlayer = Ppar([
	Pn(Pfindur(8, ~mel), inf),
	~chd
]).play(t, quant: 8);
)

~dataPlayer.stop;
~musicPlayer.stop;

That's it for tutorial 29. I hope you find these pattern techniques useful, exciting and easy to understand, and I hope they help you get to the next level of pattern expression wherever you happen to be in your SuperCollider adventures. But, regardless of whatever kinds of crazy sounds you're working with, you should be apply these pattern techniques in your own work, to help you build sequences in more sophisticated and intuitive ways.

As I wrap things up here, although patterns have been super helpful for me, personally, as a high-level framework for musical expression, I don't necessarily want to give the impression that Pbind and patterns in general are the be-all end-all best and only way to do sequencing in SuperCollider, and as proof of that, and for the sake of variety, I want to give a shoutout to Nathan Ho, who is an electronic musician, educator, and former SuperCollider developer. Lately he's been making these unbelievably virtuosic synthesis patches, and like, none of them use Pbind or note events, it's all Routines and server timing methods like s.bind. And, don't take my word for it, just listen to this one, for example.

I mean, it just sounds so good, just incredible. Nathan also has a Patreon, and also a blog which is full of really cool, interesting ideas, links in the video description, definitely check out his work if you haven't already discovered it.

Finally, a very special shoutout to my backers on Patrons, who generously help support this channel and videos like this one, thank you all so much, I really, really appreciate it. If you enjoyed this video, please give it a like, subscribe if you're new, and I hope you'll consider becoming a Patron yourself. Thanks for watching, see you next time.

Patreon.thanks;