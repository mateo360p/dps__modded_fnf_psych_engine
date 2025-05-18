package util;

import crowplexus.hscript.Types.ShortUInt;
import backend.WeekData;
import backend.WeekData.WeekFile;
import cutscenes.DialogueBoxPsych.DialogueLine;
import backend.Song.SwagSong;
import backend.LevelData.LevelFile;
import objects.MenuCharacter;
import objects.Character.AnimArray;
import objects.Character.CharacterFile;

class FileTemplates {
	public static function playerCharFile():CharacterFile {
		var dummy = charFile();
		dummy.animations = [
			charNewAnim('idle', 'bf cs idle'),
			charNewAnim('confirm', 'bf cs confirm'),
			charNewAnim('deselect', 'bf cs deselect'),
			charNewAnim('slide out', 'bf slide out'),
			charNewAnim('slide in', 'bf slide in')
		];
		dummy.hey_sound = "";
		dummy.hey_anim = "";
		dummy.image = 'charSelect/playerAssets/bf/bfChill';
        return dummy;
    }

    public static function charFile():CharacterFile {
        return {
			script_hxc: null,
            animations: [
                charNewAnim('idle', 'BF idle dance'),
                charNewAnim('singLEFT', 'BF NOTE LEFT0'),
                charNewAnim('singDOWN', 'BF NOTE DOWN0'),
                charNewAnim('singUP', 'BF NOTE UP0'),
                charNewAnim('singRIGHT', 'BF NOTE RIGHT0'),
                charNewAnim('hey', 'BF HEY')
            ],
            no_antialiasing: false,
            flip_x: false,
            healthicon: 'face',
            image: 'characters/BOYFRIEND',
            sing_duration: 4,
            scale: 1,
            healthbar_colors: [161, 161, 161],
            camera_position: [0, 0],
            position: [0, 0],
            hey_sound: null,
            hey_anim: null
        };
    }

    public static function charNewAnim(anim:String, name:String):AnimArray {
        return {
            offsets: [0, 0],
            loop: false,
            fps: 24,
            anim: anim,
            indices: [],
            name: name
        };
    }

    public static function menuCharFile():MenuCharacterFile {
        return {
			image: 'Menu_Dad',
			scale: 1,
			position: [0, 0],
			idle_anim: 'M Dad Idle',
			confirm_anim: 'M Dad Idle',
			confirm_offsets: [0, 0],
			flipX: false,
			antialiasing: true
		};
    }

    public static function weekFile():WeekFile {
		var weekFile:WeekFile = {
			levels: [
				["Bopeebo", DefaultValues.character],
				["Fresh", DefaultValues.character],
				["Dad Battle", DefaultValues.character]
			],
			player: DefaultValues.character,
			weekCharacters: DefaultValues.defaultCharacters,
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: '',
			weekColor: DefaultValues.weekColor,
			tweenTime: DefaultValues.weekTweenColorTime
		};
		return weekFile;
	}

    public static function levelFile():LevelFile {
		var levelFile:LevelFile = {
            levelDifficulties: '',
			songs: [
				["Bopeebo", "face", [146, 113, 253], ""],
				["Fresh", "face", [146, 113, 253], ""],
				["Dad Battle", "face", [146, 113, 253], ""]
			]
		};
		return levelFile;
	}

    public static function song():SwagSong {
        return {
			song: 'Test',
			notes: [],
			events: [],
			bpm: 150,
			needsVoices: true,
			speed: 2.5,
			offset: 0,
			eventsFile: '',
			audiosNames: DefaultValues.songAudiosNames,

            player2: DefaultValues.defaultCharacters[0],
			player1: DefaultValues.defaultCharacters[1],
			gfVersion: DefaultValues.defaultCharacters[2],
			stage: 'stage',
			format: 'psych_v1'
		};
    }

    public static function dialogueLine(?failedLoading:Bool = false):DialogueLine {
        return {
			portrait: DefaultValues.character,
			expression: 'talk',
			text: failedLoading ? "DIALOGUE NOT FOUND" : DefaultValues.dialogueText,
			boxState: DefaultValues.dialogueBubbleType,
			speed: 0.05,
			sound: ''
		};
    }
}
