package states.stages;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;
import shaders.OverlayBlend;
import states.stages.objects.*;

enum HenchmenKillState
{
	WAIT;
	KILLING;
	SPEEDING_OFFSCREEN;
	SPEEDING;
	STOPPING;
}

class Limo extends FunkyObject
{
	/**
	 * REMEMBER TO PUT THE "/" SHIT AT THE END!!!
	 */
	public var folder:String = "";
	public var isAlt:Bool = false;

	public var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	public var fastCar:BGSprite;
	var fastCarCanDrive:Bool = true;

	// Objects
	var limoKillingState:HenchmenKillState = WAIT;
	public var limoMetalPole:BGSprite;
	public var limoLight:BGSprite;
	public var limoCorpse:BGSprite;
	public var limoCorpseTwo:BGSprite;
	public var bgLimo:BGSprite;
	public var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var dancersDiff:Float = 320;

	// OBJECTS ERECT-ALT STAGE
	public var shootingStar:BGSprite;
	var mist1:FlxBackdrop;
	var mist2:FlxBackdrop;
	var mist3:FlxBackdrop;
	var mist4:FlxBackdrop;
	var mist5:FlxBackdrop;

	override function create()
	{
		var skyBG:BGSprite = new BGSprite('limo/' + folder + 'limoSunset', -120, -50, 0.1, 0.1);
		add(skyBG);

		if (!isAlt) {
			var sunOverlay:FlxSprite = new FlxSprite().loadGraphic(Paths.image('limo/limoOverlay'));
			sunOverlay.setGraphicSize(Std.int(sunOverlay.width * 2));
			sunOverlay.updateHitbox();

			var skyOverlay:OverlayBlend = new OverlayBlend();
			skyOverlay.funnyShit.input = sunOverlay.pixels;
			skyBG.shader = skyOverlay;
		} else {
			shootingStar = new BGSprite("limo/erect/shooting star", 200, 0, 0.12, 0.12, ["shooting star"], false);
			add(shootingStar);

			mist5 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), FlxAxes.X);
			mist5.setPosition(-650, -400);
			mist5.scrollFactor.set(0.2, 0.2);
			mist5.blend = ADD;
			mist5.color = 0xFFE7A480;
			mist5.alpha = 1;
			mist5.velocity.x = 100;
			mist5.scale.set(1.5, 1.5);
			add(mist5);
		}

		if(!ClientPrefs.data.lowQuality) {
			limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
			add(limoMetalPole);

			bgLimo = new BGSprite('limo/' + folder + 'bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
			add(bgLimo);

			limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
			add(limoCorpse);

			limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
			add(limoCorpseTwo);

			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + dancersDiff + bgLimo.x, bgLimo.y - 390);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
			add(limoLight);

			grpLimoParticles = new FlxTypedGroup<BGSprite>();
			add(grpLimoParticles);

			if (isAlt) {
				mist4 = new FlxBackdrop(Paths.image('limo/erect/mistBack'), FlxAxes.X);
				mist4.setPosition(-650, -380);
				mist4.scrollFactor.set(0.6, 0.6);
				mist4.blend = ADD;
				mist4.color = 0xFF9c77c7;
				mist4.alpha = 1;
				mist4.velocity.x = 700;
				mist4.scale.set(1.5, 1.5);
				add(mist4);
			}

			//PRECACHE BLOOD
			var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
			particle.alpha = 0.01;
			grpLimoParticles.add(particle);
			resetLimoKill();

			//PRECACHE SOUND
			Paths.sound('dancerdeath');
			setDefaultGF('gf-car');
		}

		if (isAlt) {
			mist3 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), FlxAxes.X);
			mist3.setPosition(-650, -100);
			mist3.scrollFactor.set(0.8, 0.8);
			mist3.blend = ADD;
			mist3.color = 0xFFa7d9be;
			mist3.alpha = 0.5;
			mist3.velocity.x = 900;
			mist3.scale.set(1.5, 1.5);
			add(mist3);
		}

		fastCar = new BGSprite('limo/fastCarLol', -300, 160);
		fastCar.active = true;
	}

	override function createPost()
	{
		resetFastCar();
		add(fastCar);

		var limo:BGSprite = new BGSprite('limo/' + folder + 'limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
		addBehindDad(limo); // Shhhhhhh fixed!
		if (isAlt){
			if (!ClientPrefs.data.lowQuality) {
				mist1 = new FlxBackdrop(Paths.image('limo/erect/mistMid'), FlxAxes.X);
				mist1.setPosition(-650, -100);
				mist1.scrollFactor.set(1.1, 1.1);
				mist1.blend = ADD;
				mist1.color = 0xFFc6bfde;
				mist1.alpha = 0.4;
				mist1.velocity.x = 1700;
				mist1.scale.set(1.3, 1.3);
				add(mist1);
			}

			mist2 = new FlxBackdrop(Paths.image('limo/erect/mistBack'), FlxAxes.X);
			mist2.setPosition(-650, -100);
			mist2.scrollFactor.set(1.2, 1.2);
			mist2.blend = ADD;
			mist2.color = 0xFF6a4da1;
			mist2.alpha = 1;
			mist2.velocity.x = 2100;

			add(mist2);
		}
	}

	var _timer:Float = 0;
	var limoSpeed:Float = 0;
	override function update(elapsed:Float)
	{
		if (isAlt) {
			_timer += elapsed;
			if (mist1 != null) mist1.y = 100 + (Math.sin(_timer) * 200);
			if (mist2 != null) mist2.y = 0 + (Math.sin(_timer * 0.8) * 100);
			if (mist3 != null) mist3.y = -20 + (Math.sin(_timer * 0.5) * 200);
			if (mist4 != null) mist4.y = -180 + (Math.sin(_timer * 0.4) * 300);
			if (mist5 != null) mist5.y = -450 + (Math.sin(_timer * 0.2) * 150);
		}

		if(!ClientPrefs.data.lowQuality) {
			grpLimoParticles.forEach(function(spr:BGSprite) {
				if(spr.animation.curAnim.finished) {
					spr.kill();
					grpLimoParticles.remove(spr, true);
					spr.destroy();
				}
			});

			switch(limoKillingState) {
				case KILLING:
					limoMetalPole.x += 5000 * elapsed;
					limoLight.x = limoMetalPole.x - 180;
					limoCorpse.x = limoLight.x - 50;
					limoCorpseTwo.x = limoLight.x + 35;

					var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
					for (i in 0...dancers.length) {
						if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170) {
							switch(i) {
								case 0 | 3:
									if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

									var diffStr:String = i == 3 ? ' 2 ' : ' ';
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
									grpLimoParticles.add(particle);
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
									grpLimoParticles.add(particle);
									var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
									grpLimoParticles.add(particle);

									var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
									particle.flipX = true;
									particle.angle = -57.5;
									grpLimoParticles.add(particle);
									shaderAltSet();
								case 1:
									limoCorpse.visible = true;
								case 2:
									limoCorpseTwo.visible = true;
							} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
							dancers[i].x += FlxG.width * 2;
						}
					}

					if(limoMetalPole.x > FlxG.width * 2) {
						resetLimoKill();
						limoSpeed = 800;
						limoKillingState = SPEEDING_OFFSCREEN;
					}

				case SPEEDING_OFFSCREEN:
					limoSpeed -= 4000 * elapsed;
					bgLimo.x -= limoSpeed * elapsed;
					if(bgLimo.x > FlxG.width * 1.5) {
						limoSpeed = 3000;
						limoKillingState = SPEEDING;
					}

				case SPEEDING:
					limoSpeed -= 2000 * elapsed;
					if(limoSpeed < 1000) limoSpeed = 1000;

					bgLimo.x -= limoSpeed * elapsed;
					if(bgLimo.x < -275) {
						limoKillingState = STOPPING;
						limoSpeed = 800;
					}
					dancersParenting();

				case STOPPING:
					bgLimo.x = FlxMath.lerp(-150, bgLimo.x, Math.exp(-elapsed * 9));
					if(Math.round(bgLimo.x) == -150) {
						bgLimo.x = -150;
						limoKillingState = WAIT;
					}
					dancersParenting();

				default: //nothing
			}
		}
	}

	override function beatHit()
	{
		if(!ClientPrefs.data.lowQuality) {
			grpLimoDancers.forEach(function(dancer:BackgroundDancer)
			{
				dancer.dance();
			});
		}

		if (FlxG.random.bool(10) && fastCarCanDrive)
			fastCarDrive();
	}
	
	// Substates for pausing/resuming tweens and timers
	override function closeSubState()
	{
		if(paused)
		{
			if(carTimer != null) carTimer.active = true;
		}
	}

	override function openSubState(SubState:flixel.FlxSubState)
	{
		if(paused)
		{
			if(carTimer != null) carTimer.active = false;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Kill Henchmen":
				killHenchmen();
		}
	}

	function dancersParenting()
	{
		var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
		for (i in 0...dancers.length) {
			dancers[i].x = (370 * i) + dancersDiff + bgLimo.x;
		}
	}
	
	function resetLimoKill():Void
	{
		limoMetalPole.x = -500;
		limoMetalPole.visible = false;
		limoLight.x = -500;
		limoLight.visible = false;
		limoCorpse.x = -500;
		limoCorpse.visible = false;
		limoCorpseTwo.x = -500;
		limoCorpseTwo.visible = false;
	}

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = FlxG.random.int(30600, 39600);
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.data.lowQuality) {
			if(limoKillingState == WAIT) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = KILLING;

				#if ACHIEVEMENTS_ALLOWED
				var kills = Achievements.addScore("roadkill_enthusiast");
				FlxG.log.add('Henchmen kills: $kills');
				#end
			}
		}
	}

	function shaderAltSet() {
		// Nothing :O
	}
}