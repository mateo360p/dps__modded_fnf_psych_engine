package objects.characters;

import states.stages.objects.ABotSpeaker;

enum NeneState
{
	STATE_DEFAULT;
	STATE_PRE_RAISE;
	STATE_RAISE;
	STATE_READY;
	STATE_LOWER;
}

class Nene extends BaseCharacter {
    final MIN_BLINK_DELAY:Int = 3;
	final MAX_BLINK_DELAY:Int = 7;

	final VULTURE_THRESHOLD:Float = 0.4;

    var currentNeneState:NeneState = STATE_DEFAULT;
	var blinkCountdown:Int = 3;
	var animationFinished:Bool = false;

    public var abot:ABotSpeaker;

    public function new(_char:Character) {
        super(_char);
    }

    //------------------------- OVERRIDES ------------------------------------

    override function create()
    {
        abot = new ABotSpeaker(0, 0);
		updateABotEye(true);
		gfGroup.add(abot);
    }

    override function createPost()
    {
        if (char != null) {
            char.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
                switch(currentNeneState) {
                    case STATE_PRE_RAISE:
                        if (name == 'danceLeft' && frameNumber >= 14)
                        {
                            animationFinished = true;
                            transitionState();
                        }
                    default:
                        // Ignore.
                }
            }
            if (abot != null) copyToAbot();
        }
    }

    override function startSong()
    {
        abot.snd = FlxG.sound.music;
        char.animation.finishCallback = onNeneAnimationFinished;
    }

    override function update(elapsed:Float) {
        if(char == null || !game.startedCountdown) return;

        if (abot != null) copyToAbot();
        animationFinished = char.isAnimationFinished();
		transitionState();
    }

    override function goodNoteHit(note:Note)
    {
        // 10% chance of playing combo50/combo100 animations for Nene
        if(FlxG.random.bool(10))
        {
            switch(game.combo)
            {
                case 50, 100:
                    var animToPlay:String = 'combo${game.combo}';
                    if(char.animation.exists(animToPlay))
                    {
                        char.playAnim(animToPlay);
                        char.specialAnim = true;
                    }
            }
        }
    }

    override function sectionHit()
    {
        updateABotEye();
    }

    override function beatHit()
    {
        if(abot != null && curBeat % 2 == 0) abot.beatHit();

        switch(currentNeneState) {
            case STATE_READY:
                if (blinkCountdown == 0)
                {
                    char.playAnim('idleKnife', false);
                    blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
                }
                else blinkCountdown--;

            default:
                // In other states, don't interrupt the existing animation.
        }
    }

    //------------------------- NENE'S FUNC ------------------------------------
	function transitionState() {
        switch (currentNeneState)
        {
            case STATE_DEFAULT:
                if (game.health <= VULTURE_THRESHOLD)
                {
                    currentNeneState = STATE_PRE_RAISE;
                    char.skipDance = true;
                }

            case STATE_PRE_RAISE:
                if (game.health > VULTURE_THRESHOLD)
                {
                    currentNeneState = STATE_DEFAULT;
                    char.skipDance = false;
                }
                else if (animationFinished)
                {
                    currentNeneState = STATE_RAISE;
                    char.playAnim('raiseKnife');
                    char.skipDance = true;
                    char.danced = true;
                    animationFinished = false;
                }

            case STATE_RAISE:
                if (animationFinished)
                {
                    currentNeneState = STATE_READY;
                    animationFinished = false;
                }

            case STATE_READY:
                if (game.health > VULTURE_THRESHOLD)
                {
                    currentNeneState = STATE_LOWER;
                    char.playAnim('lowerKnife');
                }

            case STATE_LOWER:
                if (animationFinished)
                {
                    currentNeneState = STATE_DEFAULT;
                    animationFinished = false;
                    char.skipDance = false;
                }
        }
    }

	function updateABotEye(finishInstantly:Bool = false)
    {
        if(PlayState.SONG.notes[Std.int(FlxMath.bound(curSection, 0, PlayState.SONG.notes.length - 1))].mustHitSection == true) abot.lookRight();
        else abot.lookLeft();

        if(finishInstantly) abot.eyes.anim.curFrame = abot.eyes.anim.length - 1;
    }

    function onNeneAnimationFinished(name:String)
    {
        if(!game.startedCountdown) return;

        switch(currentNeneState)
        {
            case STATE_RAISE, STATE_LOWER:
                if (name == 'raiseKnife' || name == 'lowerKnife')
                {
                    animationFinished = true;
                    transitionState();
                }

            default:
                // Ignore.
        }
    }

	public function copyToAbot()
    {
        @:privateAccess
        {
            abot.cameras = char.cameras;
            abot.setPosition(char.x - 60, char.y + 325);
            abot.alpha = char.alpha;
            abot.visible = char.visible;
            abot.flipX = char.flipX;
            abot.flipY = char.flipY;
            abot.shader = char.shader;
            abot.antialiasing = char.antialiasing;
            abot.colorTransform = char.colorTransform;
            abot.color = char.color;
        }
    }
}