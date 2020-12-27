+ SimpleNumber {

	tempodur {
		var tempo, beatdur;
		tempo = this;
		beatdur = 60/tempo;
		^beatdur;
	}

	durtempo {
		var beatdur, tempo;
		beatdur = this;
		tempo = 60/beatdur;
		^tempo;
	}

	play {
		arg out=0;
		{
			var sig;
			sig = SinOsc.ar(this.midicps);
			sig = sig * EnvGen.ar(Env.perc(0.001,0.2), doneAction:2);
			sig = sig * 0.5!2;
			Out.ar(out, sig);
		}.play;
	}

}

+ Env {

	*rand {
		arg numSegs, dur=1, bipolar=true;
		var env, levels, times, curves, minLevel;
		levels = {rrand(-1.0,1.0)}!(numSegs+1);
		minLevel = bipolar.asInteger.neg;
		levels = levels.normalize(minLevel, 1);
		times = {exprand(1,10)}!numSegs;
		times = times.normalizeSum * dur;
		curves = {rrand(-4.0,4.0)}!numSegs;
		env = this.new(levels, times, curves);
		^env;
	}

}

+ Window {

	*blackout {
		var win;
		win = Window.new("", Window.screenBounds, false, false);
		win.view.background_(Color.black);
		win.view.keyDownAction_({
			arg view, char, mod, uni;
			if(uni == 27, {win.close});
		});
		win.front;
	}

}

