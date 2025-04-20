package states;

import substates.FreeplayErrorSubState;
import substates.SelectStageSubState;
import backend.LevelData;
import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.HealthIcon;
import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var player:String = DefaultValues.character;
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var tabToChangeTxt:FlxText;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var musicPlayer:MusicPlayer;
	var tabPlayerSine:Float = 0;
	var onError:Bool = false;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		Conductor.bpm = TitleState.musicBPM; // Return to normal BPM & music

		persistentUpdate = true;
		PlayState.isStoryMode = false;
		LevelData.loadPlayers();
		WeekData.reloadWeekFiles(false);

		player = player.toLowerCase().trim();

		trace("PLAYER:" + FreeplayState.player);
		trace("PLAYERLIST: " + LevelData.playersList);

		var plArray:Array<String> = [];
		for (i in LevelData.playersList) plArray.push(i[0]); // Verifies if the character exist in the list [0]

		if (!plArray.contains(player)) player = DefaultValues.character;
		trace("CUR PLAYER:" + FreeplayState.player);
		LevelData.reloadLevels(false, player); // Loads level songs from the current player

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(LevelData.levelsList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.ChartingState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...LevelData.levelsList.length)
		{
			var weekData:WeekData = WeekData.getWeekFromLevel(LevelData.levelsLoaded.get(LevelData.levelsList[i]));
			if(weekIsLocked(weekData.fileName)) continue;

			var daLevel:LevelData = LevelData.levelsLoaded.get(LevelData.levelsList[i]);

			WeekData.setDirectoryFromWeek(weekData);
			for (song in daLevel.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				var weekShit:Int = 0; // I hate my life
				for (a in 0...WeekData.weeksList.length) if (WeekData.weeksList[a] == daLevel.levelWeek) weekShit = a;
				addSong(song[0], LevelData.levelsList[i], weekShit, song[3], song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		tabToChangeTxt = new FlxText(0, 0, 0, Language.getPhrase('tab_change_player', 'PRESS [TAB] TO SELECT PLAYER'), 48);
		//if(FlxG.random.bool(0.1)) tabToChangeTxt.text += '\nBITCH.'; HmmMmMMmMMmmMmM
		tabToChangeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tabToChangeTxt.borderSize = 2;
		add(tabToChangeTxt);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
		bottomString = leText;
		var size:Int = 16;
		bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
		bottomText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER);
		bottomText.scrollFactor.set();
		add(bottomText);
		
		musicPlayer = new MusicPlayer(this);
		add(musicPlayer);
		
		changeSelection();
		updateTexts();
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, levelName:String, week:Int, extraDifficulties:String, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, levelName, week, extraDifficulties, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * elapsed;

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if (!musicPlayer.playingMusic && !onError)
		{
			scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
			positionHighscore();
			
			if(songs.length > 1)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}

			if (controls.UI_LEFT_P)
			{
				changeDiff(-1);
				_updateSongLastDifficulty();
			}
			else if (controls.UI_RIGHT_P)
			{
				changeDiff(1);
				_updateSongLastDifficulty();
			}
		}

		if (controls.BACK)
		{
			if (musicPlayer.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				musicPlayer.playingMusic = false;
				musicPlayer.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !musicPlayer.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE)
		{
			if(instPlaying != curSelected && !musicPlayer.playingMusic)
			{
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;

				Mods.currentModDirectory = songs[curSelected].folder;
				var songLowercase:String = Paths.formatToSongPath(getPlayerSongName());
				var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
				Song.loadFromJson(poop, Paths.formatToSongPath(songs[curSelected].songName.toLowerCase()));
				DefaultValues.prepareSongAudios(PlayState.SONG.audiosNames);

				if (PlayState.SONG.needsVoices) {
					vocals = new FlxSound();
					opponentVocals = new FlxSound();
					PathsUtil.setUpSongVoices(true, true, vocals);
					PathsUtil.setUpSongVoices(true, false, opponentVocals);
				}

				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, PlayState.SONG.audiosNames[0]), 0.8);
				FlxG.sound.music.pause();
				instPlaying = curSelected;

				musicPlayer.playingMusic = true;
				musicPlayer.curTime = 0;
				musicPlayer.switchPlayMusic();
				musicPlayer.pauseOrResume(true);
			}
			else if (instPlaying == curSelected && musicPlayer.playingMusic)
			{
				musicPlayer.pauseOrResume(!musicPlayer.playing);
			}
		}
		else if (controls.ACCEPT && !musicPlayer.playingMusic)
		{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(getPlayerSongName());
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			var stageArr = getStagesArray();

			function gameChit() {
				try
				{
					Song.loadFromJson(poop, Paths.formatToSongPath(songs[curSelected].songName.toLowerCase()));
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());

					@:privateAccess
					if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
					{
						trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
						Paths.freeGraphicsFromMemory();
					}
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState());
					#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
					stopMusicPlay = true;

					destroyFreeplayVocals();
					#if (MODS_ALLOWED && DISCORD_ALLOWED)
					DiscordClient.loadModRPC();
					#end
				}
				catch(e:haxe.Exception)
				{
					trace('ERROR! ${e.message}');
	
					var errorSubstate:FreeplayErrorSubState = new FreeplayErrorSubState(songLowercase, e);
					errorSubstate.onClose = () -> (onError = false);
					openSubState(errorSubstate);

					onError = true;
					updateTexts(elapsed);
				}
			}
			try {
				var selectionState:SelectStageSubState = new SelectStageSubState(stageArr);
				selectionState.onClose = () -> {gameChit(); Song.selectedStage = selectionState.finalStage;};
				openSubState(selectionState);
			} catch(e:haxe.Exception) {
				gameChit();
			}
		}
		else if(controls.RESET && !musicPlayer.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(getPlayerSongName(), curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		else if (FlxG.keys.justPressed.TAB) MusicBeatState.switchState(new PlayerSelectionState());

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, Math.exp(-elapsed * 3.125)); // Reset Camera
		updateTexts(elapsed);

		//I also used something like this for my project lol
		tabPlayerSine += 90 * elapsed;
		tabToChangeTxt.alpha = 1 - Math.sin((Math.PI * tabPlayerSine) / 180);

		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0)
	{
		if (musicPlayer.playingMusic) return;

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(getPlayerSongName(), curDifficulty);
		intendedRating = Highscore.getRating(getPlayerSongName(), curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
		else
			diffText.text = displayDiff.toUpperCase();

		//idk what im doing lol, same (yeah again-)
		for (i in songs) {
			var daLevel:LevelData = LevelData.levelsLoaded.get(i.levelName);
			var songDiffs:Array<String> = Difficulty.load(daLevel.levelDifficulties, i.extraDiffs);

			if (!songDiffs.contains(Difficulty.getString(curDifficulty, false))) grpSongs.members[songs.indexOf(i)].color = FlxColor.GRAY;
			else grpSongs.members[songs.indexOf(i)].color = FlxColor.WHITE;
		}

		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (musicPlayer.playingMusic)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);

		for (item in grpSongs.members)
		{
			if (item.targetY == curSelected && item.color == FlxColor.GRAY)
			{
				changeSelection(change == 0 ? 1 : change);
				return;
			}
		}
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == curSelected)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;

		PlayState.storyWeek = songs[curSelected].week; // Fucking piece o-
		Difficulty.loadFromWeek();
		Difficulty.list = Difficulty.load(LevelData.levelsLoaded.get(songs[curSelected].levelName).levelDifficulties, songs[curSelected].extraDiffs); //UGHHH NOW ITS WORSE
		//trace(Difficulty.list);

		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff)) //whathaheck
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

	private function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}

	public function getPlayerSongName():String {
		return player + '_' + songs[curSelected].songName.toLowerCase();
	}

	function getStagesArray():Array<Array<String>> {
		try {
			var file = '$player-'  + Difficulty.getString(curDifficulty).toLowerCase() + '_stages';
			var thing = PathsUtil.getSongPath(file, ".txt", songs[curSelected].songName);
			#if MODS_ALLOWED
			var firstArray:Array<String> = Mods.mergeAllTextsNamed(thing);
			#else
			var fullText:String = Assets.getText(Paths.txt(thing));
			var firstArray:Array<String> = fullText.split('\n');
			#end
			var swagGoodArray:Array<Array<String>> = [];

			for (i in firstArray) swagGoodArray.push(i.split('--'));

			return swagGoodArray;
		} 
		catch(e:haxe.Exception) {
			trace("null stages!");
			return null;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if (ClientPrefs.data.camZooms) {
			FlxG.camera.zoom += 0.025;
			FlxTween.tween(FlxG.camera, {zoom: 1}, 0.4, {ease: FlxEase.quadOut});
		}
	}

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;
	public var extraDiffs:String = "";
	public var levelName:String = '';
	public var week:Int;

	public function new(song:String, levelName:String, week:Int, extraDiffs:String, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		this.extraDiffs = extraDiffs;
		this.levelName = levelName;
		this.week = week;
		if(this.folder == null) this.folder = '';
	}
}