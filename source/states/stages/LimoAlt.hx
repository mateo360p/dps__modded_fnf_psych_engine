package states.stages;

import objects.Character;
import shaders.AdjustColorShader;

class LimoAlt extends Limo {
    var colorShader:AdjustColorShader;

    var shootingStarBeat:Int = 0;
	var shootingStarOffset:Int = 2;

    override function create() {
        this.folder = "erect/";
        this.isAlt = true;

        colorShader = new AdjustColorShader();
        colorShader.hue = -30;
        colorShader.saturation = -20;
        colorShader.contrast = 0;
        colorShader.brightness = -30;

        super.create();
    }

    override function addCharacter(char:Character) {
        super.addCharacter(char);

        char.shader = colorShader;
    }

    override function createPost()
    {
        super.createPost();

        _shaderHelper(limoMetalPole);
        _shaderHelper(limoLight);
        _shaderHelper(limoCorpse);
        _shaderHelper(limoCorpseTwo);
        _shaderHelper(fastCar);

        shaderAltSet();
    }

    override function beatHit() {
        super.beatHit();
        if (FlxG.random.bool(10) && curBeat > (shootingStarBeat + shootingStarOffset))
        {
            doShootingStar(curBeat);
        }
    }

    function doShootingStar(beat:Int):Void
    {
        shootingStar.x = FlxG.random.int(50,900);
        shootingStar.y = FlxG.random.int(-10,20);
        shootingStar.flipX = FlxG.random.bool(50);
        shootingStar.animation.play('shooting star');

        shootingStarBeat = beat;
        shootingStarOffset = FlxG.random.int(4, 8);
    }

    function _shaderHelper(spr:FlxSprite) {
        if (colorShader == null || spr == null) return; 
        spr.shader = colorShader;
    }

    override function shaderAltSet() {
        if (!ClientPrefs.data.lowQuality) {
            grpLimoDancers.forEach(_shaderHelper);
            grpLimoParticles.forEach(_shaderHelper);
        }
    }
}