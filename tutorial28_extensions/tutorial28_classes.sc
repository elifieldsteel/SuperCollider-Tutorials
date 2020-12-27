VerbEF {

	*ar {
		arg in, dec=3.5, mix=0.08, lpf1=2000, lpf2=6000, predel=0.025, mul=1, add=0;
		var dry, wet, sig;
		dry = in;
		wet = in;
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
		sig = sig * mul + add;
		^sig;
	}

}

ColorEF {
	var <color, <window;

	*new { ^super.new.make; }

	close { this.window.close; }

	make {
		var palette;

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
	}

}