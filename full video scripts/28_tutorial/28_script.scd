Hey everybody, welcome to tutorial 28. In this video, we'll cover the basics of writing classes and methods, so that you can customize and augment the default SuperCollider library. It's a useful thing to know how to do, and part of what makes SuperCollider such a flexible piece of software.

With regard to the scope of this tutorial: we're gonna be creating new classes and methods using SuperCollider code, so, there's gonna be some new stuff, but generally speaking not too many surprises if you've been following this series. What we're *not* gonna be doing is writing any C++ code, dealing with UGens on the level of individual sample, or anything else that might be considered extensive development work.

There's a guide file called Writing Classes, which I'll be referencing throughout this video, and it's a pretty good resource, all things considered, worth reaading if you've never seen it before. The point of this tutorial is to kind of fill in the gaps with some concrete examples to supplement these more general examples.

So let's get into it. The first step to writing a new class or method, is to have some idea of the functionality you want to add—some way of creating or maniupulating data that SC doesn't already do, or at least, doesn't do it as easily or directly as you'd like. As a starting example, let's imagine we have some tempo in beats per minute and we want to know the duration, in seconds, of one beat at this tempo. Ultimately, we'd like to be able to evaluate something like this, number-dot-tempodur

144.tempodur;

Treating it like midicps... or ampdb... just a simple value conversion.

60.midicps;
0.2.ampdb;

but tempodur doesn't work because it's not defined as a method that numbers can understand. Calculating this value is pretty simple, we divide by 60 to convert beats per minute to beats per second, and then take the reciprocal to get seconds per beat.

(144/60).reciprocal;

even simpler, don't bother typing reciprocal, and instead just swap the numerator and denominator:

60/144;

So, one beat at 144 bpm is 0.4166 or 5/12ths of a second long. Another option, there's a method beatDur that's already defined for TempoClock. We make a new instance of TempoClock, which expects tempo in beats per second, and then apply the method.

TempoClock.new(144/60).beatDur;

So, although it's possible to do this without writing a new method, surely it might be convenient to have this tempodur method.

Before we code an actual method, I think it's instructive to first, implement as a plain old function—nothing we haven't seen before. And that function would look something like this: give it a name, it expects one input, a value in beats per minute, and to get the desired output, we just do the math, and remember that functions in SC return the value of the last statement when evaluated.

(
~tempodur = {
	arg bpm;
	60/bpm;
};
)

To run it, we call the value method on the function, and provide the input tempo.

~tempodur.value(144);

There's a syntax shortcut for this, you can actually drop the word 'value' but keep the period:

~tempodur.(144);

So let's go ahead and create this new method. When SC boots up it compiles classes and methods in the default class library, which is part of the main application package, and it also looks in two remote directories: your user extension directory and the system extension directory. You can get strings representing these two paths by evaluating

Platform.userExtensionDir;
Platform.systemExtensionDir;

Platform is a class for handling cross-platform discrepancies, so check out its help file if you want to see more things it can do. Anything in your user extensions folder is accessible by you, the user currently logged in, and the system folder is accessible by anyone using the computer.

So, the first step is, create a new file, and we're going to save it in one of these extensions folders. The name of the file doesn't really matter, but make sure that you save this file as a SuperCollider class file, which has the extension sc instead of scd. This is the format that SuperCollider looks for when it's compiling the class library. And, using the string in the post window as a guide, navigate to one of these extensions directories, and save.

And now we're ready to write this method. This Writing Classes guide mostly deals with writing new classes, and that's not quite what we're doing right now. Instead, we're adding a method to an existing class, so we'll scroll down to the section on "External method files." And this is the format, so copy-paste this code as a template into our blank extensions file.

At the top, right after the plus, the class name of the object for which this method is being created. In our example, 144.tempodur, tempodur is the new method, and it's being applied to 144 which is a member of the Integer class. Now, Integer is probably not be the best choice here, for reasons that will soon become clear, but I'm gonna start with Integer anyway, just to make a point. And inside the outermost curly braces is where we put the code for this new method.

Now you might already be aware of the following distinction, but just to be absolutely clear, broadly speaking, there are two types of methods in SuperCollider: instance methods and class methods, so we're gonna briefly dip into a more theoretical discussion here: In object-oriented programming, different types of information are modeled using Classes. In SC, classes start with a capital letter, examples include Integer, Float, Window, Server, Array, the list goes on and on. You should think of a class as a sort of abstract blueprint for data, but not to be confused with the data itself. An instance on the other hand is a concrete, tangible manifestation of a class. Every class has some number of class methods and some number of instance methods. As an example, series is a class method defined for Array. In this expression, we're creating an arithmetic series of 8 values, starting at 1 and counting up by 3. This class method *returns* a new Array *instance*, stored in the container "a" through variable assignment. If we try to apply this class method to an instance of array, it doesn't work, we get an error message, because series is not defined as an instance method, and if we stop and think about it, this expression doesn't even really make sense, like, what are we trying to do? Unclear. Now, reverse is an instance method defined for Array, so it's perfectly sensible to use it here and overwrite the variable with the new result. But, same issue and a similar error if we try to apply this instance method to the Array *class.* The Array class is like, the all-encompassing generalized abstract *idea* of an array, not an actual array, so not something that can be casually "reversed." — it's just nonsense.

a = Array.series(8,1,3);

a.series(8,1,3);

a = a.reverse;

Array.reverse;

Getting back to our current example, we are clearly envisioning tempodur as an instance method, because it's meant to be applied to an instance of the Integer class, not the class itself. In these sc files, when adding methods to an existing class, if it's a class method, the method name must be preceded with an asterisk. If it's an instance method, no asterisk. So, we don't need this bit, and tempodur goes here. Keep in mind all method names must begin with a lowercase alphabetic character. After that first character, you can use uppercase, numbers, and underscores, I think, but generally it's a good idea to keep it short and sweet, and follow existing style choices whenever you can.

Inside these curly braces is where we put the code that defines the behavior of this method. Now, in a regular function, when we're just doing normal code stuff, an argument declaration is the technique we use to pull external values into the function, but method definitions are a little different. Specifically, we use the special keyword "this" to refer to the receiver of the method. So let's say back in the language we evaluate 108.tempodur, then in that moment, in that specific case, this, t-h-i-s will be equal to 108. So let's try to use good programming style here. We'll start by declaring some variables, the purpose being to give things meaningful names, and we're basically working with two values here. An input tempo, and an output beat duration. The tempo is going to be equal to the reciver, so tempo equals this. And beatdur is going to be equal to 60 divided by the tempo.

Now you may be tempted to stop here, but there's one last step. Methods don't automatically return the last line the way functions do. Instead, we need to explicitly designate the value that this method returns. We precede the desired output with the caret symbol.

And this is important: anytime you make changes to an extension file, you need to do two things: 1, save the file, and 2, recompile the class library. Both of these actions have keyboard shortcuts, which is what I'm going to be relying on for the rest of this video, to save time, and I recommend you do the same.

144.tempodur;
108.tempodur;
72.tempodur;

So, it works! Our very first extension. Let's go back to our extension file and look at a few common mistakes and pitfalls. For example, if you've got a syntax error, like you forgot to separate variable declarations with a comma. If you save and recompile, you'll get an error. Now, this is a little bit scarier than usual, because now, the class library hasn't been compiled, so, like, literally nothing works.

5.squared;
s.boot;

But, the error message tries to be as helpful as possible, giving you the file path, the line, the character, so it shouldn't be too hard to track down the issue.

Maybe instead, you forgot to return a value. If you don't provide a return caret, then the method will simply return its receiver, which makes this tempodur method *quite* useless. So if the goal is to return a new value, as is the case with value conversion methods, it's an important thing to remember.

144.tempodur

And also, notice there's no semicolon at the end of the method curly braces nor the class curly braces, and in fact if you do put a semicolon in either of these spots, save, and recompile, you will get an error message.

Earlier in the video, I mentioned that defining this method for the Integer class might not be the best approach, and here's why. Suppose we want to know the duration of one beat at a tempo of 112.5:

112.tempodur;

Message not understood. It doesn't work, because we've defined tempodur for Integers, but 112.5 is not an Integer, it's a Float.

112.5.class;

So the first question is, does this code expression even make sense? The answer, of course, is yes. A non-integer tempo value is a perfectly valid thing. But asking if something makes sense is always a good first step beucase the answer's not always gonna be yes. What works for one class doesn't necessarily work for another. For example, it's perfectly sensible to ask if an integer is prime, but it's not a meaninful quesion for non-integers, which is why isPrime is only defined for integers.

5.isPrime;
5.1.isPrime;

Now, in a class extension file like this one, you're allowed to have as many extensions as you like, you don't have to create a new file for every extension, so one solution is to just copy and paste this code and define the same method for floats in addition. And technically, this works... but...there's a better solution, so we're gonna take a little detour here to talk about method inheritance, which is one of the first topics in the Writing Classes guide, and I also want to take this moment to share with you a little SuperCollider easter egg you may not be aware of, and that's the class browser, which you can bring up by typing the name of any class, followed by dot-browse.

Object.browse;

In object-oriented programming, classes are organized according to a Class Tree, a data structure in which every class has some number of subclassess, and at most one superclass—these relationships are synonymously referred to as child and parent classes. At the root of the class tree is a class called Object. It is the parent, grandparent, great-grandparent, etc. of all other classes, and it's the only class that does not have a parent class. The bottom line here, the reason I'm bringing this up, is that classes *inherit* the methods of their parent class. In other words, any methods defined for some class will automatically be defined for all of its child classes, its grandchild classes, and so on.

This class browser is an excellent tool for visualizing the class tree. You can type any class name in the search bar at the top and hit enter to view information for that class [Collection, Server]...and you can use the forward and back buttons to navigate through your browsing history...in the bottom left, there's a list of all of the immediate subclasses of the class you're currently viewing, double-click to select one of them [SequenceableCollection]...to the right, a list of all methods defined for the class being viewed. As we've already seen, an asterisk denotes a class method, no asterisk denotes an instance method. Click to select any method, and the arguments for that method will appear in the rightmost column [geom, interpolation]. If you want to know the parent class of the class being viewed, click the super button. You can open the help file for a class, if it exists, by clicking the help button, you can view the source code by clicking class source, and the method source button will open the relevant source code file if it's not already open and attempt to auto-scroll to the line where that method is defined. All things considered, very convenient, and not just for visualizing the structure of the class tree, it's also a great way to discover methods that you didn't know about.

And while we're on the subject of looking up source code, there's an option to look up implementations for classes and methods in the Language menu, the keyboard shortcut is shift-command-i, or shift control i on windows and linux. This brings up a search bar for locating the file in which a particular class or method is defined. For example, type Array and hit enter, right at the top we see the Array class and all of its class and instance methods, and in fact all of Arrays parent classes and their methods appear further down in the search results, select any of these and hit enter to open that file and auto scroll to the relevant code. Very handy for rummaging through source code and writing your own. For example, suppose we've closed the extensions file we're currently working on. Instead of navigating through a bunch of OS windows, we can get it back very quickly by looking up implementations, type tempodur, hit enter to search, enter again to open the file.

Let's get back to the issue at hand. Right now we've got the same method defined for Integer and Float. But maybe they're siblings or distant cousins, and have a parent or grand-parent class in common. The class browser will give us the answer very quickly. The parent of Float is a class called SimpleNumber, and we can see that it has exactly two children: Float and Integer. So, this is perfect. All we have to do is define the method once for SimpleNumber, and inheritance takes care of the rest. Just for a moment taking a peek one generation higher, SimpleNumber is a child class of Number, and its siblings are Polar and Complex. Perhaps it's worth asking if we should consider defining tempodur for Number instead of SimpleNumber? And the answer, I think, is a pretty obvious no. Polar and complex numbers are two dimensional values that exist on the plane, and treating a two-dimensional value as a tempo is...something I have never even considered doing. I...don't even know what that means. Anyway I think it's pretty clear that SimpleNumber is the right choice. So tempodur is now an instance method for SimpleNumber, save and recompile, and now we can get the duration of one beat at an integer tempo, or a float tempo.

112.tempodur;
112.5.tempodur;

As long as we're making a method to convert tempo to beat duration, I think its makes sense to define the inverse method, that converts in the opposite direction. With midicps we also have cpsmidi, ampdb has the inverse method dbamp, so let's make a durtempo method. Since this method will also be defined for SimpleNumber, we can just add another method function directly above or below this one. Once again we declare some variables, beatdur is the receiver, and using simple algebra, if beatdur is 60 divided by tempo, then tempo is equal to 60 divided by beatdur. Make sure to return the tempo value, save, and recompile. To test, if a beat is 0.8 seconds, then we're dealing with a tempo of 75 bpm. 75 dot tempodur, sure enough, 0.8 seconds.

0.8.durtempo;
75.tempodur;

So, that all seems good. Let's move on to another example. In tutorial 23, I used code that looked more or less like this, with Env, to generate some random wavetables for oscillators. Looks like this.

(
var env, numSegs=16;
env = Env.new(
	{rrand(-1.0,1.0)}!(numSegs+1),
	{exprand(1,10)}!numSegs,
	{rrand(-4.0,4.0)}!numSegs
);
env.plot;
)

But wouldn't it be nice if we could just type Env dot rand, and specify the desired number of segments?

Env.rand(16).plot;

Evaluating this gives us message-not-understood, which suggests that this method doesn't exist. To be more certain, we can look it up in the class browser

Env.browse;

and scanning the methods, it doesn't really look like any of them are gonna do what we want.

So let's make it. And I think this is a good follow-up example because there are two important differences between this method and the ones we just made. First, we're envisioning a class method, not an instance method, because rand in this case is being applied directly to the Env *class*. And the second thing, We're going to need some additional input here, to specify the number of envelope segments. An example from the default class library is squared and pow. squared doesn't need any additional input. it just takes the receiver and raises it to the power of two.

3.squared;

But the pow method does. The expression 3.pow; gives us an error unless we explicitly provide the exponent.

3.pow;
3.pow(4);

We've got a similar situation here. tempodur and durtempo just need the receiver, and they can do the math on their own. But this Env.rand we're imagining needs to know how many segments we want.

So let's go back to the extensions file, we're done extending SimpleNumber for now, so we're going to begin a new enclosure of methods to be added to the Env class. And very important to remember the asterisk at the beginning of the method name, because that's how we tell SuperCollider this is a class method. To start, it's pretty reasonable to just copy and paste our existing code.

Now, we definitely don't want this plot business in here, so let's get rid of that. So, the first question is, when we say Env.rand(20), or 4, or whatever the number, how do we pull this number into our method code? And the answer is, same way we do it with regular functions, we declare an argument. Now, it's up to you if you want to provide a default value. It's ultimately a design choice, I guess. Do you want Env.rand to make assumptions about how many segments you want? Or would you rather have Env remind you that you forgot to provide that information? And for me, I prefer the second option. If I'm not being specific enough, I want SuperCollider to let me know.

So, believe it or not, we're kind of done here, we just need to remember to return the new env, so just add that line at the bottom.

And also, I want to point out that instead of Env.new here, we could replace it with this.new, since this refers to the receiver, and it's a class method so the receiver will always be the Env *class*. Now if this were an instance method, we really have to use the keyword this to refer to the receiver, because instances are unique and come in all shapes and sizes, and we have no way of knowing what the instance will be until the method is actually called. But for class methods, the receiver is always the class, which is a singular entity that never changes. So this vs. Env, maybe one of these two options is considered "best practice," I'm not really sure, but practically speaking, I don't think there's a big difference.

So. Save, recompile...no error messages, so let's try it out.

Env.rand(16);

This line... returns an Env, which is what we want, and since it's an Env, we can put dot plot on the end to see what it looks like.

Env.rand(16).plot;

Looks good. Let's try 6 segments:

Env.rand(6).plot;

Also good. Env.rand with no input argument gives us an error, which is what I wanted.

Env.rand.plot;

So we could leave it like this it's a perfectly useable method, but I can think of a few refinements that might be nice. For one thing, I don't really like the look of all this stuff crammed into Env. It's just a style thing but I'm gonna change it anyway, declaring a variable for each of these three arrays and writing out these statements individually.

One issue I see is that the total duration of the envelope is unpredictable. And also can be pretty long, depending on the number of segments.

Env.rand(20).duration;

In the context of filling wavetables, the duration of the envelope doesn't really matter because in the end it's just gonna get discretized to some power of two number of samples. But in other contexts, envelope duration can be pretty important. So it'd be nice to have some control over the total duration of the envelope. So let's scale the times array so that it always sums to 1 second, and we can do this with normalizeSum, an Array method that scales the values inside an array so that their relative proportions remain unchanged, but they sum to a value of 1.

[2,3,5,6].normalizeSum;

And, just in case we want to scale this value, so that it's longer or shorter than 1 second, we can give ourselves a second argument, call it dur, and use it to scale the times array, which by itself is always one-second long. In doing so, the dur argument represents the total duration of this envelope. Save and recompile, and now by default, every envelope is exactly one second long.

Env.rand(16).duration;
Env.rand(6).duration;
Env.rand(2).duration;
Env.rand(200).duration;

And we can freely scale the duration with a second argument. If we want a 12 segment envelope that's 5 seconds long, no problem, there it is. Note that methods expects arguments in the order they were declared in the method definition, it even appears in this little yellow pop-up text.

Env.rand(12, 5).duration;
Env.rand(12, 5).plot;

A similar improvement would involve normalizing the levels array. Right now the range is bipolar around +/-1, but the values themselves are totally random, so there' nothing preventing the envelope from having levels that are all positive, all negative, all very close to zero, stuff like that. In some cases, like generating an oscillator wavetable, we want at least one positive value and one negative value so that we get a bipolar oscillator. In the case of an amplitude envelope, perhaps we want a unipolar envelope, with no negative values at all. So I think a sensible thing to do is let the user specify whether the Env is unipolar or bipolar, and automatically scale the levels so that the peak value is always 1 and the lowest value is always 0 or -1 depending on what the user wants.

So that means another argument, a boolean perhaps, indicating whether the env will be bipolar. By default, true I guess, don't really care about this right now. Let's make a new variable representing the minLevel, and after we generate the levels array, we're going to use a similar method as before, this time, normalize, which proportionally scales the values to be with a min/max range of our choosing. The max value will always be 1, but the min value will vary based on whether bipolar is true or false. if false, minlevel should be 0, and if true, minLevel should be -1. So my first thought is to use the boolean instance method asInteger, which returns 1 if the reciver is true, and 0 if false, and then neg to flip the sign and produce the desired minimum value.

Let's see if it works. Here's a 5-segment, 2-second bipolar envelope, it's small but maybe you can see the y-axis ranges from -1 to +1 or just take my word for it.

Env.rand(5, 2, true).plot;

A 7-segment, 3-second unipolar envelope:

Env.rand(7, 3, false).plot;

Looks good. I'm gonna stop here because I don't want to get too into the weeds, so feel free to experiment, but for now I think we've got a very nice random envelope generator.

Let's move on to an example that involves sound. As you know, we can boot the server, make a function, filled with some UGens and other things, and then hear the result using the play method.

s.boot;

{SinOsc.ar(60.midicps) * EnvGen.ar(Env.perc(0.001,0.2), doneAction:2) * 0.5!2}.play

There are a few different reasons why you might want to play a short simple tone like this, maybe you just want to quickly test a loudspeaker system to make sure everything's connected properly, or maybe you're listening to a song and want to figure out what key it's in. Whatever the reason, this is kind of a long line of code for a short sound, so it'd be nice if we could just type

60.play;

as a shortcut for this line. Of course, the assumption here is that we just want sound as quickly and easily as possible, and we don't really care about most of the details like amplitude, number of channels. Basically, we just want to play a midi note number and hear something.

This doesn't exist, but we can make it. Once again, I think it makes sense to define this method for SimpleNumber, so that it's inherited by integer and float. And since we already have an enclosure of extended methods for SimpleNumber, we can just add to the list. Inside the method function, we can just copy and paste our longer line here, and replace 60 with this. Save, recompile, and let's test it out.

60.play;

So, a couple things here. First, be aware that recompiling the class library has the side effect of quitting the server, so we'll need to reboot. But before we do, it's worth asking ourselves yet another design question: do we want this new method to boot the server for us, if it's not already on? And, I'm thinkin' no, because virtually every other server-related action in SC, like allocating a buffer, adding a synthdef, none of these things boot the server automatically. Booting the server ought to be viewed as a discrete, separate step, and in SuperCollilder it's also significant thing to do, you're powering on this big audio engine, and this might even have unforeseen consequences depending on the circumstances, so I think it's, just, messy to have this mostly unrelated method boot the server as a side effect. And maybe more to the point, if we run this longer line, we get this warning, which I think is a nice, helpful reminder, so it makes sense to keep this behavior consistent, and we'll just manually boot the server like we always do.

s.boot;
60.play;
67.play;
72.play;

So that works. And we've arrived at another important point to understand, which has to do with a method returning a value vs. a method having a side-effect. In the previous examples with tempodur and Env.rand, the main goal of these methods was to return a new value, so we made sure to insert a caret to designate the thing to be returned. In this example, we're not returning anything, or, more specifically, we haven't specified a return value. In SuperCollider, every method returns something, there's no such thing as returning void as is the case in some other languages. So if a method definition does not specifically designate a return value, then the method returns its receiver, and that's why we see 60,67,72 in the post window when we ran these lines. But that's fine, because in this particular case, we don't care about the returned value, it's simply not important or relevant. What we care about is the side effect of calling this method, which is to produce a sound. So, some methods are meant to return a value, others are meant to perform some side effect, and some possibly are meant to do both. But the point is, it's an important distinction. A good example of this distinction from the default library is

Window.new;

and

Window.closeAll;

These are both class methods, and looking at the source code, Window.new does some things, but ultimately has a caret at the bottom, which returns a new, initialized window instance. And that's the whole point of this method is to get that usable window as a return value. But for Window.closeAll, there's no caret, so no return value is specified. But this method has the side effect of tracking down all the open windows and closing each one. And in this case, that's the point, the window-closing side-effect is the reason we call this method. The fact that it also returns the Window class is just an unimportant thing that happens.

Anyway, while we're on the topic of sound, let's talk about Pseudo UGens. There is a Guide file called Writing Unit Generators, and for the most part, this file is all about writing actual UGens in C++, it's a good resource by itself, and includes a link to a supercollider github repository called example-plugins, which at the time of writing this video is deprecated, and redirects you to this cookiecutter template. Like I said at the beginning I'm not gonna get into any C++ in this video, but this guide file does include a section on Pseudo UGens. A Pseudo UGen is basically a wrapper for a chunk of UGen code that you want to be able to reuse more easily, and the guide file sums in up nicely: "A pseudo-UGen is a class that superficially resembles a UGen class, but it only returns a composition of existing UGens." And this ultra-simple example of a BoringMixer has one class method, ar, which expects two inputs, and returns half the sum. Doesn't get much simpler than that. So here's a more complex example of my own. In my compositions, I have this two-channel reverb that looks like this, which I often reuse and sort of continually adjust and refine as I see fit.

(
SynthDef.new(\reverb, {
	arg in=0, dec=3.5, mix=0.08, lpf1=2000, lpf2=6000, predel=0.025, out=0;
	var dry, wet, sig;
	dry = In.ar(in, 2);
	wet = In.ar(in, 2);
	wet = DelayN.ar(wet, 0.5, predel.clip(0.0001,0.5));
	wet = 16.collect{
		var temp;
		temp = CombL.ar(
			wet,
			0.1,
			LFNoise1.kr({ExpRand(0.02,0.04)}!2).exprange(0.02,0.099),
			dec
		);
		temp = LPF.ar(temp, lpf1);
	}.sum * 0.25;
	8.do{
		wet = AllpassL.ar(
			wet,
			0.1,
			LFNoise1.kr({ExpRand(0.02,0.04)}!2).exprange(0.02,0.099),
			dec
		);
	};
	wet = LeakDC.ar(wet);
	wet = LPF.ar(wet, lpf2, 0.5);
	sig = dry.blend(wet, mix);
	Out.ar(out, sig);
}).add;
)

You can probably find variations on this idea throughout my channel, I think it comes up from time to time, but basically it's a variation on a Schroeder reverb, so at it's core it's a sum of several comb filters, followed by several allpass filters in series. There's also a predelay before the body of the reverb is created, these slow-moving noise generators add just a bit of movement to the delay times to prevent the reverb character from sounding like you're inside a big oil drum, a filter that removes DC bias, a few lowpass filters here and there for damping, and the dry/wet mix is handled here, blend is just a convenience method that returns an instance of a Xfade2 ugen, just an equal-power mixer. In fact, we can look up the blend source code using the implementation search. It uses XFade2 to mix the receiver, with the first argument, and the balance is controlled by another argument between 0 and 1.

So, first let's hear what it sounds like, we can set up a stereo bus and instantiate the effect

b = Bus.audio(s,2);
Synth(\reverb, [\in, b]);

Now I'd love to be able to use this new play method to audition the reverb...

86.play;

But we didn't give ourselves the option of specifying the output bus, so it always goes straight to hardware. Let's change that real quick. First, I'm gonna rewrite this code so it's a little easier to read...at the bottom, an Out UGen, and an argument at the very top of this method function, default to 0, right after the opening brace after play. This might look a little weird, but it's a matter of scope — we have to make this argument available to the play method, not just within the UGen function, so that we can pass in a specific bus when we call the method.

Ok save and recompile, reboot the server, synthdef, bus, reverb synth, and now we can play this test tone to bus 'b'

86.play(b);

Ok so, this reverb synthdef is a good sized chunk of code, let's make a pseudo ugen for it. Back to our extensions file, there's a tricky organizational nuance here. If we make a dummy class that does nothing and put it at the bottom of the file after the method extensions, save and recompile, we get an error. But it we move this dummy class to the top of the file, it compiles just fine. So, if you're going to put all your extensions into one sc file, which I don't particularly recommend, I think the rule is, you've got to put all the classes at the top, and all the methods at the bottom.

But, now might be a good time to start organizing our work, at least split it up into two files, one for methods, one for classes. So duplicate this file, rename them as methods and classes, wipe the contents of this new file and start building our Pseudo UGen here.

First it needs a name. I'm gonna call it VerbEF, the syntax is similar to adding methods, but in the case of new classes we omit the plus symbol. This class is going to have one class method, ar, we could also make a kr method, but I can't imagine ever wanting to run this reverb at the control rate, so just this audio rate method is fine. And be aware that this method can be named whatever you want, it's just that ar is a sensible choice because that's the convention for UGens and it'll help your pseudo UGen look and feel like an actual UGen.

To start, we're going to copy the contents of the SynthDef function into the *ar method. And we have to make some changes. First, get rid of these In UGens, because this method isn't gonna read a signal from a bus. Instead, the SynthDef that this pseudo UGen belongs to is gonna handle that, and we're gonna supply the input signal, explicitly, using a named container, the same way we specify the input signal for a filter like LPF or something. So we just say dry is equal to in, the first input argument for VerbEF, and wet is also equal to in. And I suppose we don't want any default value for in, because I think of the input signal as something the user must provide on their own. Then wet goes through all this code, gets processed and recombined with dry, and a similar situation with Out.ar. We're not writing this signal to a specific bus, instead we're just returning the signal, and the SynthDef will handle the bus connection. We also don't need this output argument anymore...and...if we want to be consistent with the design of other UGens, we can put mul and add at the end of the argument list, with typical default values, and apply them just before the signal is returned, although to be honest I doubt we're gonna use these.

Save, recompile, and now, back to our SynthDef. With a Pseudo UGen ready to go, we can drastically simplify this SynthDef. Starting with the original, we keep all these arguments, just a single variable named sig, read the input signal from some bus, replace alllll of this with our pseudo, plug in the synthdef aruments, note the convenient pop-up text, and send the signal out. Reboot...and re-evaluate this stuff

(
SynthDef.new(\reverb, {
	arg in=0, dec=3.5, mix=0.08, lpf1=2000, lpf2=6000, predel=0.025, out=0;
	var sig;
	sig = In.ar(in, 2);
	sig = VerbEF.ar(sig, dec, mix, lpf1, lpf2, predel);
	Out.ar(out, sig);
}).add;
)

b = Bus.audio(s,2);
r = Synth(\reverb, [\in, b]);

86.play(b);

Everything's the same but the SynthDef is now much shorter, very nice, and we retain all the functionality from the original, for example, we can change the mix:

r.set(\mix, 0.6);
84.play(b);

We can change the decay time,

r.set(\dec, 10);
84.play(b);

We can also change the damping characteristics

r.set(\lpf2, 400);
84.play(b);

So it's all there, tucked away inside the source code. So, any cluster of interconnected UGens that you find yourself using over and over again, consider building a pseudo UGen to save yourself time and space.

Alright, so, I've got two more GUI-related examples I want to share. So a few years ago I was at a tech rehearsal for a concert, and I was going to be projecting my computer screen in addition to making sound. And I guess for some reason we were unable to mute the projector, maybe the remote control was broken, and I didn't really want to have my computer desktop on the big screen as people came into the hall, so I cooked up a few lines of code that place a full screen-sized all-black window on top of everything, that could be closed by pressing the escape key.

The code looks like this, local variable, storing a new window instance, Window.screenBounds is useful for getting a Rect that represents the size of your screen, and false comma false for not resizable, no border. background color is black, and a keyDownAction function, evaluated whenever a key is pressed with this window in focus. This function takes several arguments, the first four of which are the view object to which this function belongs, the character of the pressed key, a value indicating which modifier keys are active, and fourth, the unicode integer associated with the key being pressed. And unicode is what we're going to use here because the escape key doesn't have a printable character associated with it, but it does have a unicode representation, which I happen to know is the number 27. And this is information you can easily find on a unicode or ascii table on the web. So, if uni is 27, close the window. And finally, bring the window to the front.

(
var win;
win = Window.new("", Window.screenBounds, false, false);
win.view.background_(Color.black);
win.view.keyDownAction_({
	arg view, char, mod, uni;
	if( uni == 27, {win.close});
});
win.front;
)

Now, yes, we still have the macOS menubar, which is lame, but thankfully it's possible to hide and show the menu bar through System Preferences ... General. And I guess cram the mouse cursor off to the side somewhere. I assume it's possible to hide the OS menubar in Windows and Linux, also? But I don't know specifically how. So, fullscreen black, hit escape, and we're back.

What I'd like to do is be able to invoke this code by running

Window.blackout;

Or something like that. So, back to our methods extension file, and at this point hopefully you're starting to get a feel for the workflow here. New extension for Window, a class method called blackout, and this happens to be a case where we can just copy and paste. No need for the caret character, becuase returning a value is not really the goal here, we're more interested in the side-effect of creating this black window.

Window.blackout;

Easy. Note that I'm avoiding the temptation to use a global variable here, instead it's all local variables. It's definitely bad practice to put globals inside of classes and methods, because then it's possible to accidentally, and very secretly, overwrite existing global variables in a way that is mostly undetectable and very difficult to debug. For example, if in the method function I used the environment variable, tilde-win, and let's say i'd been working on some stuff, and ~win is equal to something, like the number 5. Then, if I run Window.blackout, now that old value is gone, and ~win is now holding a refernece to that window we just closed.

~win = 5;

Window.blackout;

~win;

So, that's pretty bad. We don't like it when variables get secretly overwritten. The lesson is, local variables only inside of class and method definitions.

Ok, last example. Maybe at some point you were designing a graphical interface in SuperCollider, and trying to figure out the color scheme. Color, as you might know, is handled by the Color class, basically it's a red-green-blue situation, in which the three values represent...i might have the wrong technical term here, but I think it's brightness, or just value of each of these three colors on a scale between 0 and 1. There's not really a built-in interface for auditioning colors in SuperCollider, so maybe you find yourself like putting in random RGB number and seeing if it looks good, just kind of aimlessly guessing. Well, we can make a simple color palette, like the kind that accompanies a lot of text editing software. This is an idea that I first found in some code by Miguel Negrão, many years ago, which is documented on the now unmaintained sourceforge wiki, and at some point got copied onto sccode.org. So credit where it's due, this is not my original idea, I'm just adapting this code to make it a little more tutorial friendly.

So, here is my version in plain old SuperCollider code. Basically, we have a default color, a small window, three knobs that represent the amounts of red, green, and blue, and a basic View, a simple rectangular space to serve as a palette where the color will be displayed. Whenever a knob is moved, it updates the color object and updates the palette background to display the color.

(
var color, window, palette;

color = Color.new(0.8,0.8,0.8);
window = Window.new("ColorEF", Rect(50,50,210,160)).front;

Knob.new(window, Rect(10,10,40,40))
.mode_(\vert)
.value_(color.red)
.color_([Color.red])
.action_({
	arg view;
	color.red_(view.value);
	palette.background_(color)
});

Knob.new(window, Rect(10,60,40,40))
.mode_(\vert)
.value_(color.green)
.color_([Color.green])
.action_({
	arg view;
	color.green_(view.value);
	palette.background_(color)
});

Knob.new(window, Rect(10,110,40,40))
.mode_(\vert)
.value_(color.blue)
.color_([Color.blue])
.action_({
	arg view;
	color.blue_(view.value);
	palette.background_(color)
});

palette = View.new(window, Rect(60,10,140,140))
.background_(color);
)

So, it's working, and the main issue is that we don't really have a good way to extract the numerical color values from the GUI, so if we were doing this as plain old code, we might put postln someplace, so we see the color whenever a knob gets touched, or use a global variable for color so we can access it anywhere, or even just add another GUI element like a StaticText to display the color information. But we're going to make this into a class, so that gives us another option. So, back to the class extensions file, new class named ColorEF, and we need some sort of class method to invoke this chunk of code here. Maybe something like make. And again we can just copy and paste. Now, we don't technically need to return anything, but it might be nice to return the window, just so we have the option to interact with it using code, like if we want to close it or something. So, save, recompile, and...

c = ColorEF.make;

There it is, and since make returns the window instance, and we've captured in lowercase c, we can do

c.close;

to get rid of it.

The way we've got ColorEF defined is...ok, for the most part, but there are some conventions we probably want to follow, mostly for consistency with other types of Objects.

First of all. We know objects inherit methods from their parent class. So what is the parent class of ColorEF? Does it have one? Let's find out.

ColorEF.browse;

It's Object. And that's part of why we can actually call browse on ColorEF, even though we didn't define such a method, it's because browse is a class method defined for Object, so every class inherits it.

If we don't specify otherwise, new Classes are built as immediate descendants of Object. In my experience, this is usually fine, especially if you're doing some very unique and customized thing, but if you are imagining a new class as some minor variation on an existing class, like, I dunno, Window, then you'd use this Syntax in the class file: new class name, space colon space, parent class, and then begins the class definition function.

ColorEF.browse;

And now we can see that ColorEF is a subclass of Window, which is a subclass of Object. But, again, in this case I think inheriting directly from Object is fine. So, any methods that work for Object will be valid for ColorEF. What about the "new" method, n-e-w? We're not using it, but it is inherited from Object. So, it works, but we can't call make on c because make is a class method, and c is an instance.

c = ColorEF.new;
c.make;

So, the convention that I've seen most often is to override the new method in a particular way, and the Writing Classes guide gives some information here, it says: "When overriding the class method .new you must call the superclass, which in turn calls its superclass, up until Object.new is called, an object is actually created and its memory allocated." So it looks like this:

class method new returns a new instance of the superclass, we use the special keyword "super" to refer to the immediate parent class, and then we call make on that new instance, so make must now be an instance method that's gonna be responsible for initializing ColorEF, so delete this asterisk. Save and recompile...

c = ColorEF.new;

So, now we can use new and the make method gets called internally. But now, "make" probably shouldn't return the window anymore because if it does, we're losing access to the instance of ColorEF, which just doesn't seem right to me, so let's remove that.

c = ColorEF.new;

And now c is an instance of the ColorEF class, and that's the behavior we're accustomed to.

But we still haven't dealt with the main problem of having access to the color instance through the ColorEF class. Right, we've got the window, we pick a color, but how to we get the numbers? Well, we could go back to the class file and add an instance method named color that returns the color, and that's generally a pretty easy thing to do. But the problem is that right now, the color variable is local to the make method, so we have no access to it outside of that scope. So the first step is to remove it from this function and instead declare it at the very top, as an instance variable. In doing so, we're making it possible to reference this attribute in any of the class or instance methods. Now, we don't have to provide an initial value, and in fact we probably shouldn't, because that's being handled by the make method. With an instance variable at the top, we can now create a method, let's call it getColor, that returns the color variable we declared. So let's try this out. Create the instance, turn the knobs, and c.getColor returns the color instance.

c = ColorEF.new;
c.getColor;

And just so you're aware, the method name and variable name are not in conflict. They can actually be identical, and that's not a problem, as long as this doesn't bother you from a stylistic perspective.

c = ColorEF.new;
c.color;

And there's actually a shortcut you can use for making access methods like this one. We don't need this method definition at all, and instead, put a less-than symbol right before the variable name.

c = ColorEF.new;
c.color;

Still works. This shortcut is documented in the Writing Classes guide, down in the section titled Getters and Setters. If a variable is preceded with a less than, you can get it but you can't set it. If it's greater than, you can set it, but you can't get it. If it's preceded with less than-greater than, you can set and get. Right now, color is gettable but not settable.

This means we can get the color:

c.color;

But if we try to set the color to something new...

c.color_(Color.new(0.2, 0.5, 0.8));

We don't have access. I think that makes sense in this case. We definitely want the ability to get the color value from the class, but we don't really need to be able to set the color using code, I mean, that's what the knobs are for. We could make color a settable variable, but then we'd have to deal with making sure the knobs get updated when the user calls the setter method, I just think that's more trouble than necessary.

So, now,

c.close;

doesn't work anymore, because that method isn't defined for Object or ColorEF. But we can give ourselves access to the window using the same technique -- making window a classwide variable and making it gettable.

c = ColorEF.new;

And now, all we have to do is

c.window.close;

Perhaps even nicer, make another instance method named close that does the work for us. All this method needs to do is this.window.close.

c = ColorEF.new;
c.close;

So, that's gonna be it for Tutorial 28, hope you enjoyed it. Now, personally, I try not to rely too heavily on extensions and Quarks and other things that are external to the default class library. The main reason for this is that in my line of work, I frequently find myself sending my code to performers, collaborators, sometimes people who've never used SuperCollider before, and it's just a lot simpler if that code doesn't have external dependencies. Otherwise I end up running tech support to help get things installed correctly. I have nothing against the idea of extensions, I think they're great, it's just that for me, not relying on them too much tends to make my life a little easier, which is kind of ironic, I guess. But if you are using SuperCollider on your own, for your own personal enjoyment, then go nuts, make all the extensions you want!

In addition to this guide, studying existing source code can be helpful, and don't forget about the Class browser and implementation search. But also, an important part of understanding the class- and method-writing process is to just start doing it. It might be challening at first, but it's good to make mistakes, ask questions, and learn things, and just get some practice in. And if you really mess something up, you can always trash SuperCollider and download a fresh copy. So...I hope these extensions have been clear and instructive, and that they give you the tools and inspiration to start writing your own. Thanks for watching, see you next time.