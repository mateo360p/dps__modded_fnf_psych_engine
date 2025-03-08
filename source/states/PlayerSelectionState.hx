package states;

import states.editors.PlayerEditorState;
import objects.SelectionPlayer;
import objects.SelectionCharacter;
import objects.PlayerIcon;
import backend.LevelData;
import objects.PlayerIcon.Lock;
import flixel.FlxObject;
import objects.PlayerNameTag;
import flxanimate.PsychFlxAnimate._AnimateHelper;
import openfl.display.BlendMode;

class PlayerSelectionState extends MusicBeatState {
    var grpIcons:FlxTypedSpriteGroup<PlayerIcon>;
    var speakers:FlxAnimate;

    var barthing:_AnimateHelper;
	var grpCursors:FlxTypedGroup<FlxSprite>;
	var dipshitBlur:FlxSprite;
	var dipshitBacking:FlxSprite;
	var chooseDipshit:FlxSprite;
	var cursor:FlxSprite;
	var cursorDenied:FlxSprite;
	var cursorBlue:FlxSprite;
	var cursorDarkBlue:FlxSprite;
	var cursorConfirmed:FlxSprite;

	var selectSound:FlxSound;
	var unlockSound:FlxSound;
	var lockedSound:FlxSound;
	var staticSound:FlxSound;

	var nametag:PlayerNameTag;
	var camFollow:FlxObject;

    var grpXSpread(default, set):Float = 107;
    var grpYSpread(default, set):Float = 127;
    var nonLocks = [];

    var bopTimer:Float = 0;
    var delay = 1 / 24;
    var bopFr = 0;
    var bopPlay:Bool = false;
    var bopRefX:Float = 0;
    var bopRefY:Float = 0;

    var holdTmrUp:Float = 0;
    var holdTmrDown:Float = 0;
    var holdTmrLeft:Float = 0;
    var holdTmrRight:Float = 0;
    var spamUp:Bool = false;
    var spamDown:Bool = false;
    var spamLeft:Bool = false;
    var spamRight:Bool = false;

    var sync:Bool = false;
    var syncLock:Lock = null;
    var audioBizz:Float = 0;
    var pressedSelect:Bool = false;
    var selectTimer:FlxTimer = new FlxTimer();
    var allowInput:Bool = true; // For now :D

    var cursorX:Int = 0;
    var cursorY:Int = 0;
    var cursorFactor:Float = 110;
    var cursorOffsetX:Float = -16;
    var cursorOffsetY:Float = -48;
    var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);

    var curChar(default, set):String;
	var gfChill:SelectionCharacter;
    var playerChill:SelectionPlayer;
    var playerChillOut:SelectionPlayer;

    var notBeat:Bool = false;

    // Done ;D
    override public function create()
    {
        super.create();

        LevelData.loadPlayers();

        // Loading music BPM
        try {
            var newBPM:String = CoolUtil.coolTextFile(Paths.getSharedPath('music/stayFunky_bpm.txt'))[0]; // l o l
            if (newBPM != null && newBPM.length > 0) Conductor.bpm = Std.parseFloat(newBPM);
        } catch(e:haxe.Exception) trace("ERROR WHILE LOADING BPM: " + e);

        var bg:FlxSprite = new FlxSprite(-153, -140);
        bg.loadGraphic(Paths.image('charSelect/charSelectBG'));
        bg.scrollFactor.set(0.1, 0.1);
        bg.antialiasing = (ClientPrefs.data.antialiasing);
        add(bg);

        var crowd:_AnimateHelper = new _AnimateHelper(0, 0, "charSelect/crowd", 0.3);
        add(crowd);

        var stageSpr:FlxSprite = new FlxSprite(-40, 391);
        stageSpr.frames = Paths.getSparrowAtlas("charSelect/charSelectStage");
        stageSpr.animation.addByPrefix("idle", "stage full instance 1", 24, true);
        stageSpr.animation.play("idle");
        stageSpr.antialiasing = (ClientPrefs.data.antialiasing);
        add(stageSpr);

        var curtains:FlxSprite = new FlxSprite(-47, -49);
        curtains.loadGraphic(Paths.image('charSelect/curtains'));
        curtains.scrollFactor.set(1.4, 1.4);
        curtains.antialiasing = (ClientPrefs.data.antialiasing);
        add(curtains);

        barthing = new _AnimateHelper(0, 0, "charSelect/barThing", 0);
        add(barthing);
        barthing.blend = BlendMode.MULTIPLY;
        barthing.y += 80;
        FlxTween.tween(barthing, {y: barthing.y - 80}, 1.3, {ease: FlxEase.expoOut});

        var charLight:FlxSprite = new FlxSprite(800, 250);
        charLight.loadGraphic(Paths.image('charSelect/charLight'));
        charLight.antialiasing = (ClientPrefs.data.antialiasing);
        add(charLight);

        var charLightGF:FlxSprite = new FlxSprite(180, 240);
        charLightGF.loadGraphic(Paths.image('charSelect/charLight'));
        charLightGF.antialiasing = (ClientPrefs.data.antialiasing);
        add(charLightGF);

        playerChill = new SelectionPlayer(620, 380, "bf");
        add(playerChill);

        gfChill = new SelectionCharacter(620, 380 , playerChill.speaker);
        add(gfChill);

        /*playerChillOut = new SelectionPlayer(0, 0, "bf");
        playerChillOut.visible = false;
        add(playerChillOut);*/

        speakers = new FlxAnimate(0, 0);
        Paths.loadAnimateAtlas(speakers, "charSelect/charSelectSpeakers");
        speakers.antialiasing = (ClientPrefs.data.antialiasing);
        add(speakers);

        var fgBlur:FlxSprite = new FlxSprite(-125, 170);
        fgBlur.loadGraphic(Paths.image('charSelect/foregroundBlur'));
        fgBlur.blend = openfl.display.BlendMode.MULTIPLY;
        fgBlur.antialiasing = (ClientPrefs.data.antialiasing);
        add(fgBlur);

        dipshitBlur = new FlxSprite(419, -65);
        dipshitBlur.frames = Paths.getSparrowAtlas("charSelect/dipshitBlur");
        dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical offset instance 1", 24, true);
        dipshitBlur.blend = BlendMode.ADD;
        dipshitBlur.animation.play("idle");
        dipshitBlur.antialiasing = (ClientPrefs.data.antialiasing);
        add(dipshitBlur);

        dipshitBacking = new FlxSprite(423, -17);
        dipshitBacking.frames = Paths.getSparrowAtlas("charSelect/dipshitBacking");
        dipshitBacking.animation.addByPrefix('idle', "CHOOSE horizontal offset instance 1", 24, true);
        dipshitBacking.blend = BlendMode.ADD;
        dipshitBacking.animation.play("idle");
        dipshitBacking.antialiasing = (ClientPrefs.data.antialiasing);
        add(dipshitBacking);
        dipshitBacking.y += 210;
        FlxTween.tween(dipshitBacking, {y: dipshitBacking.y - 210}, 1.1, {ease: FlxEase.expoOut});

        chooseDipshit = new FlxSprite(426, -13);
        chooseDipshit.loadGraphic(Paths.image('charSelect/chooseDipshit'));
        chooseDipshit.antialiasing = (ClientPrefs.data.antialiasing);
        add(chooseDipshit);

        chooseDipshit.y += 200;
        FlxTween.tween(chooseDipshit, {y: chooseDipshit.y - 200}, 1, {ease: FlxEase.expoOut});

        dipshitBlur.y += 220;
        FlxTween.tween(dipshitBlur, {y: dipshitBlur.y - 220}, 1.2, {ease: FlxEase.expoOut});

        chooseDipshit.scrollFactor.set();
        dipshitBacking.scrollFactor.set();
        dipshitBlur.scrollFactor.set();

        nametag = new PlayerNameTag(FreeplayState.DEF_PLAYER);
        add(nametag);
        nametag.scrollFactor.set();
        curChar = FreeplayState.DEF_PLAYER;

        grpCursors = new FlxTypedGroup<FlxSprite>();
        add(grpCursors);

        cursor = new FlxSprite(0, 0);
        cursor.loadGraphic(Paths.image('charSelect/charSelector'));
        cursor.color = 0xFFFFFF00;

        cursorBlue = new FlxSprite(0, 0);
        cursorBlue.loadGraphic(Paths.image('charSelect/charSelector'));
        cursorBlue.color = 0xFF3EBBFF;

        cursorDarkBlue = new FlxSprite(0, 0);
        cursorDarkBlue.loadGraphic(Paths.image('charSelect/charSelector'));
        cursorDarkBlue.color = 0xFF3C74F7;

        cursorBlue.blend = BlendMode.SCREEN;
        cursorDarkBlue.blend = BlendMode.SCREEN;

        cursorConfirmed = new FlxSprite(0, 0);
        cursorConfirmed.scrollFactor.set();
        cursorConfirmed.frames = Paths.getSparrowAtlas("charSelect/charSelectorConfirm");
        cursorConfirmed.animation.addByPrefix("idle", "cursor ACCEPTED instance 1", 24, true);
        cursorConfirmed.visible = false;
        add(cursorConfirmed);

        cursorDenied = new FlxSprite(0, 0);
        cursorDenied.scrollFactor.set();
        cursorDenied.frames = Paths.getSparrowAtlas("charSelect/charSelectorDenied");
        cursorDenied.animation.addByPrefix("idle", "cursor DENIED instance 1", 24, false);
        cursorDenied.visible = false;
        add(cursorDenied);

        grpCursors.add(cursorDarkBlue);
        grpCursors.add(cursorBlue);
        grpCursors.add(cursor);

        grpCursors.forEach(function(c) c.antialiasing = (ClientPrefs.data.antialiasing));

        // Sound shits
        selectSound = new FlxSound();
        selectSound.loadEmbedded(Paths.sound('playerSelect/CS_select'));
        selectSound.pitch = 1;
        selectSound.volume = 0.7;

        FlxG.sound.defaultSoundGroup.add(selectSound);
        FlxG.sound.list.add(selectSound);

        unlockSound = new FlxSound();
        unlockSound.loadEmbedded(Paths.sound('playerSelect/CS_unlock'));
        unlockSound.pitch = 1;
        unlockSound.volume = 0;
        unlockSound.play(true);

        FlxG.sound.defaultSoundGroup.add(unlockSound);
        FlxG.sound.list.add(unlockSound);

        lockedSound = new FlxSound();
        lockedSound.loadEmbedded(Paths.sound('playerSelect/CS_locked'));
        lockedSound.pitch = 1;

        lockedSound.volume = 1.;

        FlxG.sound.defaultSoundGroup.add(lockedSound);
        FlxG.sound.list.add(lockedSound);

        staticSound = new FlxSound();
        staticSound.loadEmbedded(Paths.sound('playerSelect/static loop'));
        staticSound.pitch = 1;

        staticSound.looped = true;

        staticSound.volume = 0.6;

        FlxG.sound.defaultSoundGroup.add(staticSound);
        FlxG.sound.list.add(staticSound);

        // playing it here to preload it. not doing this makes a super awkward pause at the end of the intro
        // -- Uhhh dude there are another ways, but heh
        FlxG.sound.playMusic(Paths.music('stayFunky'), 1);
        initIcons();

        try {
            for (member in grpIcons.members) {
                member.y += 300;
                FlxTween.tween(member, {y: member.y - 300}, 1, {ease: FlxEase.expoOut});
            }
        }
        catch(e:haxe.Exception) {};

        cursor.scrollFactor.set();
        cursorBlue.scrollFactor.set();
        cursorDarkBlue.scrollFactor.set();

        FlxTween.color(cursor, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: PINGPONG});

        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        camFollow.screenCenter();

        FlxG.camera.follow(camFollow, LOCKON, 0.01);

        /*var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
        FlxG.camera.filters = [fadeShaderFilter];*/
    }

    override public function update(elapsed:Float)
    {
        var lerpAmnt:Float = 0.95;

        // Without this shit the BeatHit doesn't work! (it was obvious, but, i'm dumb)
        if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);

        // TEST FUNCTION!
        if (FlxG.keys.justPressed.SEVEN) MusicBeatState.switchState(new PlayerEditorState());

        if (controls.UI_UP_R || controls.UI_DOWN_R || controls.UI_LEFT_R || controls.UI_RIGHT_R) selectSound.pitch = 1;

        syncAudio(elapsed);

        if (allowInput && !pressedSelect)
        {
            if (controls.UI_UP) holdTmrUp += elapsed;
            if (controls.UI_UP_R)
            {
                holdTmrUp = 0;
                spamUp = false;
            }

            if (controls.UI_DOWN) holdTmrDown += elapsed;
            if (controls.UI_DOWN_R)
            {
                holdTmrDown = 0;
                spamDown = false;
            }

            if (controls.UI_LEFT) holdTmrLeft += elapsed;
            if (controls.UI_LEFT_R)
            {
                holdTmrLeft = 0;
                spamLeft = false;
            }

            if (controls.UI_RIGHT) holdTmrRight += elapsed;
            if (controls.UI_RIGHT_R)
            {
                holdTmrRight = 0;
                spamRight = false;
            }

            var initSpam = 0.5;

            if (holdTmrUp >= initSpam) spamUp = true;
            if (holdTmrDown >= initSpam) spamDown = true;
            if (holdTmrLeft >= initSpam) spamLeft = true;
            if (holdTmrRight >= initSpam) spamRight = true;

            if (controls.UI_UP_P)
            {
                cursorY -= 1;
                cursorDenied.visible = false;

                holdTmrUp = 0;

                selectSound.play(true);
            }
            if (controls.UI_DOWN_P)
            {
                cursorY += 1;
                cursorDenied.visible = false;
                holdTmrDown = 0;
                selectSound.play(true);
            }
            if (controls.UI_LEFT_P)
            {
                cursorX -= 1;
                cursorDenied.visible = false;

                holdTmrLeft = 0;
                selectSound.play(true);
            }
            if (controls.UI_RIGHT_P)
            {
                cursorX += 1;
                cursorDenied.visible = false;
                holdTmrRight = 0;
                selectSound.play(true);
            }
        }

        if (cursorX < -1) cursorX = 1;
        if (cursorX > 1) cursorX = -1;
        if (cursorY < -1) cursorY = 1;
        if (cursorY > 1) cursorY = -1;

        curChar = gridPlayersList[getCurrentSelected()][0];

        grpIcons.forEach(function(i)
            i.focused = (i.index == getCurrentSelected())
        );

        if (allowInput && !pressedSelect && controls.ACCEPT)
        {
            spamUp = false;
            spamDown = false;
            spamLeft = false;
            spamRight = false;

            acceptEvent();
        }

        if (allowInput && pressedSelect && controls.BACK)
        {
            cursorConfirmed.visible = false;
            grpCursors.visible = true;
            grpIcons.members[getCurrentSelected()].playAnimation(false);

            FlxTween.globalManager.cancelTweensOf(FlxG.sound.music);
            FlxTween.tween(FlxG.sound.music, {pitch: 1.0, volume: 1.0}, 1, {ease: FlxEase.quartInOut});
            playerChill.playAnim("bruh");
            gfChill.playAnim("bruh");
            pressedSelect = false;
            FlxTween.tween(FlxG.sound.music, {pitch: 1.0}, 1,
            {
                ease: FlxEase.quartInOut,
                onComplete: function(twn:FlxTween) {
                    playerChill.playAnim("idle", true);
                    gfChill.playAnim("idle", true);
                    notBeat = false;
                }
            });
            selectTimer.cancel();
        }/*
        else
        {
            curChar = "locked";

            gfChill.visible = false;

            if (allowInput && controls.ACCEPT)
            {
                cursorDenied.visible = true;

                playerChill.playAnim("cannot select Label", true);

                lockedSound.play(true);
                cursorDenied.animation.play("idle", true);
                cursorDenied.animation.finishCallback = (_) -> {
                cursorDenied.visible = false;
                };
            }
        }*/

        camFollow.screenCenter();
        camFollow.x += cursorX * 10;
        camFollow.y += cursorY * 10;

        cursorLocIntended.x = (cursorFactor * cursorX) + (FlxG.width / 2) - cursor.width / 2;
        cursorLocIntended.y = (cursorFactor * cursorY) + (FlxG.height / 2) - cursor.height / 2;

        cursorLocIntended.x += cursorOffsetX;
        cursorLocIntended.y += cursorOffsetY;

        cursor.x = smoothLerp(cursor.x, cursorLocIntended.x, elapsed, 0.1);
        cursor.y = smoothLerp(cursor.y, cursorLocIntended.y, elapsed, 0.1);

        cursorBlue.x = coolLerp(cursorBlue.x, cursor.x, lerpAmnt * 0.4);
        cursorBlue.y = coolLerp(cursorBlue.y, cursor.y, lerpAmnt * 0.4);

        cursorDarkBlue.x = coolLerp(cursorDarkBlue.x, cursorLocIntended.x, lerpAmnt * 0.2);
        cursorDarkBlue.y = coolLerp(cursorDarkBlue.y, cursorLocIntended.y, lerpAmnt * 0.2);

        cursorConfirmed.x = cursor.x - 2;
        cursorConfirmed.y = cursor.y - 4;

        cursorDenied.x = cursor.x - 2;
        cursorDenied.y = cursor.y - 4;
    }

    function acceptEvent() {
        if (curChar == "locked") {
            //playerChill.playAnimation("cannot select Label", true);
            cursorDenied.visible = true;
            cursorDenied.animation.play("idle", true);

            grpIcons.members[getCurrentSelected()]._lock.playAnimation("clicked", true);
            lockedSound.play(true);

            cursorDenied.animation.finishCallback = (_) -> {
                cursorDenied.visible = false;
            };
            return;
        }
        notBeat = true;
        cursorConfirmed.visible = true;
        cursorConfirmed.animation.play("idle", true);

        grpCursors.visible = false;

        FlxG.sound.play(Paths.sound('playerSelect/CS_confirm'));
        grpIcons.members[getCurrentSelected()].playAnimation(true);

        FlxTween.tween(FlxG.sound.music, {pitch: 0.1}, 1, {ease: FlxEase.quadInOut});
        FlxTween.tween(FlxG.sound.music, {volume: 0.0}, 1.5, {ease: FlxEase.quadInOut});
        playerChill.playAnim("ready", true);
        gfChill.playAnim("ready", true);
        pressedSelect = true;
        FreeplayState.player = curChar;
        selectTimer.start(1.5, (_) -> {
            // For now, no animations or something like that
            MusicBeatState.switchState(new FreeplayState());
        });
    }

	override function beatHit()
    {
        super.beatHit();

    if (!notBeat) {
        playerChill.dance();
        gfChill.dance();
    }
        speakers.anim.play("", true); // Speakers Beat
    }

    override function destroy():Void
    {
        FlxG.sound.playMusic(Paths.music('freakyMenu'));
        super.destroy();
    }

    function getCurrentSelected():Int
    {
        var tempX:Int = cursorX + 1;
        var tempY:Int = cursorY + 1;
        var gridPosition:Int = tempX + tempY * 3;
        return gridPosition;
    }

    var iconArr:Array<PlayerIcon> = [];
    var gridPlayersList:Array<Dynamic> = [];
    var grpLocks:FlxTypedSpriteGroup<Lock>;
    function initIcons() 
    { // For now generates only 9, but soon it'll be more :3, maybe-
        grpIcons = new FlxTypedSpriteGroup<PlayerIcon>();
        add(grpIcons);

        grpLocks = new FlxTypedSpriteGroup<Lock>();
        add(grpLocks);

        var indexes:Array<Int> = [];

		for (a in LevelData.playersList) indexes.push(a[1]); // Pushes all the indexes

        for (e in 0...9) {
            // if the index doesn't have a player, then sets to locked
            if(!indexes.contains(e)) gridPlayersList.push(["locked", e]);
            else 
            {
                for (i in LevelData.playersList) { // Getting player from index :u
                    if (i[1] == e) {
                        gridPlayersList.push([i[0], e]);
                        break;
                    }
                }
            }
        }

        for (player in gridPlayersList) {
            var char = player[0];
            var temp:PlayerIcon = new PlayerIcon(0, 0, (char == "locked") ? FreeplayState.DEF_PLAYER : char, player[1], (char == "locked"));
            temp.ID = 0;
            temp._lock.ID = 0;
            grpIcons.add(temp);
            grpLocks.add(temp._lock);
        }

        updateIconPositions();
        grpIcons.scrollFactor.set();
        grpLocks.scrollFactor.set();
        trace(gridPlayersList);
    }

    function updateIconPositions()
    {
        grpIcons.x = 450;
        grpIcons.y = 120;
        for (index => member in grpIcons.members)
        {
            var posX:Float = (index % 3);
            var posY:Float = Math.floor(index / 3);

            member.x = posX * grpXSpread;
            member.y = posY * grpYSpread;

            member.x += grpIcons.x;
            member.y += grpIcons.y;
        }
        for (index => member in grpLocks.members)
        {
            var posX:Float = (index % 3);
            var posY:Float = Math.floor(index / 3);

            member.x = posX * grpXSpread;
            member.y = posY * grpYSpread;

            member.x += grpIcons.x;
            member.y += grpIcons.y;
        }
    }

    function syncAudio(elapsed:Float):Void
    {
        @:privateAccess
        if (sync && unlockSound.time > 0)
        {
            //playerChillOut.anim._tick = 0;
            if (syncLock != null) syncLock.anim._tick = 0;

            if ((unlockSound.time - audioBizz) >= ((delay) * 100))
            {
                if (syncLock != null) syncLock.anim._tick = delay;

                //playerChillOut.anim._tick = delay;
                audioBizz += delay * 100;
            }
        }
    }

    function set_curChar(value:String):String
    {
        if (curChar == value) return value;

        curChar = value;

        if (staticSound != null) {
            if (value == "locked") staticSound.play();
            else staticSound.stop();
        }

        nametag.switchChar(value);
        /*
        gfChill.visible = false;
        playerChill.visible = false;
        playerChillOut.visible = true;
        playerChillOut.playAnimation("slideout");
        var index = playerChillOut.anim.getFrameLabel("slideout").index;
        playerChillOut.onAnimationFrame.removeAll();
        playerChillOut.onAnimationFrame.add((_, frame:Int) -> {
            if (frame >= index + 1)
            {
            playerChill.visible = true;
            playerChill.switchChar(value);
            gfChill.switchGF(value);
            gfChill.visible = true;
            }
            if (frame >= index + 2)
            {
            playerChillOut.switchChar(value);
            playerChillOut.visible = false;
            playerChillOut.onAnimationFrame.removeAll();
            }
        });*/

        return value;
    }

    function coolLerp(base:Float, target:Float, ratio:Float):Float
    {
        return base + cameraLerp(ratio) * (target - base);
    }

    function cameraLerp(lerp:Float):Float
    {
        return lerp * (FlxG.elapsed / (1 / 60));
    }

    function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
    {
        if (current == target) return target;
        var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));
        if (Math.abs(result - target) < (precision * target)) result = target;
        return result;
    }

    function lerp(base:Float, target:Float, progress:Float):Float
    {
        return base + progress * (target - base);
    }

    function set_grpXSpread(value:Float):Float
    {
        grpXSpread = value;
        updateIconPositions();
        return value;
    }

    function set_grpYSpread(value:Float):Float
    {
        grpYSpread = value;
        updateIconPositions();
        return value;
    }
}