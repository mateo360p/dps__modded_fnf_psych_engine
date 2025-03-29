package states.stages;

import shaders.AdjustColorShader;

class PhillyStreetsAlt extends PhillyStreets {
    // I don't understand, the "erect" stages are also for pico, but, why-?
    // I'm putting them just for pico, bf will have his old stages, sry bud

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

    override function createPost()
    {
        super.createPost();
        boyfriend.shader = colorShader;
        gf.shader = colorShader;
        dad.shader = colorShader;
    }

    override function setupRainShader() {
        super.setupRainShader();
        rainShader.rainColor = 0xFFa8adb5;
    }
}