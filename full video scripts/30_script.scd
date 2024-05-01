Hey everyone, welcome to tutorial 30. In this video I'll talk about live coding, which is an improvisatory practice that started breaking into the mainstream of electronic music culture around the early 2000s and continues to be an area of research in which people are developing new tools and pushing boundaries. Live coding involves creating sound and/or visuals by writing and manipulating code in real-time, often featured in a concert setting, where the computer screen is projected to the audience so everyone can see the code as it evolves, but it's also a practice that can be beneficial and lead to all sorts of interesting discoveries if you're just exploring and experimenting on your own.

SuperCollider is one of a growing collection of platforms that facilitate live coded music, some other examples include Tidal Cycles, which is a Haskell environment developed by Alex McLean, and Sonic Pi, based on Ruby, created by Sam Aaron. I think it's fair to say that every system has pros and cons, it's not really a one-size-fits-all situation. Environments like Tidal Cycles and Sonic Pi are specifically designed with live coding in mind, so they tend to feel a little more optimized in this respect, they feature a more concise syntax, and they come bundled with a collection of samples and instrument definitions that help you get started quickly. SuperCollider, on the other hand, is more of a general-purpose musical language, so live coding tends to involve a little bit more in terms of typing and prep, but it's still definitely a viable and highly customizable option. And, interesting fact, Tidal Cycles and Sonic Pi both use the SuperCollider audio server as their backend synthesis engine, which I think is a pretty compelling testament to its usefulness.

In this tutorial, we are gonna focus on JITLib, short for the "Just-In-Time Library," which is a family of classes that support live coding. In the help documentation, there's a four-part tutorial on basic concepts, it's well-written with lots of interactive examples, so, definitely check it out for more info. And, for this tutorial, I had the good fortune of collaborating with Julian Rohrhuber, who offered some of his own live coding examples and a lot of valuable insight, Julian is a Professor of Music Informatics and Media Theory, a long-time developer of SuperCollider, JITLib in particular, he's also an experienced live coder and co-author of the JITLib chapter in The SuperCollider Book from 2011. So, big thank-you to Julian for sharing his expertise.

At the core of JITLib is the concept of a proxy, a type of object that operates as a placeholder for something. A proxy can be used as a component in a larger structure, even if the thing it represents is partially or even completely undefined. Proxies let us do things that otherwise seem ridiculous or impossible, like playing a sound and then figuring out what it should sound like, and more generally, with proxies, we gain the ability to perform music more dynamically, without having to know all the details in advance.

//-- Simple Examples

So, as a very simple and introductory example, if you open up SuperCollider and run j = k + 2, you'll get an error because k is nil, and addition with nil is undefined.

j = k + 2; // -> error

k; // -> nil

But if we wrap k in curly braces, suddenly the expression is valid, even though k still doesn't have a value. j becomes a type of function called a BinaryOpFunction, you don't really have to know what that means, but the way I like to conceptualize the result, is that j now "understands" how to produce a concrete result, but also sort of understands on some level that it might not have all the necessary information to do so.

j = {k} + 2;

Whenever k is assigned a suitable value,

k = 3;

we can then evaluate j, and we get a proper result.

j.();

So in this example, we could say that this function enclosure acts as a proxy for k, basically a little protective layer that intercepts evaluation and says to j, "hey, so, I may or may not have a value right now, so just hang tight, and in the meantime, here's everything you need to do your job, whenever that time comes."

s.boot;

So, with this in mind, let's now boot the server and consider a related example. f is currently nil, we can play it without an error because nil responds to the 'play' message by doing nothing. If we then assign a valid UGen function to f, we still won't hear anything because, well, basically, we did things in the wrong order. If we're not using proxies, we have to define a sound process first, and then we can play it.

f; // -> nil

x = f.play; // -> nil

f = { SinOsc.ar([300, 302], mul: 0.1) }; // -> define

x = f.play; // -> sound

And suppose we want to modify the sound in real-time, like, scale the frequency by 1.5. Changing the function at this point has no effect on the sound, because the process of building a temporary SynthDef and creating a Synth on the server, that's already done, and, we didn't plan ahead by declaring any arguments that can be controlled, so we don't really have any good options for modifying this sound, other than, you know, redefining f, releasing the current Synth, and creating a new one.

f = { SinOsc.ar([300, 302] * 1.5, mul: 0.1) };

x.release(2);

x = f.play(fadeTime: 2);

x.release(2);

But, having to manage multiple steps like this is awkward, especially in a live performance setting where we don't really want to be fumbling around too much. What we want is to just be able to run one expression that changes the algorithm and automatically applies a smooth transition, and this is precisely where JITLib comes into play.

NodeProxy is a class that serves as a placeholder for some sound process. And, before we get started, I want to strongly emphasize that, in practice, people generally do not use NodeProxy directly, and instead favor an approach based on its subclass Ndef or the environment class ProxySpace. These two approaches are more streamlined, more concise, and generally superior to using NodeProxy for stylistic reasons, we'll get to them later on, but I do want to start with NodeProxy because it's the foundation on which these other approaches are built, and I think it's instructive to see the core workflow, which you'll find is pretty easy to translate into the Ndef or ProxySpace paradigms.

So, the first step is to create a new NodeProxy, there are some arguments, like audio vs. control rate, and number of channels, but we often aren't required to provide any of this information, because the magical thing about JITLib objects is that in many cases they are able to figure out these kinds of details along the way, based on context. Even without determining what it should sound like, we can play a NodeProxy, which puts it into an active state, I'm gonna chain this method right onto the end of the expression, and also open the node tree for a visual representation of what's going on.

// open node tree

x = NodeProxy.new().play;

Every NodeProxy has a source, which is what determines its signal generating algorithm, and that's what this upper group represents. By default, a source is nil, so it's silent and the source group is empty.

x.source; // -> nil

Below the source group is a monitor group, which contains two monitoring Synths, whose job is to route signal from the source to hardware channels. There are two of them because when we play a NodeProxy, the default behavior is to assume we want stereo sound at the audio rate, which we can verify by calling the relevant methods on the NodeProxy, 'numChannels' and 'rate.'

x.numChannels; // -> 2

x.rate; // -> 'audio'

So let's give this NodeProxy a proper source by just copying the UGen function that we already have, and setting it to the source attribute, run this line, a Synth appears in the source group and we immediately hear sound since the NodeProxy is already playing. And, because we're using a proxy, any update to the source takes effect in real time.

x.source_({ SinOsc.ar([300, 302] * 1.5, mul: 0.1) });

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0), mul: 0.1) });

These source changes seem instantaneous but there's actually a crossfade whose duration is stored in the 'fadeTime' attribute, it's 0.02 seconds by default, but change it to 4, and now we have a 4-second crossfade on every source update.

x.fadeTime; // -> 0.02

x.fadeTime_(4);

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0), mul: 0.1) });

One of the simplest ways to silence a NodeProxy is to just set the source back to nil,

x.source_(nil);

although this does not change the fact that the proxy is still technically playing, so it's trivial to bring the sound back:

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0), mul: 0.1) });

x.source_(nil);

Quick side note, I'm sure I've mentioned or shown this in previous videos, but when setting an attribute of an object to some value, there are two syntax options. There's the underscore syntax with the value in parentheses, which I've been using so far,

k.foo_(1);

but you can also use the equals symbol, like this, which maybe looks a little more familiar:

x.foo = 1;

I often go back and forth, but the underscore style is advantageous because it allows us to chain multiple method calls back-to-back in a single expression.

x.foo_(1).bar_(2);

Going back to our example, an alternative to nil-ifying the source is to call 'stop' on the proxy, which is pretty much the opposite of 'play' in that it removes the monitor section from the server:

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0), mul: 0.1) });

x.stop;

x.play;

x.stop;

A NodeProxy has a Monitor object attached to it,

x.monitor;

and the monitor object has an independent fade time, applied whenever we call play or stop. We can set the monitor fade time like this, which is totally reasonable,

x.monitor.fadeTime_(1); // don't eval

But conveniently, the monitor fade time is automatically set if we specify it as an argument when calling play:

x.play(fadeTime: 1);

x.stop;

I like to think of this technique as equivalent to pulling faders up and down on a mixer, instead of messing around with the process that's actually generating the sound.

There's also the 'end' message, it takes an optional fade time of its own, which not only fades the monitor but also releases the source synth at the end of the fade:

x.play;

x.end;

But again, calling play brings the sound right back to us:

x.play;

x.end;

The fact that there are multiple independent fade times was a point of confusion for me when I was just getting started, because I thought there was only one, and I would encounter a situation where it seemed like my fade time just wasn't working.

On the topic of monitoring, there's also an attribute called 'vol', v-o-l, which is technically attached to the monitor object but it's accessible through the NodeProxy instance. 'vol' simply represents the monitoring level for that proxy, it's 1 by default but we can lower it to something reasonable. The idea here is basically to separate the task of level management from the proxy source, so that we can just run proxy sources at full nominal levels and deal with monitoring levels separately.

x.play;

x.vol;

x.vol_(0.1); // reduce monitoring level

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0)) }); // full-level source

x.end;

'vol' is also an optional argument when calling play, and often convenient and desirable to set the monitoring level right at the beginning of the NodeProxy's existence, which you'll see me do numerous times throughout the rest of this tutorial.

x = NodeProxy().play(vol: 0.1); // show but don't evaluate

Sometimes we want source changes to happen with a particular timing, so that they begin on a specific beat or synchronize with something else. To demonstrate, I'll modulate this tone with a 5 Hz pulse wave, and if we refresh the source a couple of times...

x.play;

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0)) * LFPulse.kr(5) });

you can hear that the new and old pulses don't automatically line up.

x.stop;

Now, this isn't necessarily a problem, but if you want rhythmic precision, the general approach is pretty much identical to working with timing in the context of SuperCollider's pattern library, the basic approach is to create a TempoClock running at the desired tempo, here's one at 110 beats per minute, you can make it permanent if you want it to survive command-period, assign the clock to the proxy using the 'clock' method, and assign a quantization value using the 'quant' method. quant 1 means quantize each source change on the next available beat, 4 means quantize at the start of the next group of 4 beats, and so on.

t = TempoClock(110/60).permanent_(true);

x.clock_(t).quant_(1); // change to 4, back to 1

One other thing to be aware of is that this quantization stuff doesn't really mean anything unless the tempo-oriented values in the source are some sort of integer multiple or divisor of the clock tempo. In other words, if you have a melody at, say, 120 bpm, it doesn't really make any sense to quantize that melody on a grid based on something else, like 87 bpm, because it'll just fall out of sync. But, fortunately, this is pretty easy to deal with because oscillator frequency is measured in cycles per second, and clock tempo is measured in beats per second, and these are basically the same thing. So, a pulse frequency of t.tempo times 4 means four pulses per beat. Update the source, I'll let it do its 4-second crossfade silently in the background, then we'll play the proxy, and you can hear everything stays perfectly in sync.

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0)) * LFPulse.kr(t.tempo * 4) });

x.play;

x.source_({ SinOsc.ar([300, 302] * rrand(1.0, 2.0)) * LFPulse.kr(t.tempo * 4) });

x.stop;

The source of a proxy is often a UGen function, but it can also be a Pbind, which opens up a ton of possibilities for sequences that can be dynamically controlled. In the interest of time, here I'm just doing something very basic using the default SynthDef, but you can certainly make your own for more variety, note that we don't need the curly braces here. Now, what's nice about this feature is that the Pbind will automatically inherit the clock and quant settings of the NodeProxy, and it will interpret its 'dur' values as beats relative to that clock. And, side note here, the default note event has an amplitude of 0.1 built into it, but we're already monitoring at a level of 0.1, so I'm gonna override the default amp with a value of 1, otherwise the output signal will be effectively scaled by 0.01, and that's probably a little too quiet.

x.play;

(
x.source_(Pbind(
	\dur, 1/4,
	\amp, 1,
	\sustain, 0.1,
	\degree, Pseq([1, 3, 4, 5], inf), // + 2, + 4, etc
));
)

x.stop;

One of the most powerful features of JITLib is that you can embed NodeProxyies inside other NodeProxy sources, which makes it very intuitive to deploy LFOs and other types of control signals, and also apply processing effects like delays and reverbs, without having to worry about order of execution, addActions, and other concepts from way back in tutorial 7 that can make things a little bit more unwieldy and complicated than we might want them to be. So, to demonstrate, let's create a new NodeProxy, call it y, give it a crossfade time of 4, play it with a sensible monitoring volume,

y = NodeProxy().fadeTime_(4).play(vol: 0.1);

and I'll give it a simple two-channel sine wave source.

y.source_({ SinOsc.ar([200, 202]) });

And let's do some basic FM synthesis, so proxy y will be the carrier signal, I'll create another NodeProxy, called z, which will be the modulator. I'm not gonna play this one because we don't want to hear it directly, we just want to hear its influence on proxy y.

z = NodeProxy().fadeTime_(4);

Embedding is pretty intuitive, all things considered, we simply build z into the source function for y, and then update that source. Since we're doing FM, we're gonna add z to the frequency of the SinOsc, and also upscale the amplitude of the modulator considerably in order to make the modulation effects more unambiguously audible. Now, in some cases, you can get away with just referencing the NodeProxy variable name as-is, just the letter z, but this won't always work correctly, which I'll explain shortly, the safer and more reliable approach is to specify the rate and optionally the number of channels when embedding, so in this case if we want to embed z as, say, a monophonic audio rate modulator, we'd say z dot ar with 1 in parentheses. This technique is detailed in the NodeProxy help file under the section titled "Embedding and Combining the proxy."

y.source_({ SinOsc.ar([200, 202] + (z * 1000)) }); // don't eval

y.source_({ SinOsc.ar([200, 202] + (z.ar(1) * 1000)) }); // eval

Ok, nothing interesting happens because z doesn't have a source yet — it's still basically an empty container — but I've done things in this order just to reinforce the fact that NodeProxy y "understands" the emptiness of z, on some level, so it doesn't freak out or anything, and the sound remains the same. So now, with z incorporated into y, we can now give z a concrete source, so here's a 1-channel audio rate sine LFO running at four cycles per beat.

z.source_({ SinOsc.ar(t.tempo * 4) });

If you're following along, this is a good moment to pause the video and play around with some of these FM parameters:

y.source_({ SinOsc.ar([200, 202] + (z.ar(1) * 2000)) });

z.source_({ SinOsc.ar(750) });

y.source_({ SinOsc.ar([200, 202] + (z.ar(1) * 5000)) });

z.source_({ SinOsc.ar(51) });

y.source_({ SinOsc.ar([200, 202] + (z.ar(1) * 400)) });

I'll take this opportunity to introduce the 'clear' method, which is the most destructive approach for removing a proxy. It takes an optional fade time of its own and pretty much wipes all aspects of the proxy and resets the source to nil so that it's almost like it never existed:

z.clear(2);

y.clear(2);

This embedding business is mostly straightforward, but without a more complete understanding of what's going on behind the scenes, there are a couple different pitfalls you can stumble into. So, let's back up a few steps and recreate these two proxies.

y = NodeProxy().fadeTime_(4).play(vol: 0.1);

z = NodeProxy().fadeTime_(4);

So, at this point, proxy y is initialized, and by initialized I mean it has a tangible rate and channel count.

y.rate;

y.numChannels;

This initialization is a consequence of the fact that we've chosen to play the proxy, which causes JITLib to make these sensible assumptions. But, we've not chosen to play z, nor have we provided any information for its creation arguments, so z is uninitialized; its rate returns 'scalar,' which is essentially just a placeholder until it's able to figure out whether to run at the control rate or audio rate, and it has no idea how many channels it's supposed to have.

z.rate; // -> scalar

z.numChannels; // -> nil

And so, a potential problem arises if we embed an uninitialized proxy without specifying rate and channel count, like this:

y.source_({ SinOsc.ar([200, 202] + (z * 1000)) });

Now, it doesn't sound like anything's wrong, but this act of embedding an uninitialized proxy in another proxy that's actively playing means we are forcing JITLib to make a guess, and the default behavior is for JITLib to set proxy z to run at the control rate with one channel:

z.rate; // -> control

z.numChannels; // -> 1

And that's fine, assuming this is what we want:

z.source = { SinOsc.kr(40) };

But as soon as we start deviating from this model, you'll start seeing some friendly messages in the post window, basically saying, "ok, well, that doesn't match the structure of this proxy, so I'm just gonna go ahead and change it for you," so that could mean, for example, taking an audio rate signal and downsampling to the control rate, which is gonna cause aliasing at high frequencies and make our FM example sound kinda gritty,

z.source = { SinOsc.ar(40) };

z.source = { SinOsc.ar(2000) };

it might wrap extra channels and sum them with existing channels, and that can have some interesting and unusual consequences, for example, here, these two oscillators at 40 and 41 Hz are summed together and then applied as a modulator:

z.source = { SinOsc.ar([40, 41]) };

or, extra channels might just get ignored, so here, the 41 Hz wave is just dropped, and both channels of the carrier are modulated by the 40 Hz sine wave, because that's how multichannel expansion works.

z.source = { SinOsc.kr([40, 41]) };

z.clear(2);

y.clear(2);

None of these consequences are, like, disastrous — they do make some kind of sound, they don't blow up or go silent or otherwise throw a wrench into the gears, in fact it's kind of nice that there are these built-in behaviors that adjust the source if it's not quite the right fit, but here's an even more extreme example of this kind of problem. Let's suppose z is a totally uninitialized proxy, maybe it'll be some white noise or something later on, and let's say proxy y is gonna create a low-pass filter and pass the signal from proxy z through it.

z = NodeProxy();

y = NodeProxy().source_({ LPF.ar(z, 500) }).play(vol: 0.1); // -> error

This just fails immediately with a big scary error message, but the cause of the problem is exactly the same, we are forcing JITLib to make a guess, and its guess is the control rate, but we are not allowed to have a control rate source as the input to an audio-rate filter. This wasn't an issue previously because it's totally valid to apply basic math operations to a control signal and use it to modulate the frequency of an audio rate oscillator. So, basically, context does matter.

z.clear;

y.clear;

A basic approach for avoiding these issues is to initialize every proxy when created. We can do that by providing appropriate creation arguments, like this:

z = NodeProxy(s, \control, 1); // show but don't evaluate

The class methods 'control' and 'audio' provide an alternate syntax:

z = NodeProxy.control(s, 1); // show but don't evaluate

But this isn't really an ideal solution because it requires us to plan ahead, and having to plan ahead isn't always conducive to live coding, so, a better solution, which we've already seen, is to specify rate and number of channels when embedding.

z = NodeProxy();

y = NodeProxy().source_({ LPF.ar(z.ar(2), 500) }).play(vol: 0.1); // -> no error

z.source_({ WhiteNoise.ar(1 ! 2) });

z.clear(1);

y.clear;

This is a good approach because it has the effect of initializing the proxy if it isn't already initialized, but also nice because even if a proxy is initialized, this approach gives us the option of voluntarily adapting to a different rate or using a different number of channels, without altering the proxy itself, so let me give you an example. Suppose we create proxy z, we give it a 4-second crossfade, and for the source, we're gonna use a five-channel bank of audio rate oscillators at five different frequencies.

z = NodeProxy().fadeTime_(4).source_({ SinOsc.ar([8, 100, 500, 2000, 10000]) });

In doing so, we've implicitly set this proxy to run at the audio rate, and, as you can see, it has five channels.

z.rate;

z.numChannels;

Then, let's create proxy y, with the same fade time, and play it:

y = NodeProxy().fadeTime_(4).play(vol: 0.1);

Once again we're gonna use z as a modulator but before we do, I want to show some of the finer details of this embedding syntax, so, if we just evaluate the NodeProxy variable, z, it returns the NodeProxy object, not surprising at all:

z;

But evaluating z.ar returns an array of five UGens that tangibly represent the proxy output, and this is a much more reliable and appropriate thing to be sticking into a UGen function:

z.ar;

The result of z.kr is the same five channels, but as you can see, they've been downsampled from audio to control rate using the A2K UGen, but importantly, this does not change the fact that proxy z is still running at the audio rate

z.kr; // -> a bunch of A2Ks

z.rate; // -> still audio

And because .ar and .kr return an array in this context, all of our typical array operations are valid, like square brackets to return one channel at a particular index, we can reverse or scramble the array, or whatever,

z.ar[3];

z.ar.reverse;

z.ar.scramble;

the 'ar' and 'kr' methods take some optional arguments in this context, the first of which is a channel count, so z.ar with two in parentheses returns channels 0 and 1, the oscillators at 8 and 100 Hz:

z.ar(2);

The second argument is a channel offset, so z.ar 2 comma 2 skips the first two channels and returns the signals at indices 2 and 3

z.ar(2, 2);

You can even request a number of channels that's bigger than what's available, and the default behavior is to wrap to the beginning of the multichannel signal and repeat channels as needed to meet the requested count:

z.ar(10);

So, let's put this back into context by plugging z back into y, and embed just the first channel for now, so we get 8 wobbles per second:

y.source_({ SinOsc.ar([200, 202] + (z.ar(1) * 1000)) });

And now we'll take just the first two channels:

y.source_({ SinOsc.ar([200, 202] + (z.ar(2) * 1000)) });

Skip to the next two channels, and now the 500 and 2000 Hz modulators are applied to the carrier signal:

y.source_({ SinOsc.ar([200, 202] + (z.ar(2, 2) * 1000)) });

In fact, this channel offset parameter can be modulated, which has a lot of potential for interesting and fun results, so here I'll use a sawtooth wave to basically cycle through consecutive pairs of modulators:

y.source_({ SinOsc.ar([200, 202] + (z.ar(2, LFSaw.ar(0.2).unipolar(5)) * 1000)) });

y.source_({ SinOsc.ar([200, 202] + (z.ar(2, LFSaw.ar(8).unipolar(5)) * 1000)) });

y.source_({ SinOsc.ar([200, 202] + (z.ar(2, LFSaw.ar(40).unipolar(5)) * 1000)) });

y.source_({ SinOsc.ar([200, 202] + (z.ar(2, LFSaw.ar(2000).unipolar(5)) * 1000)) });

And it's technically possible to embed all five channels simultaneously, but because proxy y is initialized to have two channels, once again, the behavior is to wrap and sum the extra channels, so modulators with indices 0, 2, and 4 modulate this 200 Hz carrier and get summed together in the left speaker, and indices 1 and 3 modulate the right channel and get summed together over there:

y.source_({ SinOsc.ar([200, 202] + (z.ar(5) * 1000)) });

y.clear(2);

Very closely related to this topic of embedding is an attribute called "reshaping," also documented in the NodeProxy help file. By default, the 'reshaping' attribute of a NodeProxy is 'nil',

z.reshaping;

which simply means if the proxy source is changed such that it's no longer consistent with the rate and/or number of channels to which the proxy was initialized, JITLib will prioritize the initial settings and adapt the new source as needed to fit into that model. And, actually, this message in the post window is a byproduct of this behavior.

// highlight in post window "NodeProxy.audio(localhost, 2): wrapped channels from 5 to 2 channels"

But, we can change reshaping to be 'elastic', which means the NodeProxy will instead prioritize the structure of the new source, and it will automatically update its rate and number of channels to match the new source.

z.reshaping_(\elastic);

So, right now z is an audio rate proxy, but if we change the source to be a bank of control rate oscillators instead, we can see that now it is a control rate proxy. Add a 6th channel, and we can see the proxy expands to accommodate.

z.rate; // -> audio

z.source_({ SinOsc.kr([8, 100, 500, 2000, 10000]) });

z.rate; // -> control

z.source_({ SinOsc.kr([8, 100, 500, 2000, 10000, 12000]) });

z.numChannels; // -> 6

z.clear;

So, there are lots of situations where elastic reshaping makes a lot of sense, like this example, but it's easy to imagine others, like being able to dynamically grow a bank of resonant filters, or to gradually add more and more voices to some cluster chord, something like that, and in fact, Julian mentioned he considered making elastic reshaping the default, but ultimately decided against it out of concern that people would occasionally fall into these surprise situations, like accidentally creating a source that has thousands of channels. But, fortunately, if you do want to work with elastic proxies by default, all you have to do is set NodeProxy.defaultReshaping to be elastic, and all proxies created from this point forward will be elastic:

NodeProxy.defaultReshaping_(\elastic);

You could even put this expression in your startup file so that you basically never have to think about it ever again. And, if you're not sure whether elastic or static proxies are better for you, I think the thing to do is just start experimenting, and over time, it'll become clear which option makes more sense.

x.clear;

So, without further ado, we've seen a lot of NodeProxy, let's move on to the two more streamlined approaches that I mentioned earlier, using Ndef and ProxySpace.

The relationship between NodeProxy and Ndef is essentially the same as MIDIFunc and MIDIdef. Now, ultimately, both do the same thing, with a different syntax, and the "def" version avoids some potential problems. When creating a MIDIFunc, we typically assign it to a variable so that we can reference it later on. So, after running these two expressions, if I turn a knob on my controller, the MIDIFunc receives the data, performs its function, and it's all good.

MIDIIn.connectAll;

m = MIDIFunc.cc({ |val| val.postln });

However, if we inadvertently run this line multiple times, well, now, we have multiple active MIDIFuncs producing duplicate behavior, which by itself has the potential to create weird, annoying problems, but also m now only refers to the most recently created MIDIFunc, and the others, we'll they're basically inaccessible, and the only reasonable thing to do at this point is hit command-period which, by default, destroys all existing MIDI receivers.

MIDIdef doesn't have this problem, because each one is stored behind the scenes in a dictionary, each one paired according to the symbol we provide, and a dictionary can't have duplicate keys, so no matter how many times we run this line, we only have one active MIDIdef at a time, because each one replaces the previous one. And, as an added bonus, we don't need to store a MIDIdef in a variable, because it already has this unique identifier.

MIDIdef.cc(\m, { |val| val.postln });

So, with these def-type objects, we can modify or update them by providing the symbol, a comma, and then whatever new content we want:

MIDIdef(\m, { |val| (val / 127).postln });

And we can simply reference a "def"-type object just using its symbol in parentheses, for example, in the case of MIDIdef, if we want to disable it or remove it entirely.

MIDIdef(\m);

MIDIdef(\m).disable;

MIDIdef(\m).free;

NodeProxy has the same problem as MIDIFunc, so, for example, consider this expression here, in which we create a NodeProxy, give it a tangible source, and play it all in one expression:

z = NodeProxy().source_({ PinkNoise.ar(1 ! 2) }).play(vol: 0.1);

Generally speaking, this is fine, but if we then absent-mindedly change the source here, on this line, and re-evaluate,

z = NodeProxy().source_({ LFTri.ar(250 ! 2) }).play(vol: 0.1);

What we've done is create a second NodeProxy, which you can hear and see on the node tree, and in doing so, we've overwritten the reference to the first one, so if we clear z,

z.clear;

the triangle wave goes away, but the noise is still playing, and we don't have a sensible way to talk to it any more, so we pretty much have to fall back on command-period.

Ndef avoids this issue the same way MIDIdef avoids it. So here's the same example. Just like NodeProxy, we can play an Ndef before it's fully defined.

Ndef(\z).play(vol: 0.1);

We can even run this line repeatedly, and even though we're calling play again and again, nothing bad happens. At this point we can provide a source by putting it right after the symbol, separated by a comma. We can keep these play messages, or not, it doesn't really matter.

Ndef(\z, { PinkNoise.ar(1 ! 2) }).play(vol: 0.1);

Ndef(\z, { LFTri.ar(250 ! 2) }).play(vol: 0.1);

Ndef(\z, { PinkNoise.ar(1 ! 2) });

Ndef(\z, { LFTri.ar(250 ! 2) });

And the rest of the workflow is virtually identical to what we've already seen with NodeProxy, so here's a quick rundown of what we've covered so far. We'll reuse the permanent TempoClock that we created earlier, we'll also set a quant value and a fade time:

Ndef(\z).clock_(t).quant_(1).fadeTime_(2);

And then we'll make some changes to the source, and we'll be able to hear that these configurations have taken effect:

Ndef(\z, { LFTri.ar(350 ! 2) * LFPulse.kr(t.tempo * 4) });

Ndef(\z, { LFTri.ar(450 ! 2) * LFPulse.kr(t.tempo * 4) });

Ndef(\z, { LFTri.ar(550 ! 2) * LFPulse.kr(t.tempo * 4) });

Again, a Pbind is absolutely a valid source for an Ndef:

Ndef(\z, Pbind(\dur, 0.25, \amp, 1, \sustain, 0.1, \degree, Pseq([0, 1, 4, 5], inf))); // + 2 to array

We can change the tempo on the clock just to confirm that the Pbind is in fact using TempoClock t:

t.tempo_(90/60);

And I'll also briefly show proxy embedding with Ndef, it's very similar, so, let's just play another Ndef named y, with the same clock and quant values.

Ndef(\y).clock_(t).quant_(1).play(vol: 0.2);

This one will be a two-channel sine wave modulated by a tempo-synchronized pulse wave:

(
Ndef(\y, {
	SinOsc.ar([60, 60.2].midicps) * LFPulse.kr(t.tempo * 4, 0, 0.2)
});
)

And we'll do some basic FM just like we did earlier, I'm actually going to use this Pbind-generated signal as the modulator. For the embedding syntax, you can put the rate and channels after the closing parentheses, which is consistent with the NodeProxy examples from earlier,

(
Ndef(\y, {
	SinOsc.ar([60, 60.2].midicps + (Ndef(\z).ar(2) * 1000))
	* LFPulse.kr(t.tempo * 4, 0, 0.2)
});
)

alternatively you can put the ar immediately after Ndef, and then in parentheses, the name and the channel count, which maybe looks a little more idiomatic, but either is fine:

(
Ndef(\y, {
	SinOsc.ar([60, 60.2].midicps + (Ndef.ar(\z, 2) * 1000))
	* LFPulse.kr(t.tempo * 4, 0, 0.2)
});
)

I'm gonna stop monitoring the Pbind so we can focus our attention on Ndef y:

Ndef(\z).stop(fadeTime: 2);

And to make things a little bit more interesting, let's do another embedding example downstream instead of upstream, so what we'll do is pass this modulated sine wave through a delay effect.

Ndef(\del).fadeTime_(4).play(vol: 0.1);

I'm gonna use CombL for this delay effect, and I will embed Ndef y as the input signal to the comb filter and give it a 0.25-second delay.

Ndef(\del, { CombL.ar(Ndef.ar(\y, 2), 0.25, 0.25, 1) * 0.5 });

And once again, if you're following along, this is another good moment to pause the video and play around on your own:

// 1000 -> 2000
Ndef(\y, { SinOsc.ar([60, 60.1].midicps + (Ndef.ar(\z) * 2000)) * LFPulse.kr(t.tempo * 4, 0, 0.2) })

// 2000 -> 5000
Ndef(\y, { SinOsc.ar([60, 60.1].midicps + (Ndef.ar(\z) * 5000)) * LFPulse.kr(t.tempo * 4, 0, 0.2) })

// 0.2 -> 0.4
Ndef(\y, { SinOsc.ar([60, 60.1].midicps + (Ndef.ar(\z) * 5000)) * LFPulse.kr(t.tempo * 4, 0, 0.4) })

// 0.4 -> 0.6
Ndef(\y, { SinOsc.ar([60, 60.1].midicps + (Ndef.ar(\z) * 5000)) * LFPulse.kr(t.tempo * 4, 0, 0.6) })

// add 7 to array
Ndef(\z, Pbind(\dur, 0.25, \amp, 1, \sustain, 0.1, \degree, Pseq([0, 1, 4, 5, 7], inf)));

// add 10 to array
Ndef(\z, Pbind(\dur, 0.25, \amp, 1, \sustain, 0.1, \degree, Pseq([0, 1, 4, 5, 7, 10], inf)));

// + 10
Ndef(\z, Pbind(\dur, 0.25, \amp, 1, \sustain, 0.1, \degree, Pseq([0, 1, 4, 5, 7, 9] + 10, inf)));

// - 25
Ndef(\z, Pbind(\dur, 0.25, \amp, 1, \sustain, 0.1, \degree, Pseq([0, 1, 4, 5, 7, 9] - 25, inf)));

// delay 0.25 -> 1/10 -> 1/35
Ndef(\del, { CombL.ar(Ndef.ar(\y), 0.25, 1/35, 1) * 0.5 });

One more advantage of Ndef is that instead of having to clear multiple proxies individually, you can just use Ndef.clear with an optional fade time, and a clear message propagates to all Ndefs currently in existence.

Ndef.clear(3);

// ProxySpace

Let's move on to ProxySpace, which is the approach I often prefer. ProxySpace is a type of environment, so some contextual information is helpful here. Unless you're totally new to SuperCollider you are probably familiar with the concept of environment variables, sometimes casually called global variables, most commonly accessed using the tilde shortcut, so things like tilde-a, tilde-b, these are containers that live in the current environment, which is a space created for us automatically when we launch SuperCollider. We can access the environment with the special keyword currentEnvironment with a capital E.

~a = 5;

~b = 7;

currentEnvironment;

and you can see, it contains a and b, which we just created. These environment variables seem to behave with global scope because we typically don't have any reason to change environments, so they remain always available to us. But, sometimes we do want to change environments, so to demonstrate what that looks like, let's make a new environment and push it so that it becomes our current environment.

e = Environment().push;

Now, we'll assign a value to tilde-c, we check the currentEnvironment and that's actually the only thing stored here, a and b are actually nil.

~c = 2;

currentEnvironment;

~a;

~b;

To return to the previous environment, we pop the current one,

e.pop;

and then check the current environment one more time,

currentEnvironment;

and there's a and b, right where we left them.

Now for all you visual learners out there, I like to imagine this process as a box, and by default we start with our single, current environment, represented by this orange disc at the top, and so, whatever's at the top of the box is our current environment. And this box is, like, spring-loaded, so when we activate another environment, we "push" it on top of the stack, compressing the spring, and so now this blue disc is our current environment. The previous environment is still there, it's just like, you know, hiding. But if we pop the current environment, it gets ejected from the top of the stack and the environment underneath rises up and becomes the current environment once again.

ProxySpace is a special type of environment with the property that everything it contains is a NodeProxy. To get started, we're gonna create a new ProxySpace, the clock argument provides an opportunity to attach a custom TempoClock to the space, always a good option when creating tempo-based music, and I'm gonna go ahead and reuse the permanent TempoClock from earlier. You can also establish an environment-level fade time and quant, if you want all proxies contained within to adopt these settings, keeping in mind that you can override these settings on an individual proxy basis, if you need to. And, finally, we push the ProxySpace.

p = ProxySpace(clock: t).fadeTime_(4).quant_(1).push;

So now we are inside a ProxySpace, and if we evaluate tilde-sig, already, you can see, it's a NodeProxy, in fact, tilde-everything is a NodeProxy. We can query some attributes, and see that it has, in fact, adopted the fade time, quant and clock tempo of its ProxySpace, remember that we changed the tempo from 110 to 90 beats per minutes a little bit earlier.

~sig;

~sig.fadeTime;

~sig.quant;

~sig.clock.tempo * 60;

And that's pretty much all the new stuff, the techniques we've already covered transfer easily, it's all pretty much the same, for example, we can play the proxy, and give it some play arguments. Repeatedly calling play on a proxy inside a ProxySpace has no undesirable effects, just like we saw with Ndef. To set the source, common practice is to assign using the equals symbol, and for a brief embedding example, here what I'll do is create a tempo-sync'd LFO, and I'm gonna build it into the sig source to modulate the cutoff frequency.

~sig.play(vol: 0.1, fadeTime: 2);

~sig = { LPF.ar(Saw.ar([60, 61]), 1000) };

~lfo = { SinOsc.kr(p.clock.tempo * 4).exprange(100, 1000) };

~sig = { LPF.ar(Saw.ar([60, 61]), ~lfo.kr(1)) };

~sig = { LPF.ar(Saw.ar([60, 61] * 3.midiratio), ~lfo.kr(1)) };

~lfo = { SinOsc.kr(p.clock.tempo * 4).exprange(100, 4000) };

~sig.end;

If you like, you can pause the video and explore a little bit on your own here. And, for the sake of variety and perspective, I asked Julian if he'd be willing to come up with a short live coding example of his own, and he very graciously obliged, so here it is, I'll try to talk through it as we go. To begin, I'm gonna reset the fade time to 0.02 seconds, bypass quantization, and return to 110 beats per minute:

p.fadeTime_(0.02).quant_(nil);

t.tempo_(110/60);

Then, I'll play proxy x:

~x.play(vol:0.1);

I'll also set the monitor volume for y but I'm not gonna play it just yet:

~y.vol_(0.1);

~x will be a pair of ringing filters at two different frequencies, driven by a trigger signal that doesn't exist yet:

~x = { Ringz.ar(~trig.ar, [782, 1032], 0.2) };

Proxy y will be similar, driven by the same triggers but using a comb filter with higher resonant frequencies:

~y = { CombL.ar(~trig.ar, 0.5, 1/[792, 1031]/5, 0.2) };

And then trig will generate two channel of impulses with a sort of polyrhythmic effect:

~trig = { Impulse.ar(p.clock.tempo * [2, 5]/4) };

Run this, and now x immediately begins making sound. We can fade out x and bring in y to hear what the other one sounds like:

~x.stop(fadeTime: 3); ~y.play(fadeTime: 3);

But let's focus on x for the time being:

~x.play(fadeTime: 3); ~y.stop(fadeTime: 3);

Ok, so, more proxies here, p is just gonna be just an array of some values:

~p = [1, 5, 2, 1.2, 5];

And, count is gonna be a process that simply counts pulses, I'll initially poll the output of this one so you can see what that looks like:

~count = { (PulseCount.ar(~trig.ar) % 1e5).poll };

This 1e5 is scientific notation for a hundred thousand, and this modulo operation, I assume, is just sort of a safety mechanism to prevent output values from getting endlessly bigger, even though it would take a long time to get there.

~count = { (PulseCount.ar(~trig.ar) % 1e5) };

And so now, we'll modify x to have a longer decay,

~x = { Ringz.ar(~trig.ar, [782, 1032], 1.4) };

and apply some ring modulation with a low frequency sine wave,

~x = { Ringz.ar(~trig.ar, [782, 1032], 1.4) * SinOsc.ar(12)};

and then we'll scale the frequency of the sine wave based on values in p, and count will determine the channel offset, so basically each impulse from trig will advance to the next value in p and wrap to the beginning when it reaches the end, keeping in mind that trig is actually two impulse generators running at two different speeds.

~x = { Ringz.ar(~trig.ar, [782, 1032], 1.4) * SinOsc.ar(12 * ~p.kr(1, ~count.kr))};

Ok, and here's where things get really interesting, we are gonna redefine the values in p so that some of them are determined by the output signals of x and y, and add to each item in this array the output of x scaled by a factor determined by the horizontal mouse position. So, in effect we're creating a feedback loop, where p influences the output of x, and the output of x influences the values of p. In this specific case, totally safe, because the values are being used to influence the frequency of a modulator, but in other cases where proxy values influence signal amplitude or maybe filter parameters, this feedback construction becomes considerably more dangerous, so, you know, exercise caution.

~p = { [~x, 5, ~y, 3, 20] + (~x * MouseX.kr(2, 100, 1)) } ;

Ok, let's turn our attention back to y,

~x.stop(fadeTime: 3); ~y.play(fadeTime: 3);

and let's adjust some of the comb filter parameters,

~y = { CombL.ar(~trig.ar, 0.5, 1/[722, 932]/3, 1.5) };

and we'll do a nearly identical ring modulation operation, but with a slightly different modulator frequency:

~y = { CombL.ar(~trig.ar, 0.5, 1/[722, 932]/3, 1.5) * SinOsc.ar(14 * ~p.kr(1, ~count.kr)) };

Maybe we'll bring x back into the mix with a slightly lower monitoring level:

~x.play(vol: 0.05);

and then to wind things down, we'll set an environment-wide fade time of 4 seconds,

p.fadeTime = 4;

desynchronize the impulses by switching over to Dust,

~trig = { Dust.ar(p.clock.tempo * [2, 5]/4) };

and we'll use Line to gradually decrease the density over 15 seconds.

~trig = { Dust.ar(p.clock.tempo * Line.kr([2, 5]/4, 0.1, 15)) };

p.end(3);

There is one little tripwire with ProxySpace, which often comes up if you're working with samples. Like, you might think to yourself — ok, let me just, you know, read a sample into a buffer, no big deal — but then WHAM SuperCollider gets a little grumpy, because we're inside of a ProxySpace, where everything is a NodeProxy, and a Buffer is not a valid source for a NodeProxy.

~buf = Buffer.read(s, Platform.resourceDir ++ "/sounds/a11wlk01.wav");

So, what do we do? The quick and dirty solution is to use a single-character interpreter variable, like b or something,

b = Buffer.read(s, Platform.resourceDir ++ "/sounds/a11wlk01.wav"); // don't eval

but I don't really recommend this because there's only 26 letters, or, not even 26 because we're already using p and s, and, if you're loading multiple samples, it's gonna be very easy to forget which is which because single-character names are not very descriptive.

A better solution is to create an empty Event and assign it to an interpreter variable, like this:

q = ();

And then, you can store whatever resources you need inside that Event, and I think Events are especially well-suited for this purpose because they allow a method-style syntax for storage and access. So, q.buf will be the container for our buffer, and then for a sound example, we're gonna just refresh the source for the sig proxy with some sort of PlayBuf thing, and then we'll play it once more.

q.buf = Buffer.read(s, Platform.resourceDir ++ "/sounds/a11wlk01.wav");

~sig = { PlayBuf.ar(1!2, q.buf, 0.75, Impulse.ar(p.clock.tempo * 2), 50000) };

~sig = { PlayBuf.ar(1!2, q.buf, 0.75, Impulse.ar(p.clock.tempo * 2), 70000) };

~sig = { PlayBuf.ar(1!2, q.buf, 0.75, Impulse.ar(p.clock.tempo * 2), 90000) };

~sig.play(vol: 0.1);

When you are completely finished with your session, you can pop to escape from the ProxySpace

p.pop;

And it's good to keep in mind that even though the ProxySpace is now no longer our current environment, it still exists in the interpreter variable p,

p; // -> stuff still here

you can see there's all our stuff, and we can still access things stored inside, just using a slightly different syntax, with p and then in square brackets, the symbol name of the proxy that we want to access

p[\sig].play

p[\sig] = { PlayBuf.ar(1!2, q.buf, 0.75, Impulse.ar(p.clock.tempo * 2), 120000) };

p[\sig] = { PlayBuf.ar(1!2, q.buf, 0.75, Impulse.ar(p.clock.tempo * 2), 130000) };

p[\sig] = nil;

And this is a nice option if you want to use ProxySpace but still retain the ability to use tilde variables like you normally would, to contain other types of data, and then you don't have to bother with this single character Event business.

q = (); // highlight this from earlier

Finally, we'll clean everything up by just clearing the entire ProxySpace.

p.clear;

// Tdef

There's one more JITLib object I want to cover, and that is Tdef. It's a subclass of TaskProxy, so, Tdef-TaskProxy, Ndef-NodeProxy, same relationship. Practically speaking, I like to think of Tdef as the live coding version of Routine, or more accurately, Task, but Routine and Task, very similar. Here's an example where I think Tdef comes in handy. Let's say you've got a NodeProxy, and it's playing some bandpass-filtered multichannel noise mixed down to stereo, like the example I'm building here, and maybe you find yourself repeatedly manipulating some parameter, like transposing a pitch collection to create some sort of harmonic sequence.

Ndef(\n).fadeTime_(0.5).play(vol: 0.1);

Ndef(\n, { Splay.ar(BPF.ar(BrownNoise.ar(1), ([58, 60, 63, 65]).midicps, 0.001, 40))});

Ndef(\n, { Splay.ar(BPF.ar(BrownNoise.ar(1), ([58, 60, 63, 65] + 3).midicps, 0.001, 40))}); // -2, 5

Ok, but, obviously we don't wanna just, sit here and babysit this proxy forever, you know, we've got other things to do, so Tdef is an option for automating this kind of thing. So, let's make a Tdef, I'm gonna name it \npat, and the source is gonna be a function, just like the contents of a normal Routine. Inside the function, we'll create a loop, and then iterate over a set of transposition values, and inside the iteration block we are going to update the Ndef, plugging in the transposition value where appropriate, and do not forget to wait at least once inside this loop, otherwise this live coding party is gonna come to a grinding halt. And finally, we're gonna play the Tdef, and off it goes.

(
Tdef(\npat, {
	loop{
		[0, 3, -2, 5].do { |n|
			Ndef(\n, { Splay.ar(BPF.ar(BrownNoise.ar(1), ([58, 60, 63, 65] + n).midicps, 0.001, 40)) });
			2.wait;
		}
	}
}).play;
)

Just like other JITLib objects, the source of a Tdef can be changed as it's playing.

// (change to midicps * 1.5)

And, stopping the Tdef only stops the looping function that we defined, it doesn't disrupt the Ndef, which just keeps doing its thing with whatever source it was most recently given.

Tdef(\npat).stop;

Ndef(\n).end(2);

Tdef doesn't understand the 'fadeTime' message, which I think makes sense if you think about it,

Tdef(\npat).fadeTime_(4); // -> error

but Tdef does understand 'clock' and 'quant', useful if you want the timing of Tdef to synchronize with other Ndefs or other Tdefs, and the syntax is exactly the same as what we've already seen with Ndef.

Ndef(\y).clock_(t).quant_(1); // go back and highlight this

So, I'm gonna stop here because an encyclopedic tutorial would be obscenely long and kind of overwhelming, and more importantly, I think you can do some really cool things with just the techniques featured in this video, especially if you're willing to sit down and log some serious practice hours, because, you know, after all, live coding is a performance practice, it's a lot like playing an instrument, and a great way to get better is just do it, a lot.

And, on that note, it just didn't feel quite right to make this tutorial without actually putting these concepts into practice, so I sat down a little bit earlier and recorded a 30 minute live coding improv session, largely unrehearsed and unprepared, except for a handful of SynthDefs and Buffers that I put into my startup file, also I confess that I did put some light compression on the recording after the fact just to make the levels sound a little more consistent. Regardless, I like how it came out, I think there are some nice moments, nothing blew up, so that's good, check that out if you're interested. Also, I have a playlist of live coding performance videos that I think are interesting and worth watching, it's pretty small right now but I'll link that in the video description if you're interested. And, to wrap things up, I came up with a few general tips that'll hopefully make your live coding experience a little bit more manageable and enjoyable,

// 1. Use a limiter

Number one, Use a limiter! I should really follow my own advice here, I don't always, don't judge me. A limiter helps avoid explosive dangerous sound, a very real risk when live coding in front of an audience with a, you know, giant PA system. Now, a limiter's not going to be like a military-grade bomb shelter, it's still possible to make really loud and startling sound, but nonetheless it is a very good and safe thing to do. In the past, I've used Batuhan Bozkurt's StageLimiter, which is part of the BatLib Quark, you can install that via Quarks dot gui, and then check the box, recompile the library, and then with the server booted, run StageLimiter.activate, and you are pretty much good to go.

Quarks.gui;

StageLimiter.activate;

// 2. No prep shame

Number 2, there is absolutely no shame in a little bit — or even a lot — of prep, and by that I mean using code that you've written ahead of time to help a live coding session flow more quickly and smoothly. Now, as I mentioned, I totally took advantage of this by putting some SynthDefs and Buffers into my startup file. You might even want to use a partially composed performance file so you can, you know, just get right into it. There are probably some purists out there who might disagree with this philosophy, and that's totally fine, I'm not trying to cramp anyone's style or anything like that. But, nonetheless, it was reassuring to learn that Julian agrees with this, and he also made the comment that deciding on the type and amount of prep code can and probably be should be viewed as an opportunity for the performer to put their own personal spin on a live coding session, and I think that's a pretty smart observation.

// 3. Use your keyboard shortcuts

Number 3, Keyboard shortcuts are your friend — learn them, customize them, use them, resist the urge to reach for the mouse, because generally speaking the keyboard is faster when used strategically. I am not very good at following this piece of advice but I'm trying to get better. Some shortcuts I use all the time are alt-arrow keys to move through text by chunk instead of by character, command-f to find something, and when you've found it, hit escape and the cursor will be right on it. I also have a shortcut to duplicate the current line above or below, and another shortcut to move the current line up or down through the rest of the code. These last two I have found to be really helpful, I can't actually remember if these actions have keybindings by default or if I customized them myself, but in the Shortcuts panel they are called "Copy Line Down and Up" and also "Move Line Down and Up." And speaking of the preferences panel, this is not technically a keyboard shortcut, but related to typing efficiency, in the Editor section, on the Behavior tab, I often like to check the box for "auto-insert matching enclosures," maybe this isn't your cup for tea, for me it took a little getting used to, but I think it's a nice quality-of-life upgrade overall.

// 4. Keep an open mind

And Number 4, keep an open mind and be patient with yourself. Live coding feels different from other types of music-making. If you identify as sort of a perfectionist and you like to fine-tune all the details, that's fine but it's probably gonna be a distraction that slows you down in a live coding setting, so I sort of think the right attitude is to just, you know, let go, be in the moment, be experimental, try things, and whatever happens happens, just like live music in general, it's not gonna be perfect, I would say it's not even supposed to be perfect, but it's happening now and that's kind of what makes it so exciting and enjoyable. And, even if you don't see yourself actually performing as a live coder in front of an audience, don't hesitate to incorporate these JITLib classes into your everyday toolset, like building more traditional compositions, or just exploring sounds in your spare time, because, really, they are very nice and flexible tools with a lot of potential.

That's it for Tutorial 30. A huge shoutout and thanks to my supporters on Patreon, who help support this channel and these videos, thank you all so much for your generosity, it means a lot to me, and I really appreciate it. Thanks again also to Julian Rohrhuber for his expertise and insightful contributions to this tutorial. And finally, if YOU — all you wonderful viewers out there — have any live coding performances, stories, tips, questions, anything you want to share, throw it in the comments, I would love to read it, and as always, thanks for watching, see you next time.

Patreon.thanks;