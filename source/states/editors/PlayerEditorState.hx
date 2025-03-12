package states.editors;

import states.editors.content.PsychJsonPrinter;
import haxe.Json;
import flixel.util.FlxDestroyUtil;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.utils.Assets;
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

    var charName(default, set):String = "bf";

    var unsavedProgress:Bool = false;
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
	var UI_box:PsychUIBox;
	var camHUD:FlxCamera;
	var imageInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var noAntialiasingCheckBox:PsychUICheckBox;
	var flipXCheckBox:PsychUICheckBox;
    var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionIconXStepper:PsychUINumericStepper;
	var positionIconYStepper:PsychUINumericStepper;
	var playerInputText:PsychUIInputText;

    override public function create()
    {
        super.create();

        camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

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

        addCharacter();
        /*playerChill = new SelectionPlayer(620, 380, "bf");
        add(playerChill);*/

        gfChill = new SelectionCharacter(620, 380 , playerChill.speaker);
        add(gfChill);

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
        updateIconOffsets();

        try {
            grpIcons.y += 300;
            FlxTween.tween(grpIcons, {y: grpIcons.y - 300}, 1, {ease: FlxEase.expoOut});
        }
        catch(e:haxe.Exception) {};

        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);
        camFollow.screenCenter();

        FlxG.camera.follow(camFollow, LOCKON, 0.01);

        FlxG.mouse.visible = true;
        makeUIMenu();

        /*var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
        FlxG.camera.filters = [fadeShaderFilter];*/
    }

    function addCharacter(?reload:Bool = false)
    {
        var pos:Int = -1;
        if(playerChill != null)
        {
            pos = members.indexOf(playerChill);
            remove(playerChill);
            playerChill.destroy();
        }

        playerChill = new SelectionPlayer(620, 380, charName);
        playerChill.debugMode = true;
        //playerChill.missingCharacter = false;

        if(pos > -1) insert(pos, playerChill);
        else add(playerChill);
        updateCharacterPositions();
        if (reload) updateIconOffsets();
        //reloadAnimList();
    }

    function makeUIMenu()
    {
        UI_box = new PsychUIBox(FlxG.width - 375, 155, 350, 280, ['Animations', 'Character']);
        UI_box.scrollFactor.set();
        UI_box.cameras = [camHUD];
        add(UI_box);
/*
        addGhostUI();
        addSettingsUI();
        addAnimationsUI();*/
        addCharacterUI();

        //UI_box.selectedName = 'Settings';
        UI_box.selectedName = 'Character';
    }

    function addCharacterUI()
    {
        var tab_group = UI_box.getTab('Character').menu;

        imageInputText = new PsychUIInputText(15, 30, 200, playerChill.image, 8);
        var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
        {
            var lastAnim = playerChill.getAnimationName();
            playerChill.image = imageInputText.text;
            //reloadCharacterImage();
            if(!playerChill.isAnimationNull()) {
                playerChill.playAnim(lastAnim, true);
            }
        });

        flipXCheckBox = new PsychUICheckBox(15, reloadImage.y + 40, "Flip X", 50);
        flipXCheckBox.checked = playerChill.flipX;
        flipXCheckBox.onClick = function() {
            playerChill.flipX = flipXCheckBox.checked;
        };

        noAntialiasingCheckBox = new PsychUICheckBox(flipXCheckBox.x + 80, flipXCheckBox.y, "No Antialiasing", 80);
        noAntialiasingCheckBox.checked = playerChill.noAntialiasing;
        noAntialiasingCheckBox.onClick = function() {
            playerChill.antialiasing = false;
            if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
                playerChill.antialiasing = true;
            }
            playerChill.noAntialiasing = noAntialiasingCheckBox.checked;
        };

        scaleStepper = new PsychUINumericStepper(noAntialiasingCheckBox.x, flipXCheckBox.y + 40, 0.1, 1, 0.05, 10, 2);

        positionXStepper = new PsychUINumericStepper(noAntialiasingCheckBox.x + 110, noAntialiasingCheckBox.y, 10, playerChill.positionArray[0], -9000, 9000, 0);
        positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, playerChill.positionArray[1], -9000, 9000, 0);

        positionIconXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, playerChill.iconPositionArray[0], -9000, 9000, 0);
        positionIconYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, playerChill.iconPositionArray[1], -9000, 9000, 0);

        var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, scaleStepper.y + 40, "Save Character", function() {
            savePlayer();
        });

        playerInputText = new PsychUIInputText(flipXCheckBox.x, saveCharacterButton.y, 200, playerChill.charName, 8);

        tab_group.add(new FlxText(imageInputText.x, imageInputText.y - 18, 100, 'Image file name:'));
        tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 100, 'Scale:'));
        tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
        tab_group.add(new FlxText(positionIconXStepper.x, positionIconXStepper.y - 18, 100, 'Icon X/Y:'));
        tab_group.add(new FlxText(playerInputText.x, playerInputText.y - 18, 100, 'Player name (for Editor):'));
        tab_group.add(imageInputText);
        tab_group.add(reloadImage);
        tab_group.add(scaleStepper);
        tab_group.add(flipXCheckBox);
        tab_group.add(noAntialiasingCheckBox);
        tab_group.add(positionXStepper);
        tab_group.add(positionYStepper);
        tab_group.add(positionIconXStepper);
        tab_group.add(positionIconYStepper);
        tab_group.add(saveCharacterButton);
        tab_group.add(playerInputText);

        reloadCharacterOptions();
    }

    override public function update(elapsed:Float)
    {
        // Without this shit the BeatHit doesn't work! (it was obvious, but, i'm dumb)
        if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);

        if (FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
        else if (FlxG.keys.pressed.E) FlxG.camera.zoom += elapsed * FlxG.camera.zoom * 1.2;
        else if (FlxG.keys.pressed.Q) FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * 1.2;

        if (FlxG.keys.pressed.A) FlxG.camera.scroll.x -= elapsed * 600;
        if (FlxG.keys.pressed.D) FlxG.camera.scroll.x += elapsed * 600;	

        if (FlxG.keys.pressed.S) FlxG.camera.scroll.y += elapsed * 600;
        if (FlxG.keys.pressed.W) FlxG.camera.scroll.y -= elapsed * 600;


        if (FlxG.keys.justPressed.P) INDEX++;
        if (FlxG.keys.justPressed.M) INDEX--;

        //if (FlxG.keys.justPressed.Q) charName = "bf";
       // if (FlxG.keys.justPressed.W) charName = "pico";

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
            else gridPlayersList.push([charName, e]);
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

    public function UIEvent(id:String, sender:Dynamic) {
        if(id == PsychUINumericStepper.CHANGE_EVENT)
        {
            if (sender == scaleStepper)
            {
                //reloadCharacterImage();
                playerChill.jsonScale = sender.value;
                playerChill.scale.set(playerChill.jsonScale, playerChill.jsonScale);
                playerChill.updateHitbox();
                unsavedProgress = true;
            }
            else if(sender == positionXStepper)
            {
                playerChill.positionArray[0] = positionXStepper.value;
                updateCharacterPositions();
                unsavedProgress = true;
            }
            else if(sender == positionYStepper)
            {
                playerChill.positionArray[1] = positionYStepper.value;
                updateCharacterPositions();
                unsavedProgress = true;
            }
            else if(sender == positionIconXStepper)
            {
                playerChill.iconPositionArray[0] = positionIconXStepper.value;
                updateIconOffsets();
                //trace(playerChill.iconPositionArray);
                unsavedProgress = true;
            }
            else if(sender == positionIconYStepper)
            {
                playerChill.iconPositionArray[1] = positionIconYStepper.value;
                updateIconOffsets();
                //trace(playerChill.iconPositionArray);
                unsavedProgress = true;
            }
        }
        else if(id == PsychUIInputText.CHANGE_EVENT)
        {
            if (sender == playerInputText) {
                playerInputText.text = playerChill.charName;
            }
        }
    }

    function reloadCharacterImage()
    {
        var lastAnim:String = playerChill.getAnimationName();

        var lastAnims = playerChill.playerAnimArr.copy();
        playerChill.atlas = FlxDestroyUtil.destroy(playerChill.atlas);
        playerChill.isAnimateAtlas = false;
        playerChill.color = FlxColor.WHITE;
        playerChill.alpha = 1;

        playerChill.loadImage(playerChill.image, playerChill.x, playerChill.y);
        playerChill.loadAnimations(lastAnims);
    }

    inline function updateCharacterPositions()
    {
        playerChill.x = playerChill.staticX + playerChill.positionArray[0];
        playerChill.y = playerChill.staticY + playerChill.positionArray[1];
    }

    inline function updateIconOffsets()
    {
        if (playerChill.iconPositionArray == null || playerChill.iconPositionArray == []) return;

        for (icon in grpIcons) {
            icon.offset.set(playerChill.iconPositionArray[0], playerChill.iconPositionArray[1]);
        }
    }

    public function reloadIcons() {
        gridPlayersList = [];
        for (e in 0...9) {
            if(INDEX != e) gridPlayersList.push(["locked", e]);
            else gridPlayersList.push([charName, e]);
        }

        for (icon in grpIcons) {
            if (icon.index != INDEX) icon.locked = true;
            else {
                icon.setPlayer(charName);
                icon.locked = false;
                updateIconOffsets();
            }
        }
    }

	function reloadCharacterOptions() {
		if(UI_box == null) return;

		imageInputText.text = playerChill.image;
        playerInputText.text = playerChill.charName;
		scaleStepper.value = playerChill.jsonScale;
		flipXCheckBox.checked = playerChill.flipX;
		noAntialiasingCheckBox.checked = playerChill.noAntialiasing;
		positionXStepper.value = playerChill.positionArray[0];
		positionYStepper.value = playerChill.positionArray[1];
		positionIconXStepper.value = playerChill.iconPositionArray[0];
		positionIconYStepper.value = playerChill.iconPositionArray[1];
	}

    var _file:FileReference;
    function onSaveComplete(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved file.");
    }

    /**
     * Called when the save file dialog is cancelled.
     */
    function onSaveCancel(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    /**
     * Called if there is an error while saving the gameplay recording.
     */
    function onSaveError(_):Void
    {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving file");
    }

    
    function savePlayer()
    {
        var json:Dynamic = {
			//"animations": playerChill.animationsArray,
            "twoBeatIdle": playerChill.twoBeatIdle,
			"image": playerChill.image,
			"scale": playerChill.jsonScale,
			//"sing_duration": playerChill.singDuration,
			//"healthicon": playerChill.healthIcon,

			"position":	playerChill.positionArray,
			//"camera_position": playerChill.cameraPosition,

			"flip_x": playerChill.flipX,
			"no_antialiasing": playerChill.noAntialiasing,
			//"healthbar_colors": playerChill.healthColorArray,
			"speaker": playerChill.speaker,
			"icon_position": playerChill.iconPositionArray,
			"editor_player": playerChill.isPlayer
		};

		var data:String = PsychJsonPrinter.print(json, ['position','icon_position']);
        var _player = playerChill.charName;

		if (data.length > 0)
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, _player + ".json");
        }
    }

    function set_INDEX(value:Int):Int {
        INDEX = value;
        reloadIcons();
        return (value);
    }

    function set_charName(value:String):String {
        charName = value;
        reloadIcons();
        return (value);
    }
}