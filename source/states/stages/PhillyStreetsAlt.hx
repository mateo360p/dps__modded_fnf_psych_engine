package states.stages;

import objects.Character;
import shaders.AdjustColorShader;

class PhillyStreetsAlt extends PhillyStreets {
    // I don't understand, the "erect" stages are also for pico, but, why-?
    // Now, I'm gonna put some chit to select the stage, but only for the Nightmare Diff.

    var colorShader:AdjustColorShader;

    override function create() {
        this.folder = "erect/";
        this.isAlt = true;

        colorShader = new AdjustColorShader();
        colorShader.hue = -5;
        colorShader.saturation = -40;
        colorShader.contrast = -25;
        colorShader.brightness = -20;

        super.create();
    }

    override function addCharacter(char:Character) {
        super.addCharacter(char);
        char.shader = colorShader;
    }

    override function setupRainShader() {
        super.setupRainShader();
        rainShader.rainColor = 0xFFa8adb5;
    }
}