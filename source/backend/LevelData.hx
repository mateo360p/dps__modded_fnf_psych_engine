package backend;

typedef LevelFile =
{
	var levelDifficulties:String;
	/**
	 * SongArray
	 */
	var songs:Array<Dynamic>;
}

typedef SongArray =
{
	var songName:String;
    var icon:String;
    var songColors:Array<Float>;
    var extraDifficulties:String;
}

/**
 * So, the levels are a group of songs with a custom player and custom difficulties for each
 * ONLY (kinda) for Freeplay, StoryMode god
 */
class LevelData {

	public static var levelsLoaded:Map<String, LevelData> = new Map<String, LevelData>();
	public static var levelsList:Array<String> = [];
    public static var playersList:Array<String> = [];

    public var levelDifficulties:String;
	/**
	 * [ songName , icon , color[ ] , songExtraDiffs[ ] ]
	 */
	public var songs:Array<Dynamic>;

    public var fileName:String;
    public var levelWeek:String;

	public static function createLevelFile():LevelFile {
		var weekFile:LevelFile = {
            levelDifficulties: '',
			songs: [
				["Bopeebo", "face", [146, 113, 253], ""],
				["Fresh", "face", [146, 113, 253], ""],
				["Dad Battle", "face", [146, 113, 253], ""]
			]
		};
		return weekFile;
	}

    public function new(levelFile:LevelFile, fileName:String) {
		for (field in Reflect.fields(levelFile))
			if(Reflect.fields(this).contains(field))
				Reflect.setProperty(this, field, Reflect.getProperty(levelFile, field));

		this.fileName = fileName;
	}

	public static function reloadLevels(isStoryMode:Null<Bool> = false, ?player:String = '') {
        levelsList = [];
        levelsLoaded.clear();
        #if MODS_ALLOWED
        var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
        var originalLength:Int = directories.length;

        for (mod in Mods.parseList().enabled)
            directories.push(Paths.mods(mod + '/'));
        #else
        var directories:Array<String> = [Paths.getSharedPath()];
        var originalLength:Int = directories.length;
        #end
        if (isStoryMode) player = '';   //Loads every level, unless Freeplay
        // Coding war crimes #21
        for (i in 0...directories.length) {
            var directory:String = directories[i] + 'weeks/levels/';
            if(FileSystem.exists(directory)) {
                for (file in FileSystem.readDirectory(directory))
                {
                    var path = haxe.io.Path.join([directory, file]);
                    trace(path);
                    if (!FileSystem.isDirectory(path) && file.endsWith(player + '.json'))
                    {
                        addLevel(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
                    }
                }
            }
        }
    }

    
	private static function addLevel(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
    {
        if(!levelsLoaded.exists(weekToCheck))
        {
            var week:LevelFile = getLevelFile(path);
            if(week != null)
            {
                var levelFile:LevelData = new LevelData(week, weekToCheck);
                var levelWeekData:WeekData = WeekData.getWeekFromLevel(levelFile);
                levelFile.levelWeek = levelWeekData.fileName;
                if((PlayState.isStoryMode && !levelWeekData.hideStoryMode) || (!PlayState.isStoryMode && !levelWeekData.hideFreeplay))
                {
                    levelsLoaded.set(weekToCheck, levelFile);
                    levelsList.push(weekToCheck);
                }
            }
        }
    }

	private static function getLevelFile(path:String):LevelFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			rawJson = File.getContent(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

    public static function loadPlayers() {
        playersList = [];
        var added:Array<String> = [];
        try {
            for (player in CoolUtil.coolTextFile(Paths.getSharedPath('players/playersList.txt')))
            {
                if (player == "-" || player == null || player == "" || player == "\n") continue;
                if(player.trim().length > 0 && !added.contains(player))
                {
                    added.push(player);
                    playersList.push(player);
                }
            }
        } catch(e) {
            trace(e);
        }
    }
}