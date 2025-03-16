package objects;

import flxanimate.PsychFlxAnimate._AnimateHelper;
#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end

class SelectionCharacter extends Character
{
    #if funkin.vis
	var analyzer:SpectralAnalyzer;
	#end
	var enableVisualizer:Bool = false;

    public function new(x:Float, y:Float, char:String)
    {
        super(x, y, char);
    }

	override public function changeCharacter(character:String)
    {
        if (character == "none") {
            this.visible = false;
            this.curCharacter = "none";
            //trace("no gf?, me neither :c");
            return; // :D
        }
        enableVisualizer = (character == "nene");

        this.visible = true;

        folder = "players";
        super.changeCharacter(character);
    }

    override public function loadCharacterFile(json:Dynamic)
    {
        super.loadCharacterFile(json);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }

	public override function draw() {
        if (analyzer != null && atlas != null) drawFFT();
        super.draw();
    }

    function drawFFT()
    {
        // this is complicated for me-
        // I hate atlas so bad :D, so I'm going to find a way to not use them for this
        if (enableVisualizer && isAnimateAtlas) // Delete this later!
        {
            var levels = analyzer.getLevels();
            var frame = atlas.anim.symbolDictionary.get("VIZ").timeline.get("VIZ_bars").get(atlas.anim.curFrame);
            //var frame = atlas.anim.curSymbol.timeline.get("VIZ_bars").get(atlas.anim.curFrame);
            var elements = frame.getList();
            var len:Int = cast Math.min(elements.length, 7);

            for (i in 0...len)
            {
                var animFrame:Int = Math.round(levels[i].value * 12);

                animFrame = Math.floor(Math.min(12, animFrame));
                animFrame = Math.floor(Math.max(0, animFrame));
                animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!

                elements[i].symbol.firstFrame = animFrame;
            }
        }
    }
}