package util;

/**
 * Obviously not ALL the default values will be here

 * Just the "most relevant" ones
 */
class DefaultValues {

    /**
	 * The default character for basically everything

	 * In case a character is missing, it will use this on its place
	**/
	public static final character:String = 'bf';
	public static final defaultCharacters:Array<String> = [#if BASE_GAME_FILES 'dad' #else character #end, character, 'gf'];

    // Hehe stuff
    public static final heheSound:String = 'hehe/eh';
	public static final heheAnim:String = 'hey';

    // Song Audios
    public static final songAudiosNames:Array<String> = ['Inst', 'Voices-Player', 'Voices-Opponent'];
    public static final audioDisable:String = 'none';

    /////-------------------------------------- Not so useful --------------------------------------
    // Week Stuff
    public static final weekColor:Array<Int> = [249, 207, 81]; //0xFFF9CF51
	public static final weekTweenColorTime:Float = 0.5;

    // Dialogues
    public static final dialogueText:String = "coolswagger";
	public static final dialogueSpeed:Float = 0.05;
	public static final dialogueBubbleType:String = "normal";

    public static function prepareSongAudios(arr:Array<String>) {
        if (arr == null || arr == []) {
            arr = songAudiosNames.copy();
            return;
        }

        for (i in 0...songAudiosNames.length)
            if (arr[i] == null || arr[i] == '') arr[i] = songAudiosNames[i];
    }
}