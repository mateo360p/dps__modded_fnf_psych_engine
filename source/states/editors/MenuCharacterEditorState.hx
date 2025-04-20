package states.editors;

import backend.WeekData;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import haxe.Json;

import objects.MenuCharacter;

import states.editors.content.Prompt;
import states.editors.content.PsychJsonPrinter;

class MenuCharacterEditorState extends MusicBeatState implements PsychUIEventHandler.PsychUIEvent
{
	var char:MenuCharacter;
	var curAnimation:Int = 0; //0 = idle, 1 = confirm ONLY WORKS FOR THE PLAYER
	var txtPosition:FlxText;

	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var characterFile:MenuCharacterFile = null;
	var txtOffsets:FlxText;
	var unsavedProgress:Bool = false;

	override function create() {
		characterFile = FileTemplates.menuCharFile();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		for (i in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter(0, 0, DefaultValues.defaultCharacters[i], i);
			//weekCharacterThing.y += 70;
			weekCharacterThing.alpha = 0.2;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, FlxColor.WHITE)); //White chit 
		add(grpWeekCharacters);

		var c = DefaultValues.weekColor; //initialization is overrated
		var colorBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, FlxColor.fromRGB(c[0], c[1], c[2]));
		colorBG.blend = MULTIPLY;
		add(colorBG); //the color

		txtPosition = new FlxText(20, 10, 0, "Pos: [0, 0]", 32);
		txtPosition.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtPosition.alpha = 0.7;
		add(txtPosition);

		txtOffsets = new FlxText(320, 10, 0, "Offsets: [0, 0]", 32);
		txtOffsets.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
		txtOffsets.alpha = 0.7;
		add(txtOffsets);

		var tipText:FlxText = new FlxText(0, 540, FlxG.width,
			"Arrow Keys - Change Offset (Start Press Animation)
			\nWASD - Change the Character Position
			\n(Hold shift for 10x speed)
			\nSpace - Play \"Start Press\" animation (Boyfriend Character Type)", 16);
		tipText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		tipText.scrollFactor.set();
		add(tipText);

		addEditorBox();
		FlxG.mouse.visible = true;
		updateCharacters();

		super.create();
	}

	var UI_typebox:PsychUIBox;
	var UI_mainbox:PsychUIBox;
	function addEditorBox() {
		UI_typebox = new PsychUIBox(100, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		
		UI_mainbox = new PsychUIBox(FlxG.width - 340, FlxG.height - 265, 240, 215, ['Character']);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		add(UI_mainbox);

		var loadButton:PsychUIButton = new PsychUIButton(0, 480, "Load Character", function() {
			loadCharacter();
		});
		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:PsychUIButton = new PsychUIButton(0, 480, "Save Character", function() {
			saveCharacter();
		});
		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	var characterTypeRadio:PsychUIRadioGroup;
	function addTypeUI() {
		var tab_group = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new PsychUIRadioGroup(10, 20, ['Opponent', 'Boyfriend', 'Girlfriend'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = updateCharacters;
		tab_group.add(characterTypeRadio);
	}

	var imageInputText:PsychUIInputText;
	var idleInputText:PsychUIInputText;
	var confirmInputText:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var flipXCheckbox:PsychUICheckBox;
	var antialiasingCheckbox:PsychUICheckBox;
	function addCharacterUI() {
		var tab_group = UI_mainbox.getTab('Character').menu;
		
		imageInputText = new PsychUIInputText(10, 20, 80, characterFile.image, 8);
		idleInputText = new PsychUIInputText(10, imageInputText.y + 35, 100, characterFile.idle_anim, 8);
		confirmInputText = new PsychUIInputText(10, idleInputText.y + 35, 100, characterFile.confirm_anim, 8);

		flipXCheckbox = new PsychUICheckBox(10, confirmInputText.y + 30, "Flip X", 100);
		flipXCheckbox.onClick = function()
		{
			grpWeekCharacters.members[characterTypeRadio.checked].flipX = flipXCheckbox.checked;
			characterFile.flipX = flipXCheckbox.checked;
		};

		antialiasingCheckbox = new PsychUICheckBox(10, flipXCheckbox.y + 30, "Antialiasing", 100);
		antialiasingCheckbox.checked = grpWeekCharacters.members[characterTypeRadio.checked].antialiasing;
		antialiasingCheckbox.onClick = function()
		{
			grpWeekCharacters.members[characterTypeRadio.checked].antialiasing = antialiasingCheckbox.checked;
			characterFile.antialiasing = antialiasingCheckbox.checked;
		};

		var reloadImageButton:PsychUIButton = new PsychUIButton(140, confirmInputText.y + 30, "Reload Char", function() {
			reloadSelectedCharacter();
		});
		
		scaleStepper = new PsychUINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		var confirmDescText = new FlxText(10, confirmInputText.y - 18, 0, 'Start Press animation on the .XML:');
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation on the .XML:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(antialiasingCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(confirmDescText);
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(scaleStepper);
	}

	function updateCharacters() {
		for (i in 0...3) {
			char = grpWeekCharacters.members[i];
			char.alpha = 0.2;
			char.character = '';
			char.changeMenuCharacter(DefaultValues.defaultCharacters[i], i);
		}
		reloadSelectedCharacter();
	}
	
	function reloadSelectedCharacter() {
		char = grpWeekCharacters.members[characterTypeRadio.checked];
		char.alpha = 1;
		char.frames = Paths.getSparrowAtlas('menucharacters/' + characterFile.image);
		char.animation.addByPrefix('idle', characterFile.idle_anim, 24);
		if(characterTypeRadio.checked == 1) char.animation.addByPrefix('confirm', characterFile.confirm_anim, 24, false);
		char.flipX = (characterFile.flipX == true);

		char.scale.set(characterFile.scale, characterFile.scale);
		char.updateHitbox();
		char.animation.play('idle');
		updatePosition();
		updateOffset();
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Menu Character Editor", "Editting: " + characterFile.image);
		#end
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == PsychUICheckBox.CLICK_EVENT)
			unsavedProgress = true;

		if(id == PsychUIInputText.CHANGE_EVENT && (sender is PsychUIInputText)) {
			if(sender == imageInputText) {
				characterFile.image = imageInputText.text;
				unsavedProgress = true;
			} else if(sender == idleInputText) {
				characterFile.idle_anim = idleInputText.text;
				unsavedProgress = true;
			} else if(sender == confirmInputText) {
				characterFile.confirm_anim = confirmInputText.text;
				unsavedProgress = true;
			}
		} else if(id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper)) {
			if (sender == scaleStepper) {
				characterFile.scale = scaleStepper.value;
				reloadSelectedCharacter();
				unsavedProgress = true;
			}
		}
	}

	override function update(elapsed:Float) {
		if(PsychUIInputText.focusOn == null)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new states.editors.MasterEditorMenu());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt());
			}

			var shiftMult:Int = 1;
			if(FlxG.keys.pressed.SHIFT) shiftMult = 10;

			if(FlxG.keys.justPressed.D) {
				characterFile.position[0] += shiftMult;
				updatePosition();
			}
			if(FlxG.keys.justPressed.A) {
				characterFile.position[0] -= shiftMult;
				updatePosition();
			}
			if(FlxG.keys.justPressed.S) {
				characterFile.position[1] += shiftMult;
				updatePosition();
			}
			if(FlxG.keys.justPressed.W) {
				characterFile.position[1] -= shiftMult;
				updatePosition();
			}

			if(FlxG.keys.justPressed.SPACE && characterTypeRadio.checked == 1) {
				var disChar = grpWeekCharacters.members[1];
				if (curAnimation == 0) {
					disChar.playAnim('confirm', true);
					curAnimation = 1;
					updateOffset();
				} else if (curAnimation == 1) {
					disChar.playAnim('idle', true);
					curAnimation = 0;
					updateOffset();
				}
			}

			var controlArray:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
			for (i in 0...controlArray.length) {
				if(controlArray[i] && characterTypeRadio.checked == 1 && curAnimation == 1) {
					var arrayVal = 0;
					if(i > 1) arrayVal = 1;
					var negaMult:Int = 1;
					if(i % 2 == 1) negaMult = -1;
					if (characterFile != null) characterFile.confirm_offsets[arrayVal] += negaMult * shiftMult;
					updateOffset();
				}
			}
		}
		else ClientPrefs.toggleVolumeKeys(false);

		super.update(elapsed);
	}

	override function beatHit(){
		if (curAnimation == 0 && characterTypeRadio.checked == 1)
			grpWeekCharacters.members[1].playAnim('idle', true);
	}

	function updatePosition() {
		char = grpWeekCharacters.members[characterTypeRadio.checked];
		char.setPosition(characterFile.position[0] + (FlxG.width * 0.25) * (1 + characterTypeRadio.checked) - 150, characterFile.position[1] + 70);
		txtPosition.text = 'Pos: ' + characterFile.position;
	}

	function updateOffset() {
		//var xdxdxd = characterFile.confirm_offsets;
		if (characterFile.confirm_offsets == null) characterFile.confirm_offsets = [0, 0];
		txtOffsets.text = 'Offsets: ' + characterFile.confirm_offsets;

		if (characterTypeRadio.checked != 1) {
			txtOffsets.visible = false;
			char.offset.set(0, 0);
		} else {
			txtOffsets.visible = true;
			if (curAnimation == 1) {
				char = grpWeekCharacters.members[1];
				if (char.confirmOffsets != null) char.offset.set(characterFile.confirm_offsets[0], characterFile.confirm_offsets[1]);
			} else {
				char.offset.set(0, 0);
			}
		}

		/*
		if (curAnimation == 1 && characterTypeRadio.checked == 1){	
			char = grpWeekCharacters.members[1];
			if (char.confirmOffsets != null) char.offset.set(characterFile.confirm_offsets[0], characterFile.confirm_offsets[1]);
		} else {
			char.offset.set(0, 0);
		}*/
	}

	var _file:FileReference = null;
	function loadCharacter() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				var loadedChar:MenuCharacterFile = cast Json.parse(rawJson);
				if(loadedChar.idle_anim != null && loadedChar.confirm_anim != null) //Make sure it's really a character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					characterFile = loadedChar;
					reloadSelectedCharacter();
					imageInputText.text = characterFile.image;
					idleInputText.text = characterFile.image;
					confirmInputText.text = characterFile.image;
					scaleStepper.value = characterFile.scale;
					updatePosition();
					updateOffset();
					_file = null;
					return;
				}
			}
		}
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	function saveCharacter() {
		var data:String = PsychJsonPrinter.print(characterFile, ['position']);
		if (data.length > 0)
		{
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[splittedImage.length-1].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, characterName + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}
