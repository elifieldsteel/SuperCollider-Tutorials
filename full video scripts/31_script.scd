// Introduction

Hey everyone, welcome to Tutorial 31. In this video, we’ll cover the basics of working with Ambisonic sound in SuperCollider. Ambisonics is a three-dimensional soundfield capture and synthesis technique, and the term "soundfield" refers to some desired pattern of pressure in space produced by an array of loudspeakers, so Ambisonic sound has applications in virtual reality, gaming, and pretty much any situation where immersive sound is valuable. One thing that makes this technique particularly unique and beneficial is the fact that spatial information is encoded into the Ambisonic signal itself, which means it's theoretically possible to reproduce a soundfield on any type of loudspeaker system, from basic stereo to massive multichannel speaker systems, and everything in between. Generally, more speakers means better spatial accuracy, but even if you're only working in stereo or on headphones, you can still use Ambisonic techniques to achieve good results, and losses to the integrity of the soundfield are usually pretty manageable.

// A Brief Overview of Ambisonic Theory

Let's begin with some fundamentals of Ambisonic theory, to better understand how an Ambisonic signal actually carries spatial information. Imagine something that takes up a large amount of space and contains multiple independent sound sources, like a musical ensemble on a wide stage. To capture a sense of width in a recording, a common approach is to set up two cardioid mics with an angle of about 90 degrees between them. One mic is focused on the left side, and the other on the right, and if these two signals are then discretely reproduced on a pair of loudspeakers, and we're sitting in the sweet spot, the result is what's called a stereo image, which provides a listening experience that's more spacious and realistic compared to what we'd get if we had just recorded the ensemble with only one microphone. There are lots of variations on this technique, but there's one in particular called Mid-Side recording, which is fundamentally different. A Mid-Side recording involves two microphones, the "Mid" is a central mic pointing forward with an omnidirectional pattern, this could be cardioid but I'm making it omni for consistency with Ambisonics. The "Side" is a bidirectional mic, placed as close as possible to the omni, and positioned 90 degrees off-axis. So, the omni is equally sensitive in all directions, and the bidirectional is minimally sensitive to sounds in the center, but increasingly sensitive to sounds originating from the far left and right. And, it's important to recognize that a sound from the left will influence the diaphragm of the bidirectional mic in some specific way, producing some specific signal, but the same sound from the opposite side influences the diaphragm in the opposite way, producing the same signal, but with an inverted polarity. So we conceptualize one half of the Side mic as being positive, and the other, negative.

So, we record, and we end up with two signals. M from the omni, S from the bidirectional. To produce a stereo image, we need to convert from Mid-Side to a left-right format using a process called matrixing or decoding, and really, this is just matrix multiplication, and the expression looks like this. We start with our two-channel Mid-Side signal, which we can think of as a 1-by-2 matrix. And the decoding matrix is a 2-by-2, the first column is 1, 1, the second column is 1, negative 1. The result is a new 1-by-2 matrix. The first value is calculated as M times 1 plus S times 1, which is just M plus S, and the second value is M times 1 plus S times -1, which is M minus S. In audio engineering terms, this is M and S mixed together, and M mixed with a polarity-flipped version of S. This result represents our left and right signals, which produce a stereo image with a clear sense of space and width when played back on loudspeakers. Technically, I think it would be more correct for some of these 1s in the decoding matrix to be 0.707 instead, to represent a 3 decibel reduction for equal power purposes, but I’m not really going for scientific precision here — just trying to show the essential concept.

Now, with or without seeing the math, it still may not be immediately clear exactly how or why this works, so let's simplify a little bit, and imagine we only have a single source, center stage. M captures the sound perfectly well, but S captures theoretically nothing, because the sound wave arrives at a null point, where the microphone is minimally sensitive, so in this case, we can treat S as being equal to zero, so M+S and M-S are both just M. On reproduction, both speakers reproduce the omnidirectional signal, which creates the illusion of the source being directly between the loudspeakers, and that's consistent with what we recorded.

Now instead, suppose that same source originated from 90 degrees to the left. M would capture pretty much the exact same signal, because it's omnidirectional, and S would also pick up the signal, at a pretty full and healthy amplitude and with the same polarity as the omni, since the wave is striking the positive side of the bidirectional diaphragm. M+S produces constructive interference, M-S produces destructive interference, so the left speaker would produce a strong signal, and the right speaker would produce theoretically nothing. And, if we imagine that the source originated from somewhere between front and left, then M would be unchanged, and S would have the same polarity, but the amplitude would be weaker since the diaphragm is less sensitive at this angle, so the constructive and destructive interference would not be quite as extreme, and on reproduction, the signal level in the left speaker would be somewhat greater compared to the signal in the right, and we’d perceive the image as being noticeably left of center, but not extremely so. And, it should be pretty obvious that if the source were originating from the right side of the stage instead, it ends up being the case that the speaker on the right is the one that exhibits constructive interference and carries the stronger signal, and so the image appears over on the right side.

Now, ok, what does all this have to do with Ambisonics? Well, the simplest type of Ambisonic signal is basically Mid-Side recording in three dimensions instead of just one. The theoretical microphone setup would be an omnidirectional mic in the middle of the space, and three bidirectional mics, angled along each of the three axes, and in fact, this Ambisonic logo on the Wikipedia page is supposed to represent a top-down projection of this microphone configuration. We call the omni signal W, the axial signals are called X, Y, and Z. And, collectively, this four channel signal constitutes what’s called a first-order Ambisonic B-format signal, and it contains all the information we need to reproduce a three-dimensional soundfield, we just need to apply some decoding process that's appropriate for the number of speakers being used for reproduction, and where those speakers are relative to the listener. And, in many cases, this just boils down to matrix multiplication.

That's the gist of the theory, if some details are still kinda fuzzy, don’t worry about it too much, my goal here is to just lay down a minimal foundation that we can build upon, and things should make more sense as we go.

// ATK Installation

For this tutorial, we'll be using the Ambisonic Toolkit, or ATK for short. The SuperCollider implementation of the ATK is led by Joseph Anderson, and hosted, maintained, and developed by artists and researchers at the Department of Digital Arts and Experimental Media, also known as DXARTS, at the University of Washington. Jo very generously offered his time and expertise in collaborating on this tutorial, so, huge thanks to him for the assist.

For those of you who've never used the ATK before, let's take some time to walk through the installation process. At the time of making this video, the ATK is in active development, so you’ll find the most up-to-date instructions on github.com/ambisonictoolkit/atk-sc3. Step 1, you'll need to install Git. To see if you already have Git installed, you can open a command line interface and run "git version". If you see a version, you're good to go and can move on to the next step. If you don't, one option is to go to git-scm.com, chase the appropriate download link and follow the instructions. Alternatively, if you're on macOS, you can install the Xcode command line tools, in which Git is included, you can do this in the Terminal by running xcode-select --install, as you can see, I’ve already got them installed. And, in fact, I think if you try to run a Git command without Git installed, an installation prompt for the Xcode command line tools should automatically pop up.

So, anyway, once you've installed Git, we can start installing the ATK itself. In SuperCollider, you can run

Quarks.install("https://github.com/ambisonictoolkit/atk-sc3.git");

This installs the atk-sc3 quark and handful of other dependencies. Recompile the class library, and then, in the help browser, if you go to Browse, Libraries, you should see the Ambisonic Toolkit.

Next, we're gonna install the SC3-extensions package, which is linked from the ATK README. Now, my understanding is that the ATK components that live in the extensions package will eventually be migrated over to the ATK quark, so at some point in the future, this step might not be necessary, but regardless, installing the SC3-extensions is not gonna do any harm. So, on the releases page, click the appropriate download link, and once you've got the folder unpacked, we just need to move it to the correct location, which we can get by evaluating:

Platform.userExtensionDir;

or, even simpler, you should be able to find "Open user support directory" as one of the drop-down options in SuperCollider, navigate to the Extensions subfolder, drop the plugins folder inside, and recompile the library again.

And finally, you'll need to download the ATK kernels, matrices, and sound files. These are just additional resources on which the ATK relies. If you've done all the previous steps, you can install these resources by evaluating the following three lines in SuperCollider:

(
Atk.downloadKernels;
Atk.downloadMatrices;
Atk.downloadSounds;
)

The files should be automatically installed in the correct location, and the post window should let you know when installation is complete. You can also evaluate:

Atk.userSupportDir;

and navigate to the returned location to confirm that these resources have been successfully installed. And that's it — you've installed the ATK, so let's get started.

// ATK Overview

The ATK workflow basically involves three things: encoding, transforming, and decoding. Encoding is the process of creating an Ambisonic B-format signal, which could be virtually synthesized from mono or stereo recordings, or better yet, directly created by recording with one of the many commercially available Ambisonic microphones out there. Transforming refers to manipulations of the soundfield itself, achieved by applying mathematical calculations to a B-format signal. Transformations include things like rotating the soundfield, or focusing the soundfield toward a point in space. And, decoding typically means converting from B-format to a more conventional multichannel signal that contains individual feeds for some specific loudspeaker setup.

There's a lot of stuff in the ATK, classes, methods, guides, tutorials. And trying to digest all of it by browsing through the help files can feel overwhelming, so before we get into specifics, I thought it might be helpful to start with a visualization of what I think are some of the most useful and commonly used classes and methods.

The ATK comprises two different toolsets. There's the First-Order Ambisonic toolset, or FOA, which is a historically-informed collection of utilities based on classic Ambisonic tools, like this NRDC Ambisonic Decoder from the late 70s and many others. And then, there's the Higher-Order Ambisonic toolset, or HOA, which represents a more modern approach to Ambisonics, capable of producing higher-order soundfields, which essentially means capturing spatial information at a higher resolution and with more precision. In many cases, you might find yourself working exclusively with one toolset or the other, but there are situations that require conversion between these two sets, so we'll cover that as well.

In the FOA, the encoding process often begins with FoaEncoderMatrix or FoaEncoderKernel. The former uses matrix multiplication, the latter uses a frequency-domain multiplication process called convolution. Common matrix creation methods include things like newDirection, newDirections, newStereo, newOmni, kernel options include newSpread, newDiffuse and newSuper. Regardless of whether we choose a matrix-based or kernel-based encoder, the encoder itself is a static object, and FoaEncode is the UGen that actually applies the encoder and calculates the Ambisonic signal. Alternatively, in the specific case of converting from monophonic to B-format, we can use FoaPanB, whose main advantage is the fact that the directional encoding information is dynamic, and can be modulated by other UGens.

FOA transformation UGens include FoaRotate, Tilt and Tumble for axial rotation, and FoaPush, Focus, Zoom, and Dominate, for various flavors of distorting or warping the soundfield in a particular direction.

For FOA decoding, we have a similar pair of options with FoaDecoderMatrix and FoaDecoderKernel. Matrix options include newStereo, newQuad, newPanto, newPeri, for pantophonic and periphoric decoding, and kernel options include newUHJ for stereo decoding, newListen and newCIPIC for binaural decoding. And FoaDecode is the UGen that applies one of these decoders in order to calculate the output signal.

On the HOA side, things are conceptually similar, but the naming scheme and available methods are different. For encoding, there are no kernel-based options, so HoaMatrixEncoder is pretty much the primary choice, methods include newDirection, newDirections, and others, and HoaEncodeMatrix is the UGen that calculates the B-format signal, basically the HOA equivalent of FoaEncode. For the specific case of encoding from monophonic to B-format, we can use the UGen HoaEncodeDirection, which is equivalent to FoaPanB, and its directional parameters can similarly be modulated.

Many transformations that exist in the FOA also exist in the HOA, including HoaRotate, Tilt, and Tumble, for axial rotation, and HoaFocus, Zoom, and Dominate for directional distortion.

HoaMatrixDecoder is used to generate decoder objects, creation methods include newProjection, newModeMatch, newDirections, and HoaDecodeMatrix is the UGen that performs the signal calculation, equivalent to FoaDecode.

A couple specific methods worth mentioning, newHoa1 is an FOA transcoder creation method that lets us convert between FOA and HOA in either direction, and newFormat is an HOA transcoder method that provides the same ability.

And, there's a couple of fun utility classes, like FoaXformDisplay and TDesign, both of which can be helpful in visualizing soundfields and their transformations, we'll talk about these toward the end of the video. Technically FoaXformDisplay is tailored to the FOA toolset so it would be more correct to put it in that column, but I’ve put it in the middle because I feel like it has broad relevance across the entire ATK.

// FOA

Ok, so with all this in mind, let's start with the FOA tools and build a basic example. Before we boot the server I'm going expand the number of hardware output channels, this'll be relevant later on with some of the more complex examples, and I’m also gonna increase the number of wire buffers, the default is 64, and if we’re doing lots of calculations with large multichannel signals, as is often the case with Ambisonics, you might run into an error that says something like “exceeded number of interconnect buffers,” so increasing this value helps avoid that problem.

s.options.numOutputBusChannels = 24;

s.options.numWireBufs = 512;

s.boot;

For source material, here I've got a recording of me cutting paper with scissors, recorded with a single cardioid condenser mic, so, nothing fancy, just a regular monophonic recording.

b = Buffer.read(s, "/Users/eli/Documents/YouTube/Tutorial 31/source/scissors.aiff");

{ PlayBuf.ar(1, b, BufRateScale.ir(b), doneAction: 2) }.play

I'm gonna be using this recording for several examples throughout the video and I know it's not, like, a very flashy or exciting sound, but it spatializes well and so it does a pretty good job of demonstrating the behavior of various ATK classes and techniques, but if you've got some monophonic sound source that you want to use instead, go for it.

Alright, step one, we need to select an encoding process. I’m gonna start with FoaEncoderMatrix.newDirection, which is a simple option that statically encodes the monophonic source as what's called a planewave, originating from an arbitrary direction in the soundfield. We specify that direction using an azimuth angle, theta, and an elevation angle, phi.

~enc = FoaEncoderMatrix.newDirection();

And this, I think, is a good moment for us to step into the soundfield to orient ourselves and better understand what these angles mean and how to specify them.

This sphere represents the Ambisonic soundfield. We have three axes: front-back, left-right, and up-down. And here's you! Right in the middle of the soundfield, having a great time, but, you know, facing forwards, not backwards. The convention is that X is the depth axis, with forward being the positive direction. Y is the width axis, with the positive direction going to the left, and Z is height, with the positive direction going up. You can remember this using the right-hand rule, you just put your right hand out in front of you and make this shape, index, middle and thumb are positive X, Y, and Z.

Azimuth is the rotational angle on the horizontal plane, and by convention, 0 degrees is straight ahead. Positive angular rotation goes counter-clockwise, so 45 degrees is halfway between front and left, negative 45 is halfway between front and right, 90 is left, negative 90 is right, positive or negative 180 is directly behind. A 0 degree elevation is on the horizon, neither up nor down, an elevation of 45 degrees is halfway between horizontal and vertical, 90 degrees is straight up, and negative 90 is straight down.

So, let's encode this sound 45 degrees left of center, with no elevation. Do keep in mind that the ATK expects all angular measurements in radians, so if you prefer to think with degrees, just make sure to use "degrad" to convert from degrees to radians before supplying values to ATK objects. You don't need to do this with zero, because zero degrees equals zero radians.

~enc = FoaEncoderMatrix.newDirection(theta: 45.degrad, phi: 0);

For the decoder, let's use FoaDecoderMatrix.newStereo to make a simple stereo decoder. This is basically a simulation of recording the soundfield using a virtual stereo microphone pair. We provide half the angle between the mics, and the microphone directionality pattern, using values from the table provided in the help file. So let's do a 110 degree angle and a cardioid pattern.

~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 0.5);

And, for those of you who like to see the math, the "matrix" method returns the actual matrix used in the multiplication that produces a stereo signal from the B-format signal, and I'm gonna round these floats to the nearest hundredths place so they don't take up as much space in the post window.

~dec.matrix.round(0.01);

Now, if we were to illustrate the complete decoder matrix multiplication operation, it would look like this, and you'll notice there are some differences between this decoder matrix and what you see in the post window. First of all, the matrix in the post window, as the ATK conceptualizes it, is transposed relative to the correct mathematical representation, basically the rows and columns have switched places. If you want, you can "flop" the array so that the appearance is consistent with the mathematical representation.

~dec.matrix.flop.round(0.01);

And second, in the illustration, the decoder matrix has four rows, representing coefficients to be multiplied by W, X, Y and Z. The Z coefficients are zero because the decoder represents two microphones that are flat and on the horizontal plane, but when using FOA tools and everything is contained within the horizontal plane, the ATK just drops the Z coefficients entirely for reasons related to DSP efficiency.

But, these differences are ultimately superficial, so setting them aside, we're really just talking about matrix multiplication again, plain and simple, and it's the same basic concept from our Mid-Side example from earlier. So our B-format signal is this 1-by-4 matrix, we multiply by this 4-by-2 matrix, so, you know, the first value is 0.71 times W plus 0.29 times X, plus...etc., etc., and what comes out is a 1-by-2 matrix that contains the two signals that we'd send to a pair of left-right speakers to reproduce the soundfield.

So, having taken a quick look at the math, and with encoder and decoder ready to go, all we have to do now is just build a SynthDef that puts all the pieces together. So, PlayBuf will generate the initial monophonic source, and then FoaEncode.ar to encode a B-format signal from the monophonic source, we provide the signal to be encoded, and the encoder object that we just created.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
}).play;
)

After encoding, this is where we could start applying soundfield transformations, and we'll get there in just a second, but for now let's just decode the soundfield as-is, using FoaDecode.ar, similarly providing the signal to be decoded, and the decoder object.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
}).play;
)

So, just to be clear, immediately after PlayBuf, sig is a normal, run-of-the-mill monophonic signal, just one channel.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig.numChannels.postln;
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
}).play;
)

After encoding, sig is a first-order Ambisonic B-format signal, which has four channels, WXYZ, carrying full-sphere spatial information.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig.numChannels.postln;
	sig = FoaDecode.ar(sig, ~dec);
}).play;
)

After decoding, sig becomes a stereo signal, which represents the two channels we'd capture if we were to set up a pair of cardioids into the middle of this soundfield, as specified in the decoder.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
	sig.numChannels.postln;
}).play;
)

So, let's output the signal and take a listen.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Now, obviously this is a dry, clinical example, it's not very exciting, but it should nonetheless sound like a reasonably convincing illusion of scissors and paper out in front of you and 45 degrees to the left. By design, this newStereo decoder is meant to be used with loudspeakers for optimal effect. If you're on headphones, that's not ideal, but, you know, it should still work well enough. If you're using built-in laptop speakers, that's probably the worst option, and I wouldn't expect anything too magical to happen.

Ok, so let's modify the encoder and place the source sound behind us and 45 degrees to the left, and then take another listen.

~enc = FoaEncoderMatrix.newDirection(theta: 135.degrad, phi: 0);

~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 0.5);

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

And, you should be able to hear that the result is not quite the same as the previous example, because this virtual microphone pair is pointed towards the front of the soundfield and doesn't pick up sounds originating from the back quite as strongly. We can also experiment with the virtual microphone pattern of the decoder, like, for example, swap cardioid for supercardioid.

~enc = FoaEncoderMatrix.newDirection(theta: 135.degrad, phi: 0);

~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 3 - sqrt(3) / 2);

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

And again, the result is very slightly different. So, this, I think, is a good spot to pause the video if you want to experiment with various encoder and decoder parameters, or if you want to continue, let's apply a rotational transformation, and to make this demonstration extra clear, I'm going to initially encode the source front and center.

~enc = FoaEncoderMatrix.newDirection(theta: 0, phi: 0);

~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 3 - sqrt(3) / 2);

FoaRotate is a UGen that will rotate a soundfield around the Z axis, sort of like sitting in a chair and spinning around. And, side note, FoaTumble rotates around the Y axis, this is like doing a somersault, and FoaTilt rotates around the X axis, like doing a cartwheel. We provide the B-format signal and a rotation angle. This can be static or dynamic, so let's use a low frequency sawtooth wave with a frequency of 1/12 Hz, ranging from negative to positive 180 degrees. The result will be a rotation angle that starts at zero and makes a full counter-clockwise circle once every 12 seconds. Let's poll to visualize these degree values, and make sure to convert to radians when plugging them into FoaRotate. Let's have another listen.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaRotate.ar(sig, azim.degrad);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

As an alternative to polling the raw azimuth values, Jo pointed me toward a handy analysis tool called FoaThetaPhiA, which analyzes an FOA B-format signal and returns the encoded azimuth and elevation, so we could poll these values instead. Now, this can be a very useful option in cases where the data for azimuth and elevation is maybe coming from somewhere else or for whatever reason it isn't readily accessible to us, like if we wanted to track the direction of a source from a recording or a live signal captured with a soundfield microphone.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180);
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaRotate.ar(sig, azim.degrad);
	FoaThetaPhiA.ar(sig).raddeg.poll;
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

So, there's a certain level of subjectivity here, maybe a little imagination is required, maybe we could fine-tune the decoder a little bit more, but, all things considered, I find this to be a pretty convincing illusion of rotation.

Now, since we are encoding from monophonic to B-format in this particular example, we do have the alternative option of using FoaPanB, so let me just quickly show what that would look like. It's a very simple change, we replace FoaEncode with FoaPanB, providing the monophonic signal, followed by azimuth and elevation, both in radians. This is the same static example that we started with.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaPanB.ar(sig, 45.degrad, 0);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

And if we wanted to modulate the azimuth angle, we can just drop in the same sawtooth wave that we were using a moment ago.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaPanB.ar(sig, azim.degrad, 0);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

So, this is another good moment to pause and play around on your own, just to get a sense of the basics, or, if you like, we can move on to another FOA example, going back to the matrix-based FoaEncode version, and this time let's use an omnidirectional matrix encoder, which takes no arguments, and will encode a monophonic source so that it's basically omnipresent. You can think of this as an infinite number of phase-aligned planewaves arriving simultaneously from all directions.

~enc = FoaEncoderMatrix.newOmni;

~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 3 - sqrt(3) / 2);

And in this version of the SynthDef we're not doing any transformation, we're just creating the source, encoding to B-format, and then decoding to stereo, so let's take a listen.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

The perception should be a directionless soundfield, and if you're on headphones, or in an acoustically neutral space, it should sound as if the sound originates inside your head, very much the same basic idea as panning center with a conventional linear stereo panner. Now, let's apply a different type of transformation using FoaPush. I think of this type of transformation as sort of exerting a gravitational pull on the soundfield, kind of drawing everything towards a point specified by an arbitrary direction. We provide the Ambisonic signal, and then a few other arguments. “angle” represents what’s called the distortion angle, which is basically the amount of warping applied to the soundfield, sort of like a measure of gravitational strength. Zero means no push, pi/2 is the maximum push, which collapses the soundfield to a point, and negative pi/2 is a maximum push in the diametrically opposite direction. The third and fourth arguments, theta and phi, represent azimuth and elevation and specify the actual direction of the push.

So, to control the strength of the push, let's use a sine wave with an 8-second cycle, starting at the lowest value, ranging from 0 to pi/4, so we're only doing half of the maximum push, but it'll be enough to notice a sense of direction. And, for now, the push direction will be a static 45 degree azimuth with no elevation. So, the sound will initially be omnipresent, over the course of four seconds it'll converge toward the front left, then over another four seconds it'll become omnidirectional again, and then that 8-second cycle will repeat.

(
SynthDef(\ambi, {
	var sig, push;
	push = SinOsc.kr(1/8, 3pi/2).unipolar(pi/4);
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaPush.ar(sig, push, 45.degrad, 0);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Things get a little more interesting when multiple transformations are chained together, for example, if we dynamically rotate the soundfield after the push, the soundfield will still be fluctuating between omnipresent and directional, but also, spinning around us.

(
SynthDef(\ambi, {
	var sig, push, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	push = SinOsc.kr(1/8, 3pi/2).unipolar(pi/4).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaPush.ar(sig, push, 45.degrad, 0);
	sig = FoaRotate.ar(sig, azim.degrad);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Keep in mind, transformations are not necessarily commutative, in other words, the order in which transformations are applied can be significant, just like regular signal processing, like, if you apply a distortion effect, followed by a low-pass filter, you'll get a different result if you filter first and then distort. For instance, if we rotate first and then push, the result would be that the rotation is completely unnoticeable, because we'd be rotating an omnidirectional soundfield, which has no audible effect, and then the push would occur always at a static 45 degree azimuth.

Moving on, let's suppose you want to encode multiple monophonic sources arriving from different directions in the soundfield. You could create multiple newDirection encoders, but it's simpler to use FoaEncoderMatrix.newDirections(). We provide an array of directional information, if it's just an array of numbers, like this, then they'll be interpreted as azimuth angles, with everything encoded on the horizontal plane, with an elevation of zero, in what's called a pantophonic arrangement. So, this encoder would expect a four-channel signal, interpreted as four individual monophonic sources, and their origin directions would be the corners of the room, front left, front right, rear right, rear left, in that order.

(
~enc = FoaEncoderMatrix.newDirections(
	directions: [45, -45, -135, 135].degrad,

);
)

Alternatively, directions can be an array of arrays, each containing azimuth and elevation for one monophonic source. So, something like this would encode four mono sources, the first originating front left and 35 degrees above the horizon, the next front right and 35 degrees below the horizon, etc.

(
~enc = FoaEncoderMatrix.newDirections(
	directions: [[45, 35], [-45, -35], [135, -35], [-135, 35]].degrad,

);
)

The second argument of newDirections is "pattern." If we were actually setting up multiple physical microphones, we would use this argument to specify their directionality pattern in order to, you know, weight the signals correctly, but since we’re dealing with virtual, synthesized sound sources, the correct thing to do is just specify nil. And, nil is actually the default, so we can actually omit the pattern specification altogether. And, you know, this "directions" keyword is here for extra clarity but, you know, technically we don't need that either.

(
~enc = FoaEncoderMatrix.newDirections(
	[[45, 35], [-45, -35], [135, -35], [-135, 35]].degrad,
);
)

I'm gonna do something a little more interesting for the directions, let's start with a random azimuth and elevation, and then we'll function-duplicate the array so that we end up with 24 uniquely random directions.

(
~enc = FoaEncoderMatrix.newDirections(
	{ [rrand(-pi, pi), rrand(-pi/2, pi/2)] } ! 24,
);
)

For the SynthDef, let's switch things up a little bit — our source signal will be 24 unique channels of Dust, each generating approximately 20 impulses per second, passed through Decay to give each impulse a slightly longer release, and then through a bank of 24 high-quality bandpass filters with random center frequencies rounded to the nearest multiple of 50. And then we encode the Ambisonic signal, and here I'll introduce FoaRTT, which is a UGen that bundles together rotate, tilt, and tumble, using three noise generators to randomly roll the soundfield around in all directions, and then, decode to stereo. So, this should sound like 24 little sparkly resonators kind of slowly moving all around you in all different directions.

(
SynthDef(\ambi, {
	var sig;
	sig = Dust.ar(20 ! 24);
	sig = Decay.ar(sig, 0.01);
	sig = BPF.ar(sig, { ExpRand(100, 10000).round(50) } ! 24, 0.003, 10);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaRTT.ar(
		in: sig,
		rotAngle: LFNoise2.kr(0.5).bipolar(pi),
		tilAngle: LFNoise2.kr(0.5).bipolar(pi),
		tumAngle: LFNoise2.kr(0.5).bipolar(pi),
	);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

So, another great spot to pause the video and experiment on your own, if you like, or, moving on, let's now take a look at the kernel-based encoders and decoders, which, as I mentioned, apply a convolution operation between a signal and a kernel, and a kernel in this case is a multichannel impulse response, some, but not all of which are based on measurements taken from real and artificial human heads, in order to capture what are called head-related transfer functions, or HRTFs, which contain information on how the head and ears filter incoming sound waves and influence our spatial perception.

For encoding a monophonic source, newSpread is a pretty good choice, it behaves sort of like a series of bandpass filters, spatially distributed across the surface of the soundfield, essentially rotating frequency content across a wider area, and basically this creates a more interesting soundfield image, especially compared to the very simple newDirection encoder that we used earlier. So, let's create one of these, subjectID is the number of bands per octave, this can be from 0 to 12, the default is 6, and we also need to select a kernel size, which has to be a power of two, though not all powers of two are available, so be sure to check the help file. Big numbers provide better low-frequency accuracy but they introduce a larger signal delay and consume more processing power. Small kernel sizes have the opposite characteristics, and a mid-range value like 2048 is often a pretty good compromise. newSpread also expects the server and the server's sampling rate, but if you’re working in a real-time context, as we are here, these kernel tools will automatically use the default server and its sampling rate, so we don’t necessarily have to provide that information ourselves.

~enc = FoaEncoderKernel.newSpread(6, 2048);

Be aware, when you create a kernel-based encoder or decoder, or maybe let's just say "transcoder," kernel data is automatically loaded into buffers behind the scenes, so two things to keep in mind: Number One, the server needs to be booted before a kernel-based transcodoer can be created, and, Number Two, make sure to free a kernel transcoder whenever you're done using it,

~enc.free;

for the same reason we free any buffer when we're done using it, because there's a limit to the total number of buffers that can be loaded onto the server, so it’s just good to clean up after ourselves.

~enc = FoaEncoderKernel.newSpread(6, 2048);

For a kernel-based decoder, newListen is based on measurements from IRCAM’s Listen HRTF database, all based on real human subjects, so it's a very good choice if the end goal is binaural reproduction on headphones. There's a range of IDs that correspond to different individual subjects, and be aware these IDs are not entirely contiguous, due to the fact that they’re based on the original research from this study, in which the numbers are also non-contiguous, so, just keep this in mind, not all numbers in this range are valid.

~dec = FoaDecoderKernel.newListen(1002);

Let's go back to that scissors sample and an earlier version of our SynthDef, in which we encode the monophonic PlayBuf signal to B-format, apply a slow counter-clockwise rotation, decode, and output. And, just to be clear, this example is very much meant to be monitored on headphones, not loudspeakers, so use headphones if you got 'em.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaRotate.ar(sig, azim.degrad);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

In this example, I don't get quite as strong of an impression of rotation, but I do think it sounds somewhat more immersive and realistic. Although, if you do want to exaggerate the perception of rotation, you can emphasize a sense of directionality by applying a gentle or moderate push transformation before rotation occurs. Now, granted, this does distort the convolution result, but really, the bottom line is that you should feel at liberty to experiment with all these tools and parameters until you are happy with how it sounds.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~enc);
	sig = FoaPush.ar(sig, pi/3);
	sig = FoaRotate.ar(sig, azim.degrad);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Let's take a very quick look of some other kernel options, newDiffuse is also good for encoding monophonic to B-format and returns a sort of "spatial smear," similar to newSpread. On the decoding side, newCIPIC is another binaural option based on measurements using human heads and KEMAR dummy heads, overall pretty similar to newListen. There’s also newSpherical which uses a filter and delay model based on generalizations from measurements taken with an earless dummy head, so, sort of binaural in nature, but more similar to a baffled microphone pair. If you want a kernel encoder that converts from stereo to Ambisonic, newSuper is a recommended choice, and for kernel decoding from Ambisonic to stereo, newUHJ is recommended.

So, by all means, experiment with different combinations. Keep in mind you can mix-and-match in the sense of using a matrix encoder with a kernel decoder, or vice-versa. It really all depends on the sounds you're working with, your speaker setup, and what sounds best to you.

Ok, so, next, let's do a couple quick workflow examples specifically for those of you lucky enough to have access to a surround system of some kind, like quadraphonic, octophonic, maybe even a three-dimensional array with speakers at different heights. So, first, let’s free the kernel transcoders since we’re done with those.

~enc.free;
~dec.free;

And the main question here is: what kind of decoder should we use? And the answer, of course, depends on the type of immersive loudspeaker setup that you're working with. So, let's imagine a quadraphonic system, with a pair of speakers in the front, another pair in the back. For this kind of setup, or really any speaker arrangement in which the speakers mark the vertices of a regular polygon on the horizontal plane, newPanto is a good solution. We provide the number of speakers, for the orientation, 'flat' means the front of the speaker arrangement is a side of the polygon, 'point' means the front of the arrangement is a vertex, so in this imagined setup, 'flat' would be correct. And then, a k-factor, which, to be precise, represents something called the "decoding beam pattern," which sounds fancy, but this is functionally equivalent to selecting a virtual microphone pattern, and there's a link to a discussion further down in the FoaDecoderMatrix help file, certain k-factor values are recommended for certain situations, but don't be shy about experimenting.

~dec = FoaDecoderMatrix.newPanto(4, 'flat', 'energy');

So in this case, we’ll get four channels out, which raises another very important question, which is: How do we route these four channels to our four speakers, you know, which one is which? Well, fortunately, you can always call 'directions' on your decoder, converting to degrees if desired, to return the locations of the speakers, in the order the ATK expects them.

~dec.directions.raddeg;

So in this case, channel 0 should go to the front-left speaker, channel 1 to the rear-left, channel 2 to the rear-right, and channel 3 to the front-right. This is consistent with the general convention in the FOA of starting in the front center and going counter-clockwise, and this is usually what I rely on. Though, keep in mind that as an alternative, you can reorder a multichannel signal using code, for example, in the following expression, the zeroth channel of sig stays where it is, we take the signal that was at index 3 and move it to index 1, the signal originally at index 1 moves to index 2, and the signal that was at index 2 moves to index 3. This technique is sort of like a digital version of re-patching a multichannel signal at an analog patchbay, and definitely useful if you're working in a studio where the physical routing is either permanent or maybe tucked away in a cabinet where it's hard to access.

So, anyway, here's our SynthDef, which encodes a slowly rotating monophonic source, and we’ve got our new quadraphonic decoder plugged in. I'll play this, but you shouldn’t really pay any attention to the sound, because we're only hearing two of four channels, so the spatial imagery is just completely inaccurate, the point here is that we can see four channels on the meters, and if they were routed correctly to four speakers, we would accurately reproduce the soundfield.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaPanB.ar(sig, azim.degrad, 0);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

If you find yourself in a dual ring speaker setup, like, four speakers in the ceiling corners, and another four on the floor, for this you can decode with newPeri, short for periphonic, we provide half the number of speakers, then the elevation of the ceiling ring, whatever that might be, let's say 35 degrees, and then orientation and k-factor.

~dec = FoaDecoderMatrix.newPeri(4, 35.degrad, 'flat', 'energy');

~dec.directions.raddeg;

The channel routing convention is essentially the same as before, with the added rule that the top ring comes first, then the bottom. So that would be 0 1 2 3 on the top, 4 5 6 7 on the bottom. Here’s the same SynthDef, using our new periphonic decoder. We’ll keep the rotation, but just to make the meters look a little more interesting, we’ll tip the soundfield back by 20 degrees, sort of like how the earth’s axis is tilted relative to its orbital plane around the sun. Again, ignore the sound, it’s not accurate, just doing this to visually show that we get eight channels out.

(
SynthDef(\ambi, {
	var sig, azim;
	azim = LFSaw.kr(1/12).bipolar(180).poll;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = FoaPanB.ar(sig, azim.degrad, 0);
	sig = FoaTumble.ar(sig, 20.degrad);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

// HOA

So, that’s the FOA workflow in a nutshell. Let’s now switch gears and take a look at the HOA toolset, and to frame this discussion, let’s first talk about what higher-order Ambisonics actually means.

On a basic level, Ambisonic order is a measure of the spatial resolution of the soundfield, and if you do an image search for "higher order ambisonics," you’ll find lots of pictures that look something like this, which Jo likes to call the "Ambisonic Christmas tree." These individual figures are called spherical harmonics, they represent mathematical functions defined on the sphere, and, conceptually, they’re pretty similar to frequency bins in the context of the Fourier Transform. Much in the same way that combining more frequency bins allows us to represent an arbitrary periodic waveform with greater precision, using more spherical harmonics allows us to synthesize and render an arbitrary soundfield with greater precision.

At the top is the spherical harmonic of degree 0, which is the unit sphere and represents the omnidirectional W signal, below that, the three spherical harmonics of degree 1, which represent the bidirectional signals, and together, these four components constitute a first-order B-format signal, like those produced by FoaEncode and FoaPanB. On the next row down are the spherical harmonics of degree 2, again these basically represent microphone polar patterns, but, you know, with just more complex shapes. If these five components are included, we then have a 2nd order Ambisonic signal, with 9 channels. If we include spherical harmonics of degree 3, we then have a 16-channel 3rd order Ambisonic signal, and so on.

For three-dimensional decoding at some arbitrary Ambisonic order, we use all of the spherical harmonics up to and including the relevant degree. But, for two-dimensional decoding, we only use the spherical harmonics on the outer edges of the tree, which as you can see, are the ones that are sensitive across the horizontal plane.

So, now, in the HOA toolset, there's no theoretical limit to Ambisonic order, but, an nth order signal has a channel size of n+1 squared, so, processing power is the limiting factor. And, there's also sort of a point of diminishing returns, like, ok, sure we could do 9th order Ambisonics, but is that really gonna sound noticeably better than 8th order? Probably not. 5th order is the highest I've encountered in practice, and 3rd order seems pretty common, so, you know, take that for what it's worth.

So let's work through a few HOA examples. For directional encoding of a monophonic source, one option is HoaMatrixEncoder.newDirection, which takes an azimuth and elevation, also a beamshape, which is roughly the same concept as selecting a virtual microphone pattern, the options here are \basic, \energy, and \controlled, which represent hyper, super, and regular cardioid, Jo recommends \basic as a typical choice for most users, and we also provide the Ambisonic order, let's do 3rd order.

~enc = HoaMatrixEncoder.newDirection(0, 0, \basic, 3);

If we omit the order, the ATK will fall back on whatever value is returned by AtkHoa.defaultOrder, and this happens to be three by default, but you can change this at the start of your code using AtkHoa.setDefaultOrder, providing the desired order in parentheses, and from that point onward, all HOA objects will use that order if unspecified, which obviously has the potential to save lots of time if you want to switch your entire project to a different order at some point down the road.

AtkHoa.defaultOrder; // -> 3

AtkHoa.setDefaultOrder(5);

~enc = HoaMatrixEncoder.newDirection(0, 0, \basic);

~enc.order; // -> 5

AtkHoa.setDefaultOrder(3); // (return to default)

~enc = HoaMatrixEncoder.newDirection(0, 0, \basic);

~enc.order; // -> 3

For decoding, I actually want to start with a more complex example, basically just to get it out of the way, so I'm imagining 20 speakers at the vertices of a dodecahedron. Now, I realize this isn’t gonna be super relevant for most people, I am mostly just doing this for completeness of the tutorial. So, for a full-sphere speaker array like this, newProjection or newModeMatch are both good decoder choices. For the directions, we provide an array of arrays, containing azimuth and elevation for each loudspeaker, you can provide these in any order you want, you just have to be consistent with how you route the signals to speakers. So for this arrangement, which I'm just gonna paste in to save time, we have four stacked rings, five speakers in each ring, here’s the topmost ring, and then the ring slightly above the equator, another ring slightly below the equator, and then the bottom ring. For beam shape and gain matching, Jo recommends \energy which tends to provide the biggest sweet spot, and \rms, which is sort of a classic approach. HoaMatrixDecoder also takes the Ambisonic order as its last argument, but we'll omit that and just rely on the default order that we discussed a moment ago.

(
~dec = HoaMatrixDecoder.newModeMatch(
	directions: [
		[36, 54], [108, 54], [180, 54], [-108, 54], [-36, 54],
		[36, 18], [108, 18], [180, 18], [-108, 18], [-36, 18],
		[0, -18], [72, -18], [144, -18], [-144, -18], [-72, -18],
		[0, -54], [72, -54], [144, -54], [-144, -54], [-72, -54]
	].degrad,
	beamShape: \energy,
	match: \rms
);
)

The structure of an appropriate SynthDef is pretty much same as what you’d expect in the FOA toolset, the main difference is that we’re just using HOA tools instead. We generate the monophonic signal, encode with HoaEncodeMatrix, I’m using HoaRTT to randomly rotate, tilt, and tumble all over, and decode with HoaDecodeMatrix.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeMatrix.ar(sig, ~enc);
	sig = HoaRTT.ar(
		in: sig,
		rotate: LFNoise2.kr(0.5).bipolar(pi),
		tilt: LFNoise2.kr(0.5).bipolar(pi),
		tumble: LFNoise2.kr(0.5).bipolar(pi),
	);
	sig = HoaDecodeMatrix.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Ignore the sound, it's inaccurate, it's wrong, we're only hearing 2 out of 20 channels, I'm just doing this to show that we do actually get 20 channels out.

On the assumption that you do not have a dodecahedron of speakers, a much more practical option is to decode from HOA to stereo, and to do this, a very simple option is HoaMatrixDecoder.newDirections, conceptually pretty similar to the FOA newStereo example from earlier, we provide an array of directions for the virtual mics, let's set them 65 degrees left and right of center, \controlled specifies a cardioid pattern, and \beam for the gain matching, this is appropriate whenever we’re using a beamforming decoder like this one.

~dec = HoaMatrixDecoder.newDirections([65, -65].degrad, \controlled, \beam);

And we can actually just use the exact same SynthDef from the previous example, which is now gonna be using the stereo decoder that we just created.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeMatrix.ar(sig, ~enc);
	sig = HoaRTT.ar(
		in: sig,
		rotate: LFNoise2.kr(0.5).bipolar(pi),
		tilt: LFNoise2.kr(0.5).bipolar(pi),
		tumble: LFNoise2.kr(0.5).bipolar(pi),
	);
	sig = HoaDecodeMatrix.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Keep in mind, these virtual mics are flat, on the horizontal plane, they can’t distinguish up from down, so we are making a pretty significant sacrifice here, the ideal situation would be to render this soundfield on a loudspeaker array that includes a height component of some kind.

And, another thing to point out here is that because we’re encoding from mono to HOA, we have the alternative option of using HoaEncodeDirection instead of creating a separate matrix encoder object. Just like FoaPanB, this option lets us dynamically modulate azimuth and elevation, so we don’t really need this HoaRTT anymore. In addition to azimuth and elevation, HoaEncodeDirection also lets us encode and modulate radial distance, which introduces proximity filtering, and gives a noticeable bass boost at smaller radii.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeDirection.ar(
		in: sig,
		theta: LFNoise2.kr(0.5).bipolar(pi),
		phi: LFNoise2.kr(0.5).bipolar(pi/2),
		radius: 0.3,
	);
	sig = HoaDecodeMatrix.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

And before you pause the video and start randomizing these parameters, it is extremely important here to recognize that if the radius gets too close to zero, the signal will distort quite dramatically, and in a pretty dangerous way, and that’s because we’re essentially synthesizing a quote "perfect" microphone, with a frequency response that extends all the way down to 0 Hz. So what Jo recommends is limiting the radius so that it is no smaller than 0.3 meters, optionally pre-processing your signal with a high-pass filter like HPF, with a cutoff frequency of at least 20 Hz, maybe higher if the signal includes a lot of low frequency content, and also, of course, just generally being mindful of hearing damage and ear safety.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HPF.ar(sig, 20);
	sig = HoaEncodeDirection.ar(
		in: sig,
		theta: LFNoise2.kr(0.5).bipolar(pi),
		phi: LFNoise2.kr(0.5).bipolar(pi/2),
		radius: MouseX.kr(0.3, 1.5).max(0.3).poll,
	);
	sig = HoaDecodeMatrix.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

// HOA -> FOA Conversion

Ok, so, another option for decoding HOA to a two-channel format is to first convert from HOA to FOA, which gives us access to all the stereo and binaural decoders in the FOA toolset. There's a guide file called Ambisonic Format Exchange, which gives step-by-step instructions for various types of Ambisonic conversions. I've found this to be one of the most useful files in the entire ATK package. It exists because there isn't one singular, definitive Ambisonic format, the unfortunate truth is that there are several different formats that have emerged and evolved over the years, and if we don't correctly convert from one to another, we run the risk of distorting the soundfield in ways that could be subtle or really dramatic.

There are four things we need to know about an Ambisonic signal before we can perform a successful format conversion, we can find these things in another useful guide file called ABCs of the ATK, and scrolling down to the section on "Encoding formats."

The first of these four things is Ambisonic order, and we’ve already discussed what that means a little bit earlier, when I showed the Ambisonic Christmas tree with all the spherical harmonics, so, you know, we're talking about first order, second order, third order, all that stuff.

AtkFoa.defaultOrder;

AtkHoa.defaultOrder;

Component ordering means the order in which the individual B-format channels appear. The FOA toolset uses what's called the Furse-Malham scheme, the ATK abbreviates this as the symbol 'fuma', which means WXYZ. This ordering scheme is also sometimes called "traditional" B-format. HOA uses an ordering scheme called Ambisonic Channel Number, or ACN, which numbers the components as they appear on the Ambisonic Christmas tree,  left-to-right, top-to-bottom, so using letters, this would be WYZX, and it should be pretty obvious why component ordering matters, because if the channels aren’t in the correct order, the soundfield, like, literally goes sideways.

Component normalization refers to the gain coefficients by which each individual channel is scaled, I’m not gonna dwell on the math here, we just need to know that in the ATK, the FOA toolset uses a scheme called MaxN, and the HOA uses something called N3D. We can verify the ordering and normalization schemes of both toolsets by evaluating:

AtkFoa.format;

and

AtkHoa.format;

Now, for the FOA, I would sort of expect to see [fuma, MaxN] instead of [fuma, fuma], but the ATK is designed to interpret 'fuma' as a synonym for 'MaxN' in the context of component normalization.

Now, if you're curious, there is a Wikipedia page titled "Ambisonic data exchange formats," and if you scroll down to this table of normalization values, you can maybe get a sense of why I'm not gonna bother trying to unpack the math. Basically, we have these different schemes, and if you perform an Ambisonic operation using the wrong coefficients, then the signals just get scaled incorrectly.

And the fourth thing we need to know is reference radius, which represents wavefield-encoded distance from the origin of our virtual sound sources, and we’ve already gotten a taste of this with the radius argument for HoaEncodeDirection. Reference radius in the FOA defaults to infinity, basically this just means far enough from the origin that the sound wave arrives as a flat planewave instead of having a spherical wavefront, and the HOA defaults to a reference radius of 1.5 meters.

AtkFoa.refRadius;

AtkHoa.refRadius;

So, a lot of useful stuff on this ABCs page, and frankly this Wikipedia page is also pretty helpful for some things.

Anyway, let's go back to the previous example and decode to stereo by first converting from HOA to FOA. So we will need a decoder that goes from FOA B-format to stereo, so let's reuse this newStereo decoder from earlier. We will also need a transcoder that goes from HOA to FOA, this can be viewed as either encoding FOA from HOA, or decoding HOA to FOA, so we have two options, I'll show both. For encoding FOA from HOA, we would use FoaEncoderMatrix.newHoa1, providing the component ordering and normalization of the B-format signal we’re starting with, so that would be \acn, \n3d. These are actually the default parameters for newHoa1, so in this particular case we could omit them.

(
~hoaToFoa = FoaEncoderMatrix.newHoa1(\acn, \n3d);
~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 3 - sqrt(3) / 2);
)

And now, we just put the pieces together in the SynthDef. So, reusing what we already have, I’m gonna simplify the encoding so that the source just slowly rotates around the equator, no elevation variance, and a constant 1.5 meter radius. The next step is to convert from 3rd order to 1st order, and this is actually very easy, we just drop the 2nd and 3rd degree spherical harmonics from the multichannel Ambisonic signal, 'keep' is useful here, 'keep' is an array method that retains a certain number of items from the beginning of an array and just discards the rest. So if we have the array of integers from 0 to 9, keep(4) returns the array [0, 1, 2, 3].

(0..9);

(0..9).keep(4);

So, obviously we could just say sig = sig.keep(4) since we want a 1st order signal and we already know this data is contained in the first four channels. But this is an opportunity to introduce the HoaOrder class, which is basically a utility that lets us extract various types of information from an HOA signal of an arbitrary order, and one of those pieces of information is the number of channels in the signal, which we can get using 'size'. So for example, a 1st order HOA signal has 4 channels, 2nd has 9, etc.

HoaOrder.new(1).size;

HoaOrder.new(2).size;

So instead of 4, we could deploy HoaOrder.new(1).size, which is obviously more typing but, you know, maybe looks a little more meaningful, so, whatever makes more sense to you.

Next, we convert reference radius, so, assuming the HOA signal was encoded at the default radius of 1.5 meters, we can handle this with HoaNFProx, this is short for "nearfield proximity." We provide the signal, and the Ambisonic order, which at this point is now 1, instead of 3.

And, an important side note on HoaNFProx is related to this warning in the help file, which says a pre-conditioned input signal is necessary to avoid overflow, and all this really means is that you should apply a high-pass filter to the signal before passing it through HoaNFProx, otherwise you risk blowing up the signal, and we've already touched upon this with HoaEncodeDirection, so I'm gonna include a high-pass filter immediately after the conversion to 1st order. A cutoff frequency of 20 Hz is a good starting point, but depending on how much low frequency content is present, you might want to be more aggressive and go a little higher. Jo emphasized to me that signals that contain DC offset, which is often the case with FM synthesis, are particularly dangerous and should be handled very carefully.

Continuing the conversion process, next we're gonna deal with component ordering and normalization, and this is precisely why we created this HOA to FOA transcoder, so we just plug it into FoaEncode, and that takes care of that. And now that we've dealt with all four aspects of conversion, so now we can use our regular FOA decoder to produce a stereo signal.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeDirection.ar(
		in: sig,
		theta: LFSaw.kr(1/12).bipolar(pi),
		phi: 0,
		radius: 1.5,
	);
	sig = sig.keep(4);
	sig = HPF.ar(sig, 20);
	sig = HoaNFProx.ar(sig, 1);
	sig = FoaEncode.ar(sig, ~hoaToFoa);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

The alternative to newHoa1 is to use HoaMatrixDecodoer.newFormat, this is the other conversion option I mentioned at the start of the video, which decodes from HOA to a variety of other formats, including the traditional Furse-Malham B-format. Now, for the format, you can provide the array of two symbols, ['fuma', 'fuma'], or you can just use AtkFoa.format, which returns the same thing, and then the desired Ambisonic order, which in this case is 1.

(
~hoaToFoa = HoaMatrixDecoder.newFormat(AtkFoa.format, 1);
~dec = FoaDecoderMatrix.newStereo(angle: 110.degrad/2, pattern: 3 - sqrt(3) / 2);
)

The SynthDef is pretty much the same, all we have to do is replace FoaEncode with HoaDecodeMatrix.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeDirection.ar(
		in: sig,
		theta: LFSaw.kr(1/12).bipolar(pi),
		phi: 0,
		radius: 1.5,
	);
	sig = sig.keep(4);
	sig = HPF.ar(sig, 20);
	sig = HoaNFProx.ar(sig, 1);
	sig = HoaDecodeMatrix.ar(sig, ~hoaToFoa);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

And, if we want binaural decoding instead of stereo, well, this is also a very simple change, which we already know how to do, we just create a binaural FOA decoder, like newListen, or whatever, and use that instead.

(
~hoaToFoa = HoaMatrixDecoder.newFormat(AtkFoa.format, 1);
~dec = FoaDecoderKernel.newListen(1002);
)

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(1, b, BufRateScale.ir(b), loop: 1);
	sig = HoaEncodeDirection.ar(
		in: sig,
		theta: LFSaw.kr(1/12).bipolar(pi),
		phi: 0,
		radius: 1.5,
	);
	sig = sig.keep(4);
	sig = HPF.ar(sig, 20);
	sig = HoaNFProx.ar(sig, 1);
	sig = HoaDecodeMatrix.ar(sig, ~hoaToFoa);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

// Other Conversion Scenarios

So, at this point, hopefully the basic workflow for the ATK is starting to come into focus, and so, next, what I’d like to do is cover a few additional conversion scenarios that you might encounter, and how to approach them. One scenario might be that instead of encoding from monophonic to B-format, maybe you've already got an audio file in B-format, and you just want to decode it so you can listen to it. For example, let's go into the ATK sounds directory, and we will grab one of the B-format files, and load it into a buffer.

b.free;

b = Buffer.read(s, "/Users/eli/Library/Application Support/ATK/sounds/b-format/Pampin-On_Space.wav");

To correctly decode and render this soundfield, we need to know the format that it's in, and through conversation with Jo I confirmed that these are "traditional" B-format files, so first order, WXYZ ordering, MaxN normalization, and infinite reference radius. To render this soundfield, no encoding is necessary, because it's already in B-format. And in the SynthDef, we just play the 4 channel B-format file, and decode. Simple as that.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(4, b, BufRateScale.ir(b), loop: 1);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

Another scenario: maybe you've got an Ambisonic recording from somewhere else, maybe an online repository, like this one at library.soundfield.com. I downloaded one of these ahead of time, so first things first, let's load it into a buffer.

b.free;

b = Buffer.read(s, "/Users/eli/Documents/YouTube/Tutorial 31/source/crowd.wav");

It's got four channels, so that means it's a first-order recording.

b.numChannels;

And, poking around on this website, we can see that these recordings are in the AmbiX format, which is actually a pretty common Ambisonic format, and, according to Wikipedia it uses ACN ordering and SN3D normalization. For AmbiX files, it’s safe to assume a reference radius of infinity, which is indicated in the Ambisonic Format Exchange guide file, down in footnote 3. This is consistent with the default radius in the FOA toolset, so no radius adjustment is needed.

So, we’ll need a transcoder to go from AmbiX to the ATK FOA format, for this we have the convenience method FoaEncoderMatrix.newAmbix1, which doesn't need any arguments since it's basically designed for this one specific purpose.

~ambixToFoa = FoaEncoderMatrix.newAmbix1;

In the SynthDef, we play the four-channel AmbiX file, use FoaEncode to convert from AmbiX to FOA, and then decode however you want, I’ll just reuse the same decoder from the previous example.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(4, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~ambixToFoa);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

One last conversion scenario, if you happen to have one of these tetrahedral soundfield microphones, the raw four-channel signal it captures is called Ambisonic A-format, and the microphone probably comes with software that converts from A to B-format, but alternatively you can bring the A-format signal straight into SuperCollider and convert to B-format there, using FoaEncoderMatrix.newAtoB, providing the correct orientation and weight. The orientation is based on how the microphone capsules are positioned and ordered when the mic is set up and facing forward, for example, 'flu' means the input channel with the lowest-numbered index is pointing front-left-up, the next channel is pointing front-right-down, and so on, so you'll just want to pick the correct orientation for that microphone, you might need to read the manual, and the weight should match the directionality pattern of the microphone capsules. I would guess cardioid is probably the most common, but again, you'll want to read the manual to be sure.

It's worth mentioning that 'newAtoB' is strictly a matrix multiplication operation and it doesn’t include any additional filtering related to capsule response or radial distance. Commercial products that convert from A to B-format should and probably do include these additional filtering steps, but in the ATK, conversion between A and B-format is primarily focused on spherical decomposition and recomposition as a creative practice.

There are a couple of A-format recordings in the ATK sounds directory, so let’s load one into a buffer.

b.free;

b = Buffer.read(s, "/Users/eli/Library/Application Support/ATK/sounds/a-format/Thomas_Mackay.wav");

And Jo confirmed that for the Thomas Mackay file, ‘flrd’ is the correct orientation,

~a2b = FoaEncoderMatrix.newAtoB('flrd', 'car');

and hopefully you're starting to see a pattern here in that the SynthDef is, you know, again, pretty much the same, we just play the A-format file, transcode from A to B-format, and then decode as desired.

(
SynthDef(\ambi, {
	var sig;
	sig = PlayBuf.ar(4, b, BufRateScale.ir(b), loop: 1);
	sig = FoaEncode.ar(sig, ~a2b);
	sig = FoaDecode.ar(sig, ~dec);
	Out.ar(0, sig);
}).play;
)

// Graphical Utilities

Alright, finally, let's take a look at the two utility classes I mentioned way back at the beginning. First is FoaXformDisplay.new,

FoaXformDisplay.new;

which is a very nice graphical tool that helps visualize different types of soundfield transformations. You can select one from the drop-down and play around, like, here's rotate, here's tilt, here's focus. And you can even chain multiple transformations back-to-back, so let's start with a focus, angled off to the front right, and then we'll follow that up with a tumble, so, you get the general idea.

We can also use this utility to audition the sound of various transformations using some basic sound sources, so, we can adjust the overall gain here, we click the little play icon on one of these tabs to start the sound, maybe adjust some other basic parameters. Now, the output is B-format, and FoaXformDisplay doesn’t have a built-in decoder, so right now we're just hearing W and X, but we can route the B-format signal to a non-hardware bus, like audio bus 2, so that it plays silently on busses 2, 3, 4 and 5, and then we'll just make a quick and dirty UGen function that uses FoaDecode to grab the B-format signal from those channels, decode it using the binaural decoder we have, and play the result on busses 0 and 1.

{ FoaDecode.ar(In.ar(2, 4), ~dec) }.play(addAction: \addAfter);

So, lots of fun. The other utility is TDesign, which defines a set of points evenly distributed on the surface of a sphere. TDesign.new is valid, but if we're gonna be using this with HOA objects, 'newHoa' is a more appropriate creation method, and we can just specify the desired number of points, let's do 24.

t = TDesign.newHoa(24);

Easily, the best part of TDesign is the 'visualize' method, which provides a really nice visual rendering of the points, I mean, come on, look at this, it's gorgeous — you can click and drag to rotate, and there's also a variety of interactive controls to customize the viewing experience. It's just fantastic.

t.visualize;

In practice, one application of TDesign is to encode many directional sources all over the soundfield, without having to explicitly specify the directions yourself. For the encoding process, we can use HoaMatrixEncoder.newSphericalDesign, we provide an instance of TDesign, and a valid symbol for the virtual microphone pattern.

~enc = HoaMatrixEncoder.newSphericalDesign(t, \basic);

Assuming stereo or binaural is the end goal, we can just apply the necessary transcoding process that we covered earlier, in this case let’s use newHoa1 again to encode FOA from HOA, and we'll continue using the same binaural decoder for the end result.

For some sound, let’s revisit the 24-channel resonator SynthDef from earlier. So, we’re gonna encode these 24 channels using the TDesign encoder, HoaRTT to slowly and randomly roll the soundfield around in all directions, transcode to FOA, and then decode to binaural. And, let’s also include an amplitude envelope, because, you know, why not.

(
SynthDef(\ambi, {
	var sig;
	sig = Dust.ar(20 ! 24);
	sig = Decay.ar(sig, 0.01);
	sig = BPF.ar(sig, { ExpRand(100, 10000).round(50) } ! 24, 0.003, 10);
	sig = HoaEncodeMatrix.ar(sig, ~enc);
	sig = HoaRTT.ar(
		in: sig,
		rotate: LFNoise2.kr(0.5).bipolar(pi),
		tilt: LFNoise2.kr(0.5).bipolar(pi),
		tumble: LFNoise2.kr(0.5).bipolar(pi)
	);
	sig = sig.keep(4);
	sig = HPF.ar(sig, 20);
	sig = HoaNFProx.ar(sig, 1);
	sig = FoaEncode.ar(sig, ~hoaToFoa);
	sig = FoaDecode.ar(sig, ~dec);
	sig = sig * Env([0, 1, 0], [6, 6], [-2, -2]).kr(2);
	Out.ar(0, sig);
}).play;
)

And that is gonna be it for Tutorial 31. I hope this gives you a clear sense of how to use the ATK on a basic level, and the knowledge and confidence to start experimenting on your own. There's a lot of good info in the help documentation, particularly in the Guides & Tutorials section. For me, some of the most useful files are listed in this ABCs of the ATK document, which includes the more general ABCs file, three pages on Encoding, Transforming, and Decoding FOA, also this Ambisonic Format Exchange file that we looked at earlier, and these two pages on monitoring HOA in stereo and binaurally. In the video description, I’m also including some links to external resources which might be interesting for anyone looking for further reading. Big thanks once again to Jo Anderson for his expertise and all the fine folks at DXARTS who've put so much work into developing this amazing project. And, of course, a very special shoutout and thanks to my Patrons, who so generously support this channel and videos like this one, thank you all so much, I really appreciate it, it means so much to me. Feel free to leave any comments or questions on YouTube, and as always, thanks for watching, see you next time.

Patreon.thanks;