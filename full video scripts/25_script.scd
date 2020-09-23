Hey everybody, welcome to tutorial 25. In the next two videos we'll talk about granular synthesis, which refers to a family of techniques that involve chopping up a sound into short segments, called grains, and reassembling them to create a new, and possibly very different sound. In this video, I'll focus on granulating an audio file that's been recorded and stored in a buffer ahead of time, and in the next video I'll show you my approach for doing real-time granulation on a live signal. What I hope to demonstrate is that granular synthesis is a very powerful, flexible tool, capable of producing many different results, including rhythmic patterns, complex drones, pitch shifting and time stretching effects, and lots of other bizarre and exciting transformations.

The default SuperCollider library has a small but robust core collection of granular UGens, which you can find in the help documentation under Browse, UGens, generators, and then at the top, the Granular category. Some of these, like GrainFM and GrainSin synthesize an audio signal and then granulate it, GrainIn will granulate an arbitrary audio signal, so this might be coming from a microphone, an internal audio bus, or it could just be the output of another UGen, and then the other granulators, GrainBuf, TGrains, and Warp1, operate on an audio signal that's been stored in a Buffer.

Ultimately, these UGens are all granulators, so naturally they're all kind of similar in some ways, but unique and interesting in their own ways, so it's definitely worth experimenting and seeing which ones are most exciting to you. Personally, I have found that about 99% of the time, GrainBuf does everything I need it to do, so that's the UGen I'm going to focus on.

s.boot;
s.meter;
s.plotTree;
s.scope;

So, first, we boot the server and I'm also gonna open a few GUI tools to help us visualize what's going on, and then, we need to go find some audio and load it into a buffer. Now, I've gone ahead and grabbed this sample of me talking about my brain exploding back in Tutorial 21.

b = Buffer.read(s, "/Users/eli/Desktop/tutorial21_sample.aiff");
b.play;

I think spoken text is one of the more interesting things to granulate because it's often rhythmically and spectrally interesting to begin with, it has this extra layer of language and meaning that synthesized sound doesn't usually have. Of course you can granulate anything you want, but the main reason I've chosen this sound is because I think spoken text makes for a particularly clear, instructive demonstration of granular synthesis, and helps explain the nuances of how it works. So let's get started, and build a simple function with GrainBuf. We're gonna talk our way through the arguments, set up some simple sound examples as we go in order to demonstrate how the arguments behave and interact with one another, and finish with a slightly more complex and creative example.

The first argument is the number of channels that you want GrainBuf to output. The default is 1, this produces a monophonic output signal, this is pretty boring, and in most cases you'll probably want to put two for stereo output. We'll leave it a 1 for now, and come back to it.

(
{
	var sig;
	sig = GrainBuf.ar(
		1
	);
}.play
)

Next argument is trigger, and whenever this value undergoes a non-positive to positive transition, that's GrainBuf's cue to generate a grain. This can technically be any signal, but there are two UGens in particular that come to mind that I think make a lot of sense to use here, and these are Impulse and Dust. Impulse has a frequency argument and outputs a periodic stream of pulses at that frequency, so this would be exactly 10 grains per second. Dust, on the other hand, outputs pulses at random intervals, but maintains a relatively constant density of pulses per second, so this would give us a cluster of approximately 10 grains per second, maybe a little more or less. We'll use Impulse for now and come back to this later.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10), //Dust.ar(10), back to Impulse

	);
}.play
)

Next is dur, which controls the duration of individual grains, measured in seconds. Like the trigger argument, this can also be a signal, but to keep it simple, for now we'll fix it at 0.09 seconds.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10),
		0.09,
	);
}.play
)

Fourth argument, soundbuf, is the bufnum of the buffer containing the audio we want to granulate, and we've named that buffer b, so b.bufnum will work, or to keep it short, we can just put b.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10),
		0.09,
		b, //.bufnum then delete
	);
}.play
)

Next is rate, this is a ratio corresponding to the playback speed of each grain, and this behaves like the rate argument in PlayBuf from tutorial 8. 1 is no change in pitch, 2 is an octave up, 0.5 an octave down. We'll put 1 for right now.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10),
		0.09,
		b,
		1, //2, 0.5, 1,
	);
}.play
)

After rate is pos, which is short for playback position, this corresponds to the location in the buffer where each grain will start, and this is on a normalized scale, which means 0 is the beginning of the file, and 1 is the end. I'm gonna use a value of 0.2, so all grains will be extracted starting at the same spot, one fifth of the way through the original file.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2
	);
}.play
)

Now, this should make sound if we stop here, but for the sake of completeness, I want to finish off the rest of these arguments, so next is interpolation, which determines the type of sample interpolation if there's a change in playback speed. 1 means no interpolation, 2 is linear, and 4 is cubic. The default is 2 which is fine for most applications, and we'll come back to this later in the video.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2
	);
}.play
)

Next is pan position. If you provided 1 for the number of channels, then GrainBuf ignores pan. But if you provide 2 for numChannels, then the pan argument is interpreted exactly as it is in Pan2, where 1 is hard right, negative 1 is hard left, and 0 in the center.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
	);
}.play
)

After pan is envBufNum, like soundbuf, this should refer to a buffer that contains the shape of an amplitude envelope, and this envelope will be applied to each grain. The default is -1, which means GrainBuf will use a built-in Hanning window, which has a bell curve shape like this:

Signal.hanningWindow(1000).plot

So by default every grain has a smooth fade-in and fade-out, reaching peak amplitude in the middle, and this helps avoid clicks and discontinuities in the output waveform. For now the built-in Hanning envelope is fine, and I'll show you how to use custom grain envelopes later on.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
	);
}.play
)

The next argument is maxGrains, this is simply the maximum number of overlapping grains that can exist at any moment. The default is 512 which is fairly generous, and I don't think I've ever needed to increase or decrease it. However, do keep in mind that this value can't be dynamically changed as the sound is running, in other words, this is a fixed value at the moment when the sound begins.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

The last two arguments are mul and add. These are included in basically every UGen, we can use them to mathematically scale and shift the output waveform, and we're just going to ignore these like we often do.

Let's play it.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

Command-period to stop that... So, nearly all parameters are constant, so as expected, we get a stream of 10 identical grains per second, each one 90 milliseconds long, all panned center, etc.

Now, if you're following along, and you don't hear anything when you run this code, I can think of...two reasons that might be happening. One thing to consider is that in your audio file, whatever it happens to be, there might just be 90 milliseconds of silence starting 1/5th of the way through, in which case you're creating grains that contain nothing, so the first thing to try is nudge this position value around and see if something pops out.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2, //0.3, 0.5, 0.8
		2,
		0,
		-1,
		512
	);
}.play
)

If you STILL don't hear sound, then I can almost guarantee the problem is that you loaded a stereo file into your buffer, and in the help file for GrainBuf, it says soundbuf must be a buffer holding a *mono* audio signal, and I believe this is also a requirement for the other buffer-granulating UGens. So, using numChannels,

b.numChannels;
b.free;

we can see that my buffer is monophonic, that's good, but let's see what would have happened if I'd accidentally loaded a stereo file instead.

So, here's the same audio, but it's in two identical channels instead of just one...

b = Buffer.read(s, "/Users/eli/Desktop/tutorial21_sample_stereo.aiff");
b.numChannels;
b.play;

And now, if we re-evaluate this function...

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

Absolutely nothin'. On the node tree, we can see that we've created a Synth, and it's sitting right there in the default group, but nothing in the output meters, nothing on the scope. Now, [cmd-.] at the time of making this video, what the helpfile doesn't tell you, is that if you try to granulate a multichannel buffer, GrainBuf will fail silently, no errors, no warnings, so if you're not expecting it, this can become a brutally difficult problem to diagnose. Now before you jump into your favorite audio editor and start mixing all your files down to mono, there's a much better option, which is to use Buffer dot readChannel, we saw this back in Tutorial 8. After server and path, we skip ahead and say channels colon, and provide an array of the channel or channels we want to read. The array [0], reads only the left channel, evaluate, we can verify b is once again a one-channel buffer...

b.free;
b = Buffer.readChannel(s, "/Users/eli/Desktop/tutorial21_sample_stereo.aiff", channels:[0]);
b.numChannels;

and...we have sound once again.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

So the takeaway here is, mono buffers only, so using readChannel and specifying channel [0] is a good habit to get into.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

A quick bit of context here -- we know what the original file is, but what exactly are we hearing from GrainBuf? To unpack this particular sound, here's the source audio in a waveform editor and one fifth of the way through, well that's the buffer duration divided by five...

b.duration/5;

that's about 1.38 seconds, which means our grain starts right about...here, and is just shy of a tenth of a second long. [play x3] Zoom out a bit...[play context]...so it's the "buh" at the beginning of "broke my brain." So this is just to give us a sense of where we are in the file as we now turn our attention to these various GrainBuf parameters, and explore how they affect the output sound, starting with... this Impulse generator, which is producing 10 grains per second. Relatively speaking, that's kind of slow, slow enough at least that we can perceive the grains as individual sonic events, so let's press on the gas pedal a little bit (12, 15, 20, 25, 30, 43)...

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10), //12, 15, 20, 25, 30
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

With grains produced at a fixed time interval, using Impulse, we can call this periodic or synchronous granular synthesis, and around 20 grains per second or so, the individual grains start to fuse together and we start perceiving a unified sense of pitch instead of the individual grains. MouseX allows us to focus on that threshold more easily.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(MouseX.kr(1,200,1).poll),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

Swap Impulse for Dust, and we're doing asynchronous granular synthesis.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(MouseX.kr(1,200,1).poll),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

We're still controlling density with the mouse, but ultimately the grains are randomly generated so they never fuse together into a coherent pitch sensation. Instead, we just get a big noisy grain cloud that sounds kind of like making popcorn.

Let's reset the trigger and move on to grain duration.

If we increase the grain duration little by little, then we'll be able to hear more and more of the phrase "broke my brain".

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09, //0.13, 0.2, 0.5, 1, 2
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

It's very easy to notice is that it gets louder. The rate at which grains are generated stays the same, but the grains are getting longer, which means there's more grain overlap. And when sounds overlap like this, their amplitudes get summed together, so in some cases we're likely to see higher peaks on the meters, and possibly even clipping if we're not careful. So with high grain densities or long grains, you might want to compensate for the increase in amplitude, by just simply by scaling the output, like this.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		2,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.5
}.play
)

If we keep the grains long but lower the trigger frequency, we can get a sort of trance-inducing loop, like this.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10), //4, 2.2.
		2,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.5
}.play
)

If the frequency of the trirggers and the grain duration are inverse values, then each grain begins exactly when previous one ends.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(0.5),
		2,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.5
}.play
)

And notice, with long sparse grains it becomes a lot easier to actually hear the bell curve shape of the Hanning envelope that's applied to each grain.

So now, let's go the other direction and start shortening the grains.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09, //0.06, 0.02
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	); //delete scaling
}.play
)

And, already, we have a problem. The start position stays the same, but the duration shrinks, so our grains have gone from [audacity] here... to here. And...yeah, ain't much going on in here. Under other circumstances we could have also ended up...here...or here...so this is something to watch out for. So let's go ahead and nudge the starting position forward a little bit.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.02, //0.01, 0.005, 0.002, 0.001, 0.0002
		b,
		1,
		0.23, //change to 0.23
		2,
		0,
		-1,
		512
	);
}.play
)

When the grains get this small, they basically become little clicks, each one maybe a dozen samples long, and the nature of the original sound they came from is totally concealed. What can we do with these? Well, for one thing we can make buzzy tones by providing a fast enough trigger rate.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(60),
		0.0002,
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
}.play
)

And I know that doesn't sound like much, but we could make a stereo beating effect using multichannel expansion and two slightly different frequencies, also making sure to change this back to to a one-channel GrainBuf that can then be expanded to two...

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar([60,60.5]),
		0.0002,
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
}.play
)

By changing the grain size ever so subtly, we allow a slightly different chunk of audio into the grain, so we're slightly changing the shape of this 60 Hz fundamental cycle. And when the waveform shape changes, so does the timbre of the resulting tone.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar([60,60.5]),
		0.0002, //0.001, 0.002, 0.005, 0.01, 0.02
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
}.play
)

Let's use MouseX again, and also bring up a real time spectrum analyzer alongside the scope.

FreqScope.new;

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar([60,60.5]),
		MouseX.kr(0.0002,0.1,1).poll,
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
	//sig = sig * 0.5
}.play
)

Or, instead of MouseX, we could automate this parameter with a noise generator, allowing the grain duration to kind of move around on its own, using multichannel expansion here as well, so that grain duration is unique in each channel.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar([60,60.5]),
		LFNoise1.kr(0.3!2).exprange(0.0002,0.1),
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
}.play
)

And...just for fun, take this one step further, and instead of two, we'll make twelve slightly different GrainBufs, each with a unique grain trigger and grain duration, and spread them out across the stereo field using Splay.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Impulse.ar({ExpRand(60,60.5)}!12),
		LFNoise1.kr(0.3!12).exprange(0.0002,0.1),
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
	sig = Splay.ar(sig);
}.play
)

That's nice. Now, like before, if we swap Impulse for Dust, our sense of pitch goes right out the window, because the grains are no longer generated at regular intervals.

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Dust.ar({ExpRand(60,60.5)}!12),
		LFNoise1.kr(0.3!12).exprange(0.0002, 0.1),
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
	//sig = sig * 0.5
	sig = Splay.ar(sig);
}.play
)

And going back to that stereo configuration...with short grains that are more sparse, we're back to our crackly popcorn bits, but with a litte bit more variety in the sound quality

(
{
	var sig;
	sig = GrainBuf.ar(
		1,
		Dust.ar(20!2),
		LFNoise1.kr(0.3!2).exprange(0.0002, 0.2),
		b,
		1,
		0.23,
		2,
		0,
		-1,
		512
	);
	//sig = sig * 0.5
	//sig = Splay.ar(sig);
}.play
)

So that's basically how grain duration fits into the big picture. Let's reset to our original settings and move on to this grain start position value.

//close freqscope

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

As we've already seen, we can manually change this value to extract grains from different parts of the original file. But this doesn't need to be a static value. For example, we can make it completely random. Now in this case, we're generating ten grains per second, but this LFNoise is zipping around much faster, 500 random values per second, so how this works is basically, whenever we get a trigger here, GrainBuf takes a snapshot of this value, wherever it happens to be at that instant, that's the location in the buffer where it pulls the next grain. So this is gonna sound like some real mumbo jumbo for sure.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		LFNoise1.ar(500).range(0,1),
		2,
		0,
		-1,
		512
	);
}.play
)

There's nothing wrong with 500, but it is a lot faster than we actually need, I think we could drop it all the way down to 10, just like the grain trigger frequency, and we'll get very similar results,

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		LFNoise1.ar(10).range(0,1),
		2,
		0,
		-1,
		512
	);
}.play
)

With a much lower frequency, and because LFNoise1 is a linearly-interpolating noise generator, we can actually hear the grain pointer slowly meandering around the file, which is kind of a cool effect.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(10),
		0.09,
		b,
		1,
		LFNoise1.ar(0.1).range(0,1),
		2,
		0,
		-1,
		512
	);
}.play
)

And, same deal as before, we can freely adjust the synchronicity, density and grain duration for noticeably different types of effects, so, this particular configuration with longer asynchronous grains will sound like this:

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(40),
		0.5,
		b,
		1,
		LFNoise1.ar(0.5).range(0,1),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.5
}.play
)

Another variation, we could make the grains much shorter, and bring the frequency of the pointer randomness back up to 500:

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(40),
		0.01,
		b,
		1,
		LFNoise1.ar(500).range(0,1),
		2,
		0,
		-1,
		512
	);
}.play
)

There are lots more interesting variations to explore, and you can pick something different here instead of LFNoise1, so I'll leave it to you if you want to continue experimenting. But let's say we don't want randomness, let's say we want the grain pointer to move through the file from beginning to end. So for this, we could use a Line ...that goes from 0 to 1...and the amount of time it takes to make that trip is determined by the duration of the buffer that we're granulating , and when we get to the end, let's say we're done listening, so doneAction:2.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		0.01,
		b,
		1,
		Line.ar(0, 1, BufDur.ir(b), doneAction:2),
		2,
		0,
		-1,
		512
	);
}.play
)

And all of a sudden we can make sense of the whole phrase once again. But we also have this buzzy 40 Hz tone quality to it, got a little robot voice effect going on. This opens up some new possibilities for us. First let's gradually shrink the grains and see what happens.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		0.01, //0.005, 0.002, 0.001, 0.0005
		b,
		1,
		Line.ar(0, 1, BufDur.ir(b), doneAction:2),
		2,
		0,
		-1,
		512
	);
}.play
)

When the grain duration was 0.01, the grains were big enough that our brains were able to get enough information to translate the sound into words, but small enough that they also have a clicky buzzy flavor. But with these extremely short grains, the crispy buzzy stuff is the overwhelming quality, and we no longer can clearly hear the content of the original file.

With longer grains, we lose the buzziness and start reconstructing the original audio file. And in this case, the ideal grain duration for a perfect file reconstruction is twice the reciprocal of the grain generation rate. which in this case is 2 times 1/40, which is 1/20. This means we get a very precise crossfade between adjacent grains, where each grain reaches its peak exactly at the moment that the previous grain fades out completely.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		Line.ar(0, 1, BufDur.ir(b), doneAction:2),
		2,
		0,
		-1,
		512
	);
}.play
)

To my ear this is indistinguishable from just straight up playing an audio file with PlayBuf. Now if we increase the grain duration beyond this value, nothing interesting is gonna happen, it's just gonna get louder, because we'll have more grain overlap, and all the grains are perfectly in phase with each other.

//1/10, 1/5

You get the idea. But now, let's spice things up a bit. Let's say we don't want too much structure and order, instead of a perfectly straight line from 0 to 1, maybe we want this line to, you know, jiggle around a little bit as it makes the trip, but still maintain its overall 0 to 1 trajectory. To do this, all we have to do is add a bit of noise to the line, like we did before. But for the sake of consistency, I think it would make the most sense if we express these values in samples, and convert to a normalized range as the very last step.

So our Line is now going to represent a sample pointer from 0 to the last sample in the buffer, which has an index of the number of samples in the buffer, minus one, and the duration of the line stays equal to the duration of the buffer. Then, we're going to add a fast-moving noise generator with an output range of plus or minus a thousand samples. Or, if you prefer, you can specify a value in seconds and multiply by the sample rate to convert to samples (0.01). Last, because GrainBuf needs this value to be between 0 to 1, we take the whole thing, and divide by the number of samples in the buffer.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b), doneAction:2)
			+ LFNoise1.ar(100).bipolar(1000) //-> to 0.01*SampleRate.ir
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

So it sounds just a little bit...shaky, I guess. One way to conceptualize what's going on here is imagine yourself trying to draw a perfect circle with pencil and paper. It's obviously gonna look like a circle, but it won't be a perfect circle. In this analogy, the noise generator here basically represents the amount of human imperfection in the drawing. And if we increase this error little by little, eventually it completely overwhelms the line.

//0.05, 0.13, 0.5

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b), doneAction:2)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir) //-> to 0.01*SampleRate.ir
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

Yeah, so a deviation of a half second in either direction, is like trying to draw a perfect circle...during an earthquake.

//back to 0.01

Now a cool variation on this idea is to change the duration of the line, and indirectly, this affects the speed at which the pointer moves through the buffer from beginning to end. So for example, times 4 means it'll take 4 times as long to get to the end.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Line.ar(0, BufSamples.ir(b)-1, BufDur.ir(b) * 4, doneAction:2)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

And if that's not creepy enough for you, we could also make the grain pointer move backwards by swapping the start and end values.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Line.ar(BufSamples.ir(b)-1, 0, BufDur.ir(b) * 4, doneAction:2)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

Ok, sweet dreams everyone.

Let's say we want to go from beginning to end not once, but over and over again, well we're basically talking about sample looping, and as discussed in tutorial 8, we can't use Line for this, because Line doesn't loop, but there are are a few UGens that can do this relatively easily, which are LFSaw, Sweep, and Phasor, and for completeness, I'm gonna try to show all three of these options as quickly as I can. And, just a heads up, this part of the tutorial is gonna get a little more math-heavy than usual.

LFSaw generates a pure sawtooth shape, so it's literally just a repeating diagonal line from low to high. It's an oscillator, so it expects a frequency in Hz, so to achieve normal pointer speed, we need the duration of one cycle to be equal to the duration of the buffer. And because frequency and period are inversely related, we set the frequency to be 1 divided by buffer duration. And since we're thinking in terms of samples, the range of LFSaw should be 0 to number of samples minus 1

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			LFSaw.ar(1/BufDur.ir(b)).range(0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

Notice that it doesn't actually start at the beginning, that's because the default initial phase of LFSaw is zero, which causes the sawtooth to start

{LFSaw.ar(10)}.plot(0.2);

at the midpoint of its diagonal segment, and that corresponds to the middle of the audio file. So we provide a phase value of 1

{LFSaw.ar(10,1)}.plot(0.2);

to offset the phase of LFSaw so that it starts at the bottom.

//add phase = 1, play

And from here we can use simple multiplication to scale the frequency as needed in order to move the pointer faster or slower.

//* 2, * 0.5

Sweep, is a ramp that starts at zero and by default counts the number of seconds that have gone by since the last time it received a trigger.

So, the idea is to re-trigger Sweep every time a buffer duration's worth of time has elapsed. We can do this with Impulse running at a frequency of 1/buffer duration, just like we did with LFSaw. The default rate of Sweep is 1, but the technically correct thing to do here is to multiply by BufRateScale, just in case the sample rate of the original audio file is different from the current sample rate of the SuperCollider audio server. And if this sounds totally unfamiliar to you, I recommend you go back and do a quick review of tutorial 8. Last, because Sweep is counting seconds, and we're thinking in terms of samples, we need to multiply Sweep by the sampling rate.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Sweep.ar(1/BufDur.ir(b), 1 * BufRateScale.ir(b)) * SampleRate.ir
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

And from here we can continue scaling the pointer speed as desired by changing this number here.

// * 2, 0.1

Now if that seems like an annoying amount of math for you, well, buckle up beacuse Phasor isn't that much better, although I do think it's the UGen that's most clearly designed to be used for this purpose and it's the one I usually go with because I think it provides the most flexibility.

Phasor is kind of like LFSaw in that it's a repeating linear ramp from A to B. The first argument is the reset trigger, which I'm just gonna put a zero here and ignore it. Phasor automatically wraps back to the start when it gets to the end, so this is only useful if we want to manually retrigger Phasor. Next is rate, and this is a per-sample increment. By default this is 1 which means Phasor is basically counting the number of audio samples  that have gone by. Becasue we're thinking in terms of samples I'm gonna leave this at 1, but again it's appropriate to multiply by BufRateScale just in case we have a sample rate mismatch. After this, Phasor needs its start and end values. We start at zero, end at number of samples minus 1. And the last argument for phasor is reset position -- this is not relevant in this particular case, so I'm just gonna ignore it.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

And once again, this value here is the one we change to make the grain pointer move faster or slower

//2, 0.1

Phew! Ok, that concludes the math segment of this video. I think that's probably enough pointer madness for now, so let's move on to grain playback rate, which is this value here. So we already know this is a ratio, so 2 transposes every grain up an octave, classic chipmunk voice...and 0.5 is an octave in the other direction and that's your sort of basic demonic voice

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(40),
		1/20,
		b,
		1, //2, 0.5
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
}.play
)

But the interesting thing here is that we're shifting pitch without also affecting the total duration of the audio file, and this is something that we can't really do using basic sample playback techniques. So, let's adjust a few things and see if we can't make this pitch shifting effect a little cleaner. For example, we might consider using a higher grain density and relatively long grains, to kind of fill in all the gaps. And, we should anticipate that lots of grains overlapping means higher amplitude, so scaling back the amplitude is probably a good idea.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(100),
		0.2,
		b,
		30.midiratio,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

//1.4, 0.65

And, keep in mind that you don't have to think in terms of frequency ratios, which can be kind of clumsy -- if you want to think in terms of musical semitones, you can do so, and use midiratio to convert.

//-4.midiratio, -1, 2, 5

I think this actually sounds pretty decent, it's probably not the world's worst pitch shifter, probably not the best either. It's important to keep in mind is that there's always going to be some degree of digital artifacts introduced when you apply a pitch shifting process like this, but it tends to be less severe if the amount of pitch shift is relatively small. If you've ever played around with pitch correction software, you've probably noticed that you can make small pitch changes and kind of get away with it without anyone noticing, but if you try to adjust by like several octaves then the sound just becomes like, utterly, utterly ridiculous. Observe:

//30.midicps

Eugh. No. Now there is one possible pitfall to be aware of. Suppose we eliminate this random pointer deviation by collapsing the range to zero, and then let's play around with these playback rate values again.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(100),
		0.2,
		b,
		1.4, //1.5, 1.6, 1.7, 0.8, 0.7
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.00*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

And weirdly, all of a sudden the sound has this strong ringing character. Let's swap this value for MouseX, which might make it a little easier to hear what's going on.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(100),
		0.2,
		b,
		MouseX.kr(0.5,2,1).poll,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.00*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

Sounds cool and weird, but this is definitely not a good pitch shifting effect. It is a little tricky to explain what is going on here, it's the result of a few different things working together but basically we are having phase issues with overlapping grains. If you've ever taken an audio recording class, or maybe a musical acoustics class, you might have heard of something called comb filtering, which is a type of resonance caused by a regular pattern of signal interference, often the result of a signal being added to a delayed copy of itself, and that's basically what's going on here. There's the grain generation rate, grain duration, resampling factor resulting from the playback rate, and of course there's also the content of the original audio file to consider, and basically all these factors are working together to create a predictable pattern of phase-related interference between overlapping grains. As a result, certain frequencies reinforce themselves, and other frequencies cancel themselves out, so as a result, we get these unique spectral colors with strong resonance at certain harmonics. We hear these clearly whenever the mouse is standing still, and moving the mouse causes the resonances to sweep up and down, causing a sort of zipper effect.

//play again

Wild stuff. The point is, if you're aiming for a clean pitch shift, this tiny amount of randomness in the grain pointer can make all the difference, because even a tiny bit is enough to diffuse the phase issues and produce a noticeably cleaner sound.

//reintroduce 0.01 deviation

Similarly, you might find a slight impromevent if you use Dust instead of Impulse for the grain trigger, because that helps remove the inhehrent fundamental frequency of the grain trigger. Now, because Dust is random, the overall amplitude of the output signal might be a little less consistent than Impulse, but I usually find this to be not too much of a problem.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(100),
		0.2,
		b,
		MouseX.kr(0.5,2,1).poll,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.01*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

And with Dust, usually, or at least in this case, you can actually omit the slight randomness in the pointer, and the pitch shift still sounds pretty good.

//0.01 --> 0.00, play

You can decide for yourself which version you think sounds best.

Alright, and now for something I hope you will find very entertaining, Let's use the horizontal and vertical mouse position to control pitch and time, independent of one another.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(100),
		0.2,
		b,
		MouseX.kr(0.5,2,1),
		(
			Phasor.ar(0, MouseY.kr(0.1,2,1) * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.00*SampleRate.ir)
		) / BufSamples.ir(b),
		1,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

ah, ok, so...these four parameters -- grain trigger, grain duration, grain playback rate, and grain start position -- I consider these the four central pillars of GrainBuf, and if you can wrap your head around these then you're basically good to go.

Let's talk about this interpolation value for a second. This is what determines how samples are interpolated when the playback rate changes. 2 is linear, but if we drop it to 1, then the change in quality is subtle but definitely audible, particularly for downward pitch shifting. So here's my voice down about half an octave with linear interpolation...and again with no interpolation...can you hear the difference? downpitching means the granulator is stretching out the waveform, and in this case it has to do some guesswork in-between the original samples, and with no interpolation, it's simply not guessing at all, so the resolution of the waveform degrades quite a bit, and there's a noticeable loss of quality that manifests as a bunch of high frequency garbage. So, generally I would not recommend an interpolation of 1.

//amp 0.5, pch 0.25, interp 2 then 1

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(400),
		0.1,
		b,
		0.7,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(0.00*SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

Now, if you want to go up from linear to cubic, personally, I cannot hear much of a difference in most cases, and the increase in CPU is noticeable. For a moment, watch this first green number in the corner, just to the right of the word Server. with linear interpolation...it kind of hovers around 2%, maybe just below 2%...and with cubic... it's up around 3%, maybe just below. Now, that doesn't seem like much, but if you've got a lot of granulation happening all at once, it can really add up. So, feel free to explore, but generally I think linear strikes a good balance.

//pch 0.7, interp 2 then 4

Panning is straightforward. We know how to pan. Since we specified two channels, then this value here between -1 and +1 represents stereophonic position. So, grains toward the left...grains toward the right...and of course we can also use a signal, noise generator, oscillator, whatever, to automate the pan position, as long as the output range is between negative 1 and positive 1.

//randomness = SR, rate = 1, dur = 0.05, dust40
//pan -0.7, 0.7, LFNoise1.kr(100).range(-1,1)

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(40),
		0.05,
		b,
		1,
		(
			Phasor.ar(0, 1 * BufRateScale.ir(b), 0, BufSamples.ir(b)-1)
			+ LFNoise1.ar(100).bipolar(SampleRate.ir)
		) / BufSamples.ir(b),
		2,
		LFNoise1.kr(100).range(-1,1),
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

Now, for grain envelope, this -1 means we're using a built-in Hanning envelope, and with a density configuration like this, we can easily hear the bell curve shape of the fade-in and fade-out on each grain.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(1),
		0.75,
		b,
		1,
		0.45,
		2,
		0,
		-1,
		512
	);
	sig = sig * 0.4;
}.play
)

Let's say we want to use our own grain envelope, something different, maybe a percussive shape with a very short attack and long release. The first step is to create an instance of Env representing that shape, maybe something like this.

Env.new([0,1,0],[0.01,1],[0,-4]).plot;
e = Env.new([0,1,0],[0.01,1],[0,-4]);

So, get rid of this plot message, store it in the variable e. And we load this env into a buffer, so we use...Buffer.sendCollection, providing the server, and the envelope, -- but -- we can't just load an Env into a Buffer as is, because these types of data are not compatible. Buffers are discrete, Envs are not. I know it kind of looks like it is, but it's not. Env is a specification for an abstract shape with no predetermined duration or length or size. We need to convert the Env into a discrete collection of numbers, and we can do that with the method discretize, providing the desired size of the resulting collection in parentheses. The default is 1024 and that's probably fine but since we have such a short attack transient I think I'd like just a little more resolution so I'm gonna go with 8192, and keep in mind that this does not have to be a power of two, I'm just being a weirdo.

(
e = Env.new([0,1,0],[0.01,1],[0,-4]);
~grainEnv = Buffer.sendCollection(s, e.discretize(8192));
)

Evaluate this, and then plug it into GrainBuf, and now we're applying our custom grain envelope to every single grain.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(1),
		0.75,
		b,
		1,
		0.45,
		2,
		0,
		~grainEnv,
		512
	);
	sig = sig * 0.4;
}.play
)

That is GrainBuf in a nutshell. Now before I conclude with a more substantially creative examples, I want to tie up a few loose ends.

Number 1: I've been using a mix of ar and kr UGens inside of GrainBuf. For example, earlier in the video I used the mouse to control the frequency at which grains are generated, and I used an audio rate impulse generator, like this. Now you might reasonably ask, Impulse is *controlling* some aspect of GrainBuf, we're not listening to Impulse directly, so can't we just use kr and save some CPU cycles? well, sure, let's do that and see how it sounds.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(MouseX.kr(1,300,1).poll), //play, kr, play
		0.09,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

And let's compare that again to ar, which I think you'll agree, sounds much cleaner.

//back to ar, play

At really low frequencies, it's not really a problem, but when we get into higher frequencies, kr just sounds kind of crappy, the grains aren't perfectly synchronized, it kind of hiccups a little bit. This is because the control rate just isn't fast enough to provide the precise resolution we're looking for with these fast, synchronous grains. And this problem might pop up with other parameters in GrainBuf as well, so the lesson here is, when in doubt, use an audio rate UGen, especially if it's a periodic generator running at a relatively high frequency.

Number 2. Here's a question. Suppose we configure GrainBuf to produce grains that are each two seconds long, but they start 85% of the way through the file. In this case, that puts us at 5.85 seconds, which is right about...here, just before "could exist."

b.duration * 0.85;

there's only about a second of audio between the start position and the end of the file. So what happens? How does GrainBuf conjure up a 2-second grain?

Well, the simple answer is, if GrainBuf bumps into the end of the file, it wraps back to the beginning, and finishes the rest of the grain there, as we can clearly hear from this example.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(0.5),
		2,
		b,
		1,
		0.85,
		2,
		0,
		-1,
		512
	);
}.play
)

So this is just something to be aware of, and a very good reason to make sure the beginning...and end...of your original file are faded in and out, because if you're careless and, like, clumsily hack off some important content, then all of a sudden there' a discontinuity between the end and the beginning of your buffer, and that means some grains could have a big ugly click right in the middle.

Number 3: negative playback ratios. Yes, you can do it, and yes it results in grains being played backwards. But it's useful to know precisely how it works. To demonstrate, here is "broke my brain" over and over again.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Impulse.ar(0.8),
		1.1,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		512
	);
}.play
)

And now let's flip the sign of the playback rate.

//-1

As you might be able to tell, "il-eel-kma" is not broke my brain backwards. Instead of extracting the grain and then reversing it, which would sound like this, GrainBuf starts at the start position and actually moves the pointer in the opposite direction, and literally plays the file backwards, so what we're getting is the word completely, but backwards. Again, just a little quirk to keep in mind if you feel like messing around with negative playback rates.

Number 4: max grains, 512 by default, like I said this is a high ceiling that you probably won't hit unless you are actively trying to do so. Nevertheless, a very sensible question is - "what happens if you go above the maximum number of grains"? Does it crash the server? Blow up like a recursive filter? Fortunately, it does not. To demonstrate, I'm gonna make a somewhat dense texture, and drop maxGrains down to 12.

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(40),
		0.2,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		12 //from 512
	);
}.play
)

So it sounds fine, but the post window is trying to get our attention. And just for emphasis, let's go ahead and drop maxGrains all the way down to 2

(
{
	var sig;
	sig = GrainBuf.ar(
		2,
		Dust.ar(40),
		0.2,
		b,
		1,
		0.2,
		2,
		0,
		-1,
		2
	);
}.play
)

So, obviously, there are too many grains. GrainBuf just won't create any new grains if it's already at capacity. It's kind of like a bouncer at the entrance to a club, who is not letting people in because it's already ridiculously crowded inside.

Last one, Number 5: and this should be fairly obvious already, but keep in mind that your results will vary...greatly...depending on the type of source file you're using. So, I encourage you to try granulating all sorts of things. Not just spoken word, but recordings of instruments, synthesized sounds, ambient or envionmental recordings, drum loops in particular can have very interesting results. Regardless of what you choose, I think it's a good idea to just...spin the wheel, plug all sorts of numbers into GrainBuf and see what happens, just make sure you're careful with your volume when using high grain densities or long grain durations.

Now, we've finally come to the end, and since we've just been kind of casually goofing around with function.play this whole time, the last thing I want to do is show you a SynthDef and some other bits of code I've prepared ahead of time, as a way of showing you what a more robust, polished example might look and sound like.

Here's the SynthDef, and although at a glance, it looks quite a bit different, most of the differences are superficial. I've got a ton of arguments for the sake of flexibility, and one of the main differences is that instead of cramming all the details into GrainBuf, instead, I declared several variables to represent GrainBuf's parameters, like density control, grain duration control, etc. One small upgrade I did here was use Select so that I can choose either Dust or Impulse, depending on the value of this sync argument. I'm kind of thinking of it like a boolean value here, so in other words, do I want synchronous grains? 1 for yes, 0 for no, and then that number is used as an index into this array containing Dust and Impulse. Dur control is simply a base duration value multiplied by a noise generator, so if I say durRand is equal to 2, then the grains can be up to 2 times longer or 2 times shorter. for position control, I've separated things out into multiple steps for clarity. We start with phasor, which is our basic sample pointer with an argument for the speed, we add some noise the amount of which we can control using posRand which is a value in seconds, we then divide by bufsamples to convert to a normalized range between 0 and 1, and finally I've made one small addition which is to add a base position value, which basically allows us to offset the pointer somewhere into the middle of the file, instead of always starting from the beginning. Pan control has a base pan position plus some randomness, and we have the ability to control the speed and range of randomness. We plug all this into GrainBuf, then multiply by the envelope and amplitude control, and that's it.

(
SynthDef.new(\gs, {
	arg sync=1, dens=20, baseDur=0.1, durRand=1, buf=0,
	rate=1, pos=0, posSpeed=1, posRand=0,
	grainEnv=(-1), pan=0, panHz=0.1, panRand=0,
	atk=1, sus=2, rel=1, c0=1, c1=(-1), amp=1, out=0;

	var sig, env, densCtrl, durCtrl, posCtrl, panCtrl;

	env = EnvGen.ar(Env.new([0,1,1,0],[atk,sus,rel],[c0,0,c1]),doneAction:2);

	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);

	durCtrl = baseDur * LFNoise1.kr(100).exprange(1/durRand,durRand);

	posCtrl = Phasor.ar(0, posSpeed * BufRateScale.ir(buf), 0, BufSamples.ir(buf)-1);
	posCtrl = posCtrl + LFNoise1.kr(100).bipolar(posRand*SampleRate.ir);
	posCtrl = posCtrl / BufSamples.ir(buf);
	posCtrl = posCtrl + pos;

	panCtrl = pan + LFNoise1.kr(panHz).bipolar(panRand);

	sig = GrainBuf.ar(
		2,
		densCtrl,
		durCtrl,
		buf,
		rate,
		posCtrl,
		2,
		panCtrl,
		grainEnv
	);

	sig = sig * env * amp;

	Out.ar(out, sig);
}).add;
)

The default argument values I've chosen specifically so that when we don't specify anything other than the buffer we want to granulate...

(
Synth.new(\gs, [
	\buf, b,
]);
)

We basically reconstruct the original sound, with a simple 4-second envlope applied to the overall thing. But, we can add a few custom values to recreate our very first example from the beginning of this tutorial:

(
Synth.new(\gs, [
	\buf, b,
	\sync, 1,
	\dens, 10,
	\baseDur, 0.09,
	\posSpeed, 0,
	\pos, 0.2,
]);
)

Bring the density up and the amplitude down to compensate, and we get a drone

(
Synth.new(\gs, [
	\buf, b,
	\sync, 1,
	\dens, 100,
	\baseDur, 0.09,
	\pos, 0.2,
	\posSpeed, 0,
	\amp, 0.3,
]);
)

we can also specify the density as a midi note number, converted to cycles per second, if we want to think in terms of musical pitch

(
Synth.new(\gs, [
	\buf, b,
	\sync, 1,
	\dens, 52.midicps, //50, 47
	\baseDur, 0.09,
	\pos, 0.2,
	\posSpeed, 0,
	\amp, 0.3,
]);
)

Going into asynchronous mode, we get popcorn

(
Synth.new(\gs, [
	\buf, b,
	\sync, 0,
	\dens, 52.midicps,
	\baseDur, 0.09,
	\pos, 0.2,
	\posSpeed, 0,
	\amp, 0.3,
]);
)

With pos speed at 0.25, and adjusting density and duration to really fill in all the gaps, we get a time stretching effect

(
Synth.new(\gs, [
	\buf, b,
	\sync, 0,
	\dens, 400,
	\baseDur, 0.2,
	\pos, 0,
	\posSpeed, 0.25,
	\amp, 0.3,
]);
)

If we want to hear more, we can just extend the sustain time of the envelope

(
Synth.new(\gs, [
	\buf, b,
	\sync, 0,
	\dens, 400,
	\baseDur, 0.2,
	\pos, 0,
	\posSpeed, 0.25,
	\amp, 0.3,
	\sus, 5,
]);
)

And we can independently add some pitch shifting to the mix.

(
Synth.new(\gs, [
	\buf, b,
	\sync, 0,
	\dens, 400,
	\baseDur, 0.2,
	\pos, 0,
	\posSpeed, 0.25,
	\rate, -7.midiratio,
	\amp, 0.3,
	\sus, 5,
]);
)


Finally, here's a slightly more creative example, now you can pause the video, study the code and pick through the details at your leisure, but essentially at the top I've got a looping process that generates chords, below that, another looping process that generates percussive rhythms, and at the bottom, a looping process that just being creepy and playing large grains of my voice that are backwards and slowed down, with a good amount of randomness sprinkled throughout the entire thing.

So, that's it for tutorial 25, I hope you found some of this useful, hope you enjoy this musical outro, thanks for watching, see you next time.

(
~r0 = Routine.new({
	loop{
		(1..8).choose.do({
			var rate = [0,2,3,7,9,10].choose + 70;
			rate = rate.midicps * [2,1,0.5,0.25].choose;
			4.do({
				Synth.new(\gs, [
					\buf, b,
					\sync, 1,
					\dens, rate * rrand(-0.15,0.15).midiratio,
					\baseDur, 0.02,
					\pos, [0.3, 0.4, 0.5, 0.6].choose,
					\posSpeed, 0,
					\amp, exprand(0.05,0.15),
					\atk, exprand(1,4),
					\sus, 0,
					\rel, exprand(3,6),
					\pan, rrand(-0.8,0.8),
				]);
			});
			exprand(0.1,8).wait;
		});
	};
}).play;

~r1 = Routine.new({
	loop{
		(2..5).do({
			Synth.new(\gs, [
				\buf, b,
				\sync, 1,
				\dens, [0.25,0.5,1,2,4,8].choose,
				\baseDur, exprand(0.001,0.025),
				\pos, [0.1, 0.206, 0.398, 0.877].choose,
				\posSpeed, 0,
				\rate, [-2,0,12].choose.midiratio,
				\panHz, exprand(0.1,1),
				\panRand, 0.8,
				\atk, 3, \sus, 1, \rel, 3,
				\amp, exprand(0.25,0.6),
			]);
		});
		exprand(0.5,4).round(0.5).wait;
	};
}).play;

~r2 = Routine.new({
	loop{
		Synth.new(\gs, [
			\buf, b,
			\sync, 0,
			\dens, exprand(0.2,1),
			\baseDur, exprand(0.5,2),
			\pos, rrand(0.0,1.0),
			\posSpeed, rrand(-0.9,0.9),
			\rate, rrand(-10.0,-2.0).midiratio.neg,
			\panHz, 0.1,
			\panRand, 0.5,
			\amp, exprand(0.15,0.4),
			\atk, 4, \sus, 0, \rel, 4,
		]);
		exprand(4,15).wait;
	};
}).play;
)

(
~r0.stop;
~r1.stop;
~r2.stop;
)

/*============ errata ============*/

Hey, it's me, from the future. What I meant to put here was 0.5 comma 2 comma 1. But I mistyped and gave myself a linear range from 0.5 to 2.1, instead of an exponential range from 0.5 to 2. This barely has an effect on the sound and nothing's broken, but, it not what I meant to do. I guess I was just typing too fast.

Hey, me again, from the future. It's not really good practice to declare a synthdef argument named dur. In this particular case it's fine, but if you want to use Pbind to generate a sequence using this instrument, then there's no way to differentiate between dur: the SynthDef argument, and dur: the delta time between events. What I should have done is give this a different name, like baseDur, grainDur, something that isn't dur. If you watch tutorial 10 this'll proabbly make a little more sense. Carry on.