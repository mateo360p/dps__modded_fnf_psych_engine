package util;

import flixel.util.FlxDestroyUtil;
import objects.Character;

/**
 * I'm pretty organized, so I made this enum to set every folder/obj type

 * (I moved a lot of folders and I hated changing Strings file per file)
 *  * So if I wanna change some path I just put a value to the var!
 *  * I may not use this in a future, but just in case
 *  * THE FOLDERS SHOULD BE IN THE SHARED OR IN A MOD FOLDER!!!
 */
enum abstract ObjectsPath(String) from String to String {
    var characters = "data/characters/"; // like this
    var players = "data/players/";
	var menuCharacters = "images/menuCharacters/data/";
	var stages = "data/stages/";
    var weeks = "data/weeks/";
    var levels = weeks + "levels/";
	var songs = "data/songs/";
	var scripts = "scripts/"; //.hxc
}

/**
 * Some people find this unnecesary

 * I'm not one of them
 */
class PathsUtil {
    private static function charPathTemplate(path:String, fileName:String, postfix:String) {
		if (fileName == null) fileName = DefaultValues.character;
		if (postfix == null) postfix = ".json";
		return path + fileName + postfix;
    }

    private static function dataPathTemplate(path:String, fileName:String, postfix:String) {
		if (fileName == null) fileName = "";
		if (postfix == null) postfix = "";
		return path + fileName + postfix;
    }

    //-------------------------------------- Funcs --------------------------------------

	/**
	 * @return If there's an invalid "letter" or character in the `str` string
	 */
	inline static public function searchInvalidCharsHXC(str:String):Bool { // This should work
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return (hideChars.match(str) || invalidChars.match(str));
	}

    public static function setUpSongVoices(forMusicPlayer:Bool, isPlayer:Bool, vocals:FlxSound) {
		try {
			var num:Int = (isPlayer) ? 1 : 2;
			if (PlayState.SONG.audiosNames[num].toLowerCase().trim() == DefaultValues.audioDisable) return;

			var preVocals = Paths.voices(PlayState.SONG.song, PlayState.SONG.audiosNames[num]);
			vocals.loadEmbedded(preVocals ?? Paths.voices(PlayState.SONG.song));
			if (forMusicPlayer) {
				FlxG.sound.list.add(vocals);
				vocals.persist = vocals.looped = true;
				vocals.volume = 0.8;
				vocals.play();
				vocals.pause();
			}
		} catch(e:Dynamic) {
			var bud:String = switch(isPlayer) {
				case true: "player";
				case false: "opponent";
				default: ""; //like null, and, just null
			}
			trace('Error while setting $bud vocals');
			vocals = FlxDestroyUtil.destroy(vocals);
		}
    }

    //-------------------------------------- Getters --------------------------------------
    /**
	 * Returns a file on the Characters folder
	 * @param fileName if null, returns the Default character!!!
	 * @param postfix if null, it sets to .json
	 */
	public static function getCharacterPath(?fileName:String = null, ?postfix:String = null):String {
        return charPathTemplate(ObjectsPath.characters, fileName, postfix);
	}

    /**
	 * Returns a file on the Menu Characters folder
	 * @param fileName if null, returns the Default character!!!
	 * @param postfix if null, it sets to .json
	 */
	public static function getMenuCharacterPath(?fileName:String = null, ?postfix:String = null):String {
        return charPathTemplate(ObjectsPath.menuCharacters, fileName, postfix);
	}

    /**
	 * Returns a file on the Players folder
	 * @param fileName if null, returns the Default character!!!
	 * @param postfix if null, it sets to .json
	 */
	public static function getPlayerPath(?fileName:String = null, ?postfix:String = null):String {
        return charPathTemplate(ObjectsPath.players, fileName, postfix);
	}

    /**
	 * Returns a file on the Stages folder
	 * @param fileName if null, it sets to ""
	 * @param postfix if null, it sets to ""
	 */
	public static function getStagePath(?fileName:String = "", ?postfix:String = ""):String {
        return dataPathTemplate(ObjectsPath.stages, fileName, postfix);
	}

    /**
	 * Returns a file on the Weeks folder
	 * @param fileName if null, it sets to ""
	 * @param postfix if null, it sets to ""
	 */
	public static function getWeekPath(?fileName:String = "", ?postfix:String = ""):String {
        return dataPathTemplate(ObjectsPath.weeks, fileName, postfix);
	}

    /**
	 * Returns a file on the Levels folder
	 * @param fileName if null, it sets to ""
	 * @param postfix if null, it sets to ""
	 */
	public static function getLevelPath(?fileName:String = "", ?postfix:String = ""):String {
        return dataPathTemplate(ObjectsPath.levels, fileName, postfix);
	}

    /**
	 * Returns a file on the Levels folder
	 * * THIS FUNCTIONS AUTOMATICALLY CALLS Paths.formatToSongPath and .toLowerCase for the songName
	 * @param fileName if null, it sets to ""
	 * @param postfix if null, it sets to ""
	 * @param songName if null, it sets to the current PlayState song!!!
	 */
	public static function getSongPath(?fileName:String = "", ?postfix:String = "", ?songName:String = null):String {
        if (songName == null || songName.length == 0) songName = PlayState.SONG.song;
		songName = Paths.formatToSongPath(songName.toLowerCase());
        return dataPathTemplate(ObjectsPath.songs + '$songName/', fileName, postfix);
	}
}