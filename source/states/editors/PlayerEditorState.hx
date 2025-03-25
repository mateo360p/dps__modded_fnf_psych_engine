package states.editors;

import funkin.vis.dsp.SpectralAnalyzer;
import states.editors.content.Prompt;
import states.editors.content.Prompt.ExitConfirmationPrompt;
import objects.Character;
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
    var ghost:FlxSprite;
	var animateGhost:FlxAnimate;
	var animateGhostImage:String;
    var copiedOffset:Array<Float> = [0, 0];
	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	var undoOffsets:Array<Float> = null;

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;
	var cameraZoomText:FlxText;
	var frameAdvanceText:FlxText;

    var selectedFormat:FlxTextFormat = new FlxTextFormat(FlxColor.LIME);
    var unsavedProgress:Bool = false;
    var anims:Array<AnimArray> = null;
	var animsTxt:FlxText;
	var curAnim = 0;

    var INDEX(default, set):Int = 4;
    var speakers:FlxAnimate;

    var barthing:_AnimateHelper;
	var dipshitBlur:FlxSprite;
	var dipshitBacking:FlxSprite;
	var chooseDipshit:FlxSprite;

	var nametag:PlayerNameTag;
	var camFollow:FlxObject;
    var charDropDown:PsychUIDropDownMenu;

    var grpXSpread(default, set):Float = 107;
    var grpYSpread(default, set):Float = 127;

	var gfChill:SelectionCharacter;
    var playerChill:SelectionPlayer;
    var playerChillOut:SelectionPlayer;

    var notBeat:Bool = false;
	var grpIcons:FlxTypedSpriteGroup<PlayerIcon>;

	var camHUD:FlxCamera;
	var imageInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var noAntialiasingCheckBox:PsychUICheckBox;
	var flipXCheckBox:PsychUICheckBox;
    var positionXStepper:PsychUINumericStepper;
	var positionYStepper:PsychUINumericStepper;
	var positionIconXStepper:PsychUINumericStepper;
	var positionIconYStepper:PsychUINumericStepper;
	var speakerNameInputText:PsychUIInputText;
	var characterNameInputText:PsychUIInputText;
	var reloadSpeakerButton:PsychUIButton;
	var reloadAssetsButton:PsychUIButton;

	var UIGhost_box:PsychUIBox;
    var UI_box:PsychUIBox;
    var curChar:String;
    var goToSelector:Bool;

    public function new(?char:String = null, ?goToSelector:Bool = true)
    {
        this.curChar = char;
        this.goToSelector = goToSelector;

        super();
    }

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

		ghost = new FlxSprite();
		ghost.visible = false;
		ghost.alpha = ghostAlpha;
		add(ghost);

        animsTxt = new FlxText(10, 32, 400, '');
		animsTxt.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
		animsTxt.scrollFactor.set();
		animsTxt.borderSize = 1;
		animsTxt.cameras = [camHUD];
        add(animsTxt);

        addCharacter(false, curChar);

        gfChill = new SelectionCharacter(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1], playerChill.speaker);
        add(gfChill);

        gfChill.x += gfChill.positionArray[0];
        gfChill.y += gfChill.positionArray[1];

        // Unused
        @:privateAccess
        gfChill.analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
        #if desktop
        @:privateAccess
        gfChill.analyzer.fftN = 512;
        #end

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

        nametag = new PlayerNameTag(Character.DEFAULT_CHARACTER);
        add(nametag);
        nametag.scrollFactor.set();

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
		cameraZoomText = new FlxText(0, 50, 200, 'Zoom: 1x');
		cameraZoomText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		cameraZoomText.scrollFactor.set();
		cameraZoomText.borderSize = 1;
		cameraZoomText.screenCenter(X);
		cameraZoomText.cameras = [camHUD];
		add(cameraZoomText);

		frameAdvanceText = new FlxText(0, 75, 350, '');
		frameAdvanceText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		frameAdvanceText.scrollFactor.set();
		frameAdvanceText.borderSize = 1;
		frameAdvanceText.screenCenter(X);
		frameAdvanceText.cameras = [camHUD];
		add(frameAdvanceText);

        FlxG.mouse.visible = true;
		FlxG.camera.zoom = 1;
		addHelpScreen();
        makeUIMenu();

        playerChill.finishAnimation();

        //super.create();

        /*var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
        FlxG.camera.filters = [fadeShaderFilter];*/
    }

    
	function addHelpScreen()
    {
        var str:Array<String> = ["CAMERA",
        "E/Q - Camera Zoom In/Out",
        "J/K/L/I - Move Camera",
        "R - Reset Camera Zoom",
        "",
        "CHARACTER",
        "Ctrl + R - Reset Current Offset",
        "Ctrl + C - Copy Current Offset",
        "Ctrl + V - Paste Copied Offset on Current Animation",
        "Ctrl + Z - Undo Last Paste or Reset",
        "W/S - Previous/Next Animation",
        "Space - Replay Animation",
        "Arrow Keys/Mouse & Right Click - Move Offset",
        "A/D - Frame Advance (Back/Forward)",
        "",
        "OTHER",
        "Hold Shift - Move Offsets 10x faster and Camera 4x faster",
        "Hold Control - Move camera 4x slower"];

        helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        helpBg.scale.set(FlxG.width, FlxG.height);
        helpBg.updateHitbox();
        helpBg.alpha = 0.6;
        helpBg.cameras = [camHUD];
        helpBg.active = helpBg.visible = false;
        add(helpBg);

        helpTexts = new FlxSpriteGroup();
        helpTexts.cameras = [camHUD];
        for (i => txt in str)
        {
            if(txt.length < 1) continue;

            var helpText:FlxText = new FlxText(0, 0, 600, txt, 16);
            helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
            helpText.borderColor = FlxColor.BLACK;
            helpText.scrollFactor.set();
            helpText.borderSize = 1;
            helpText.screenCenter();
            add(helpText);
            helpText.y += ((i - str.length/2) * 32) + 16;
            helpText.active = false;
            helpTexts.add(helpText);
        }
        helpTexts.active = helpTexts.visible = false;
        add(helpTexts);
    }

    function addCharacter(?reload:Bool = false, ?name:String = null)
    {
        var pos:Int = -1;
        var char:String = (name == null) ? Character.DEFAULT_CHARACTER : name;
        if(playerChill != null)
        {
            pos = members.indexOf(playerChill);
            if (name == null) char = playerChill.curCharacter;
            remove(playerChill);
            playerChill.destroy();
        }

        playerChill = new SelectionPlayer(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1], char);
        playerChill.debugMode = true;

        curChar = char;

        if(pos > -1) insert(pos, playerChill);
        else add(playerChill);
        updateCharacterPositions();
        if (reload) updateIconOffsets();
        reloadAnimList();
    }

    function makeUIMenu()
    {
        UI_box = new PsychUIBox(FlxG.width - 375, 155, 350, 280, ['Animations', 'Character']);
        UI_box.scrollFactor.set();
        UI_box.cameras = [camHUD];
        add(UI_box);

        UIGhost_box = new PsychUIBox(FlxG.width - 275, 25, 250, 120, ['Ghost']);
        UIGhost_box.scrollFactor.set();
        UIGhost_box.cameras = [camHUD];
        add(UIGhost_box);

        addGhostUI();
        addAnimationsUI();
        addCharacterUI();

        UI_box.selectedName = 'Character';
        UIGhost_box.selectedName = "Ghost";
    }

	var ghostAlpha:Float = 0.6;
	function addGhostUI()
    {
        var tab_group = UIGhost_box.getTab('Ghost').menu;
        var makeGhostButton:PsychUIButton = new PsychUIButton(25, 15, "Make Ghost", function() {
            var anim = anims[curAnim];
            if(!playerChill.isAnimationNull())
            {
                var myAnim = anims[curAnim];
                if(!playerChill.isAnimateAtlas)
                {
                    ghost.loadGraphic(playerChill.graphic);
                    ghost.frames.frames = playerChill.frames.frames;
                    ghost.animation.copyFrom(playerChill.animation);
                    ghost.animation.play(playerChill.animation.curAnim.name, true, false, playerChill.animation.curAnim.curFrame);
                    ghost.animation.pause();
                }
                else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
                {
                    if(animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
                    {
                        animateGhost = new FlxAnimate(ghost.x, ghost.y);
                        animateGhost.showPivot = false;
                        insert(members.indexOf(ghost), animateGhost);
                        animateGhost.active = false;
                    }

                    if(animateGhost == null || animateGhostImage != playerChill.imageFile)
                        Paths.loadAnimateAtlas(animateGhost, playerChill.imageFile);
                    
                    if(myAnim.indices != null && myAnim.indices.length > 0)
                        animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
                    else
                        animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

                    animateGhost.anim.play('anim', true, false, playerChill.atlas.anim.curFrame);
                    animateGhost.anim.pause();

                    animateGhostImage = playerChill.imageFile;
                }
                
                var spr:FlxSprite = !playerChill.isAnimateAtlas ? ghost : animateGhost;
                if(spr != null)
                {
                    spr.setPosition(playerChill.x, playerChill.y);
                    spr.antialiasing = playerChill.antialiasing;
                    spr.flipX = playerChill.flipX;
                    spr.alpha = ghostAlpha;

                    spr.scale.set(playerChill.scale.x, playerChill.scale.y);
                    spr.updateHitbox();

                    spr.offset.set(playerChill.offset.x, playerChill.offset.y);
                    spr.visible = true;

                    var otherSpr:FlxSprite = (spr == animateGhost) ? ghost : animateGhost;
                    if(otherSpr != null) otherSpr.visible = false;
                }
            }
        });

        var highlightGhost:PsychUICheckBox = new PsychUICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
        highlightGhost.onClick = function()
        {
            var value = highlightGhost.checked ? 125 : 0;
            ghost.colorTransform.redOffset = value;
            ghost.colorTransform.greenOffset = value;
            ghost.colorTransform.blueOffset = value;
            if(animateGhost != null)
            {
                animateGhost.colorTransform.redOffset = value;
                animateGhost.colorTransform.greenOffset = value;
                animateGhost.colorTransform.blueOffset = value;
            }
        };

        var ghostAlphaSlider:PsychUISlider = new PsychUISlider(15, makeGhostButton.y + 25, function(v:Float)
        {
            ghostAlpha = v;
            ghost.alpha = ghostAlpha;
            if(animateGhost != null) animateGhost.alpha = ghostAlpha;

        }, ghostAlpha, 0, 1);
        ghostAlphaSlider.label = 'Opacity:';

        tab_group.add(makeGhostButton);
        //tab_group.add(hideGhostButton);
        tab_group.add(highlightGhost);
        tab_group.add(ghostAlphaSlider);
    }

    var animationDropDown:PsychUIDropDownMenu;
	var animationInputText:PsychUIInputText;
	var animationNameInputText:PsychUIInputText;
	var animationIndicesInputText:PsychUIInputText;
	var animationFramerate:PsychUINumericStepper;
	var animationLoopCheckBox:PsychUICheckBox;
	function addAnimationsUI()
	{
		var tab_group = UI_box.getTab('Animations').menu;

		animationInputText = new PsychUIInputText(15, 85, 80, '', 8);
		animationNameInputText = new PsychUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new PsychUIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new PsychUINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new PsychUICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

		animationDropDown = new PsychUIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = playerChill.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:PsychUIButton = new PsychUIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indicesText:String = animationIndicesInputText.text.trim();
			var indices:Array<Int> = [];
			if(indicesText.length > 0)
			{
				var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
				if(indicesStr.length > 0)
				{
					for (ind in indicesStr)
					{
						if(ind.contains('-'))
						{
							var splitIndices:Array<String> = ind.split('-');
							var indexStart:Int = Std.parseInt(splitIndices[0]);
							if(Math.isNaN(indexStart) || indexStart < 0) indexStart = 0;
	
							var indexEnd:Int = Std.parseInt(splitIndices[1]);
							if(Math.isNaN(indexEnd) || indexEnd < indexStart) indexEnd = indexStart;
	
							for (index in indexStart...indexEnd+1)
								indices.push(index);
						}
						else
						{
							var index:Int = Std.parseInt(ind);
							if(!Math.isNaN(index) && index > -1)
								indices.push(index);
						}
					}
				}
			}

			var lastAnim:String = (playerChill.animationsArray[curAnim] != null) ? playerChill.animationsArray[curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in playerChill.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(playerChill.hasAnimation(animationInputText.text))
					{
						if(!playerChill.isAnimateAtlas) playerChill.animation.remove(animationInputText.text);
						else @:privateAccess playerChill.atlas.anim.animsMap.remove(animationInputText.text);
					}
					playerChill.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			playerChill.animationsArray.push(addedAnim);

			reloadAnimList();
			@:arrayAccess curAnim = Std.int(Math.max(0, playerChill.animationsArray.indexOf(addedAnim)));
			playerChill.playAnim(addedAnim.anim, true);
			//trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:PsychUIButton = new PsychUIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in playerChill.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == playerChill.getAnimationName()) resetAnim = true;
					if(playerChill.hasAnimation(anim.anim))
					{
						if(!playerChill.isAnimateAtlas) playerChill.animation.remove(anim.anim);
						else @:privateAccess playerChill.atlas.anim.animsMap.remove(anim.anim);
						playerChill.animOffsets.remove(anim.anim);
						playerChill.animationsArray.remove(anim);
					}

					if(resetAnim && playerChill.animationsArray.length > 0) {
						curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
						playerChill.playAnim(anims[curAnim].anim, true);
					}
					reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		reloadAnimList();
		animationDropDown.selectedLabel = anims[0] != null ? anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

    function addCharacterUI()
    {
        var tab_group = UI_box.getTab('Character').menu;

        scaleStepper = new PsychUINumericStepper(15, 30, 0.1, 1, 0.05, 10, 2);

        imageInputText = new PsychUIInputText(scaleStepper.x, scaleStepper.y + 40, 200, playerChill.imageFile, 8);
        var reloadImage:PsychUIButton = new PsychUIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function()
        {
            playerChill.imageFile = imageInputText.text;
            reloadCharacterImage();
        });

        var saveCharacterButton:PsychUIButton = new PsychUIButton(reloadImage.x, reloadImage.y + 40, "Save Character", function() {
            savePlayer();
        });

        speakerNameInputText = new PsychUIInputText(scaleStepper.x + 100, scaleStepper.y, 100, playerChill.imageFile, 8);
        reloadSpeakerButton = new PsychUIButton(reloadImage.x, reloadImage.y - 40, "Reload Speaker", function()
        {
            playerChill.speaker = speakerNameInputText.text;
            gfChill.changeCharacter(playerChill.speaker);
            gfChill.setPosition(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1]);
            gfChill.x += gfChill.positionArray[0];
            gfChill.y += gfChill.positionArray[1];
        });

        characterNameInputText = new PsychUIInputText(imageInputText.x, imageInputText.y + 40, 100, playerChill.curCharacter, 8);
        reloadAssetsButton = new PsychUIButton(characterNameInputText.x + 110, characterNameInputText.y - 3, "Reload Assets", function()
        {
            playerChill.curCharacter = characterNameInputText.text;
            reloadIcons();
            nametag.switchChar(playerChill.curCharacter);
        });

        flipXCheckBox = new PsychUICheckBox(scaleStepper.x, characterNameInputText.y + 40, "Flip X", 50);
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

        positionXStepper = new PsychUINumericStepper(noAntialiasingCheckBox.x + 110, noAntialiasingCheckBox.y, 10, playerChill.positionArray[0], -9000, 9000, 0);
        positionYStepper = new PsychUINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, playerChill.positionArray[1], -9000, 9000, 0);

        positionIconXStepper = new PsychUINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, playerChill.iconPositionArray[0], -9000, 9000, 0);
        positionIconYStepper = new PsychUINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, playerChill.iconPositionArray[1], -9000, 9000, 0);

        gfChill.changeCharacter(playerChill.speaker);

		var reloadCharacter:PsychUIButton = new PsychUIButton(flipXCheckBox.x, flipXCheckBox.y + 40 - 3, "Reload Char", function()
        {
            addCharacter(true);
            reloadCharacterOptions();
            reloadCharacterDropDown();
        });

        var templateCharacter:PsychUIButton = new PsychUIButton(reloadCharacter.x, reloadCharacter.y + 40, "Load Template", function()
        {
            var func:Void->Void = function()
            {
                final _template:CharacterFile =
                {
                    animations: [
                        newAnim('idle', 'bf cs idle'),
                        newAnim('confirm', 'bf cs confirm'),
                        newAnim('deselect', 'bf cs deselect'),
                        newAnim('slide out', 'bf slide out'),
                        newAnim('slide in', 'bf slide in')
                    ],
                    no_antialiasing: false,
                    flip_x: false,
                    healthicon: 'face',
                    image: 'charSelect/playerAssets/bf/bfChill',
                    sing_duration: 1,
                    scale: 1,
                    healthbar_colors: [0, 0, 0],
                    camera_position: [0, 0],
                    position: [0, 0],
                    hey_sound: "",
                    hey_anim: ""
                };

                playerChill.loadCharacterFile(_template);
                playerChill.missingCharacter = false;
                playerChill.color = FlxColor.WHITE;
                playerChill.alpha = 1;
                reloadAnimList();
                reloadCharacterOptions();
                updateCharacterPositions();
                reloadCharacterDropDown();
                gfChill.changeCharacter(playerChill.speaker);
                gfChill.setPosition(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1]);
                gfChill.x += gfChill.positionArray[0];
                gfChill.y += gfChill.positionArray[1];
            }

            openSubState(new Prompt('Are you sure you want to start over?', func));
        });
        templateCharacter.normalStyle.bgColor = FlxColor.RED;
        templateCharacter.normalStyle.textColor = FlxColor.WHITE;
        charDropDown = new PsychUIDropDownMenu(positionIconXStepper.x, positionIconXStepper.y + 40, [''], function(index:Int, intended:String)
        {
            if(intended == null || intended.length < 1) return;

            var characterPath:String = 'players/$intended.json';
            var path:String = Paths.getPath(characterPath, TEXT);
            #if MODS_ALLOWED
            if (FileSystem.exists(path))
            #else
            if (Assets.exists(path))
            #end
            {
                trace('FOUNDED CHAR: $path');
                addCharacter(false, intended);
                reloadCharacterOptions();
                reloadCharacterDropDown();
                gfChill.changeCharacter(playerChill.speaker);
                gfChill.setPosition(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1]);
                gfChill.x += gfChill.positionArray[0];
                gfChill.y += gfChill.positionArray[1];
            }
            else
            {
                trace('NOT FOUNDED CHAR: $path');
                reloadCharacterDropDown();
                FlxG.sound.play(Paths.sound('cancelMenu'));
            }
        });
        reloadCharacterDropDown();
        charDropDown.selectedLabel = playerChill.curCharacter;

        tab_group.add(new FlxText(speakerNameInputText.x, speakerNameInputText.y - 18, 100, 'Speaker char:'));
        tab_group.add(new FlxText(imageInputText.x, imageInputText.y - 18, 100, 'Image file name:'));
        tab_group.add(new FlxText(characterNameInputText.x, characterNameInputText.y - 18, 100, 'Character name:'));
        tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 100, 'Scale:'));
        tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
        tab_group.add(new FlxText(positionIconXStepper.x, positionIconXStepper.y - 18, 100, 'Icon X/Y:'));
        tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character List:'));

        tab_group.add(speakerNameInputText);
        tab_group.add(reloadSpeakerButton);
        tab_group.add(imageInputText);
        tab_group.add(reloadImage);
        tab_group.add(characterNameInputText);
        tab_group.add(reloadAssetsButton);
        tab_group.add(saveCharacterButton);
        tab_group.add(flipXCheckBox);
        tab_group.add(noAntialiasingCheckBox);
        tab_group.add(scaleStepper);
        tab_group.add(positionXStepper);
        tab_group.add(positionYStepper);
        tab_group.add(positionIconXStepper);
        tab_group.add(positionIconYStepper);
        tab_group.add(reloadCharacter);
        tab_group.add(templateCharacter);
        tab_group.add(charDropDown);

        reloadCharacterOptions();
    }

    override public function update(elapsed:Float)
    {
        // Without this shit the BeatHit doesn't work! (it was obvious, but, i'm dumb)
        if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
        super.update(elapsed);

        if (FlxG.keys.justPressed.P) INDEX++;
        if (FlxG.keys.justPressed.M) INDEX--;

        if (INDEX > 8) INDEX = 0;
        if (INDEX < 0) INDEX = 8;

        if(PsychUIInputText.focusOn != null)
        {
            ClientPrefs.toggleVolumeKeys(false);
            return;
        }
        ClientPrefs.toggleVolumeKeys(true);

        var shiftMult:Float = 1;
        var ctrlMult:Float = 1;
        var shiftMultBig:Float = 1;
        if(FlxG.keys.pressed.SHIFT)
        {
            shiftMult = 4;
            shiftMultBig = 10;
        }
        if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

        // CAMERA CONTROLS
        if (FlxG.keys.pressed.J) FlxG.camera.scroll.x -= elapsed * 500 * shiftMult * ctrlMult;
        if (FlxG.keys.pressed.K) FlxG.camera.scroll.y += elapsed * 500 * shiftMult * ctrlMult;
        if (FlxG.keys.pressed.L) FlxG.camera.scroll.x += elapsed * 500 * shiftMult * ctrlMult;
        if (FlxG.keys.pressed.I) FlxG.camera.scroll.y -= elapsed * 500 * shiftMult * ctrlMult;

        var lastZoom = FlxG.camera.zoom;
        if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL) FlxG.camera.zoom = 1;
        else if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3) {
            FlxG.camera.zoom += elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
            if(FlxG.camera.zoom > 3) FlxG.camera.zoom = 3;
        }
        else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1) {
            FlxG.camera.zoom -= elapsed * FlxG.camera.zoom * shiftMult * ctrlMult;
            if(FlxG.camera.zoom < 0.1) FlxG.camera.zoom = 0.1;
        }

        if(lastZoom != FlxG.camera.zoom) cameraZoomText.text = 'Zoom: ' + FlxMath.roundDecimal(FlxG.camera.zoom, 2) + 'x';

        // CHARACTER CONTROLS
        var changedAnim:Bool = false;
        if(anims.length > 1)
        {
            if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
            else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;

            if(changedAnim)
            {
                undoOffsets = null;
                curAnim = FlxMath.wrap(curAnim, 0, anims.length-1);
                playerChill.playAnim(anims[curAnim].anim, true);
                updateText();
            }
        }

        var changedOffset = false;
        var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
        var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
        if(moveKeysP.contains(true))
        {
            playerChill.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
            playerChill.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
            changedOffset = true;
        }

        if(moveKeys.contains(true))
        {
            holdingArrowsTime += elapsed;
            if(holdingArrowsTime > 0.6)
            {
                holdingArrowsElapsed += elapsed;
                while(holdingArrowsElapsed > (1/60))
                {
                    playerChill.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
                    playerChill.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
                    holdingArrowsElapsed -= (1/60);
                    changedOffset = true;
                }
            }
        }
        else holdingArrowsTime = 0;

        if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
        {
            playerChill.offset.x -= FlxG.mouse.deltaScreenX;
            playerChill.offset.y -= FlxG.mouse.deltaScreenY;
            changedOffset = true;
        }

        if(FlxG.keys.pressed.CONTROL)
        {
            if(FlxG.keys.justPressed.C)
            {
                copiedOffset[0] = playerChill.offset.x;
                copiedOffset[1] = playerChill.offset.y;
                changedOffset = true;
            }
            else if(FlxG.keys.justPressed.V)
            {
                undoOffsets = [playerChill.offset.x, playerChill.offset.y];
                playerChill.offset.x = copiedOffset[0];
                playerChill.offset.y = copiedOffset[1];
                changedOffset = true;
            }
            else if(FlxG.keys.justPressed.R)
            {
                undoOffsets = [playerChill.offset.x, playerChill.offset.y];
                playerChill.offset.set(0, 0);
                changedOffset = true;
            }
            else if(FlxG.keys.justPressed.Z && undoOffsets != null)
            {
                playerChill.offset.x = undoOffsets[0];
                playerChill.offset.y = undoOffsets[1];
                changedOffset = true;
            }
        }

        var anim = anims[curAnim];
        if(changedOffset && anim != null && anim.offsets != null)
        {
            anim.offsets[0] = Std.int(playerChill.offset.x);
            anim.offsets[1] = Std.int(playerChill.offset.y);

            playerChill.addOffset(anim.anim, playerChill.offset.x, playerChill.offset.y);
            updateText();
        }

        var txt = 'ERROR: No Animation Found';
        var clr = FlxColor.RED;
        if(!playerChill.isAnimationNull())
        {
            if(FlxG.keys.pressed.A || FlxG.keys.pressed.D)
            {
                holdingFrameTime += elapsed;
                if(holdingFrameTime > 0.5) holdingFrameElapsed += elapsed;
            }
            else holdingFrameTime = 0;

            if(FlxG.keys.justPressed.SPACE)
                playerChill.playAnim(playerChill.getAnimationName(), true);

            var frames:Int = -1;
            var length:Int = -1;
            if(!playerChill.isAnimateAtlas && playerChill.animation.curAnim != null)
            {
                frames = playerChill.animation.curAnim.curFrame;
                length = playerChill.animation.curAnim.numFrames;
            }
            else if(playerChill.isAnimateAtlas && playerChill.atlas.anim != null)
            {
                frames = playerChill.atlas.anim.curFrame;
                length = playerChill.atlas.anim.length;
            }

            if(length >= 0)
            {
                if(FlxG.keys.justPressed.A || FlxG.keys.justPressed.D || holdingFrameTime > 0.5)
                {
                    var isLeft = false;
                    if((holdingFrameTime > 0.5 && FlxG.keys.pressed.A) || FlxG.keys.justPressed.A) isLeft = true;
                    playerChill.animPaused = true;
    
                    if(holdingFrameTime <= 0.5 || holdingFrameElapsed > 0.1)
                    {
                        frames = FlxMath.wrap(frames + Std.int(isLeft ? -shiftMult : shiftMult), 0, length-1);
                        if(!playerChill.isAnimateAtlas) playerChill.animation.curAnim.curFrame = frames;
                        else playerChill.atlas.anim.curFrame = frames;
                        holdingFrameElapsed -= 0.1;
                    }
                }
    
                txt = 'Frames: ( $frames / ${length-1} )';
                //if(playerChill.animation.curAnim.paused) txt += ' - PAUSED';
                clr = FlxColor.WHITE;
            }
        }
        if(txt != frameAdvanceText.text) frameAdvanceText.text = txt;
        frameAdvanceText.color = clr;

        // OTHER CONTROLS

        if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE))
        {
            helpBg.visible = !helpBg.visible;
            helpTexts.visible = helpBg.visible;
        }
        else if(FlxG.keys.justPressed.ESCAPE)
        {
            if(!unsavedProgress)
            {
                MusicBeatState.switchState(new states.editors.MasterEditorMenu());
                FlxG.sound.playMusic(Paths.music('freakyMenu'));
            }
            else openSubState(new ExitConfirmationPrompt());
            return;
        }
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
            else gridPlayersList.push([playerChill.curCharacter, e]);
        }

        for (player in gridPlayersList) {
            var char = player[0];
            var temp:PlayerIcon = new PlayerIcon(0, 0, (char == "locked") ? Character.DEFAULT_CHARACTER : char, player[1], (char == "locked"));
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
            // nothing :O
        }
    }

    /*
    one thing, i don't know why
    it doesn't even matter how hard you try
    keep that in mind, i designed this rhyme to explain in due time
    all i know, time is a valuable thing...
    */

    function reloadCharacterImage()
    {
        var lastAnim:String = playerChill.getAnimationName();
		var anims:Array<AnimArray> = playerChill.animationsArray.copy();

		playerChill.atlas = FlxDestroyUtil.destroy(playerChill.atlas);
		playerChill.isAnimateAtlas = false;
		playerChill.color = FlxColor.WHITE;
		playerChill.alpha = 1;

		if(Paths.fileExists('images/' + playerChill.imageFile + '/Animation.json', TEXT))
		{
			playerChill.atlas = new FlxAnimate();
			playerChill.atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(playerChill.atlas, playerChill.imageFile);
			}
			catch(e:Dynamic)
			{
				FlxG.log.warn('Could not load atlas ${playerChill.imageFile}: $e');
			}
			playerChill.isAnimateAtlas = true;
		}
		else
		{
			playerChill.frames = Paths.getMultiAtlas(playerChill.imageFile.split(','));
		}

		for (anim in anims) {
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop; //Bruh
			var animIndices:Array<Int> = anim.indices;
			addAnimation(animAnim, animName, animFps, animLoop, animIndices);
		}

		if(anims.length > 0)
		{
			if(lastAnim != '') playerChill.playAnim(lastAnim, true);
			else playerChill.dance();
		}
    }

    function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
    {
        if(!playerChill.isAnimateAtlas)
        {
            if(indices != null && indices.length > 0)
                playerChill.animation.addByIndices(anim, name, indices, "", fps, loop);
            else
                playerChill.animation.addByPrefix(anim, name, fps, loop);
        }
        else
        {
            if(indices != null && indices.length > 0)
                playerChill.atlas.anim.addBySymbolIndices(anim, name, indices, fps, loop);
            else
                playerChill.atlas.anim.addBySymbol(anim, name, fps, loop);
        }

        if(!playerChill.hasAnimation(anim))
            playerChill.addOffset(anim, 0, 0);
    }

    inline function newAnim(anim:String, name:String):AnimArray
    {
        return {
            offsets: [0, 0],
            loop: false,
            fps: 24,
            anim: anim,
            indices: [],
            name: name
        };
    }

    inline function reloadAnimList()
    {
        anims = playerChill.animationsArray;
        if(anims.length > 0) playerChill.playAnim(anims[0].anim, true);
        curAnim = 0;

        updateText();
        if(animationDropDown != null) reloadAnimationDropDown();
    }

    function reloadAnimationDropDown() 
    {
		var animList:Array<String> = [];
		for (anim in anims) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

    inline function updateText()
    {
        animsTxt.removeFormat(selectedFormat);

        var intendText:String = '';
        for (num => anim in anims)
        {
            if(num > 0) intendText += '\n';

            if(num == curAnim)
            {
                var n:Int = intendText.length;
                intendText += anim.anim + ": " + anim.offsets;
                animsTxt.addFormat(selectedFormat, n, intendText.length);
            }
            else intendText += anim.anim + ": " + anim.offsets;
        }
        animsTxt.text = intendText;
    }

    var characterList:Array<String> = [];
	function reloadCharacterDropDown() {
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'players/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = playerChill.curCharacter;
	}

    inline function updateCharacterPositions()
    {
        if (playerChill == null) return;
        playerChill.setPosition(PlayerSelectionState.positionsArr[0], PlayerSelectionState.positionsArr[1]);

		playerChill.x += playerChill.positionArray[0];
		playerChill.y += playerChill.positionArray[1];
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
            else gridPlayersList.push([playerChill.curCharacter, e]);
        }

        for (icon in grpIcons) {
            if (icon.index != INDEX) icon.locked = true;
            else {
                icon.setPlayer(playerChill.curCharacter);
                icon.locked = false;
                updateIconOffsets();
            }
        }
    }

	function reloadCharacterOptions() {
		if(UI_box == null) return;

        speakerNameInputText.text = playerChill.speaker;
		imageInputText.text = playerChill.imageFile;
        characterNameInputText.text = playerChill.curCharacter;
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
            "speaker": playerChill.speaker,
			"icon_position": playerChill.iconPositionArray,

			"animations": playerChill.animationsArray,
			"image": playerChill.imageFile,
			"scale": playerChill.jsonScale,
			"position":	playerChill.positionArray,
			"flip_x": playerChill.flipX,
			"no_antialiasing": playerChill.noAntialiasing,

			"sing_duration": 1,
			"healthicon": "face",
			"camera_position": [0, 0],
			"healthbar_colors": [0, 0, 0],
			"hey_sound": "",
			"hey_anim": "",
			"_editor_isPlayer": false
		};

		var data:String = PsychJsonPrinter.print(json, ['offsets', 'position', 'healthbar_colors', 'camera_position', 'indices']);
        var _player = playerChill.curCharacter;

		if (data.length > 0)
        {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data, _player + ".json");
        }
        unsavedProgress = false;
    }

    function set_INDEX(value:Int):Int {
        INDEX = value;
        reloadIcons();
        return (value);
    }
}