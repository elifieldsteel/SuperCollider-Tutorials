s.boot;
s.scope;
FreqScope.new;

Hey everyone, welcome to tutorial 24. In this video we'll get into some of the more complex and interesting techniques in the wavetable synthesis family. In particular, I want to talk about multiple wavetable synthesis using VOsc, and waveshaping using Shaper. So let's begin with multiple wavetable synthesis.

In the previous video we spent a lot of time creating different types of wavetables. But when playing these wavetables using Osc, there was no clear or obvious way for us to smoothly transition from one wavetable to another, so we ended up switching instantaneously, which is kind of clumsy and unmusical.

This is where multiple wavetable synthesis comes in. In this approach, an oscillator has access to more than one wavetable, and here

[img 25b0]

we're just looking at the simplest case with exactly two wavetables. Let's say the wavetable on the left has index 0, and on the right, index 1. We provide a floating point index between 0 and 1, and the oscillator will interpolate between these two tables according to the index. And if we  use a Line UGen or something similar to sweep from 0 to 1, we get this very cool result where one wavetable morphs into another.

[video 9]

This is precisely what VOsc is designed to do, so let's see how it works. First, we need to generate at least two wavetables. Here is the code that I used to generate the two wavetables in the animated example we just saw,

(
~wt0 = Signal.sineFill(
	1024,
	1/(1..8),
	0!8
).asWavetable;

~wt1 = Signal.sineFill(
	1024,
	[1,0,1/2,1,1/4],
	[0,0,pi,0,pi]
).asWavetable;
)

~wt0.plot; ~wt1.plot;

So, load these wavetables into buffers,

(
~b0 = Buffer.loadCollection(s,~wt0);
~b1 = Buffer.loadCollection(s,~wt1);
)

and then make a quick sound function using VOsc.

(
{
	var sig;
	sig = VOsc.ar()
}.play;
)

Like Osc, VOsc has an argument that tells it which Buffer to use for wavetable information, but because VOsc deals with multiple wavetables, the behavior here is a little bit different. The bufpos argument should correspond to the lowest bufnum of all the wavetable buffers that are being used. As we can see here, buffer ~b0 has bufnum 0, and ~b1 has bufnum 1.

~b0.bufnum;
~b1.bufnum;

So in this case we could *technically* use something like MouseX with a range from 0 to 1, allowing us to sweep the mouse across the screen from left to right, causing wavetable 0 to morph into wavetable 1.

(
{
	var sig;
	sig = VOsc.ar(MouseX.kr(0,1), 300, mul:0.2!2);
}.play
)

This works, but we're being really sloppy here, so I'm gonna take a step back for a moment and discuss a few important points to keep in mind. First, let's convert this sound function into a more robust and flexible SynthDef.

(
SynthDef(\vosc, {
	arg out=0;
	var sig, bufpos;
	bufpos = MouseX.kr(0,1);
	sig = VOsc.ar(bufpos, 300, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

Synth(\vosc);

The first point is that all the buffers that VOsc uses have to be the same size. We've already taken care of this by creating two signals, each with size 1024. We can also confirm this is the case by checking the number of frames in each buffer.

~b0.numFrames;
~b1.numFrames;

Not being able to mix-and-match wavetable sizes isn't a big deal at all, just something you have to remember. If you do accidentally mix-and-match, as I'm doing here,

(
~wt0 = Signal.sineFill(
	1024,
	1/(1..8),
	0!8
).asWavetable;

~wt1 = Signal.sineFill(
	2048,
	[1,0,1/2,1,1/4],
	[0,0,pi,0,pi]
).asWavetable;
)

Buffer.freeAll;

(
~b0 = Buffer.loadCollection(s,~wt0);
~b1 = Buffer.loadCollection(s,~wt1);
)

then VOsc will fail silently,

Synth(\vosc);

with no audio glitches, no error messages, just...silence. And situations like this, where SuperCollider gives you no feedback at all, can easily be the hardest and most frustrating to debug. So, keep all your wavetables the same size, and you'll be fine.

// back to 1024

Next, it's not a great idea to hard-wire bufnums 0 and 1 into our SynthDef, as I've done here.

(
SynthDef(\vosc, {
	arg out=0;
	var sig, bufpos;
	bufpos = MouseX.kr(0,1);
	sig = VOsc.ar(bufpos, 300, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

For example if later on we create additional wavetables with bufnums 2, 3, 4, etc, this overly-specific SynthDef becomes kind of useless. A better solution is to provide some arguments, corresponding to the lowest bufnum, call it buf, and the number of buffers you're using, call this numBufs, and then calculate the bufpos argument using some simple math.

(
SynthDef(\vosc, {
	arg out=0, buf=0, numBufs=2;
	var sig, bufpos;
	bufpos = buf + MouseX.kr(0, numBufs-1);
	sig = VOsc.ar(bufpos, 300, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

This keeps the functionality the same, but adds some valuable flexibilty for which and how many wavetables we want to use. So now, instantiating the Synth would look like this, providing the lowest bufnum, and the number of wavetables

Synth(\vosc, [\buf, ~b0.bufnum, \numBufs, 2]);

Another important point is that VOsc assumes, or essentially requires that your wavetable buffer indices are consecutive, ascending numbers. In our case, we allocated these two buffers

~b0.bufnum;
~b1.bufnum;

back-to-back, one right after the other, so of course they're gonna have consecutive buffer numbers and this won't be a problem. But if you allocate your buffers in a haphazard way, like if you scatter the process into smaller chunks across a larger project, you might inadvertently end up with non-consecutive wavetable buffers, and VOsc won't be able to properly interpolate between them. So, let me free all the buffers for a sec and show you what I mean.

Buffer.freeAll;

First, we allocate and fill a buffer with wavetable 0, and then let's pretend we're being careless and allocate handful of buffers that just take up space, and *then* wavetable 1.

~b0 = Buffer.loadCollection(s,~wt0);

Buffer.alloc(s, 2048); //x4

~b1 = Buffer.loadCollection(s,~wt1);

Now, if we play our Synth and sweep the mouse...

Synth(\vosc, [\buf, ~b0.bufnum, \numBufs, 2]);

VOsc morphs from wavetable 0 to whatever's in buffer with index 1 and that happens to be one of these empty junk buffers. So we're morphing from wavetable to silence, very boring, and not what we want. So, is there a way to guarantee our wavetables have consecutive indices? One of the best ways, which the VOsc help file recommends, is to use the buffer class method allocConsecutive. Here's an example. First, here's some code that creates four random wavetables using the Env class, and Array.fill to store them in an Array called ~wt. You can pause the video if you want to dissect, and keep in mind that this is pretty much copy-and-paste from one of the examples in the previous video.

(
~wt = Array.fill(4, {
	var numSegs = rrand(4,20);
	Env(
		[0]++
		(({rrand(0.0,1.0)}!(numSegs-1)) * [1,-1]).scramble
		++[0],
		{exprand(1,20)}!numSegs,
		{rrand(-20,20)}!numSegs
	).asSignal(1024).asWavetable;
});
)

//clear post

Then we use Buffer.allocConsecutive, providing the number of buffers we want, the server on which to create them, and the number of frames in each one.

~buf = Buffer.allocConsecutive(4, s, 2048);

This returns an array that contains these four buffers—very convenient.

//no clear post

~buf.class;
~buf[0]; //1, 2, 3

Next, we need to fill these buffers with our four wavetables, we can do this easily by just iterating over the array, ~buf dot do, passing in each buffer and an iteration counter, and use loadCollection to fill each buffer with the corresponding wavetable data.

(
~buf.do({
	arg buf, i;
	buf.loadCollection(~wt[i]);
});
)

For a quick visual aid, let's plot these four wavetables, and for clarity, I'll put each bufnum in the title bar of its corresponding plot window:

~wt.do({arg n,i; n.plot()});
~wt.do({arg n,i; n.plot(~buf[i].bufnum.asString)});

I intentionally didn't free the six buffers from the previous example, so those bufnums are still in use, and these four buffers have bufnums 6, 7, 8, and 9. Let's poll these bufpos values for additional clarity,

(
SynthDef(\vosc, {
	arg out=0, buf=0, numBufs=2;
	var sig, bufpos;
	bufpos = buf + MouseX.kr(0, numBufs-1);
	sig = VOsc.ar(bufpos.poll, 300, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

Finally, play the Synth, making sure to specify the lowest-index bufnum that we're using, and the correct number of buffers.

Synth(\vosc, [\buf, ~buf[0].bufnum, \numBufs, 4]);

On the left edge, here's bufnum 6...morphing to bufnum 7...bufnum 8...and at the right edge, bufnum 9.

So that's very nice, we can now smoothly interpolate across multiple wavetables. Now, before we jump over to waveshaping, I do want to quickly enhance our SynthDef to make it a bit more interesting and a bit less clinical. First, obviously, it makes a ton of sense to have a frequency argument:

(
SynthDef(\vosc, {
	arg out=0, buf=0, numBufs=2, freq=300;
	var sig, bufpos;
	bufpos = buf + MouseX.kr(0, numBufs-1);
	sig = VOsc.ar(bufpos.poll, freq, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

Synth(\vosc, [\freq, 28.midicps, \buf, ~buf[0].bufnum, \numBufs, 4]);

And instead of MouseX, let's use LFNoise1 to automate and randomize the position of the wavetable index. So now, our shape randomly morphs from one to another, and I don't have to push the mouse around any more.

(
SynthDef(\vosc, {
	arg out=0, buf=0, numBufs=2, freq=300;
	var sig, bufpos;
	bufpos = buf + LFNoise1.kr(0.5).range(0, numBufs-1);
	sig = VOsc.ar(bufpos.poll, freq, mul:0.2!2);
	Out.ar(out, sig);
}).add;
)

Synth(\vosc, [\freq, 28.midicps, \buf, ~buf[0].bufnum, \numBufs, 4]);

And I can never resist the urge to take advantage of multichannel expansion, so I'm going to make a detune signal, an 8-channel array of noise generators, each one ranging from negative to positive 0.2 semitones. So, VOsc becomes an Array of 8 VOscs, and because we only have two speakers, we'll use Splay to spread the eight signals across a stereo field. Like we did in the previous video, LeakDC is helpful in case there's any weird DC bias, an amplitude argument probably a good idea too, so we'll take this mul value away and plug this amplitude control in down here.


//delete poll
//var detuneSig,
//detuneSig = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio,
//Splay, LeakDC, arg amp, amp=0.2, remove mul:0.2!2
(
SynthDef(\vosc, {
	arg out=0, buf=0, numBufs=2, freq=300, amp=0.2;
	var sig, bufpos, detuneSig;
	detuneSig = LFNoise1.kr(0.2!8).bipolar(0.2).midiratio;
	bufpos = buf + LFNoise1.kr(0.5).range(0, numBufs-1);
	sig = VOsc.ar(bufpos, freq * detuneSig);
	sig = Splay.ar(sig);
	sig = LeakDC.ar(sig) * amp;
	Out.ar(out, sig);
}).add;
)

Synth(\vosc, [\freq, 28.midicps, \buf, ~buf[0].bufnum, \numBufs, 4]); //40,47,54,56,61,63

s.freeAll;

You can keep going of course, this example would certainly be improved by including an amplitude envelope, you can also use other types of signals for moving between wavetables, it doesn't have to be a noise generator, so, still plenty of room for experimentation, but that's multiple wavetable synthesis in a nutshell, hopefully that puts things into perspective and gives you a good starting point.

So, let's move on and talk about waveshaping. Waveshaping involves an input signal --

[images]

this can be a sine wave, sawtooth wave, whatever, and a transfer function. Now, the transfer function is a little bit different, it doesn't represent amplitude as a function of time, instead it represents an input/output graph, with both axes on a normalized amplitude scale between negative 1 and positive 1. Amplitude values from the input signal are fed into the transfer function, and the values that come out of the transfer function are used to construct our output signal. If this is a totally new concept for you, it might be a bit tricky to wrap your brain around it at first, but let's start by imagining a very simple case, in which the input signal is a sine wave, and the transfer function is the line y = x. x is the input, y is the output This means every value we put in to the transfer function comes out unchanged. It makes sense to call this the identity transfer function. It's a special case that has no effect on the input, like multiplying by 1 or adding zero. It's also an extremely boring example of waveshaping--

so consider, instead, the transfer function along the line y = x over 2. In this case, everything that goes through the transfer function is reduced by half. This has the effect of uniformly scaling down the amplitude of the input signal, in other words, how to use waveshaping to make a volume knob.

Yet another simple example, consider the transfer function along the line y = negative x. In this case, every value in is effectively multiplied by negative 1, and this has the effect of inverting the input signal.

To reiterate, these three examples are meant to be instructive, so they're boring and not musically interesting on purpose, so, pause for a second and consider this transfer function. Near x = 0, the slope is very steep, but it levels off near x = plus and minus 1. This means low amplitude values in the input signal tend to get boosted away from zero more rapidly, and medium-to-high amplitude values will plateau. In more casual terms, our sine wave gets squashed and starts to resemble a square wave.

If we have a transfer function that loosely resembles the line y = x, but sort of wiggles around it, then we can expect the shape of our input signal to take on these wiggly characteristics.

Let's also not forget that our input signal can be whatever we like, so here's a single cycle of a more complex periodic wave, being shaped by that same wiggly transfer function, and here's the waveform that waveshaping gives us in this particular case.

So keeping these animated examples in mind, let's go back to this relatively simple example and put it into practice using the Shaper UGen. Shaper has a very simple design, it only needs the transfer function buffer, and an audio signal as an input. So here's the Env that I used to create this particular transfer function

~tf = Env([-0.8,0,0.8],[1,1],[8,-8]).plot;
~tf = Env([-0.8,0,0.8],[1,1],[8,-8]).asSignal();

But, here, there's an important distinction between Shaper and the other wavetable UGens we've looked at. For Osc and VOsc, we made a signal whose size was a power of two, and we used asWavetable to convert from Signal to Wavetable format, like this.

(
~tf = Env([-0.8,0,0.8],[1,1],[8,-8]).asSignal(1024);
~tf = ~tf.asWavetable;
)

This method had the effect of doubling the size of the signal,

~tf.size

~tf.plot

because the wavetable conversion process calculates and interleaves additional values into the table in order to make linear interpolation more efficient on the audio server. When we use something like Osc and VOsc, we think of the wavetable as being an inherently cyclic thing, where the end is conceptually connected to the beginning, because in these cases, the wavetable is literally being used as one cycle of a periodic wave. So when we use *asWavetable*, the last interpolation calculation is made using the last point and the first point, basically, the process wraps back to beginning in order to finish the job.

However, when we're using a wavetable with Shaper, we don't conceptualize the wavetable as being inherently cyclic, instead, we see it as a singular transfer function with a beginning, a middle, and an end. So, it doesn't make sense to do the final interpolation calculation using the last and first value, because these two values don't necessarily have anything to do with each other.

So, in order to do the final calculation correctly, we make the size of the Signal a power of two plus one, essentially tagging one extra value onto the end for the very last calculation, and we use the method asWavetableNoWrap.

(
~tf = Env([-0.8,0,0.8],[1,1],[8,-8]).asSignal(1025);
~tf = ~tf.asWavetableNoWrap;
)

And notice that the resulting wavetable still has a power of two, which is a requirement for using waveshaping UGens.

~tf.size;

This business involving a power of two plus 1 and asWavetableNoWrap is something we specifically do when using Shaper, but for wavetable oscillators, we use a normal power of two, and the method asWavetable.

.asSignal(1025).asWavetableNoWrap;
.asSignal(1024).asWavetable;

That fact that you need to do this when using Shaper is mentioned in a couple of comments in one of the examples in the Shaper help file...here we see "size must be power of two plus 1" ... "asWavetableNoWrap"...and it also appears in the Signal source file, which is where the asWavetableNoWrap method is defined.

So, with that out of the way, fill a Buffer with this transfer function,

~tfBuf = Buffer.loadCollection(s, ~tf);

And feed it to Shaper, along with a sine wave input signal.

{Shaper.ar(~tfBuf, SinOsc.ar(400)) * 0.2!2}.play;

There's our simple example, so let's do a more interesting and complex example. For the transfer function, I'm gonna start with the identity transfer function,

~tf = Env([-1,1],[1],[0]).asSignal(1025).plot;

and I'm going to introduce some irregularities by adding it to another Signal of the same size.

(
~tf = Env([-1,1],[1],[0]).asSignal(1025);
~tf = ~tf + (

);
)

We'll use Signal.sineFill for the thing we're gonna add, and for the amplitude array, we'll skip the first three partials by silencing them, and randomly pick three partials from partials 4 thru 9, and randomize the phases. This second signal will look something like this:

(
~tf = Env([-1,1],[1],[0]).asSignal(1025);
~tf = ~tf + (

	Signal.sineFill(
		1025,
		(0!3) ++ [0,0,0,1,1,1].scramble,
		{rrand(0,2pi)}!16
	).plot;

);
)

Signal.sineFill always normalizes to full amplitude, but I want to add a scaled-down version to the identity transfer function, so I'll divide it by 4 before adding it, and then normalize the sum, and that will look something like this:

(
~tf = Env([-1,1],[1],[0]).asSignal(1025);
~tf = ~tf + (
	Signal.sineFill(
		1025,
		(0!3) ++ [0,0,0,1,1,1].scramble,
		{rrand(0,2pi)}!16
	) / 4
);
~tf = ~tf.normalize;
~tf.plot;
)

convert to wavetable and fill the buffer.

(
~tf = Env([-1,1],[1],[0]).asSignal(1025);
~tf = ~tf + (
	Signal.sineFill(
		1025,
		(0!3)++( scramble((0!3)++(1!3)) ),
		{rrand(0,2pi)}!16
	) * 0.25
);
~tf.plot;
~tf = ~tf.normalize.asWavetableNoWrap;
~tfBuf.loadCollection(~tf);
)

plot the buffer, that pretty much looks the way it's supposed to.

~tfBuf.plot

Here's our one-liner from before,

{Shaper.ar(~tfBuf, SinOsc.ar(120)) * 0.2!2}.play;

let's space it out so it's a little bit easier to read, and play it

(
{
	var sig, input;
	input = SinOsc.ar(120);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.2!2;
}.play;
)

So yeah, that's our sine wave shaped by our wiggly transfer function.

Here's one thing that is really cool about waveshaping, especially when we have a non-linear or otherwise crazy-lookin transfer function. Imagine that we fade in the amplitude of input signal, what does the output signal do? Well, initially you might expect to see a boring, predictable, corresponding amplitude fade in with the output signal, but that's not what happens. Instead, what happens is, (speak slowly) as input amplitude increases, the shape and spectrum of the output signal evolve in a very interesting way. This happens, because as input amplitude increases, we end up using a larger and larger subsection of the transfer function, and each of these transfer function slices is unique. And eventually, at full amplitude, the input signal traverses the entire transfer function.

So, in practice, we can use a Line UGen that goes from zero to one over some period of time.

(
{
	var sig, input;
	input = SinOsc.ar(120) * Line.kr(0,1,7);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

For something a bit more interesting, we can use a noise generator instead, so that the output signal is constantly morphing from one thing to another.

(
{
	var sig, input;
	input = SinOsc.ar(120) * LFNoise1.kr(0.5).range(0.1,1);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

Multichannel expansion is great here, like it usually is, we can make 8 sine waves, all slightly detuned, multiply them by 8 unique noise generators, and splay these eight signals across a stereophonic field.

(
{
	var sig, input;
	input = SinOsc.ar({120 * Rand(-0.1,0.1).midiratio}!8);
	input = input * LFNoise1.kr(0.5!8).range(0.1,1);
	sig = Shaper.ar(~tfBuf, input);
	sig = Splay.ar(sig) * 0.3;
}.play;
)

And just to remind you, the input signal doesn't have to be a sine wave. For example, here's a sawtooth wave

(
{
	var sig, input;
	input = LFSaw.ar({120 * Rand(-0.1,0.1).midiratio}!8);
	input = input * LFNoise1.kr(0.4!8).range(0.1,1);
	sig = Shaper.ar(~tfBuf, input);
	sig = Splay.ar(sig) * 0.3;
}.play;
)

So, on the topic of sawtooth waves, the last thing I want to discuss is...sort of a different way to conceptualize waveshaping as a signal operation. So far, we've been envisioning the transfer function as a shape that very loosely resembles the line y = x, maybe incorporating angles and curves in order to take some input signal and sort of mush it around. But let's think about this differently -- let's say we have a transfer function. Some wiggly thing or whatever. And let's say our input signal is a plain old ramp function that goes from -1 to +1 in a straight line, over and over again, aka a non-band limited sawtooth wave. In this case, we just end up reading values from the transfer function from beginning to end, so the transfer function actually becomes our cyclic waveshape on the other side.

In fact, take a step back and realize this is exactly how Osc works. We provide a shape which is assumed to be one cycle of a desired output wave, and Osc produces that shape again and again. So Osc, in fact, is a lot like Shaper, the main difference being that Osc's "input", so to speak, is always a linear sawtooth ramp, but with Shaper, the input can be whatever we like, so with this in mind, consider a variation on this idea, with a triangle wave instead of a sawtooth, so now we have a ramp that goes up and down instead of just up. In this case, we read through the transfer function forward and then backward, and this cyclic shape becomes our output waveform.

Another variation on this idea involves taking an input signal with linear segments, like this triangle wave here, and mathematically curving it away from linearity. The input slope corresponds to the speed at which we read through the transfer funcion, so with this kind of shape, we go forward through the transfer function quickly, gradually getting slower, then backwards through the transfer function slowly at first, gradually getting faster.

Let's see this in practice. Here is the wiggly transfer function we just saw, it's a little complicated, but everything you see here is covered in the previous video, so I'll leave this as a study exercise if you want to pause the video and pick through it on your own time.

(
~tf = Signal.newClear(1025).waveFill({
		arg x, old, i;
		sin(x)
	}, -pi/2,pi/2);
~tf = ~tf.waveFill({
		arg x, old, i;
		old * ((cos(x*0.08) / 4) + 0.3);
	}, 0,50pi).normalize;
~tf.plot;
~tfBuf.loadCollection(~tf.asWavetableNoWrap);
)

~tfBuf.plot;

and using LFSaw, we linearly index through transfer function, producing a periodic wave with that exact shape.

(
{
	var sig, input;
	input = LFSaw.ar(250);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

Doesn't sound great or anything, pretty harsh, noticeable aliasing,

~tf.plot;

because of the gigantic discontinuity when we jump from the end to the beginning.

Using LFTri for a triangle wave index, on the other hand, gives us an up-down ramp, so we get the transfer function forward and backward. As a result, we no longer have that discontinuity, the waveform is smooth, and the spectrum much more mellow.

(
{
	var sig, input;
	input = LFTri.ar(250);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

And as for the curving operation we just saw, here's a plot of a basic triangle wave,

{LFTri.ar(250)}.plot(0.01);

We can use lincurve to bend these linear segments. The input range is the same as the output range, negative positive 1, maps onto negative positive 1, and the fifth value is the curvature, exactly like we've seen with the curve array of Env.new. So, 0 is linear, which will have no effect, but here's the result with a curve value of negative 1,

{LFTri.ar(250).lincurve(-1,1,-1,1,-1)}.plot(0.01);

negative 2, and negative 3.

{LFTri.ar(250).lincurve(-1,1,-1,1,-2)}.plot(0.01);
{LFTri.ar(250).lincurve(-1,1,-1,1,-3)}.plot(0.01);

So, plug this into our sound function:

(
{
	var sig, input;
	input = LFTri.ar(250).lincurve(-1,1,-1,1,-3);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

And we get a pretty funky lookin wave, with a noticeably different shape and spectrum. We can audition a few other numbers here to really reinforce what's going on here

(
{
	var sig, input;
	input = LFTri.ar(250).lincurve(-1,1,-1,1,-1); //-2, -4, -8
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

And yes we absolutely can use a noise generator or any other signal to control the curvature,

(
{
	var sig, input, curve;
	curve = LFNoise1.kr(0.5).bipolar(4);
	input = LFTri.ar(250).lincurve(-1,1,-1,1,curve);
	sig = Shaper.ar(~tfBuf, input);
	sig = sig * 0.3!2;
}.play;
)

In case you haven't noticed, I am completely unable to resist the siren song of multichannel expansion, which is very handy for enriching your synthesis with chorus, detuning, and other nice things.

Not sure if LeakDC is strictly necessary but probably a good and safe thing to do here:

(
{
	var sig, input, curve;
	curve = LFNoise1.kr(0.5!8).bipolar(-4);
	input = LFTri.ar({250 * Rand(-0.1,0.1).midiratio}!8);
	input = input.lincurve(-1,1,-1,1,curve);
	sig = Shaper.ar(~tfBuf, input);
	sig = Splay.ar(sig) * 0.3;
	sig = LeakDC.ar(sig);
}.play;
)

If we were going to turn this function into a SynthDef, it might look something like this, I've added an amplitude envelope along with a few arguments, and again I'll leave this as a study exercise for you if you want to get into the details on your own.

(
SynthDef.new(\shaper, {
	arg buf=0, freq=250, amp=0.2, out=0,
	atk=1, sus=0, rel=5, curvemax=1;
	var sig, input, curve, env;
	env = EnvGen.kr(
		Env.linen(atk,sus,rel,1,[1,0,-1]),
		doneAction:2
	);
	curve = LFNoise1.kr(0.5!8).bipolar(curvemax);
	input = LFTri.ar({freq * Rand(-0.1,0.1).midiratio}!8);
	input = input.lincurve(-1,1,-1,1,curve);
	sig = Shaper.ar(buf, input);
	sig = Splay.ar(sig) * amp * env;
	sig = LeakDC.ar(sig);
	Out.ar(out, sig);
}).add;
)

(slowly) And here is a short iterative function that plays four Synths by picking four pitches between midi notes 40 and 90, rounding them to the nearest scale degree in this arbitrary collection 0, 7, 9, 10, which represents C, G, A, and B-flat, amplitude is dependent on frequency so higher pitches are a little quieter, and curvemax determines how curvy the triangle wave can get, so as this value increases, the shape of the transfer function gets more and more warped, and this produces more and more higher partials in the output spectrum.

(
({rrand(40,90)}!4).do{
	arg n;
	Synth(\shaper, [
		\buf, ~tfBuf,
		\freq, n.nearestInScale([0,7,9,10]) /* wait here */ .postln.midicps,
		\amp, n.lincurve(40,90,0.3,0.1,-2),
		\curvemax, 0,
	]);
};
)

And from here, the possibilities expand in all directions -- you could, for example, jump right into Pbind and other patterns to create interesting sequences, you could modulate the amplitude of the input signal to create that evolving effect that we saw earlier, you could go back to the drawing board and make several different transfer functions and choose randomly from that collection, and in some cases you can some really interesting results by putting several Shaper UGens in series, essentially feeding the output of Shaper back into itself for a second round of waveshaping. So, lots to think about.

Anyway, that's gonna be it for tutorial 24. As I hope is clear from these two videos, wavetable synthesis provides a massive world of creative techniques for you to explore, and if that weren't awesome enough, it's one of the least expensive digital synthesis techniques in terms of CPU overhead. So, I hope you enjoyed this video, and maybe got some fresh ideas for your own work. In the next two videos, we're gonna take a look at granular synthesis using the UGen GrainBuf. In the first video, we'll focus on granulating a pre-recorded audio file, stored in a buffer, and following that, I'll do a video on real-time granulation, and how to apply granular synthesis to a live microphone signal. So, look forward to that, and in the meantime, please leave any comments or questions below, like and subscribe, all that good stuff, thank you very much for watching, see you next time.