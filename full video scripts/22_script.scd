Hey, welcome to tutorial 22. Here we'll continue with FM and get into the technical details a bit so that we have a more complete understanding of how it works, and how to build an FM instrument that's useful for creating specific pitches, melodies, chords, etc, instead of just making random stuff.

Let's start with some basic principles. FM synthesis creates additional frequency components in the output spectrum, called sidebands, that appear in pairs on either side of the carrier frequency. Where these sidebands appear depends on the frequency of the modulator, and the number of sidebands that are present depends on a factor called index of modulation, which is directly proportional to the amplitude of the modulator.

//or just do before start recording
s.boot;
s.scope;
FreqScope.new;

Before we take a closer look at the numbers, here's a sound example, with a carrier at 800 Hz and modulator at 200 Hz. Right now, the modulator amplitude is zero. This means the index of modulation is also zero, and the modulator is completely removed from the equation, and all we get is a pure 800 Hz tone.

{SinOsc.ar(800 + SinOsc.ar(200, mul:0)) * 0.2!2}.play;

If we use MouseY to control modulator amplitude, we can control the number of sideband pairs that appear in the spectrum.

{SinOsc.ar(800 + SinOsc.ar(200, mul:MouseY.kr(0,400).poll)) * 0.2!2}.play;

This brings us to rule number 1 of FM: as the amplitude of the modulator increases, the number of audible sidebands increases, in other words, we get a wider and more complex output spectrum.

Now let's add MouseX to control the modulator frequency, like we did in the previous video.

{SinOsc.ar(800 + SinOsc.ar(MouseX.kr(200,1200).poll, mul:MouseY.kr(0,400))) * 0.2!2}.play;

As modulator frequency increases, you can see that the spacing between sidebands increases. In fact, this is rule number 2 of FM, and that is-- the interval at which sidebands appear is equal to the modulator frequency, so here, with the modulator at 200 Hz,

{SinOsc.ar(800 + SinOsc.ar(200, mul:400)) * 0.2!2}.play;

sidebands appear below the 800 Hz carrier at 600, 400, 200, and above at 1000, 1200, 1400, etc.

Increase the modulator to 300 Hz,

{SinOsc.ar(800 + SinOsc.ar(300, mul:400)) * 0.2!2}.play;

and now sidebands appear below at 500, 200, and above at 1100, 1400, 1700, etc.

Going back to the MouseX version for a second,

{SinOsc.ar(800 + SinOsc.ar(MouseX.kr(200,1200).poll, mul:400)) * 0.2!2}.play;

look at the spectrum analyzer and notice that as modulator frequency increases, the lower sidebands look like they're about to cross into negative values, but instead they sort of bounce off zero Hz and get reflected back into the positive domain.

There are different ways to explain this behavior. One way to conceptualize it is that a negative frequency means we're asking an oscillator to produce its periodic shape in reverse. In the case of a sine wave, this produces a waveform which sounds indistinguishable from its positive frequency counterpart, the only difference is that the polarity of the waveform is inverted.

If we modify our code so that the modulator is 350 Hz,

{SinOsc.ar(800 + SinOsc.ar(350, mul:400)) * 0.2!2}.play;

here's our carrier at 800, subtract 350 to get a sideband at 450 Hz, subtract again for a sideband at 100Hz, subtracting again gives us negative 250 Hz, so here's our sideband at positeve 250. We can even see the next sideband at 600 Hz although it's very quiet and probably has a very minimal effect on our perception, if anything.

So back to the matter at hand, we now know that modulator frequency determines sideband spacing, modulator amplitude determines number of audible sidebands, but what about the carrier frequency? Well, the carrier frequency simply determines the point of origin around which this cluster of sideband activity occurs.

So let's use MouseX to sweep the carrier frequency up and down,

{SinOsc.ar(MouseX.kr(800,3000,1).poll + SinOsc.ar(350, mul:400)) * 0.2!2}.play;

and the carrier and sidebands all shift together, but the relative spacing of the partials remains the same. This looks a little more convincing if we change the analyzer scale from logarithmic to linear.

Ok, we're making progress, but we're not quite there, we still can't play a tune. I want to point out something that you might have already noticed, using this line of code featured in the previous video:

{SinOsc.ar(500 + SinOsc.ar(MouseX.kr(1,2000,1).poll, mul:400)) * 0.2!2}.play;

And that is, if we sweep through the modulator frequency more slowly, and listen really carefully, you'll notice there are these pockets where we get a very clear sense of pitch, like here, for example, where the modulator is almost exactly 100 Hz. There are other several spots where this happens, and you can try to find some yourself, for example it happens again around 250 Hz, and also happens all the way up here at our upper limit of 2 kHz.

So rule number 3 of FM, or I guess this is maybe more of a guideline of FM: we tend to get a very clear sense of pitch when the carrier and modutalor frequencies form a simple ratio. like 2:1, 3:1, 3:2, or something like that. So if the modulator's at 100 Hz, we have a carrier/modulator ratio of 5 to 1.

{SinOsc.ar(500 + SinOsc.ar(100, mul:400)) * 0.2!2}.play;

The shape of the waveform is completely stable and cyclic. Sort of difficult to see on this particular analyzer, but we have sidebands at intervals of 100 Hz, so we have the carrier at 500, and 4-3-2-100 below, and 6-7-8-900, etc. We perceive this harmonic spectrum as having a clear sense of pitch at a fundamental of 100 Hz.

Likewise, with the modulator at 250Hz, we have 2:1 ratio, which again produces a stable waveform and a fundamental at 250 Hz, and harmonics at 500, 750, 1000, 1250, etc.

{SinOsc.ar(500 + SinOsc.ar(250, mul:400)) * 0.2!2}.play;

2000 Hz gives us a 1:4 ratio,

{SinOsc.ar(500 + SinOsc.ar(2000, mul:400)) * 0.2!2}.play;

and in this particular case the math shakes out such that we only get odd numbered harmonics -- at 1500, 2500, 3500 Hz, etc. You can experiment with ratios of your own and see what kinds of spectra are produced.

I think we're actually ready to start building a SynthDef that incorporates these principles, we haven't yet talked about the math behind index of modulation, but we'll deal that along the way. So I'm gonna paste in our SynthDef from the previous tutorial

(
SynthDef(\fm, {
	arg carHz=500, modHz=100, modAmp=200,
	amp=0.2, atk=0.01, rel=1, pan=0;
	var car, mod, env;
	env = EnvGen.kr(Env.perc(atk,rel),doneAction:2);
	mod = SinOsc.ar(modHz, mul:modAmp);
	car = SinOsc.ar(carHz + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

Synth(\fm);

and make a few changes. Now, what we'd like to be able to do is specify one frequency value as an input argument, and always hear that frequency as the perceived pitch. So instead of declaring two frequency arguments, we just declare one called freq, and two values, call them mRatio and cRatio, that we can use to indepedently scale the frequencies of the two oscillators, and more easily specify an FM configuration in terms of a carrier modulator ratio.

(
SynthDef(\fm, {
	arg freq=500, mRatio=1, cRatio=1, modAmp=200,
	amp=0.2, atk=0.01, rel=3, pan=0;
	var car, mod, env;
	env = EnvGen.kr(Env.perc(atk,rel),doneAction:2);
	mod = SinOsc.ar(freq * mRatio, mul:modAmp);
	car = SinOsc.ar(freq * cRatio + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

Default settings now sound like this:

Synth(\fm)

And check this out, our frequency argument is behaving like a nice, normal frequency argument:

Synth(\fm, [\freq, 600])
Synth(\fm, [\freq, 700])
Synth(\fm, [\freq, 800])
Synth(\fm, [\freq, 900])

Which means if we want, we can think about pitch in terms of midi note numbers

Synth(\fm, [\freq, 60.midicps])
Synth(\fm, [\freq, 62.midicps])
Synth(\fm, [\freq, 64.midicps])
Synth(\fm, [\freq, 66.midicps])

Let's see what happens if we increase the carrier multiplier incrementally by integers. We keep the same intervallic spacing of harmonics, which means the perceived fundamental doesn't change, but we end up listening to a cluster of harmonics centered increasingly higher on the overtone series:

Synth(\fm, [\freq, 66.midicps, \cRatio, 2])
Synth(\fm, [\freq, 66.midicps, \cRatio, 3])
Synth(\fm, [\freq, 66.midicps, \cRatio, 4])
Synth(\fm, [\freq, 66.midicps, \cRatio, 5])
Synth(\fm, [\freq, 66.midicps, \cRatio, 6])

And non-integer values will tend to give us spectra that we perceive as being inharmonic, with no clear pitch center, usually has kind of a bell-like sound

Synth(\fm, [\freq, 66.midicps, \cRatio, 2])
Synth(\fm, [\freq, 66.midicps, \cRatio, 2.1])
Synth(\fm, [\freq, 66.midicps, \cRatio, 2.2])
Synth(\fm, [\freq, 66.midicps, \cRatio, 2.7])

If we increase the modulator multiplier by integers, the carrier stays put but the spacing of the sidebands increases, so we get different combinations of specific overtones.

Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 2])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 3])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 4])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 5])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 6])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 7])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 8])

And again, non-integer values tend to produce inharmonic spectra.

Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 3.6])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 3.7])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 3.8])
Synth(\fm, [\freq, 66.midicps, \cRatio, 1, \mRatio, 3.9])

You can modify both of these scaling factors together, for example here's a ratio of 2 to 3...5 to 2

Synth(\fm, [\freq, 66.midicps, \cRatio, 2, \mRatio, 3])
Synth(\fm, [\freq, 66.midicps, \cRatio, 5, \mRatio, 2])

Ok, so let's talk about index of modulation, which as I mentioned is directly proportional to modulator amplitude, so as one increases, so does the other. Index of modulation is expressed as the ratio of modulator amplitude to modulator frequency.

index = modAmp/modHz

The reason this value is useful, is because it loosely corresponds to the number of audible sideband pairs in the spectrum. The rule of thumb I tend to go with is the number of audible sideband pairs in the spectrum is equal to index plus 1, but whether something is audible is pretty subjective so, it's kind of a vague and casual measurement.

So in our SynthDef, we'll declare an index argument, I'm gonna set it to 1 by default, and I'm gonna do something that might look a little weird at first, but we're not going to use modAmp anymore, insead we're going to set the modulator mul value to be exactly the same as its frequency, and if we stop here, then the index of modulation is always gonna be 1, Because modulator amplitude and modulator frequency are equal, and that's how our index equation works. So now we just multiply index by modulator amplitude. For example, if we say index is 2, then modulator amplitude is equal to twice the value of modulator frequency.

(
SynthDef(\fm, {
	arg freq=500, mRatio=1, cRatio=1, index=1,
	amp=0.2, atk=0.01, rel=3, pan=0;
	var car, mod, env;
	env = EnvGen.kr(Env.perc(atk,rel),doneAction:2);
	mod = SinOsc.ar(freq * mRatio, mul:freq * mRatio * index);
	car = SinOsc.ar(freq * cRatio + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

So now, if the index is zero, we expect to hear a pure sine wave at note number 66...and we do

Synth(\fm, [\freq, 66.midicps, \index, 0])

and as we increase the index of modulation, we see more and more sidebands populate the output spectrum.

Synth(\fm, [\freq, 66.midicps, \index, 1])
Synth(\fm, [\freq, 66.midicps, \index, 2])
Synth(\fm, [\freq, 66.midicps, \index, 3])
Synth(\fm, [\freq, 66.midicps, \index, 4])
Synth(\fm, [\freq, 66.midicps, \index, 5])
Synth(\fm, [\freq, 66.midicps, \index, 10])
Synth(\fm, [\freq, 66.midicps, \index, 20])
Synth(\fm, [\freq, 66.midicps, \index, 30])

There's one last thing I'd like to do to our SynthDef, and that is add an envelope to control the index of modulation. An index envelope allows us to dynamically shape the sound spectrum over the course a single note, which tends to make our sounds a bit more lively and interesting, and it's also useful for modeling the dynamic spectra of some acoustic instruments.

So, I'll add a new variable for the index envelope. This envelope will start at our base index value, move to the index scaled by some amount that we specify, and then back to the base index. I'm gonna set the default index scale at 5. For envelope segment durations, it's possible to have this envelope be completely independent from the amplitude envelope, but just for fun, I'm gonna lock them together so that they always have the same attack and release time. And just arbitrarily throw some curve values in there, and I'm actually gonna use these same curve values for the amplitude envelope too. Now because these two envelopes are always the same length, we don't need another doneAction:2, that's already being handled by our first envelope. And then finally, replace this static index value with our new index envelope.

(
SynthDef(\fm, {
	arg freq=500, mRatio=1, cRatio=1,
	index=1, iScale=5, cAtk=4, cRel=(-4),
	amp=0.2, atk=0.01, rel=3, pan=0;
	var car, mod, env, iEnv;
	iEnv = EnvGen.kr(
		Env(
			[index, index*iScale, index],
			[atk, rel],
			[cAtk, cRel]
		)
	);
	env = EnvGen.kr(Env.perc(atk,rel, curve:[cAtk,cRel]),doneAction:2);
	mod = SinOsc.ar(freq * mRatio, mul:freq * mRatio * iEnv);
	car = SinOsc.ar(freq * cRatio + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

Let's try it out.

Synth(\fm, [\freq, 40.midicps]);
Synth(\fm, [\freq, 42.midicps]);
Synth(\fm, [\freq, 45.midicps]);
Synth(\fm, [\freq, 47.midicps]);

Maybe let's do a shorter release

Synth(\fm, [\freq, 47.midicps, \rel, 1]);

You can see and hear that at the peak amplitude of the sound, the spectrum is relatively broad, and then as the amplitude decays, the higher partials fade away more quickly. It's kind of a subtle effect right now, but if we increase the index envelope scaling factor, then the peak of our sound has even more partials.

Synth(\fm, [\freq, 47.midicps, \rel, 1, \iScale, 10]);

And if we fine-tune the envelope release curve

Synth(\fm, [\freq, 47.midicps, \rel, 1, \iScale, 10, \cRel, -8]);
Synth(\fm, [\freq, 47.midicps, \rel, 1, \iScale, 10, \cRel, -16]);
Synth(\fm, [\freq, 47.midicps, \rel, 1, \iScale, 10, \cRel, -24]);
Synth(\fm, [\freq, 38.midicps, \rel, 1, \iScale, 10, \cRel, -24]);
Synth(\fm, [\freq, 35.midicps, \rel, 1, \iScale, 10, \cRel, -24]);

Yeah and that's...now we've got like a slap bass synth kind of thing.

We can make the index envelope go the opposite direction too, all we need to do is start with a higher base index and scale it by a value between 0 and 1

Synth(\fm, [\freq, 47.midicps, \rel, 4, \index, 20, \iScale, 0.5]);
Synth(\fm, [\freq, 47.midicps, \rel, 4, \index, 20, \iScale, 0.2]);
Synth(\fm, [\freq, 47.midicps, \rel, 4, \index, 20, \iScale, 0.05]);
Synth(\fm, [\freq, 38.midicps, \rel, 4, \index, 20, \iScale, 0.05]);
Synth(\fm, [\freq, 40.midicps, \rel, 4, \index, 20, \iScale, 0.05]);
Synth(\fm, [\freq, 35.midicps, \rel, 4, \index, 20, \iScale, 0.05]);

And let's not forget we can also play around with the carrier/modulator ratio

Synth(\fm, [\freq, 35.midicps, \rel, 4, \index, 20, \iScale, 0.05, \mRatio, 2]);
Synth(\fm, [\freq, 35.midicps, \rel, 4, \index, 20, \iScale, 0.05, \mRatio, 5]);
Synth(\fm, [\freq, 35.midicps, \rel, 4, \index, 20, \iScale, 0.05, \mRatio, 10]);
Synth(\fm, [\freq, 35.midicps, \rel, 4, \index, 20, \iScale, 0.05, \mRatio, 0.5]);

So I've tried to keep this SynthDef relatively simple, but as you hear see it gives you access to a huge world of FM sounds just waiting to be explored.

The last thing I want to do is point out there is a UGen called PMOsc, which stands for phase modulation oscillator. Now, hang on a sec, I thought we were talking about frequency modulation, what is this phase modulation business? Well, in a digital context, most oscillators, including SinOsc, are wavetable oscillators, which means they read values from a table instead of mathematically calculating them on-the-fly, so modulating the phase of one of these oscillators means we're asking a wavetable pointer to move more quickly and more slowly through the wavetable, and indirectly, this affects the frequecy of the oscillator in the exact same way that we've been doing. So FM vs PM, different implementation, but essentially same results. Technically there are some differences, but they only really come into play if you've got a more complicated modulation network with multiple modulations and multiple carriers, and in those cases phase modulation is considered superior, because it's a little more flexible and avoids some problems that can pop up with an FM approach, but this is kind of advanced stuff, and for most purposes you should consider FM and PM to be virtually equivalent.

Let's actually look at the source code for PMOsc. In the Language menu, select look up implementations, the hotkey is shift-command-I, type PMOsc, and double click it from the list to bring up the source code, note that the source code is also available using this link in the help document. And we can see that it's a so-called "pseudo UGen", basically a UGen that serves as a shorthand for a more complex combination of other UGens. This caret mark here indicates that the ar method of PMOsc returns a SinOsc, with another SinOsc controlling its phase.

So our version, which is more of a direct frequency modulation implementation, looks like this, with a SinOsc added to a base frequency value -- carrier 500, modulator 4, index 10.

{SinOsc.ar(500 + SinOsc.ar(4, mul:4*10)) * 0.2!2}.play;

A phase modulation version would look like this, where we don't manipulate the frequency directly, but instead use a SinOsc as the phase input for the carrier oscillator, and with PM, the math works out in such a way that there's no need to have the modulator amplitude and frequency be mathematically related to each other -- instead the index of modulation is equal to the modulator amplitude.

{SinOsc.ar(500, SinOsc.ar(4, mul:10)) * 0.2!2}.play;

And from here, PMOsc is a convenience that accomplishes the same thing with less code:

{PMOsc.ar(500, 4, 10) * 0.2!2}.play

But! There's something important I need to point out here, and that is at the time of making this video, there's an oversight in the source code for PMOsc. When using SinOsc, phase values should not exceed positive or negative 8pi, according to the SinOsc help file, otherwise I think they get clipped within these boundaries. But, in the source code for PMOsc, there's nothing preventing you from specifying a super high value for pmindex that will cause the modulator output to exceed these boundaries. Now, if the index is less or equal to 8pi, as it is here, it's not a problem. But set it a bit higher, and it starts to sound kind of weird,

{PMOsc.ar(500, 4, 10) * 0.2!2}.play

{PMOsc.ar(500, 4, 50) * 0.2!2}.play;

The frequency of the carrier has a staircase effect because the internal phase values have a range that's bigger than plus and minus 8pi, so they're getting truncated, so we end up losing the smooth sinusoidal movement in the carrier frequency. It's supposed to sound like this

{SinOsc.ar(500 + SinOsc.ar(4, mul:4*50)) * 0.2!2}.play;

Now of course, sound is sound, and if you're experimenting and you like this sound, then go for it. But if it's classic FM synthesis you're after, then PMOsc isn't going to deliver the correct results. Fortunately, SC is open source, so we can fix it ourselves, and in fact, it's really really easy, way easier than you might think. We just need to use .mod(2pi) on the phase values, to wrap them within appropriate boundaries. Probably mod 8pi would also work, but it says 2pi here, so that's what we're gonna do, so watch this. We go into the source code file, add .mod(2pi) to the end of the modulating oscillator, let's be consistent and also fix the kr method while we're at it, save this source file, and then in the Language menu, recompile the class library. This causes the server to quit, so we need to reboot it,

s.boot;

And now PMOsc works perfectly.

{PMOsc.ar(500, 4, 50) * 0.2!2}.play;

{SinOsc.ar(500 + SinOsc.ar(4, mul:4*50)) * 0.2!2}.play;

I noticed this in the process of making this tutorial, and opened an issue on GitHub, so this might be fixed in a future release, but regardless, once it's working properly, PMOsc is a handy tool if you want to do straight up, classic FM stuff, with one modulator one carrier, both sine waves, and as we've seen, even this super basic construction is capable of a huge variety. And you can just as easily build a SynthDef using PMOsc instead of explicitly making your own carrier and modulator as we did here. But personally, I prefer this DIY approach because you can add your own spice and variation however you like. For example, the carrier and modulator can be any type of oscillator you like, or maybe you want independent envelopes for amplitude and modulation index, so they're not always locked together, whatever you want it's all doable. And maybe coolest of all, you can design an FM SynthDef with multiple modulators and/or multiple carriers that are affecting each other in series, in parallel, or other complex interconnections, and just see what kind of sound comes out. Just to get the wheels turning a little bit, here's an example -- let's give ourselves a second modulator, modulating the first modulator, and then that signal modulates the carrier.

(
SynthDef(\fm, {
	arg freq=500, mRatio=1, cRatio=1,
	index=1, iScale=5, ic_atk=4, ic_rel=(-4),
	amp=0.2, atk=0.01, rel=3, pan=0;
	var car, mod, env, iEnv, mod2;
	iEnv = EnvGen.kr(
		Env(
			[index, index*iScale, index],
			[atk, rel],
			[ic_atk, ic_rel]
		)
	);
	env = EnvGen.kr(Env.perc(atk,rel),doneAction:2);
	mod2 = SinOsc.ar(freq/10, mul:freq/10 * iEnv);
	mod = SinOsc.ar(freq * mRatio + mod2, mul:freq * mRatio * iEnv);
	car = SinOsc.ar(freq * cRatio + mod) * env * amp;
	car = Pan2.ar(car, pan);
	Out.ar(0, car);
}).add;
)

Synth(\fm,[\rel, 3]);

And the sky's the limit, and it can get as crazy as you want, so don't feel like you need to stop there.

That's it for tutorial 22. I hope this video provides a more complete understanding of the concepts behind FM, and I hope it gives you lots of ideas for experimenting, creating interesting FM sounds and sequences, and whatever else you want to do. If you cook up something cool, I'd love to hear it, feel free to link it in a comment, and I'll also try to put a link in the description to some of the FM examples I was developing in the process of making this video. My example code got kind of long and and a little complicated, so I figured I'd make it available if you want to study it or mess around with it, but not actually put it in the video and take up time. In the next tutorial, we'll take a look at waveshaping and wavetable synthesis in SuperCollider, and some of the things you can do with it. Should be a lot of fun, so, as always, thanks for watching, see you next time.