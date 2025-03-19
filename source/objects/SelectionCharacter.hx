package objects;

import states.stages.objects.ABotSpeaker;
import flxanimate.PsychFlxAnimate._AnimateHelper;
#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end

class SelectionCharacter extends Character
{
    final VIZ_POS_X:Array<Float> = [0, 26, 52.6, 80, 108, 139.2, 167];
	final VIZ_POS_Y:Array<Float> = [0, 1.7, 5, 10.3, 18.6, 29.1, 41.2];
    
    #if funkin.vis
	var analyzer:SpectralAnalyzer;
	#end
	var enableVisualizer:Bool = false;
	public var vizSprites:Array<FlxSprite>;

    public var speakerBG:FlxSprite;

    public var snd(default, set):FlxSound;
	function set_snd(changed:FlxSound)
	{
		snd = changed;
		#if funkin.vis
		initAnalyzer();
		#end
		return snd;
	}

    public function new(x:Float, y:Float, char:String)
    {
        super(x, y, char);
    }

	override public function changeCharacter(character:String)
    {
        if (character == "none") {
            this.visible = false;
            this.curCharacter = "none";
            this.enableVisualizer = false;
            //trace("no gf?, me neither :c");
            return; // :D
        }

        if (character == "nene") {
            enableVisualizer = true;
            speakerBG = new FlxSprite(0, 0).loadGraphic(Paths.image('charSelect/playerAssets/pico/stereoBG'));
            speakerBG.antialiasing = ClientPrefs.data.antialiasing;
            vizSprites = ABotSpeaker.setVizSprites('charSelect/playerAssets/pico/aBotViz', VIZ_POS_X, VIZ_POS_Y);
            //if (vizSprites != null) for (i in vizSprites) i.setPosition(i.x + this.x, i.y + this.y);
        } else {
            enableVisualizer = false;
            speakerBG = null;
            vizSprites = null;
        }

        this.visible = true;

        folder = "players";
        super.changeCharacter(character);
    }

    override public function loadCharacterFile(json:Dynamic)
    {
        super.loadCharacterFile(json);
    }

    #if funkin.vis
	var levels:Array<Bar>;
	var levelMax:Int = 0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (vizSprites != null) for (i in vizSprites) i.visible = speakerBG.visible = this.visible;
        if(analyzer == null || enableVisualizer == false || vizSprites == null ) return;

		levels = analyzer.getLevels(levels);
		levelMax = 0;
		for (i in 0...Std.int(Math.min(vizSprites.length, levels.length)))
		{
			var animFrame:Int = Math.round(levels[i].value * 5);
			animFrame = Std.int(Math.abs(FlxMath.bound(animFrame, 0, 5) - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!
		
			vizSprites[i].animation.curAnim.curFrame = animFrame;
			levelMax = Std.int(Math.max(levelMax, 5 - animFrame));
		}
    }
    #end

	#if funkin.vis
	public function initAnalyzer()
	{
		@:privateAccess
		analyzer = new SpectralAnalyzer(snd._channel.__audioSource, 7, 0.1, 40);
	
		#if desktop
		// On desktop it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
		// So we want to manually change it!
		analyzer.fftN = 256;
		#end
	}
	#end
}