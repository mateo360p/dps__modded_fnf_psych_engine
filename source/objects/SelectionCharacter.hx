package objects;

import states.PlayerSelectionState;
import states.stages.objects.ABotSpeaker;
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
	var enableVisualizer(default, set):Bool = false;

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
        this.enableVisualizer = false;
        switch (character) {
            case "none":
                this.alpha = 0;
                this.curCharacter = "none";
                //trace("no gf?, me neither :c");
                return;
            case "nene":
                this.enableVisualizer = true;
            default:
        }

        this.alpha = 1; // Since alpha isn't used here...
        folder = "players";

        super.changeCharacter(character);

        snd = FlxG.sound.music;
        setPosition(PlayerSelectionState.positionsArr[0] + positionArray[0], PlayerSelectionState.positionsArr[1] + positionArray[1]);
        setObjectsPos();
    }

    inline function speakerAnalyzerExists():Bool return (speakerBG != null) && (vizSprites != null);

    inline public function funcSpeakerBG(functionChit:FlxSprite->Void) {
        if (speakerBG == null) return;
        functionChit(speakerBG);
    }

    inline public function funcVizSpr(functionChit:FlxSprite->Void) {
        // Someone has to make a function like this for an array, if no one does or no one hasn't, I might do it, idk
        if (vizSprites == null || vizSprites == []) return;
        for (i in vizSprites) {
            functionChit(i);
        }
    }

    inline public function setObjectsPos() {
        funcSpeakerBG(function(i) i.setPosition(this.x + 145.3, this.y + 49.5));
        funcVizSpr(function(i) i.setPosition(i.x + this.x + 193.15, i.y + this.y + 81.4));
    }

    #if funkin.vis
	var levels:Array<Bar>;
	var levelMax:Int = 0;
    override function update(elapsed:Float)
    {
        super.update(elapsed);

        funcVizSpr(function(a) a.visible = speakerBG.visible = this.visible);
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

    function set_enableVisualizer(value:Bool):Bool {
        if (value) {
            if (!speakerAnalyzerExists()) {
                speakerBG = new FlxSprite(0, 0).loadGraphic(Paths.image('charSelect/playerAssets/pico/stereoBG'));
                speakerBG.antialiasing = ClientPrefs.data.antialiasing;
            }
            vizSprites = ABotSpeaker.setVizSprites('charSelect/playerAssets/pico/aBotViz', VIZ_POS_X, VIZ_POS_Y);
            //setObjectsPos();
        } else {
            speakerBG = null;
            vizSprites = null;
        }
        return (enableVisualizer = value);
    }

    
    public function onFinishAnimationOnce(anim:String, aFunction:Void -> Void) {
        if (!isAnimateAtlas) {
            this.animation.finishCallback = function(name:String) {
                if (name != anim) return;
                aFunction();
                this.animation.finishCallback = null;
            }
        } else {
            this.atlas.anim.onComplete.add( function() {
                if (getAnimationName() != anim) return;
                aFunction();
                this.atlas.anim.onComplete.removeAll();
            });
        }
    }
}