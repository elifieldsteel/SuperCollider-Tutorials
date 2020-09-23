Hey everybody, welcome to tutorial 26. In this video I'll show you an approach that I like to use for applying granular synthesis to a live audio signal. Once again, I'm gonna be using my voice as the thing we're gonna granulate, so before starting this recording, I grabbed a microphone and an audio interface, and connected them to my computer. I assume most people watching this video are already familiar with this kind of setup, but if not, I've covered this process in tutorial 20. And, as a reminder, whenever you're coding with a live microphone, it's usually a good idea to use headphones to avoid feedback.

So, before booting the server, we'll get a list of the available audio hardware, and set input and output devices.

ServerOptions.devices;

(
s.options.inDevice_("MOTU UltraLite mk3 Hybrid");
s.options.outDevice_("Built-in Output");
s.boot;
s.meter;
)

And just to confirm that our signal flow and gain stages are all in good shape, I'll build a quick sound function that uses a comb filter to apply a feedback delay to the mic signal.

(
x = {
	var sig;
	sig = SoundIn.ar(0!2);
	sig = sig + CombN.ar(sig, decaytime: 3, mul:0.5);
}.play
)

x.free;

"testing 1...2..."

Fantastic.

If you watched the previous video on GrainBuf, you might guess that we're gonna use GrainIn to granulate the mic signal, and in fact, that's a pretty logical guess, considering its description. However, if you look more closely at the help file, you'll see that GrainIn doesn't have quite as many arguments as GrainBuf, in particular it's missing grain playback rate and grain start position. And this means we can't really use GrainIn to do any sort of pitch- or time manipulations like we did in the last video. All things considered, GrainIn is pretty simple, the main thing it does is apply little grain windows to an input signal, allowing those parts to be heard whenever we get a trigger. Just to demonstrate, here's a simple example with approximately 20 grains per second, each one 0.08 seconds long:

(
x = {
	var sig;
	sig = SoundIn.ar(0!2);
	sig = GrainIn.ar(1, Dust.ar(20), 0.08, sig);
}.play
)

And it sounds like this, where parts of my voice come through as grains, and other parts don't.

x.free;

And it occurs to me, GrainIn by itself is essentially kind of a glorified envelope generator. For example, if we swap GrainIn for EnvGen, specify a sinusoidal shape 0.08 seconds long and retrigger the envelope in the same way,

(
x = {
	var sig;
	sig = SoundIn.ar(0!2);
	sig = sig * EnvGen.ar(Env.sine(0.08), Dust.ar(20));
}.play
)

we get almost exactly the same sound, it's pretty much indistinguishable from the first example.

x.free;

So it's not that GrainIn is totally useless, you could certainly combine it with other signal processors like delays and filters, maybe some iteration or multichannel expansion, you know, whatever, but I don't think GrainIn quite gives us the flexibility we want. So then, the question is, how are we actually going to implement this?

Well, once again, we're gonna use GrainBuf. But, in contrast to the previous video, where we just had one SynthDef, here the configuration is necessarily a bit more complex, and in fact it's gonna involve several different SynthDefs that work together. To help explain how it's gonna work, here's a visualization.

First, we allocate an empty, one-channel buffer, just a block of memory where we can read and write audio samples. Let's say, 5 seconds long. And then, in terms of signal processing, we'll have four discrete parts.

Number 1, a SynthDef that uses SoundIn to read a signal from audio hardware and writes it to a bus, so that other processes can access it.

Number 2, a SynthDef that generates a periodic ramp, and writes that signal to a different bus. Conceptually,the output range corresponds to the size of the buffer, with the duration of one complete cycle being equal to buffer duration.

Number 3, a SynthDef that reads the mic signal and ramp signal from those two busses, and records the microphone signal into the buffer, using the ramp as a sample index. Because the ramp signal periodically repeats, this means that when we reach the end of the buffer, we automatically jump back to the beginning and overwrite old samples with new samples.

And finally, number 4, a SynthDef that uses GrainBuf to generate grains from the contents of the buffer. For the grain start position, we use the same ramp signal, but we subtract some amount from that signal, use a modulo operation to wrap the result within the appropriate range, and in effect we get a grain start pointer that tags along behind the record pointer, sort of endlessly chasing it around.

There's a few interesting varitaions on this idea. For one thing, we could add a little randomness to the grain pointer so that it skitters around as it moves, and this'll have the effect of jumbling syllables and generally making the recording less intelligible. And another variation, just because we only have one GrainBuf SynthDef doesn't mean we're only allowed to make one Synth. For example, we could make five Synths, so that we have five grain pointers all generating grains independently, all following behind the record pointer.

Now you might be wondering, why bother anchoring the grain pointer to the record pointer at all? Can't we just pull grains from anywhere in the buffer? Well, technically yes, you can, but this brings us to the main pitfall of this approach. At any point in time, there is almost guaranteed to be a discontinuity in the buffer, at the record head, right between between the oldest and newest recorded sample. And if we ignore this discontinuity, or don't properly factor it into our algorithm, for example if we generate a grain that is longer than the distance between these two pointers, then that grain will include the discontinuity, and we're likely to hear a big ugly click, and generally we try to avoid this because, it sounds bad.

And, just in case you don't quite know what I'm talking about when I say big ugly click, here's a sample of me talking... and here's an example of what a grain might sound like, if you fall into this trap. And I'm gonna intentionally make this click sound fairly egregious.

It's not good. So, generally, this is why we tether the grain pointer to the record pointer, basically so that we have a strong guarantee that grains won't spill over and collide with this discontinuity.

So, with that introduction out of the way, let's turn these ideas into code.

First, allocate an empty buffer, so b = Buffer.alloc, name of the server, and the number of frames, so for five seconds, we'd do s.sampleRate * 5, keep in mind this duration is mostly arbitrary — you could make it smaller, although it might get a little claustrophobic around 1 second or so, but larger is certainly fine, so, 30, 60 seconds, especially if you want to capture a recording of stuff that happens over a relatively long period of time. Third is the number of buffer channels, we want one channel. One is the default so technically we don't need it, but I'm gonna leave it here for clarity.

b = Buffer.alloc(s, s.sampleRate * 5, 1);

Next, we need two one-channel audio busses, one for the mic, one for the pointer. And again, one is the default for number of channels but I'm gonna type it in anyway

(
~micBus = Bus.audio(s,1);
~ptrBus = Bus.audio(s,1);
)

And now we're ready to start building SynthDefs. First, a SynthDef called mic, which simply reads a signal from a hardware input bus, with an amplitude control just in case we want to mute or adjust the level, and out it goes onto a bus.

SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in) * amp;
	Out.ar(out, sig);
}).add;

That's it. Next SynthDef, called pointer... this one will use Phasor, with very much the same technique we saw in the previous video, to generate a repeating ramp to index into the buffer. And, unfortunately, I made a mistake in the previous video. It wasn't so much of a big deal in tutorial 25 with pre-recorded sound, but here, in a live context it is a big deal. In the help file for Phasor, we note that the end value is defined as the wrap point, so the ramp it generates goes up to that value but is never actually equal to that value, so for the end value we need BufFrames, _not_ BufFrames-1 as I did in the last video. I apologize. That was my mistake. Also, just a quick note that I'm not really thinking about these argument values right now, these zeroes are just placeholders, we'll make sure to set these correctly when we actually start instantiating Synths.

SynthDef.new(\ptr, {
	arg out=0, buf=0;
	var sig;
	sig = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
	Out.ar(out, sig);
}).add;

Third, a SynthDef responsible for reading the mic signal, reading the ramp signal, and recording into the buffer. So, here's our pointer, here's our live sound, and BufWr to record sig into buf, using ptr as the sample index. Conspicuously, there's no Out.ar here, because this SynthDef doesn't actually output a signal, it's only job is to record a live signal into a buffer.

SynthDef.new(\rec, {
	arg ptrIn=0, micIn=0, buf=0;
	var ptr, sig;
	ptr = In.ar(ptrIn, 1);
	sig = In.ar(micIn, 1);
	BufWr.ar(sig, buf, ptr);
}).add;

And finally, number four, the granulator. Now these first three were pretty simple, this one's gonna take a little more work. Fundamentally, I'm gonna base this off of the one we saw at the end of the previous video, but with a number of changes to accommodate real-time considerations. So first, I'm gonna paste in the easy stuff.

We have an envelope for overall amplitude, a basic attack-sustain-release shape that can be held open with a gate. Basically this just gives us an easy way to turn granulators on and off with a nice fade-in and fade-out.

Grain density control, exactly the same as it was in the last video, grain duration control, also exactly the same, except I changed this argument name from dur to baseDur, rate control, here I've decided to multiply by a noise generator so that the overall playback rate can be randomized within a range, and pan control, with a base pan value and a random amount of spread.

SynthDef.new(\gran, {
	arg amp=0.5, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

And now, we're gonna incrementally add in the new stuff, which is gonna be mostly focused on the grain pointer, how it interacts with other parameters, and just generally making sure that our grains don't have clicks.

To start, we need to read in the pointer signal, so In.ar, adding a new ptr variable and pointer bus argument along with it.

SynthDef.new(\gran, {
	arg amp=0.5, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptr = In.ar(ptrBus, 1);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

As we saw in the visual demo, the grain pointer lags begind the record pointer by some amount, so let's declare an argument to represent that value. For a sensible default I'll arbitrarily say 20000 samples, we can change this at instantiation time, if we want.

SynthDef.new(\gran, {
	arg amp=0.5, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptr = In.ar(ptrBus, 1);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

And at a very basic level, what we want to do is subtract this delay from the sample pointer, so that would look like this.

SynthDef.new(\gran, {
	arg amp=0.5, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - ptrSampleDelay;

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

And then, because GrainBuf expects a normalized pointer, between 0 and 1, divide this value by the number of frames in the buffer.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - ptrSampleDelay;
	ptr = ptr / BufFrames.ir(buf);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

But there's an issue we need to consider here. Let's imagine a specific moment in time when the pointer signal is at zero or just slightly above. If the pointer delay is 20000 samples or some other large number, then the end result is a negative pointer value, but GrainBuf expects something between 0 and 1. So, probably a good idea to wrap this value between 0 and 1, which we can do with ptr.wrap(0,1) or, alternatively, we can take the pointer value modulo 1, which has the same effect.

ptr = ptr.wrap(0,1);
//delete
ptr = ptr % 1;

That said, it seems GrainBuf does this modulo operation internally, as we can demonstrate with a quick sound example. Here's that short sample of me...

z = Buffer.read(s, "/Users/eli/Desktop/sounds_like_this.aiff");
z.play;

and here's a simple GrainBuf example:

{GrainBuf.ar(2,Impulse.ar(2.5), 0.5, z, 1, 0.6)}.play;

The grain position is 0.6. And as long as we change this value in increments of 1, even going into negative values, the results are identical.

{GrainBuf.ar(2,Impulse.ar(2.5), 0.5, z, 1, -5.4)}.play; //1.6, 10.6, -0.4, -5.4

So I'm pretty confident that putting a modulo operation in the SynthDef is technically not necessary.

Now, if we want to implement that random skittering pointer effect, we'll need a noise generator, which I'll call ptrRand. I'm gonna give this a default range of 5000 samples. And because there are now two things affecting grain pointer position, I think it would be convenient to create a variable that represents the total number of samples we're gonna subtract from the incoming pointer. So, the total number of samples we subtract is equal to the base sample delay amount, minus the pointer randomness. And then down here, we're now going to subtract the _total_ delay from the pointer.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = ptrSampleDelay - ptrRand;

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

Now here, there's another possible issue. There's nothing in place to prevent the user from specifying a small base pointer delay, and a large amount of randomness, in which case, totalDelay would often be some positive value, which would push the grain pointer forward in such a way that we'd very likely be capturing the buffer discontinuity in the grains, and that's what we're trying to avoid. So it would be a really good idea to implement some sort of safety mechanism that forces totalDelay to be greater than some established minimum. And a very easy way to do this is to use max, which compares two values and takes whichever is greater. And...I do recognize it's still possible to break this code by putting, like, a negative value here for minPtrDelay... we could try to anticipate every possible careless thing the user is gonna do, but ehh, I gotta draw the line somewhere—you know what? if breaking this code makes you happy and gets you up in the morning, go for it, live your best life.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000, minPtrDelay=1000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

Ok, so now that totalDelay is guaranteed to be greater than or equal to minPtrDelay, we have a nice healthy-looking grain pointer. The last piece of the puzzle has to do with grain duration. Basically, the grain pointer is behind the record pointer by some amount of time, and that distance determines the maximum grain duration. So it's tempting to build a similar safety mechanism that uses min to compare the user-specified grain duration and the actual amount of time between the pointers, and then take the smaller value, that would look like this.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000, minPtrDelay=1000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay, maxGrainDur;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);

	maxGrainDur = totalDelay / SampleRate.ir;
	durCtrl = min(durCtrl, maxGrainDur);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

But ah, if only it were that easy. It's...it actually is pretty easy, it's  just a tiny bit more complicated. We also have to factor in grain playback rate. And to demonstrate precisely why grain playback rate needs to be factored into the process of avoiding the discontinuity, here is another visual demonstration, in which we imagine that this is our five second buffer, being filled and granulated in real-time, and we've magically hit pause on this process and are now looking at a moment, frozen in time.

Our record pointer, and therefore the buffer discontinuity, is right here, let's say two seconds from the beginning. So the oldest audio is here, about to be overwritten, and the newest audio is here, freshly laid in a mere second ago.

And let's also imagine that at this moment, the grain pointer is behind the record pointer by half a second.

So we're about to produce a grain, let's say the algorithm requests a half second grain, with a playback rate of 1. Well, that's no problem, we just read this half second chunk and we're done. But now, instead, let's suppose the algorithm requests a half-second grain with a playback rate of 2. Now you might suppose that GrainBuf carves out a half-second chunk, and then resamples it at twice the speed, but this is _not_ what actually happens, because in this case, we wouldn't get the half-second grain that we asked for — this grain is only a quarter second long. What GrainBuf actually does is it carves out a chunk of the buffer equal to grain duration times playback ratio, so in this particular case, twice as much. It _then_ resamples in order to give us the correct grain duration and correct playback rate. And as a consequence, we've inadvertently included the discontinuity in the grain. So the takeaway here is that even if we ask for a grain duration that is equal to or smaller than the distance between these two pointers, we can still accidentally bonk into the discontinuity if the playback rate is too high.

And, while we're here, you may already be able to see that pitch shifting up is the problem case, while pitch shifting down, with ratios less than one, is actually pretty harmless. For example, if our specified playback rate was 0.5 instead of two, then GrainBuf only needs to take half as much audio, and then stretches it out by a factor of two, and the discontinuity is not a problem.

So, that's why it's necessary to account for playback rate in order to avoid unwanted clicks.

So, what exactly do we do to this SynthDef? Well, feel free to pause the video here and see if you can work out the solution on your own. In fact I recommend you do so, because I think this is a good opportunity for a little self-learning exercise. There are probably a few different ways to express it, but I've chosen to do it like this: the maximum allowable grain size is equal to the total pointer delay divided by the grain playback rate, and because this is a value in samples, divide by the sampling rate to convert to seconds. And then, we use min to take whichever of these two values is smaller, and the result is the actual grain duration.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0,
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000, minPtrDelay=1000;

	var env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay, maxGrainDur;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);

	maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
	durCtrl = min(durCtrl, maxGrainDur);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

And now there's just one more thing we're missing, and that is GrainBuf, filled with all of our meticulously calculated control signals.

SynthDef.new(\gran, {
	arg amp=0.5, buf=0, out=0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40,
	baseDur=0.05, durRand=1,
	rate=1, rateRand=1,
	pan=0, panRand=0, grainEnv=(-1),
	ptrBus=0, ptrSampleDelay=20000,
	ptrRandSamples=5000, minPtrDelay=1000;

	var sig, env, densCtrl, durCtrl, rateCtrl, panCtrl,
	ptr, ptrRand, totalDelay, maxGrainDur;

	env = EnvGen.kr(Env.asr(atk,1,rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand,durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.ir(buf);

	maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
	durCtrl = min(durCtrl, maxGrainDur);

	sig = GrainBuf.ar(
		2,
		densCtrl,
		durCtrl,
		buf,
		rateCtrl,
		ptr,
		2,
		panCtrl,
		grainEnv
	);

	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;

So that wraps up the SynthDef creation process, so we're now ready to start placing Synths on the server. If you recall tutorial 7, you'll remember that when we're using busses to pass signals from one Synth to another, as we're doing here, any Synth that writes to a bus needs to be upstream of any Synth that reads from that bus.

s.plotTree;

In this particular case, we need the mic and pointer Synths to be upstream of the recording and granulating Synths.

I'm gonna use Groups to manage node order, specifically I'm going to make four Groups, one for each type of Synth, placing each one after the one before it. Keep in mind this is not the only way to do it, but it seems sensible to me.

(
~micGrp = Group.new;
~ptrGrp = Group.after(~micGrp);
~recGrp = Group.after(~ptrGrp);
~granGrp = Group.after(~recGrp);
)

So, a mic Synth, writing the mic signal to micBus, placed into the micGroup. A pointer synth, which needs to know which buffer it's indexing, writing the ramp signal to ptrBus, placed into the ptrGroup. And, a record Synth, which needs to know the two input busses it's reading from, and which buffer it's recording into, place that in the correct group as well.

(
Synth(\mic, [\in, 0, \out, ~micBus], ~micGrp);
Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);
Synth(\rec, [\ptrIn, ~ptrBus, \micIn, ~micBus, \buf, b], ~recGrp);
)

We're not done yet, but let's run these three lines anyway.

The node tree looks good. We don't hear anything, because currently nothing is sending signal to hardware output busses. But, right now, in fact, we are recording my voice into buffer b, and to verify this, we can plot it:

b.plot;

There's definitely something there. And if you want, you can even play the buffer to hear what's in it. And although you can evaluate b.play while all this is happening, for clarity, what I'd prefer to do is first free these three Synths. I could hit command-period, but that'll remove the Groups too, so to free all the Synths but leave the Groups intact, we can do s.defaultGroup.deepFree;

s.defaultGroup.deepFree;

And now let's play the buffer.

b.play;

So, yeah, this is great, everything seems to be working, we're successfully writing audio into the buffer. Cool stuff.

Let's clear everything out of the the buffer with b.zero...good as new.

b.zero;
b.plot;

Now for the final ingredient, we'll create a granular Synth, drop it into the appropriate group, and give it a short name so we can talk to it more easily. To save time, I've copied and formatted all the SynthDef arguments ahead of time, so I'm just gonna paste them here. A lot of these default values we can just leave them as they are, change them as desired, but there are a few we need to address up front, in particular we need to specify the buffer to granulate, so, buf b, and we also need to make sure this Synth is reading the pointer signal from the correct bus, so tilde ptrBus goes here.

Now, in the interest of starting with a relatively simple sound, I'm gonna zero out the pointer randomness, so the grain pointer is smoothly following behind the record pointer, just maintaining its distance. And this 20000 is fine, but it was kind of a placeholder, so let's be more precise and make the grain pointer lag behind by exactly one third of a second.

And, before we run this code, I'm just gonna warn you one more time, make sure you've either got headphones in, or otherwise have your feedback situation under control.

(
Synth(\mic, [\in, 0, \out, ~micBus], ~micGrp);
Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);
Synth(\rec, [\ptrIn, ~ptrBus, \micIn, ~micBus, \buf, b], ~recGrp);
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 1,
		\dens, 40,
		\baseDur, 0.05,
		\durRand, 1,
		\rate, 1,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, s.sampleRate/3,
		\ptrRandSamples, 0,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

Alright...like I said, this configuration produces a fairly simple sound. We're doing 40 synchronous grains per second, each one 1/20th of a second long, so they overlap in a very precise way, and as a result, we reconstruct the recorded signal very accurately, with a 1/3rd second delay, of course. Let's fade this out by closing the envelope gate.

~g.set(\gate, 0);

So, all we've really done so far is make an unusually complicated delay line. But now we can start having some fun with these grain parameters. For instance, let's bring back that pointer randomness, deviating by up to a sixth of a second in either direction. And, for ease of code evaluation, let's detach this clump and put b.zero at the top, so that we're clearing the buffer each time we start up a new granulator.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 1,
		\dens, 40,
		\baseDur, 0.05,
		\durRand, 1,
		\rate, 1,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, s.sampleRate/3,
		\ptrRandSamples, s.sampleRate/6,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

So, even with this relatively small change, we've created a considerably more interesting granular effect, but, of course, there's no reason to stop here.

~g.set(\gate, 0);

Let's randomize the playback rate within a range of 2 semitones up or down, and also create a more interesting stereo image by widening the amount of spatial randomness.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 1,
		\dens, 40,
		\baseDur, 0.05,
		\durRand, 1,
		\rate, 1,
		\rateRand, 2.midiratio,
		\pan, 0,
		\panRand, 0.5,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, s.sampleRate/3,
		\ptrRandSamples, s.sampleRate/6,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

So now we've got a jumpier sound, more variation, more changes, that sort of thing, you know, getting some good use out of these granular parameters.

~g.set(\gate, 0);

Now, think back to that first visual example where we had five independent grain pointers all anchored at various distances behind the record pointer. Let's turn that into a reality. So what I'm gonna do is use collect to generate five Synths, put them in an array and store the array in the variable g. Since we're making 5, we'll dial back on the amplitude. Let's randomize the grain densities a bit, also increase the base grain duration and randomize it by a factor of 1.5. Now it'd be kind of redundant to have all five pointers clustered around the same spot, so let's space them out. Inside this collect block, the argument n is gonna be equal to the integers 0 through 4, so we can use this value along with linlin to easily place the grain pointers at specific spots. The whole buffer is five seconds long, and I don't want to go back in time too far, so let's say the first grain pointer will be 20000 samples behind, and the last grain pointer will be...2 seconds behind, with these five pointers linearly distributed across this distance. And let's have each pointer wiggle around by 10000 samples in either direction. And...you know what? let's do a similar thing with amplitude, so that the grains that are closer to the record pointer are louder, and grains that are farther behind are quieter, which should sound a little more natural, maybe a little less chaotic. So, I'm gonna map the iteration count linearly onto decibels, and then convert from decibels to amplitude.

Because g is going to be an Array of Synths, g.set won't work anymore, so let's prepare another line of code that will iterate over the array and close the gate on each Synth.

(
b.zero;
~g = 5.collect({
	arg n;
	Synth(\gran,
		[
			\amp, n.linlin(0,4,-3,-20).dbamp,
			\buf, b,
			\out, 0,
			\atk, 1,
			\rel, 1,
			\gate, 1,
			\sync, 1,
			\dens, exprand(20,40),
			\baseDur, 0.08,
			\durRand, 1.5,
			\rate, 1,
			\rateRand, 2.midiratio,
			\pan, 0,
			\panRand, 0.5,
			\grainEnv, -1,
			\ptrBus, ~ptrBus,
			\ptrSampleDelay, n.linlin(0,4,20000,s.sampleRate * 2),
			\ptrRandSamples, 10000,
			\minPtrDelay, 1000;
		],
		~granGrp
	);
});
)

So, this is what it sounds like, kind of a psychedelic echo effect.

~g.do({ arg n; n.set(\gate, 0) });

That covers the basic functionality of the live granulator, so from here, let's do a couple variations.

s.defaultGroup.deepFree;

First, I want to make a granular freeze effect, in other words, apply a granular sample and hold technique to a very short segment of sound. The main thing we need to do is give ourselves a way to pause and resume the pointer signal, and the easiest way I can think of to do that is to go back to the pointer SynthDef and add a rate argument. And, to verify that it works, let's temporarily poll the signal so we can see the values.

SynthDef.new(\ptr, {
	arg out=0, buf=0, rate=1;
	var sig;
	sig = Phasor.ar(0, BufRateScale.kr(buf) * rate, 0, BufFrames.kr(buf));
	Out.ar(out, sig);
}).add;

Instantiate a Synth using this modified SynthDef

Synth(\ptr, [\buf, b, \out, ~ptrBus], ~ptrGrp);

And we can zero the rate, therefore freezing the pointer, by sending a set message to the enclosing group:

~ptrGrp.set(\rate, 0);
~ptrGrp.set(\rate, 1);
~ptrGrp.set(\rate, 0);
~ptrGrp.set(\rate, 1);

That looks good.

s.defaultGroup.deepFree;
//delete .poll and re-eval

So let's go back a few steps to where we had a single granulator instead of five, and make a few changes to give the granular freeze effect a nicer aesthetic, sensible amplitude, dense, asynchronous grains, stabilize the grain duration at 0.1, remove the playback rate randomness, fix the pointer delay at ten thousand samples, and minimize the pointer randomness.

(
Synth(\mic, [\in, 0, \out, ~micBus], ~micGrp);
Synth(\ptr, [\buf, b, \out, ~ptrBus, \rate, 1], ~ptrGrp);
Synth(\rec, [\ptrIn, ~ptrBus, \micIn, ~micBus, \buf, b], ~recGrp);
)

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, 1,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0.5,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 10000,
		\ptrRandSamples, 2000,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

Ok, so now we can use a set message to freeeeeeeeeeeeee

~ptrGrp.set(\rate, 0);

[ahem]...right, I was saying, we can use a set message to freeze the grain pointer, and we get stuck on this one specific chunk. And from here we can unfreeze the pointer by setting rate back to 1...and things keep moving along.

~ptrGrp.set(\rate, 1);

~g.set(\gate, 0);

This freeze effect gets the job done, but it isn't perfect, because we're taking a short and kind of sloppy approach. By doing a hard stop on the pointer, we're disrupting the recording process, but sound keeps happening and real-time keeps moving forward, which means we're actually introducing a discontinuity into the buffer, and we might hear a few clicks when the pointer resumes. So if this bothers you, one solution would be to somehow build in a crossfade whenever the pointer stops or starts, or allocate multiple buffers, so after you do a freeze, resume the recording and granulating processes using a new, empty buffer, and once that takes over, fade out the old frozen one.

s.defaultGroup.deepFree;

Let's do one more variation, and see if we can make a half-decent real-time harmonizer.

Now, as we saw in tutorial 25, some of the recommendations for optimizing a clean granular pitch shifting effect are use dense, asyncronous grains, a relatively large grain size, And let's start by pitching down by 3 semitones. Let's also remove this panning randomness. As for sample delay, we'd probably want this delay to be as small as possible because we want to hear the harmonization immediately, you know, as soon as we start making sound. Now, our SynthDef safety mechanisms should protect us from hearing any buffer discontinuity clicks, but nevertheless, we can do the math ourselves. So our grain size is 0.2, converted to samples, and then scaled by the playback ratio, makes our pointer delay only as big as it needs to be. As for pointer randomness, I don't think we'll need any. A small amount probably wouldn't hurt...but for now I'm just gonna leave it at zero.

Let's try it out.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.2, //
		\durRand, 1,
		\rate, -3.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 0.2 * s.sampleRate * (-3.midiratio),
		\ptrRandSamples, 0,
		\minPtrDelay, 1000
	],
	~granGrp
);
)

Well, it sounds like this. and as you can hear there's quite a noticeable amount of latency between my voice and the harmonized voice.

~g.set(\gate, 0);

If we want to reduce that latency, one thing we can try is reducing the size of the grains to something that produces a more tolerable amount of latency, like 0.07 seconds, maybe

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.07,
		\durRand, 1,
		\rate, -3.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 0.07 * s.sampleRate * (-3.midiratio),
		\ptrRandSamples, 0,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

And this is definitely an improvement in terms of latency, still an audible delay though. and in terms of sound quality, eh, about the same, maybe a little worse.

~g.set(\gate, 0);

And in case you're wondering, we can't just drop the grain size to something microscopic, because then the grains are just too short, and they'll start sounding kinda glitchy:

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.01,
		\durRand, 1,
		\rate, -3.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 0.01 * s.sampleRate * (-3.midiratio),
		\ptrRandSamples, 0,
		\minPtrDelay, 1000;
	],
	~granGrp
);
)

Interesting effect, for sure, but not a good harmonizer. And in fact,

~g.set(\gate, 0);

in this case, our pointer delay is less than min pointer delay, so min pointer delay is taking over, overriding this value, and imposing 1000 samples worth of latency, even though it's more than we actually need.

So...as I was writing this tutorial, I was messing around, and there is a...kind of a cute trick to help reduce latency. So, we go back to our granular SynthDef, and basically we're going to disable our safety mechanisms, so these two lines that constrain grain duration based on available space, comment them out. And the other safety mechanism, for totalDelay, well minPtrDelay is an argument so we can manually set it to zero ourselves. In making these changes, the SynthDef is basically saying hey, you want to avoid grains with clicks in em? you're on your own. do the math. you figure it out.

//maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
//durCtrl = min(durCtrl, maxGrainDur);

So back to the Synth, set the grain duration to some sensnible size, like 0.1, and set the pointer sampleDelay to be...you know what? Let's do 1 sample. The smallest increment of digital audio. This means the grain pointer is right behind the record pointer, practically right on top of it. So, let's run this...

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, -3.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 1,
		\ptrRandSamples, 0,
		\minPtrDelay, 0,
	],
	~granGrp
);
)

And you can hear that the latency is extremely low, I would say, completely negligible. Now we've got our safety mechanisms off, and 0.1 seconds is definitely longer than 1 sample. So, a sensible question is -- how in the world are we not bumping into the discontinuity? Like, shouldn't we be hearing a bunch of gross clicky audio?

~g.set(\gate, 0);

Well, no, the secret ingredient is, we are pitching *down* and as demonstrated in that second visualization, we really have nothing to fear when the playback process is slower than the recording process, because remember —— all of this is happening in real-time. So, we start making a grain, and we're reading the buffer samples at a rate slightly slower than normal, but the recording process is going along at normal speed, so by the time the grain is finished, all of those samples have already been filled in by the record pointer. So genereally speaking, if you're pitching down, you have virtually nothing to worry about.

Now, pitch shifting up, well that's a different story. Let's go up by a mere one semitone and keep all the other settings the same.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, 1.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 1,
		\ptrRandSamples, 0,
		\minPtrDelay, 0,
	],
	~granGrp
);
)

And wow, it sounds like absolute garbage.

~g.set(\gate, 0);

In this example, the playback process is happening *faster* than the record process —— so fast, in fact, that it's catching up to the record pointer, and going past it, and that's not good because we don't have a time machine and we can't know what happens before it happens, so GrainBuf just blindly charges forward and suddenly it's capturing the buffer discontinuity along with stuff that happened five seconds ago, and well...it's just a complete mess.

The reality is that a delay of 1 sample is just not enough space if we want to shift up by 1 semitone. So, a very good question is...what is the minimum amount of latency we need to impose in order to avoid this obnoxiously repulsive sound?

Well, I believe it works like this: our grains are a tenth of a second long, so the amount of buffer that GrainBuf takes is this value times playback ratio.

0.1 * 1.midiratio

And because both pointers are moving at these two different rates, we don't need this full delay amount, we only need the difference between this modified duration and the duration at normal speed.

(0.1 * 1.midiratio) - 0.1

and then, convert this to samples...

(0.1 * 1.midiratio) - 0.1 * s.sampleRate;

So 263 samples should do the trick.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, 1.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 263,
		\ptrRandSamples, 0,
		\minPtrDelay, 0,
	],
	~granGrp
);
)

And there you go, pitch shifting up with minimal latency.

~g.set(\gate, 0);

If you want to go up by more than 1 semitone, we can't just change the rate and leave everything else alone.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, 2.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 263,
		\ptrRandSamples, 0,
		\minPtrDelay, 0;
	],
	~granGrp
);
)

because it's no good, we are back in garbage town.

~g.set(\gate, 0);

To do this correctly, we'd also need to redo this calculation,

((0.1 * 2.midiratio) - 0.1) * s.sampleRate

And increase the pointer delay as necessary.

(
b.zero;
~g = Synth(\gran,
	[
		\amp, 0.5,
		\buf, b,
		\out, 0,
		\atk, 1,
		\rel, 1,
		\gate, 1,
		\sync, 0,
		\dens, 200,
		\baseDur, 0.1,
		\durRand, 1,
		\rate, 2.midiratio,
		\rateRand, 1,
		\pan, 0,
		\panRand, 0,
		\grainEnv, -1,
		\ptrBus, ~ptrBus,
		\ptrSampleDelay, 541,
		\ptrRandSamples, 0,
		\minPtrDelay, 0;
	],
	~granGrp
);
)

And now we're up by 2 semitones, and still we have a respectably small amount of latency.

~g.set(\gate, 0);

So it is possible harmonize up , but the higher you want to go, you're just gonna have to eat more and more latency. So, you just gotta make the call for yourself, how much latency are you willing to accept, that determines how high you can go. Basically, if you can adapt your creative workflow to favor downward pitch shifting whenever possible and go up only when absolutely necessary, then you're in a good spot.

That said, let's go back to our multiple Synth example using collect, and here's a version that creates a real-time harmonized chord.

(
b.zero;
~g = [-5,-3,0,2].collect({
	arg n;
	Synth(\gran,
		[
			\amp, 0.15,
			\buf, b,
			\out, 0,
			\atk, 1,
			\rel, 1,
			\gate, 1,
			\sync, 0,
			\dens, 200,
			\baseDur, 0.1,
			\durRand, 1,
			\rate, n.midiratio,
			\rateRand, 1,
			\pan, 0,
			\panRand, 0,
			\grainEnv, -1,
			\ptrBus, ~ptrBus,
			\ptrSampleDelay, 541,
			\ptrRandSamples, 0,
			\minPtrDelay, 0;
		],
		~granGrp
	);
});
)

["ahhh....harmonizerrrrrrr"]

~g.do(_.set(\gate, 0));

Or, we could change these pitch values to do something a little more dissonant and sinister:


(
b.zero;
~g = (1.5,0.7..-12).collect({
	arg n;
	Synth(\gran,
		[
			\amp, 0.15,
			\buf, b,
			\out, 0,
			\atk, 1,
			\rel, 1,
			\gate, 1,
			\sync, 0,
			\dens, 200,
			\baseDur, 0.1,
			\durRand, 1,
			\rate, n.midiratio,
			\rateRand, 1,
			\pan, 0,
			\panRand, 0,
			\grainEnv, -1,
			\ptrBus, ~ptrBus,
			\ptrSampleDelay, 541,
			\ptrRandSamples, 0,
			\minPtrDelay, 0;
		],
		~granGrp
	);
});
)

we are the borg. you will be assimilated.

~g.do(_.set(\gate, 0));

It's worth pointing out that there is a UGen called PitchShift, which is a granular-based harmonizer, and it's basically optimized for this sort of thing. I recommend trying it out, you might find the sound quality to be good enough for some applications. With granular harmonizers you're always going to have some flavor of imperfection and digital artifacts, but using PitchShift is certainly less work than putting all this business together. However, if you're looking for a broader and more multi-purpose palette of real-time granular textures, I think this approach we've covered here is well worth the effort.

So, that's it for tutorial 26. I hope this video helps you understand the principles of live granular synthesis on a deeper level, and I hope it gives you some useful tools and exciting ideas for your own creative work. As always, if you have any comments or questions, please feel free to leave them below. Thanks for watching, I'll see you next time.