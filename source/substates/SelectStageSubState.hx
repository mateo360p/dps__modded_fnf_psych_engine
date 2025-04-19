package substates;

import flixel.group.FlxGroup;
import backend.WeekData;
import backend.Highscore;

import flixel.FlxSubState;
import objects.HealthIcon;

class SelectStageSubState extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var alphabetArray:Array<Alphabet> = [];
	var onYes:Bool = false;
	var yesText:Alphabet;
	var noText:Alphabet;

	var stagesArr:Array<String> = [];
	var stagesClass:Array<String> = [];

	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var difficultySelectors:FlxGroup;

	var curSelected:Int = 0;
	var curStage:String = "";

	var stageText:Alphabet;

	public var onClose:Void -> Void;
	public var finalStage:String;

	public function new(stageArray:Array<Array<String>>)
	{
		super();

		for (i in stageArray) {
			stagesArr.push(i[0]);
			stagesClass.push(i[1]);
		}

		curStage = stagesArr[curSelected];

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(850, 0);
		leftArrow.screenCenter(Y);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		//curSelected = Math.round(Math.max(0, stagesArr.indexOf(lastDifficultyName)));

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		var text:Alphabet = new Alphabet(0, 180, Language.getPhrase('select_stage_freeplay', 'Select the stage:'), true);
		text.screenCenter(X);
		alphabetArray.push(text);
		text.alpha = 0;
		add(text);

		stageText = new Alphabet(0, text.y + 90, curStage, true);
		stageText.alpha = 0;
		alphabetArray.push(stageText);

		change(0);
		add(stageText);
	}

	function change(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, stagesArr.length - 1);
		curStage = stagesArr[curSelected];

		var tooLong:Float = (curStage.length > 18) ? 0.8 : 1; // Just in case
		stageText.text = curStage;
		stageText.scaleX = tooLong;
		stageText.screenCenter(X);

		leftArrow.y = stageText.y;
		rightArrow.y = stageText.y;

		leftArrow.x = stageText.x - 20 - leftArrow.width;
		rightArrow.x = FlxG.width - leftArrow.x-  leftArrow.width;
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if(bg.alpha > 0.6) bg.alpha = 0.6;

		for (i in 0...alphabetArray.length) {
			var spr = alphabetArray[i];
			spr.alpha += elapsed * 2.5;
		}

		if (controls.UI_LEFT_P) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			change(-1);
		}
		if (controls.UI_RIGHT_P) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			change(1);
		}
		if(controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			close();
		} else if(controls.ACCEPT) {
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			this.finalStage = stagesClass[curSelected];
			if (onClose != null) onClose();
			close();
		}
		super.update(elapsed);
	}
}