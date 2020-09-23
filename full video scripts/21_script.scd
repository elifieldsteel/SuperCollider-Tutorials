Hey everyone, welcome to Tutorial 21. In this video I've decided to cover some introductory approaches to frequency modulation synthesis, usually just called 'FM' for short. FM refers to a synthesis configuration in which the output signal of one oscillator, called the modulator, is used to offset the frequency of another oscillator, called the carrier. This is a really simple concept, but as we'll see in this video, FM is capable of creating a really impressive variety of sound that ranges from pure sine waves to dense, complex, and chaotic spectra, all of which can be generated from as few as two oscillators. In classic FM, the carrier and the modulator are both sine waves, so that's a good place for us to start.

Let's boot the server, and also launch our scope and frequency analyzer utilities, so that we can see what we're dealing with as we hear it.

s.boot;
s.scope;
FreqScope.new;

Here's a sound we've heard many times in this tutorial series: a lovely sine wave

{SinOsc.ar(500) * 0.2!2}.play;

with a fixed frequency of 500 Hz, amplitude scaled down by 0.2, and invoking multichannel expansion so that we hear it in both speakers. This will be our carrier oscillator, and the conventional way of introducing FM is to simply add another audio rate oscillator to the carrier frequency, like this. This'll be our modulator. Initially I'll set its frequency to be 1 Hz, and for right now, that's the only thing I'll specify:

{SinOsc.ar(500 + SinOsc.ar(1)) * 0.2!2}.play;

Right off the bat, this sounds like basically the exact same thing we just heard. But, we can see just the tiniest bit of left-right movement on our visuals, indicating that the frequency of the carrier is oscillating. If we don't specify otherwise, the output range of a SinOsc UGen is between negative 1 and positive 1, which means the frequency of the tone we're listening to is fluctuating between 499 and 501 Hz. And this is, like, *just* enough deviation for our ears to notice a change. It's sort of right on the threshold of perception. But, to get more substantial variation in the carrier frequency, all we have to do is amplify the modulating oscillator. The simplest way to do this is to specify a value for its 'mul' argument. With mul at 20, the carrier ranges from 480 to 520 Hz:

{SinOsc.ar(500 + SinOsc.ar(1, mul:20)) * 0.2!2}.play;

definitely wide enough to notice. And, with mul at 400, we get a very generous range, sweeping from 100 all the way up to 900 Hz.

{SinOsc.ar(500 + SinOsc.ar(1, mul:400)) * 0.2!2}.play;

So, technically we're already doing FM, but we haven't gotten into the really interesting stuff yet. All we've done for now is just make this wacky exaggerated vibrato effect. So, let's increase the modulator frequency little by little. So, instead of 1 Hz, here's 2 Hz...4 Hz...8 Hz.

{SinOsc.ar(500 + SinOsc.ar(2, mul:400)) * 0.2!2}.play;
{SinOsc.ar(500 + SinOsc.ar(4, mul:400)) * 0.2!2}.play;
{SinOsc.ar(500 + SinOsc.ar(8, mul:400)) * 0.2!2}.play;

Now, I'm gonna go ahead and replace this static value with MouseX, so that the horizontal screen position of the cursor controls the modulator frequency, starting at 1 Hz on the left edge, and 2 kHz at the right edge, and one for the third argument of MouseX specifies an exponential mapping. We'll also poll these values, so we can see them in the post window. And listen carefully, because there's a very interesting transformation that occurs as the modulator frequency crosses into the audible spectrum, somewhere around 20 Hz, give or take a little.

{SinOsc.ar(500 + SinOsc.ar(MouseX.kr(1,2000,1).poll, mul:400)) * 0.2!2}.play;

It's a pretty wild sound! This line of code is similar to one of the examples in the SinOsc help file. The syntax is a little different, but the concept is exactly the same:

{SinOsc.ar(SinOsc.ar(XLine.kr(1,1000,9), 0, 200, 800), 0, 0.25)}.play;

This was actually one of the first sounds I ever made in SuperCollider, like 12 years ago, when all I knew how to do was boot the server and run helpfile examples, and I remember it just completely broke my brain. I had no idea what I was hearing, or that sounds like this could exist — no clue what was going on. It was great.

So, if you are similarly excited by this kind of sound, and just want to mess around, you can, for example, substitute some more unit generators and just see what happens. For example, lets use MouseY for the carrier frequency, and poll that as well:

{SinOsc.ar(MouseY.kr(200,5000,1).poll + SinOsc.ar(MouseX.kr(1,2000,1).poll, mul:400)) * 0.2!2}.play;

And let's use a non-interpolating noise generator for modulator amplitude, generating new values eight times a second, which can range from 20 to 10,000:

{SinOsc.ar(MouseY.kr(200,5000,1).poll + SinOsc.ar(MouseX.kr(1,2000,1).poll, mul:LFNoise0.kr(8).range(20,10000))) * 0.2!2}.play;

So that's really fun. Endless hours of entertainment. But this line of code is kind of long, not very readable, hard to tell at a glance what's going on, so real quick, for good practice, let's revisit concepts from tutorial three and convert this function into a SynthDef, so that we can treat it more like a blueprint for a sound, rather than a sort of fixed sound object.

For arguments, we need a carrier frequency, a modulator frequency, and a modulator amplitude. I'm just gonna give these some arbitrary but sensible default values. We also need variables to keep a reference to our carrier and modulator oscillators. Our modulator is a sine wave, running at modHz, scaled by modAmp, and our carrier (also a sine wave) is running at a frequency determined by carHz plus the modulator signal. And for now, we'll keep our fixed amplitude scaling like we had before, and our multichannel expansion. Make sure to add an Out unit generator, and add the SynthDef to the audio server.

(
SynthDef.new(\fm, {
	arg carHz=500, modHz=100, modAmp=200;
	var car, mod;
	mod = SinOsc.ar(modHz, mul:modAmp);
	car = SinOsc.ar(carHz + mod) * 0.2!2;
	Out.ar(0, car);
}).add;
)

With default argument values it sounds like this:

Synth(\fm)

Visiting concepts from tutorial 4, it would make a lot of sense to add an amplitude envelope, so that every FM sound we create has a beginning and an end, so it doesn't just go on forever. I'm just gonna do a basic percussive envelope, with an attack and release.

(
SynthDef.new(\fm, {
	arg carHz=500, modHz=100, modAmp=200, atk=0.01, rel=1;
	var car, mod, env;
	env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	mod = SinOsc.ar(modHz, mul:modAmp);
	car = SinOsc.ar(carHz + mod) * env * 0.2!2;
	Out.ar(0, car);
}).add;
)

Synth(\fm);

Let's turn this 0.2 into an actual amplitude argument, so that we have some basic volume control, if we want to use it. And for fun, let's add a pan argument so that we can position each FM sound in the stereo field. So, we'll remove our multichannel expansion here, and instead run this now mono signal through a Pan2.

(
SynthDef.new(\fm, {
	arg carHz=500, modHz=100, modAmp=200,
	atk=0.01, rel=1, amp=0.2, pan=0;
	var car, mod, env;
	env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	mod = SinOsc.ar(modHz, mul:modAmp);
	car = SinOsc.ar(carHz + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

And now let's just check a few things: so we have hard left:

Synth(\fm, [\pan, -1]);

hard right:

Synth(\fm, [\pan, 1]);

in the middle:

Synth(\fm, [\pan, 0]);

and just confirming that amplitude works:

Synth(\fm, [\pan, 0, \amp, 0.7]);
Synth(\fm, [\pan, 0, \amp, 0.1]);

and some of our other arguments:

Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 200]);
Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 1000]);
Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 1000, \modHz, 200]);
Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 1000, \modHz, 200]);
Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 1000, \modHz, 300]);
Synth(\fm, [\pan, 0, \amp, 0.3, \carHz, 1000, \modHz, 360]);

Yeah, so, let's just go nuts here and dump a full plate of randomness all over these arguments. And, for carrier & modulator frequency, and modulator amplitude, there are really no, you know, "dangerous" values — it's just one oscillator controlling the frequency of another oscillator. So, extreme values might give you some glitchy results, but for these three it's basically anything goes. For overall amplitude, envelope, and pan, we'll just do some sensible random ranges here. Feel free to copy along with me, or just chart your own path.

(
Synth(\fm, [
	\carHz, exprand(20, 10000),
	\modHz, exprand(20, 10000),
	\modAmp, rrand(0, 10000),
	\amp, exprand(0.1, 0.5),
	\atk, exprand(0.001, 0.05),
	\rel, exprand(0.05, 1.2),
	\pan, rrand(-1.0, 1.0),
]);
)

And, already, we're getting a very pleasant variety here. And then finally, to really put the SuperCollider platform to good use, let's use Pbind from tutorial 10 to make an FM sequencer, specifying SynthDef name and delta time, let's do an eighth of a second for each event, and then just using what we already have. But, if we use these random number generator as they appear, then the first Synth that Pbind generates will initially be random, but these random values will then persist for every Synth, so it’ll sound like this:

(
p = Pbind(
	\instrument, \fm,
	\dur, 1/8,
	\carHz, exprand(20, 10000),
	\modHz, exprand(20, 10000),
	\modAmp, rrand(0, 10000),
	\amp, exprand(0.1, 0.5),
	\atk, exprand(0.001, 0.05),
	\rel, exprand(0.05, 1.2),
	\pan, rrand(-1.0, 1.0),
).play;
)

p.stop;

And that's not really what we want. So, the correct thing to do is convert these language-side random number generators into their pattern-equivalent objects.

(
p = Pbind(
	\instrument, \fm,
	\dur, 1/8,
	\carHz, Pexprand(20, 10000),
	\modHz, Pexprand(20, 10000),
	\modAmp, Pwhite(0, 10000),
	\amp, Pexprand(0.1, 0.5),
	\atk, Pexprand(0.001, 0.05),
	\rel, Pexprand(0.05, 1.2),
	\pan, Pwhite(-1.0, 1.0),
).play;
)

p.stop;

So, this is what I'd consider to be a very entry-level introduction to FM in SuperCollider. Feel free to go absolutely crazy on these numbers, and see what kind of sounds and patterns and textures you can make, you know, maybe stretch out the duration of the envelope to create a drone texture, or use more predictable patterns instead of these random ones. Maybe you can also very the time between events, so it's not always 1/8th of a second. But, one thing we cannot do very easily with this code is play a tune — you know, like, create a specific melody. This is because, in FM synthesis, neither the carrier frequency nor the modulator frequency directly corresponds to the pitch that our brain perceives. The pitch we perceive, and also whether we actually perceive a clear pitch at all, is the result of a more complex relationship between carrier frequency modulator frequency and modulator amplitude. So, we'll continue this conversation in the next video, where we'll back up a few steps, dive little deeper, unpack all these numbers, figure out what they mean, and give ourselves a more robust understanding of the principles behind classic FM, and how to implement them in SuperCollider. So, thanks for watching this video, I hope you have some fun making these FM bleeps and bloops, and see you next time.