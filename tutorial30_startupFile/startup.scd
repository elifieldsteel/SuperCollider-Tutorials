(
s.options.memSize_(2.pow(20));
s.waitForBoot({

	SynthDef(\k, {
		var sig, freqSweep, env;
		freqSweep = Env([\freq.ir(2000), 50, 20], [0.025, 1], [-8, -4]).ar;
		env = Env([0, 1, 0], [\atk.ir(0.005), \rel.ir(0.5)], [1, -12]).ar(2);
		sig = SinOsc.ar(freqSweep);
		sig = (sig * 1.1).clip(-1, 1);
		sig = Pan2.ar(sig.distort * 2, 0, \amp.ir(0.2));
		sig = LPF.ar(sig, \lpf.ir(20000).clip(20, 20000)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\b, {
		var sig, env, buf = \buf.ir(0);
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = PlayBuf.ar(1, buf, BufRateScale.ir(buf) * \rate.ir(1), 1, \spos.ir(0), \loop.ir(0));
		sig = LPF.ar(sig, \lpf.ir(20000).clip(20, 20000));
		sig = HPF.ar(sig, \hpf.ir(20).clip(20, 20000));
		sig = Pan2.ar(sig, \pan.ir(0), \amp.ir(0.5)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\imp, {
		var sig, env;
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = Impulse.ar(
			\freq.ir(1000) * 2.pow({ (\dtn.ir(0.05)/12).sum3rand } ! 8)
		);
		sig = Splay.ar(sig);
		sig = Balance2.ar(sig[0], sig[1], \pan.ir(0), \amp.ir(0.1)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\sin, {
		var sig, env;
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = SinOsc.ar(
			\freq.ir(1000) * 2.pow({ (\dtn.ir(0.05)/12).sum3rand } ! 8)
		);
		sig = Splay.ar(sig);
		sig = Balance2.ar(sig[0], sig[1], \pan.ir(0), \amp.ir(0.1)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\tri, {
		var sig, env;
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = LFTri.ar(\freq.ir(1000) * 2.pow({ (\dtn.ir(0.05)/12).sum3rand } ! 8));
		sig = Splay.ar(sig);
		sig = LPF.ar(sig, \lpf.ir(1000).clip(20, 20000));
		sig = Balance2.ar(sig[0], sig[1], \pan.ir(0), \amp.ir(0.1)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\saw, {
		var sig, env;
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = Saw.ar(\freq.ir(1000) * 2.pow({ (\dtn.ir(0.05)/12).sum3rand } ! 8));
		sig = Splay.ar(sig);
		sig = LPF.ar(sig, \lpf.ir(20000).clip(20, 20000));
		sig = Balance2.ar(sig[0], sig[1], \pan.ir(0), \amp.ir(0.1)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	SynthDef(\pul, {
		var sig, env, rq = \rq.ir(0.7);
		rq = rq.clip(0.0001, 1);
		env = Env.linen(
			\atk.ir(0.001), \sus.ir(0), \rel.ir(0.5),
			curve: [\ca.ir(-1), 0, \cr.ir(-4)]
		).ar(2);
		sig = Pulse.ar(
			\freq.ir(1000) * 2.pow({ (\dtn.ir(0.05)/12).sum3rand } ! 8),
			\wdt.ir(0.5)
		);
		sig = Splay.ar(sig);
		sig = LPF.ar(sig, \lpf.ir(20000).clip(20, 20000));
		sig = Balance2.ar(sig[0], sig[1], \pan.ir(0), \amp.ir(0.1)) * env;
		Out.ar(\out.ir(0), sig);
	}).add;

	~makeBuffers = { |path, event, mono = false|
		var dir = PathName.new(path);
		var contents = dir.entries;

		if (contents.select({ |n| n.isFile }).size > 0)
		{
			var files, bufArray;
			files = contents.select({ |n| n.isFile });
			files = files.select({ |n|
				["aif", "aiff", "wav"].includesEqual(n.extension)
			});

			if (event[dir.folderName.asSymbol] != nil)
			{ "duplicate subfolder name ignored".warn; }
			{
				bufArray = files.collect({ |n|
					if(mono)
					{ Buffer.readChannel(s, n.fullPath, channels:[0]) }
					{ Buffer.read(s, n.fullPath) };
				});
				event[dir.folderName.asSymbol] = bufArray;
			};
		};

		if (contents.select({ |n| n.isFolder }).size > 0)
		{
			var folders = contents.select({ |n| n.isFolder });
			folders.do({ |n| ~makeBuffers.(n.fullPath, event, mono) });
		};

		event;
	};

	b = ~makeBuffers.("/Users/eli/Music/Compositions/Boneyard Festival 2019/amb/", ());
	b = ~makeBuffers.("/Users/eli/Sounds/scaudio/shades/", b);
	b = ~makeBuffers.("/Users/eli/Sounds/scaudio/glitch/", b, true);
	b = ~makeBuffers.("/Users/eli/Sounds/scaudio/groh/metal/flowerPot/", b, true);
	b = ~makeBuffers.("/Users/eli/Sounds/scaudio/miscellaneous/pno/", b, true);

});
)