package states.editors;

import states.editors.content.Prompt;
import flxanimate.data.SpriteMapData.JsonNormal;
import objects.Character;
import openfl.net.FileFilter;
import openfl.net.FileReference;
import openfl.events.Event;
import haxe.Json;
import openfl.events.IOErrorEvent;
import backend.LevelData;
import states.editors.content.Prompt.ExitConfirmationPrompt;
import lime.system.Clipboard;
import objects.HealthIcon;
import backend.WeekData;
import backend.LevelData.LevelFile;

class LevelEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var levelFile:LevelFile = null;
	var unsavedProgress:Bool = false;
	var playerInputText:PsychUIInputText;
    var _player:String;
	var diffsInputText:PsychUIInputText;
    var _week:String;

	public function new(levelFile:LevelFile = null, player:String = "bf", isReload:Bool = false, week:String = "week")
	{
		super();
        this._player = player;
        this._week = week;
		this.levelFile = LevelData.createLevelFile();
        this.unsavedProgress = isReload;
		if(levelFile != null) this.levelFile = levelFile;
	}

	var bg:FlxSprite;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var curSelected = 0;

	override function create() {
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = FlxColor.WHITE;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

        grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		addEditorBox();

        grpSongs.forEach((a) -> {grpSongs.remove(a); a.destroy();});
        grpIcons.forEach((i) -> {grpIcons.remove(i); i.destroy();});

        for (i in 0...levelFile.songs.length)
        {
            var songText:Alphabet = new Alphabet(90, 320, levelFile.songs[i][0], true);
            songText.isMenuItem = true;
            songText.targetY = i;
            grpSongs.add(songText);
            songText.scaleX = Math.min(1, 980 / songText.width);
            songText.snapToPosition();

            var icon:HealthIcon = new HealthIcon(levelFile.songs[i][1]);
            icon.sprTracker = songText;

            // using a FlxGroup is too much fuss!
            // DP: Says who, buddy?
            grpIcons.add(icon);
        }

		changeSelection(0);

        FlxG.mouse.visible = true;

		super.create();
	}

	var UI_box:PsychUIBox;
	function addEditorBox() {
		UI_box = new PsychUIBox(FlxG.width, FlxG.height, 250, 320, ['Level', 'Freeplay']);
		UI_box.x -= UI_box.width + 100;
		UI_box.y -= UI_box.height + 60;
		UI_box.scrollFactor.set();
        addLevelUI();
		addFreeplayUI();
		add(UI_box);
	}
	
	public function UIEvent(id:String, sender:Dynamic)
	{
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText))
		{
            if (sender == iconInputText) {
                levelFile.songs[curSelected][1] = iconInputText.text;
                grpIcons.members[curSelected].changeIcon(iconInputText.text);
            } else if (sender == extraDiffsInputText) {
                levelFile.songs[curSelected][3] = extraDiffsInputText.text.trim();
            } else if (sender == diffsInputText) {
                levelFile.levelDifficulties = diffsInputText.text;
            }
		}
		else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			if(sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB)
				updateBG();
		}
	}

    function addLevelUI() {
        var tab_group = UI_box.getTab('Level').menu;

        playerInputText = new PsychUIInputText(10, 40, 100, _player, 8);

        diffsInputText = new PsychUIInputText(playerInputText.x, playerInputText.y + 40, 100, levelFile.levelDifficulties, 8);

		var loadLevelButton:PsychUIButton = new PsychUIButton(diffsInputText.x, diffsInputText.y + 70, "Load Level or Old Week songs", function() {
            if(!unsavedProgress) loadLevel();
			else openSubState(new Prompt('Are you sure you want to start over?', loadLevel));
		}, 160);

        var loadFWeekButton:PsychUIButton = new PsychUIButton(playerInputText.x, loadLevelButton.y + 40, "Load From Week", function() {
            if(!unsavedProgress) loadLevelFromWeek();
			else openSubState(new Prompt('Are you sure you want to start over?', loadLevelFromWeek));
		}, 100);

		var saveLevelButton:PsychUIButton = new PsychUIButton(playerInputText.x, loadFWeekButton.y + 40, "Save Level", function() {
			saveLevel(levelFile);
		});

        tab_group.add(new FlxText(playerInputText.x, playerInputText.y - 18, 0, 'Player name:'));
        tab_group.add(new FlxText(diffsInputText.x, diffsInputText.y - 18, 0, 'Level difficulties:'));
        tab_group.add(playerInputText);
        tab_group.add(diffsInputText);
        tab_group.add(loadLevelButton);
        tab_group.add(loadFWeekButton);
        tab_group.add(saveLevelButton);
    }

	var bgColorStepperR:PsychUINumericStepper;
	var bgColorStepperG:PsychUINumericStepper;
	var bgColorStepperB:PsychUINumericStepper;
	var iconInputText:PsychUIInputText;
	var extraDiffsInputText:PsychUIInputText;
	function addFreeplayUI() {
		var tab_group = UI_box.getTab('Freeplay').menu;

		bgColorStepperR = new PsychUINumericStepper(10, 40, 20, 255, 0, 255, 0);
		bgColorStepperG = new PsychUINumericStepper(80, 40, 20, 255, 0, 255, 0);
		bgColorStepperB = new PsychUINumericStepper(150, 40, 20, 255, 0, 255, 0);

		var copyColor:PsychUIButton = new PsychUIButton(10, bgColorStepperR.y + 25, "Copy Color", function() Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue);

		var pasteColor:PsychUIButton = new PsychUIButton(140, copyColor.y, "Paste Color", function()
		{
			if(Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);
					if(!Math.isNaN(toPush))
					{
						if(toPush > 255) toPush = 255;
						else if(toPush < 0) toPush *= -1;
						leColor.push(toPush);
					}
				}

				if(leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];
					updateBG();
				}
			}
		});

		iconInputText = new PsychUIInputText(10, bgColorStepperR.y + 70, 100, '', 8);

		extraDiffsInputText = new PsychUIInputText(10, iconInputText.y + 70, 100, '', 8);

		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));
		tab_group.add(new FlxText(10, extraDiffsInputText.y - 18, 0, 'Extra Difficulties:'));
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(iconInputText);
		tab_group.add(extraDiffsInputText);
	}

	function updateBG() {
		levelFile.songs[curSelected][2][0] = Math.round(bgColorStepperR.value);
		levelFile.songs[curSelected][2][1] = Math.round(bgColorStepperG.value);
		levelFile.songs[curSelected][2][2] = Math.round(bgColorStepperB.value);
		bg.color = FlxColor.fromRGB(levelFile.songs[curSelected][2][0], levelFile.songs[curSelected][2][1], levelFile.songs[curSelected][2][2]);
	}

    function reloadChits() {
		iconInputText.text = levelFile.songs[curSelected][1];
		extraDiffsInputText.text = levelFile.songs[curSelected][3];

        var colors = levelFile.songs[curSelected][2];
		bgColorStepperR.value = Math.round(colors[0]);
		bgColorStepperG.value = Math.round(colors[1]);
		bgColorStepperB.value = Math.round(colors[2]);
    }

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, levelFile.songs.length - 1);
		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = grpIcons.members[num];
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}

        reloadChits();
		updateBG();
	}

	override function update(elapsed:Float) {
        if(loadedLevel != null) {
			levelFile = loadedLevel;
			loadedLevel = null;

			//reloadChits();
		}

		if(PsychUIInputText.focusOn != null)
			ClientPrefs.toggleVolumeKeys(false);
		else
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt());
			}

			if(controls.UI_UP_P) changeSelection(-1);
			if(controls.UI_DOWN_P) changeSelection(1);
		}
		super.update(elapsed);
	}

	private static var _file:FileReference;
	public function loadLevel() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

    public function loadLevelFromWeek() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadFromWeekComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	public static var loadedLevel:LevelFile = null;
	public static var loadError:Bool = false;
	private function onLoadComplete(_):Void // Loads a Level File
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadFromWeekComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				loadedLevel = cast Json.parse(rawJson);
				if(loadedLevel.songs != null) // Make sure it's really a level, ORRR and old week ;D
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);

					var simpleLevel:LevelFile = LevelData.createLevelFile(); // This is to evoid all the shit that an old week has
					simpleLevel.songs = loadedLevel.songs;
					if (loadedLevel.levelDifficulties != null) simpleLevel.levelDifficulties = loadedLevel.levelDifficulties;
                    MusicBeatState.switchState(new LevelEditorState(simpleLevel, cutName.substring(cutName.lastIndexOf("_") + 1), false, cutName.substring(0, cutName.lastIndexOf("_"))));
					return;
				} else {
                    FlxG.sound.play(Paths.sound('cancelMenu')); // Dumbass
                    trace("This isn't a Level File, or at least an old week, is it?");
                }
			}
		}
		loadError = true;
		loadedLevel = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

    private function onLoadFromWeekComplete(_):Void { // Loads the songs added to a Week File
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadFromWeekComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
            if(rawJson != null) {
				var loadedWeek:WeekFile = cast Json.parse(rawJson);
				if(loadedWeek.levels != null) // If there are at least levels in that chit
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);

					levelFile.levelDifficulties = loadedWeek.difficulties ?? ""; // WHAT, THIS EXISTS!?
                    levelFile.songs = []; // Yeah, "null" songs
                    for (i in loadedWeek.levels) {
                        levelFile.songs.push([i[0], 'face', [146, 113, 253]]);
                    }
                    MusicBeatState.switchState(new LevelEditorState(levelFile, Character.DEFAULT_CHARACTER, true, cutName));
					return;
				} else {
                    FlxG.sound.play(Paths.sound('cancelMenu')); // Dumbass
                    trace("This isn't a Week File, is it?");
                }
			}
        }
    }

	/**
		* Called when the save file dialog is cancelled.
		*/
	private function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadFromWeekComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
        _file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadFromWeekComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public function saveLevel(levelFile:LevelFile) {
		var data:String = haxe.Json.stringify(levelFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, _week + "_" + playerInputText.text + ".json");
		}
	}
	
	private function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
		unsavedProgress = false;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	private function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace("Cancelled file saving.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
