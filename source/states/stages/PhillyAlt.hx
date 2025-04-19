package states.stages;

import shaders.AdjustColorShader;

class PhillyAlt extends Philly {
    var colorShader:AdjustColorShader;
    override function create() {
        this.folder = "erect/";
        this.isAlt = true;

        super.create();
        phillyLightsColors = [0xFFb66f43, 0xFF329a6d, 0xFF932c28, 0xFF2663ac, 0xFF502d64];

        colorShader = new AdjustColorShader();
		colorShader.hue = -26;
		colorShader.saturation = -16;
		colorShader.contrast = 0;
		colorShader.brightness = -5;
    }

    override function createPost() {
        super.createPost();

        boyfriend.shader = colorShader;
        gf.shader = colorShader;
        dad.shader = colorShader;
        this.phillyTrain.shader = colorShader;
        this.preLightsShader = colorShader;
    }
}