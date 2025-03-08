package states.editors;

import objects.SelectionPlayer;
import objects.SelectionCharacter;
import objects.PlayerIcon;
import backend.LevelData;
import objects.PlayerIcon.Lock;
import flixel.FlxObject;
import objects.PlayerNameTag;
import flxanimate.PsychFlxAnimate._AnimateHelper;
import openfl.display.BlendMode;

class PlayerEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent {

    var CHARACTER(default, set):String = "bf";
    var INDEX(default, set):Int = 4;
    var speakers:FlxAnimate;

    var barthing:_AnimateHelper;
	var dipshitBlur:FlxSprite;
	var dipshitBacking:FlxSprite;
	var chooseDipshit:FlxSprite;

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

    var curChar(default, set):String = FreeplayState.DEF_PLAYER;
	var gfChill:SelectionCharacter;
    var playerChill:SelectionPlayer;
    var playerChillOut:SelectionPlayer;

    var notBeat:Bool = false;
	var grpIcons:FlxTypedSpriteGroup<PlayerIcon>;

    override public function create()
    {
        super.create();

        LevelData.loadPlayers();

        // Loading music BPM
        try {
            var newBPM:String = CoolUtil.coolTextFile(Paths.getSharedPath('music/stayFunky_bpm.txt'))[0]; // l o l
            if (newBPM != null && newBPM.length > 0) Conductor.bpm = Std.parseFloat(newBPM);
            //trace(newBPM);
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
/*
        playerChill = new SelectionPlayer(620, 380, "bf");
        add(playerChill);

        gfChill = new SelectionCharacter(620, 380 , playerChill.speaker);
        add(gfChill);*/

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

        FlxG.sound.playMusic(Paths.music('stayFunky'), 0);
        initIcons();

        try {
            grpIcons.y += 300;
            FlxTween.tween(grpIcons, {y: grpIcons.y - 300}, 1, {ease: FlxEase.expoOut});
        }
        catch(e:haxe.Exception) {};

        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        camFollow.screenCenter();

        FlxG.camera.follow(camFollow, LOCKON, 0.01);

        /*var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
        FlxG.camera.filters = [fadeShaderFilter];*/
    }

    override public function update(elapsed:Float)
    {
        // Without this shit the BeatHit doesn't work! (it was obvious, but, i'm dumb)
        if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);

        if (FlxG.keys.justPressed.P) INDEX++;
        if (FlxG.keys.justPressed.M) INDEX--;

        if (FlxG.keys.justPressed.Q) CHARACTER = "bf";
        if (FlxG.keys.justPressed.W) CHARACTER = "pico";

        if (FlxG.keys.justPressed.ESCAPE) MusicBeatState.switchState(new PlayerSelectionState());

        if (INDEX > 8) INDEX = 0;
        if (INDEX < 0) INDEX = 8;
        curChar = gridPlayersList[INDEX][0];

        //camFollow.screenCenter();
        /*
        camFollow.x += cursorX * 10;
        camFollow.y += cursorY * 10;*/
    }

	override function beatHit()
    {
        super.beatHit();
        speakers.anim.play("", true); // Speakers Beat
    }

    override function destroy():Void
    {
        super.destroy();
    }

    var gridPlayersList:Array<Dynamic> = [];
    var grpLocks:FlxTypedSpriteGroup<Lock>;
    function initIcons() 
    {
        grpIcons = new FlxTypedSpriteGroup<PlayerIcon>();
        add(grpIcons);

        grpLocks = new FlxTypedSpriteGroup<Lock>();
        add(grpLocks);

        var index:Int = INDEX; // There will be only one player

        for (e in 0...9) {
            if(index != e) gridPlayersList.push(["locked", e]);
            else gridPlayersList.push([CHARACTER, e]);
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

    function set_curChar(value:String):String
    {
        if (curChar == value) return value;

        curChar = value;

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

    public function UIEvent(id:String, sender:Dynamic) {}

    public function reloadIcons() {
        gridPlayersList = [];
        for (e in 0...9) {
            if(INDEX != e) gridPlayersList.push(["locked", e]);
            else gridPlayersList.push([CHARACTER, e]);
        }

        for (icon in grpIcons) {
            if (icon.index != INDEX) icon.locked = true;
            else {
                icon.setPlayer(CHARACTER);
                icon.locked = false;
            }
        }
    }

    function set_INDEX(value:Int):Int {
        INDEX = value;
        reloadIcons();
        return (value);
    }

    function set_CHARACTER(value:String):String {
        CHARACTER = value;
        reloadIcons();
        return (value);
    }
}