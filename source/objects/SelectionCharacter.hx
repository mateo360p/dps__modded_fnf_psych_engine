package objects;

import backend.animation.PsychAnimationController;
import haxe.Json;
import states.FreeplayState;
import lime.utils.Assets;
import flixel.FlxSprite;

typedef PlayerAnimArray = {
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class SelectionCharacter extends FlxSprite
{
    public var animOffsets:Map<String, Array<Dynamic>>;

	public var twoBeatIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
    public var noAntialiasing:Bool;
	public var positionArray:Array<Float> = [0, 0];

	public var playerAnimArr:Array<PlayerAnimArray> = [];
    public var animList:Array<String> = [];

    public var atlas:FlxAtlasSprite;
    public var isAnimateAtlas:Bool = false;
	public var debugMode:Bool = false;
	public var danced:Bool = false;

    public var staticX:Float = 0;
    public var staticY:Float = 0;

    public var image:String;
    public var isPlayer:Bool;
	public var jsonScale:Float;
    public var charName:String;

    public function new(x:Float, y:Float, char:String, ?isSpeaker:Bool = true)
    {
        super(x, y);

        staticX = x;
        staticY = y;

        animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		changeCharacter(char, isSpeaker);
    }
/*
    override public function setPosition(x = 0.0, y = 0.0) {
        this.staticX = x;
        this.staticY = y;

        this.x = staticX + positionArray[0];
        this.y = staticY + positionArray[1];
    }*/

	public function changeCharacter(character:String, ?isGF:Bool = true)
    {
        if (character == "locked") return; // :D

        animOffsets = [];
        var characterPath:String = 'players/$character.json';
        if (isGF) characterPath = 'players/speakers/$character.json';

        var path:String = Paths.getPath(characterPath, TEXT);
        #if MODS_ALLOWED
        if (!FileSystem.exists(path))
        #else
        if (!Assets.exists(path))
        #end
        {
            trace("sorry bud: " + character);
            path = Paths.getSharedPath('players/' + FreeplayState.DEF_PLAYER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
        }

        try
        {
            #if MODS_ALLOWED
            loadCharacterFile(Json.parse(File.getContent(path)));
            #else
            loadCharacterFile(Json.parse(Assets.getText(path)));
            #end
        }
        catch(e:Dynamic)
        {
            trace('Error loading character file of "$character": $e');
        }

        recalculateDanceIdle();
        dance();
    }

    public function loadCharacterFile(json:Dynamic)
    {
        loadImage(json.image);

        image = json.image;
        charName = json.character;
        isPlayer = json.editor_player;
		jsonScale = json.scale;
        scale.set(jsonScale, jsonScale);
        updateHitbox();

        // positioning
        if (json.position != null) positionArray = json.position;
        setPosition(staticX + positionArray[0], staticY + positionArray[1]);

        // data
        flipX = json.flip_x;

        // antialiasing
        noAntialiasing = (json.no_antialiasing == true);
        antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

        twoBeatIdle = json.twoBeatIdle;

        prepareAnimations(json);
        loadAnimations(playerAnimArr);
        #if flxanimate
        if(isAnimateAtlas) copyAtlasValues();
        #end
        updateHitbox();
        //trace('Loaded file to character ' + curCharacter);
    }

    public function loadImage(_image:String, ?x:Float = 0, ?y:Float = 0) {
        var atlaspath:String = Paths.getSharedPath('images/charSelect/playerAssets/$_image');
        isAnimateAtlas = false;

        #if flxanimate
        var animToFind:String = atlaspath + '/Animation.json';
        trace("ATLAS SHOULD BE IN: " + animToFind);
        if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
            isAnimateAtlas = true;
        #end
/*
        scale.set(1, 1);
        updateHitbox();*/
        try {        
            if(!isAnimateAtlas)
            {
                frames = Paths.getMultiAtlas(_image.split(','));
            }
        #if flxanimate
            else
            {
                atlas = new FlxAtlasSprite(0, 0, atlaspath);
                atlas.showPivot = false;
            }
        } catch(e:haxe.Exception) {
            FlxG.log.warn('Could not load image or atlas: $e');
            trace(e.stack);
        }
        //if(isAnimateAtlas) copyAtlasValues();
        //updateHitbox();
        #end
    }

    public function prepareAnimations(json:Dynamic) {
        playerAnimArr = [json.animReady, json.animBruh]; //json.animations;
        animList = ["ready", "bruh"];

        if (twoBeatIdle)  {
            playerAnimArr.push(json.animLeft);
            playerAnimArr.push(json.animRight);
            animList.push("left");
            animList.push("right");
        } else {
            playerAnimArr.push(json.animIdle);
            animList.push("idle");
        }
    }

    public function loadAnimations(animArray:Array<PlayerAnimArray>) {
        if(animArray != null && animArray.length > 0) {
            for (num => anim in playerAnimArr) {
                var animName:String = '' + anim.name; // Name in xml/json
                var animFps:Int = anim.fps;
                var animLoop:Bool = !!anim.loop; //Bruh
                var animIndices:Array<Int> = anim.indices;
                var animAnim:String = animList[num]; // Animation game to use

                if(!isAnimateAtlas)
                {
                    if(animIndices != null && animIndices.length > 0)
                        animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
                    else
                        animation.addByPrefix(animAnim, animName, animFps, animLoop);
                }
                #if flxanimate
                else
                {
                    if(animIndices != null && animIndices.length > 0)
                        atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
                    else
                        atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
                }
                #end

                if(anim.offsets != null && anim.offsets.length > 1) addOffset(animAnim, anim.offsets[0], anim.offsets[1]);
                else addOffset(animAnim, 0, 0);
            }
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if(isAnimateAtlas) atlas.update(elapsed);
    }

	public function copyAtlasValues()
    {
        @:privateAccess
        {
            atlas.cameras = cameras;
            atlas.scrollFactor = scrollFactor;
            atlas.scale = scale;
            atlas.offset = offset;
            atlas.origin = origin;
            atlas.x = x;
            atlas.y = y;
            atlas.angle = angle;
            atlas.alpha = alpha;
            atlas.visible = visible;
            atlas.flipX = flipX;
            atlas.flipY = flipY;
            atlas.shader = shader;
            atlas.antialiasing = antialiasing;
            atlas.colorTransform = colorTransform;
            atlas.color = color;
            atlas.updateHitbox();
        }
    }

    public function dance()
    {
        if (!debugMode)
        {
            if(twoBeatIdle)
            {
                danced = !danced;

                if (danced) playAnim('right');
                else playAnim('left');
            }
            else playAnim("idle");
        }
    }

    var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return _lastPlayedAnimation;
	}

    public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
    {
        if(!isAnimateAtlas)
        {
            animation.play(AnimName, Force, Reversed, Frame);
        }
        else
        {
            atlas.anim.play(AnimName, Force, Reversed, Frame);
            atlas.update(0);
        }
        _lastPlayedAnimation = AnimName;

        if (hasAnimation(AnimName))
        {
            var daOffset = animOffsets.get(AnimName);
            offset.set(daOffset[0], daOffset[1]);
        }
        //else offset.set(0, 0);
    }
    
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
    {
        animOffsets[name] = [x, y];
    }

    public function quickAnimAdd(name:String, anim:String)
    {
        animation.addByPrefix(name, anim, 24, false);
    }

    inline public function isAnimationNull():Bool
    {
        return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curInstance == null || atlas.anim.curSymbol == null);
    }

    public function hasAnimation(anim:String):Bool
    {
        return animOffsets.exists(anim);
    }

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() 
    {
		var lastDanceIdle:Bool = !twoBeatIdle;

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (twoBeatIdle? 1 : 2);
		}
		else if(lastDanceIdle != twoBeatIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(twoBeatIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

    public override function draw()
    {
        var lastAlpha:Float = alpha;
        var lastColor:FlxColor = color;

        if(isAnimateAtlas)
        {
            if(atlas.anim.curInstance != null)
            {
                copyAtlasValues();
                atlas.draw();
                alpha = lastAlpha;
                color = lastColor;
            }
            return;
        }
        super.draw();
    }
/*
    public function switchChar(str:String)
    {
        switch str
        {
        default:
            loadAtlas(Paths.animateAtlas("charSelect/" + str + "Chill"));
        }

        playAnimation("slidein", true, false, false);

        updateHitbox();

        updatePosition(str);
    }*/
}