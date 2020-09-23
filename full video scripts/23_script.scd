Hey everyone, welcome to tutorial 23. Here, we'll talk about wavetable synthesis, what it is, how it works, and the various options you have for exploring it in SuperCollider.

At its most basic level, wavetable synthesis involves the use of an ordered collection of values, called a wavetable, and it can contain virtually any shape, as long as it represents a sample of a valid time domain function, and for computer efficiency reasons, the size of a wavetable is usually a power of two. In the simplest application of wavetable synthesis, the wavetable is treated as a single cycle of a periodic wave, and we use a wavetable oscillator to read through these values at a particular frequency.

In SuperCollider, the primary UGen for this purpose is Osc, a wavetable oscillator that uses linear interpolation. It's actually very similar to SinOsc, and they even use the same implementation, the only difference is that SinOsc always uses a built-in sine wavetable, whereas Osc has an additional argument that allows us to specify a custom wavetable, stored in a Buffer. Osc has a few close relatives that offer variations on this idea, like the chorusing wavetable oscillator, COsc, the variable wavetable oscillator, VOsc, And there's also Shaper, a waveshaping UGen that uses a wavetable as a transfer function in order to alter the shape of an input signal. In this video, however, I'm gonna focus on Osc, and we'll explore these variations in the next video.

What we need to do to make sound with Osc is generate a wavetable and load it into a Buffer on the audio server. To start this process, I'm gonna use a class called Signal. Despite the name and description here, "Sampled audio buffer," Signal is not a server-side object, and doesn't directly interface with audio. It's a language-side object, it's an ordered collection, sort of like Array, but it can only contain floats. Generally speaking, it's useful for representing sampled audio signals in an offline context, away from the audio server.

Signal is particularly handy if you want to build a wavetable using sums of harmonically related sine waves, using the sineFill method. We provide is the size of the signal. This can be any number, but, if we want this to be a wavetable, it needs to be a power of 2. Several different powers of 2 will work just fine, although in my opinion if you go smaller than 128 or so, the distortion from having a low resolution table is going to become really obvious, and if you go higher than maybe 8192, there's kind of a point of diminishing returns, where you need bigger and bigger buffers to hold your wavetable, but you're not really improving the sound quality in a noticeable way. Just for reference, SinOsc uses 8192, but I'm gonna do 1024. Next, we provide an array representing the amplitudes of the harmonics, and an array representing the initial phases of the harmonics. So if we specify the array 1, followed by the array 0,

~sig = Signal.sineFill(1024);
~sig = Signal.sineFill(1024, [], []);
~sig = Signal.sineFill(1024, [1], [0]);

this means the signal contains the first harmonic, which is the fundamental, at full amplitude, with an initial phase offset of 0 radians. It's not at all obvious to see this in the post window, but conveniently, we can plot a signal,

(
~sig = Signal.sineFill(1024, [1], [0]);
~sig.plot("Signal");
)

So just to keep things simple, let's make Osc produce a sine tone using this wavetable. But here, there's a twist that makes wavetable synthesis in SuperCollider sort of unique. Almost every wavetable UGen requires a buffer that has been filled according to something called "Wavetable format." Osc says it needs wavetable format, VOsc needs wavetable format, Shaper needs it as well. However, what we have here is *not* in wavetable format, it's just a plain regular collection that represents one cycle of a sine wave. To convert a signal to wavetable format, we use the method asWavetable. Now if we plot both,

(
~sig = Signal.sineFill(1024, [1], [0]);
~sig.plot("Signal");
~wt = ~sig.asWavetable;
~wt.plot("Wavetable");
)

they look the same, and in fact, they are the same. This is because of a little quirk that when we plot a wavetable object, as we can see in the source code, it gets converted back to a signal, and then plotted, plot basically undoes our conversion and then shows us the original thing, so yeah this is the wrong way to demonstrate the difference between Signal and Wavetable. But check the sizes of these two objects,

~sig.size;
~wt.size;

and we see that the wavetable is twice as big, so there's definitely something going on here. I'm going to do a little trick here so that we can propery visualize the wavetable, before we plot, I'm gonna iterate over the wavetable with collect, and just pass the values through. This has the side-effect of converting the Wavetable into a plain old Array, and when we plot the Array,

(
~sig = Signal.sineFill(1024, [1], [0]);
~sig.plot("Signal");
~wt = ~sig.asWavetable;
~wt.collect({arg n; n}).plot("Wavetable");
)

we can see more clearly what wavetable format looks like. So this is wavetable format. It's got the same general shape as the signal, but it looks pretty weird, and the first thing you might notice is that it does this crazy dance if we change the width the window. This is kind of intriguing and also kind of distracting, so I want to explain this first, and it's a little easier to explain if we shrink the size of the wavetable, so now our signal is size 128, which means wavetable is 256:

/*
Window.closeAll;
*/

(
~sig = Signal.sineFill(128, [1], [0]);
~sig.plot("Signal");
~wt = ~sig.asWavetable;
~wt.collect({arg n; n}).plot("Wavetable");
)

So the crazy dance still happens if the window is small enough, but if we stretch it out, it stops, and this is truly what wavetable format looks like. It's got this distinct zigzag pattern on a value-by-value basis. I'm gonna hit the M key to view this as points instead of lines, and shrink the window back down, everything's fine until the graph occupies fewer than 256 pixels on my screen. When that happens, we no longer have enough pixels to represent the full shape. With the signal, if we drop a few values, it's no big deal, we can still see the general shape very clearly, but with the wavetable, because this value-by-value zigzag shape, we instantly get very severe visual aliasing. It's exactly the same type of phenomenon that occurs with sound, if we sample a frequency that's too high for the sampling rate, we get aliasing, or foldover, and the result is a bunch of bogus data in the output.

Wavetable isn't just a format, it's actually a class, and near the bottom of the help file, in these advanced notes, we get a glimpse of detail on the math behind wavetable format. Whereas a signal just contains the raw values, wavetable takes the first adjacent pair and does these two calculations, then it shifts over by one value and does these calculations again...and again. So this explains why wavetable format is twice as big, because there are two calculations for each value, and if you think about the actual numbers, it also explains the zig-zag pattern. But the question is why convert to this strange format? The key word here is efficient, and the Shaper help file has the clearest explanation -- essentially, wavetable format is a special representation to make linear interpolation faster. And this is a really clever concept, because if our wavetable is a plain regular collection, like Signal, the audio server has to take the burden of doing the linear interpolation math, and this is more costly in terms of CPU, and therefore the ceiling is lower for the number of signal processors that we're able to use. But, by pre-processing the wavetable using this special format, we do some of the work ahead of time, and the interpolation math becomes a lot easier for the audio server, so the processing load is reduced, and we have more headroom for the number of UGens we can throw at the server, allowing us to do heavier and more complex signal processing algorithms.

So that's wavetable format in an nutshell, which means we're ready to make some sound. Let's boot the server and launch our analyzer utilities, go back to our original table size,

s.boot;
Window.closeAll;
s.scope;
FreqScope.new;

(
~sig = Signal.sineFill(1024, [1], [0]);
~wt = ~sig.asWavetable;
)

There are a few different ways to load a collection into a Buffer, what I'm going to do is first explicitly allocate a buffer using Buffer.alloc, onto the localhost server s, size 2048 because wavetable format is twice the size of the signal it comes from,

b = Buffer.alloc(s, 2048);

(
~sig = Signal.sineFill(1024, [1], [0]);
~wt = ~sig.asWavetable;
)

And I'm putting this line outside of our parenthetical clump because we only need to do do this once, and inside we're going to use the instance method loadCollection,

s.boot;

b = Buffer.alloc(s, 2048);

(
~sig = Signal.sineFill(1024, [1], [0]);
~wt = ~sig.asWavetable;
b.loadCollection(~wt);
)

to fill the allocated Buffer using the wavetable. This way, we can easily change the wavetable shape, re-run this clump to overwrite the contents of the buffer, but not re-allocate an entirely new Buffer, which would be unnecessary.

Plot the buffer just to be sure it worked:

b.plot

FreqScope.new;
s.scope;

That's our wavetable. And now for a quick sound function, Osc needs the wavetable buffer, a frequency, let's use MouseX. I don't really care about the phase argument right now, but I am going to scale the amplitude down and use multichannel expansion to turn mono into stereo.

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

Hey, we did it! All that work for a sine wave. Oh, and just for fun, here's what happens if you *don't* convert to wavetable format:

(
~sig = Signal.sineFill(2048, [1], [0]);
~wt = ~sig.asWavetable;
b.loadCollection(~sig);
)

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

I mean, that's pretty cool, and it doesn't blow up in your face or crash the audio server or anything, but it's probably not really what we want.

(
~sig = Signal.sineFill(1024, [1], [0]);
~wt = ~sig.asWavetable;
b.loadCollection(~wt);
)

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

But now, let's go back and take advantage of the fact that Osc lets us use any wavetable we like. So, I'll space out the code a little bit for better readability, and let's do the first harmonic at full amplitude, 2nd harmonic amplitude scaled by 1/4, the 3rd by 1/6, and the fourth by 1/2, and we'll keep them all in phase, just use our exclamation point shortcut for that

(
~sig = Signal.sineFill(
	1024,
	[1, 1/4, 1/6, 1/2],
	0!4
);
~wt = ~sig.asWavetable;
b.loadCollection(~wt);
)

We can plot the buffer

b.plot;

...but if we want to see and understand the waveshape, it's better to just plot the signal

~sig.plot;

Play it, and if we line it up nicely, we can clearly see the shape on the scope window...and on the frequency analyzer, we've got the harmonics we specified, at the amplitude ratios we specified.

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

Let's do something even more exotic. So I'm going to make an array called ~amps. It'll start with the fundamental at full amplitude, and then we're going to concatenate amplitudes for another 31 harmonics. For each of these overtones, we're going to make a choice. Either we skip the harmonic by giving it a zero amplitude, or pick a random amplitude between 0.05 and 0.5.

~amps = [1]
~amps = [1] ++
~amps = [1] ++ ({  }!31)
~amps = [1] ++ ({ [].choose }!31)
~amps = [1] ++ ({ [0, ].choose }!31)
~amps = [1]++({ [0, exprand(0.05,0.5)].choose }!31);

Plug this in for our amplitudes, and again keep all the phases at zero.

(
~sig = Signal.sineFill(
	1024,
	~amps,
	0!32
);
~wt = ~sig.asWavetable;
b.loadCollection(~wt);
)

So here's our wacky wavetable,

~sig.plot;

And it sounds like this.

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

[slow] In this particular case, we're basically doing additive synthesis here, and actually it's possible to use SinOsc, some similar code, and some clever multichannel manipulation, to get the exact same effect.

{SinOsc.ar(MouseX.kr(100,1000,1) * (1..32), 0, ~amps*0.1).sum!2}.play;

But the drawback of using SinOsc should be fairly obvious here, and that is that we need a UGen for each partial, whereas with Osc we pre-fill a wavetable, and we only need one oscillator to get the full spectrum, so it's considerably more efficient.

Signal.sineFill is just one of several ways to generate wavetables. You can also use the buffer instance methods sine1, sine2, and sine3. These are pretty similar to Signal.sineFill, in that they're based on sums of sine waves, but sine2 and sine3 have a distinct advantage over Signal.sineFill, because they allow you to specify frequencies of the partials directly, and you're not limited to integer multiples of a fundamental.

So let's use sine3 to fill our Buffer with a new wavetable. For simplicity we'll start with the same pure sine wave, so here's the fundamental, at full amplitude, with a phase of 0 radians.

b.sine3([1],[1],[0]).plot;

That's wavetable format, so if we want to see the plot more clearly, we can set the asWavetable argument to be false. Some of the help documents refer to this as the wavetable flag [Osc help file].

b.sine3([1],[1],[0], asWavetable:false).plot;

So, back in wavetable format,

b.sine3([1],[1],[0], asWavetable:true).plot;
{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

that's a nice clean sine wave. Now here's what I mean about partials whose frequencies are not integer multiples of a fundamental. Let's say I want partial number 1.25. This means we fill the buffer with one and one quarter cycle of a sine wave.

b.sine3([1.25],[1],[0],asWavetable:false).plot;

So what happens here is that Osc is going to cycle through this shape, and when it gets to the end and wraps back to the beginning, there's a big discontinuity because it has to jump instantaneously 1 to 0. Let's see and hear what it sounds like.

b.sine3([1.25],[1],[0],asWavetable:true).plot;

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

That's what I'd call a busted sine wave. It sounds more like a sawtooth wave, because of the big vertical slice we've put into it, and the spectrum looks like a sawtooth spectrum as well, with basically all the partials in decreasing amplitude. And this is generally what happens if you oscillate using a discontinuous wavetable. It's an easy way to get a rich harmonic spectrum quickly. The only thing you should keep in mind is that when you have a discontinuous waveform like this, the signal is gonna alias pretty hard, especially at higher frequencies, and you can hear the aliasing clearly if we increase the upper bound of MouseX:

{Osc.ar(b, MouseX.kr(100,10000,1), mul:0.2!2)}.play;

And, in fact, aliasing is something to watch out for with wavetable synthesis in general, even if we don't have a wavetable with discontinuities, for instance, here's a wavetable table that contains the fundamental and the 50th harmonic at equal amplitudes and phases, which looks like this.

b.sine3([1,50],[1,1],[0,0],asWavetable:false).plot;

b.sine3([1,50],[1,1],[0,0],asWavetable:true);
{Osc.ar(b, MouseX.kr(100,10000,1), mul:0.2!2)}.play;

Down here it's fine...but...this 50th harmonic bonks into the nyquist frequency *so* soon and then folds all over the place. So, definitely important to be aware of this potential problem, and solutions include A- you can just be ok with this kind of sound, B- incorporate some lowpass filtering into your synthesis to soften high frequencies before they alias, although this is not going to make the problem magically disappear or anything, and/or C- consider doing all your synthesis at a higher sampling rate, which raises the nyquist frequency and therefore raises the threshold at which aliasing occurs. I think you could also try using larger wavetables, although to be honest I'm not completely sure whether or how much that would help.

But regardless, although aliasing is something that's usually avoided, it's not objectively wrong, its just a type of sound, and sound is contextual and subjective, and it shouldn't discourage you from experimenting with funky random wavetables, like this, where I've got sixteen random partials between harmonic number 0.75 and 40, sorted from low to high, 16 random amplitudes sorted from high to low, and 16 random phases. Produces a lot of interesting-looking results.

(
b.sine3(
	({exprand(0.75,40)}!16).sort,
	({exprand(0.05,0.9)}!16).sort.reverse,
	{rrand(0,2pi)}!16,
	asWavetable:false
).plot;
)

So let's try one of them.

(
b.sine3(
	({exprand(0.75,40)}!16).sort,
	({exprand(0.05,0.9)}!16).sort.reverse,
	{rrand(0,2pi)}!16,
	asWavetable:true
);
)

{Osc.ar(b, MouseX.kr(100,1000,1), mul:0.2!2)}.play;

And, one of the nice perks about using these buffer methods is that Buffers can be modified while the server is running, even if UGens are actively using them.

I'm getting bored of this sound so I'm going to make it a little more interesting by having the right channel one octave higher and slightly detuned.

{Osc.ar(b, MouseX.kr(10,1000,1) * [1, 2.01], mul:0.2!2)}.play;

A third approach for generating wavetables, which I particularly like, is to use the Env class. As a reminder, Env is a language-side specification for a segmented envelope shape, most often used in conjunction with EnvGen in order to produce an envelope signal. But it can be used by itself for a number of reasons, and it's particularly good for wavetables if we just want think in terms of an abstract shape, and not concern ourselves so much with the particulars of spectrum or sums of sine waves.

So to start, let's just plug in some hard values, for levels, let's do 0, 0.6,-0.9, 0.3, and back to 0. For segment durations, because we're eventually going to discretize this envelope, you only have to worry about relative proportions of the durations, rather than the actual values themselves. So let's make the first segment the longest, and get progressively shorter. For this array we could also do 8,6,4,2, or 400, 300, 200, 100, and the resulting wavetable would be exactly the same. And then segment curves. These numbers will have a noticeable impact on the spectrum, with straight lines, angles, and corners tending to produce a wide spectrum, while smooth, curvy, continuous shapes will produce fewer and quieter high harmonics. Let's just do linear interpolation for now, so it looks like this:

Env([0, 0.6, -0.9, 0.3, 0], [4,3,2,1], \lin).plot;

We need this Env to become a Signal, then convert to wavetable format, and then dump it into a buffer. It's possible to cram all this into one line, but for clarity, here's a nice, readable, step-by-step approach, declare a few variables. Convert the Env using asSignal, we tell it the size and it does the math of breaking up the Env into discrete values, convert the signal to wavetable, and load it into our buffer.

(
var env, sig, wt;
env = Env([0, 0.6, -1, 0.3, 0], [4,3,2,1], \lin);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
)

That looks correct,

b.plot;

and sounds like this:

{Osc.ar(b, MouseX.kr(100,1000,1) * [1, 2.01], mul:0.2!2)}.play;

We can soften the corners using sinusoidal interpolation instead, so watch the visuals here:

(
var env, sig, wt;
env = Env([0, 0.6, -1, 0.3, 0], [4,3,2,1], \sine);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
)

Or we can use an array of random numbers

(
var env, sig, wt;
env = Env([0, 0.6, -1, 0.3, 0], [4,3,2,1], {rrand(-20,20)}!4);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
)

{Osc.ar(b, MouseX.kr(100,1000,1) * [1, 2.01], mul:0.2!2)}.play;

Or do what I like to do and just randomize the whole thing and see what comes out. Let's add a variable for number of segments, that can range from 4 to 20, envelope points can be anything from -1 to +1, random durations, random curves... producing wavetables that look like this:

(
var env, sig, wt, numSegs;
numSegs = rrand(4,20);
env = Env(
	{rrand(-1.0,1.0)}!(numSegs+1),
	{exprand(1,20)}!numSegs,
	{rrand(-20,20)}!numSegs
);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
sig.plot;
)

One possible danger here, it's sort of unlikely, but possible that the envelope points will come out all positive, or all negative, in which case the waveshape will be entirely above or below zero, and this means we're introducing some considerable DC offset into the signal, basically pushing  it away from the horizontal axis, and loudspeakers don't like reproducing these kinds of signals, it's not good or healthy for them. For a 20 segment envelope, this is the equivalent of flipping a coin and getting heads 20 times in a row...not very probable. But for only 4 coin flips, this outcome is considerably more likely.

So an improvement here is to limit the range from 0 to 1, and then multiply the resulting array by the array [1, -1],

{rrand(-1.0,1.0)}!(numSegs+1);
{rrand(0.0,1.0)}!10
({rrand(0.0,1.0)}!10) * [1,-1]

and this type of array multiplication in SuperCollider is defined such that corresponding values are multiplied together, and the smaller array will repeat itself as many times as necessary to interact with every value in the larger array:

[1,2,3,4,5,6,7] * [1,-1]

({rrand(0.0,1.0)}!10) * [1,-1]

In other words, all the numbers in the random array with even indices are positive, and the numbers with odd indices are negative, you can see that here. This basically guarantees that we get a waveform that's reasonably well-centered around zero. And then just to shake things up a little, we can scramble the whole result so it's not always alternating positive, negative, positive, negative.

(({rrand(0.0,1.0)}!10) * [1,-1]).scramble

(
var env, sig, wt, numSegs;
numSegs = rrand(4,20);
env = Env(
	(({rrand(0.0,1.0)}!(numSegs+1)) * [1,-1]).scramble,
	{exprand(1,20)}!numSegs,
	{rrand(-20,20)}!numSegs
);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
sig.plot;
)

Looks basically the same as before, but now we can rest easier knowing that our wavetables will be a little more speaker-friendly. Although, even with a 50/50 balance of positive and negative values, it doesn't guarantee that won't get a wavetable that's lopsided, asymmetrical, or just leaning really heavily into positive or negative territory. And because of this, I think it's a good idea to incorporate the LeakDC UGen into your synthesis. It's basically a filter that removes DC offset and centers the waveform around zero, very handy for experimental wavetable stuff, and I always use the default coefficient argument and just pass the audio signal through it, so you'd probably stick a line into a SynthDef that looks like sig equals LeakDC dot ar, sig.

sig = LeakDC.ar(sig);

I'm not going to use LeakDC right now, it's not absolutely necessary, but I will point it out later in the video in the context of an actual SynthDef.

Anyawy, let's play some of these new wavetables.

(
var env, sig, wt, numSegs;
numSegs = rrand(4,20);
env = Env(
	(({rrand(0.0,1.0)}!(numSegs+1)) * [1,-1]).scramble,
	{exprand(1,20)}!numSegs,
	{rrand(-20,20)}!numSegs
);
sig = env.asSignal(1024);
wt = sig.asWavetable;
b.loadCollection(wt);
//sig.plot;
)

{Osc.ar(b, MouseX.kr(10,1000,1) * [1, 2.01], mul:0.2!2)}.play;

I think...these sound...awesome. I like using Env for making wavetables, and I'm usually very pleased with the results. I want to briefly point out a fourth option for generating wavetables, and that is a Signal instance method called waveFill. It's a bit more generalized and open-ended than some of the other methods we looked at, but essentially it's a lot like collect, it's an iterative method that operates on a Signal, and we use a function to algorithmically fill that signal with new values. waveFill is an instance method, which means we have to create a new instance first, newClear is good if we want to start with an empty signal. In the waveFill function we get to pass in three arguments, as usual we can call them whatever we want, the first is the value along the interval from 0 to 1, so on the first iterative pass, x is 0, halfway through it's 0.5, and when we get to index 1023, x is just shy of 1.0, it's equal to 1023/1024, so it's just a normalized value you can use in your algorithm, the second argument is the current value in the signal, because this is a new, empty signal, this will be zero on every iteration, but this argument is useful if you want to apply multiple waveFill operations to a signal, one after the other, and pass the output values back in. And the last argument is an index, so this is simply an iteration counter. We also have the option of supplying a min and max after the function to change the interval for the first argument, so now it'll range from 0 to 2pi, so making a sine wave is very simple now, we just make the function return sin(x).

(
var sig;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	sin(x);
}, 0, 2pi);
sig.plot;
)

But we have complete control over what happens in this function, so maybe we'll do sine of x to the power of 1.5, which makes the frequency of the sine wave increase as x increases...

(
var sig;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	sin(x.pow(1.5));
}, 0, 2pi);
sig.plot;
)

multiply all the values by 1.5,

(
var sig;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	1.5 * sin(x.pow(1.5));
}, 0, 2pi);
sig.plot;
)

but we don't want wavetable values to go beyond -1 or +1, so we can fold these values back into the desired range...

(
var sig;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	var out;
	out = 1.5 * sin(x.pow(1.5));
	out = out.fold(-1,1);
}, 0, 2pi);
sig.plot;
)

and then maybe cube the values

(
var sig;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	var out;
	out = 1.5 * sin(x.pow(1.5));
	out = out.fold(-1,1);
	out = out.cubed;
}, 0, 2pi);
sig.plot;
)

And when you're happy with your function, convert the signal to wavetable and fill the buffer, and play it.

(
var sig, wt;
sig = Signal.newClear(1024);
sig.waveFill({
	arg x, old, i;
	var out;
	out = 1.5 * sin(x.pow(1.5));
	out = out.fold(-1,1);
	out = out.cubed;
}, 0, 2pi);
wt = sig.asWavetable;
b.loadCollection(wt);
)

{Osc.ar(b, MouseX.kr(10,1000,1) * [1, 2.01], mul:0.2!2)}.play;

So that's at least four diverse options for creating wavetables: Signal.sineFill, the buffer methods sine1, sine2, and sine3, using Env, and using Signal.waveFill. Where I'd go from here, is make a SynthDef and add a few more arguments like pan position, detune, etc, and then allocate multiple Buffers and fill each one with a different wavetable and then use Pbind and other patterns to produce an interesting sequence, and just make a really tasty smorgasbord of wavetable synthesis. In fact, that's what I've done. I'm gonna link this code in the description so you can download it, study it, play around with it if you want, and the linked version will also have comments, but here's a very quick rundown:

I've got some setup slash cleanup code where I start a tempoclock, allocate an audio bus for a reverb effect, I boot the server, and then generate 10 wavetables using Env and some carefully crafted randomness and load them into buffers. The summary is that wavetable 0 tends to be the smoothest and has the fewest segments, so it's got a relatively simple spectrum, and wavetable 9 is the most complex, with lots of segments and sharp angles, so it's got the widest spectrum. Here's my wavetable oscillator synthdef, I've got an envelope, and a slow noise generator for detuning the frequency, here's my wavetable oscillator, I use multichannel expansion to make 8 of these, and then spread them across a stereo field using Splay, as I mentioned earlier, here's LeakDC to re-center the waveform if there's any DC bias, balance2 for left-right panning, apply the envelope, and then I have a direct output and an aux output for the reverb effect, here's the reverb synthdef that I always keep in my back pocket, I'll probably cover making a DIY reverb effect like this in a future video. I put the reverb synth on the server, and make it so that it gets reinstantiated if I ever hit command period, and then here are my patterns. I have a background pad that uses the simpler wavetables, an arpeggiated bass pulse that uses some of the more complex wavetables, a minimal melody that uses simpler wavetables, and then a big pattern than chooses from a collection of smaller finite rhythmic patterns. So I'm gonna have this music be the outro for the video, that's it for tutorial 23. In the next video we'll continue what we started here, and talk about multiple wavetable synthesis and waveshaping using VOsc and Shaper, respectively. I look forward to seeing you there, thanks for watching.