package states.stages;

import lime.utils.Assets;
import objects.Character;
import shaders.DropShadowShader;

class SchoolAlt extends School {
    override function create() {
        this.folder = "erect/";
        this.isAlt = true;

        super.create();
    }

    override function addCharacter(char:Character) {
        if (char == null) return;

        var shdr = shaderHelper(char);
        switch(char._baseChar.charType) {
            case BF:
            case DAD:
            case GF:
                shdr.setAdjustColor(-42, -10, 5, -25);
                shdr.distance = 3;
                shdr.threshold = 0.3;
            case OTHER:
        }
        var img:String = Paths.getPath('images/weeb/erect/masks/' + char.curCharacter + '_mask.png', IMAGE);
		if (#if MODS_ALLOWED FileSystem.exists(img) || #end Assets.exists(img)) {
            shdr.loadAltMask(img);
            trace("mask founded!");
        } else trace("null mask dude :c");

        shdr.maskThreshold = 1;
        shdr.useAltMask = true;
        char.animation.callback = function(name:String, frame:Int, id:Int) {
            if (char != null) shdr.updateFrameInfo(char.frame);
        }

        char.shader = shdr;
    }

    function shaderHelper(char:Character):DropShadowShader {
        var rim = new DropShadowShader();
		rim.setAdjustColor(-66, -10, 24, -23);
        rim.color = 0xFF52351d;
		rim.antialiasAmt = 0;
		rim.attachedSprite = char;
		rim.distance = 5;
        rim.angle = 90;

        return rim;
    }
}