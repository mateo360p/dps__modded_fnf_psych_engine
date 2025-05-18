package objects.scriptables;

import substates.GameOverSubstate;

class Pico extends BaseCharacter {
    public static var neneToss:String = 'nene/NeneKnifeToss';
    public static var deadChar:String = 'pico-dead';
    public function new(_char:Character) {
        super(_char);

        switch (_char.curCharacter) {
            case "pico-christmas":
                neneToss = 'nene/neneChristmasKnife';
                deadChar = '';
            default:
                neneToss = 'nene/NeneKnifeToss';
                deadChar = 'pico-dead';
        }
    }

    override function create() {
        var _song = PlayState.SONG;
		if(_song.gameOverSound == null || _song.gameOverSound.trim().length < 1) GameOverSubstate.deathSoundName = 'death/fnf_loss_sfx-pico';
		if(_song.gameOverLoop == null || _song.gameOverLoop.trim().length < 1) GameOverSubstate.loopSoundName = 'death/pico/gameOver-pico';
		if(_song.gameOverEnd == null || _song.gameOverEnd.trim().length < 1) GameOverSubstate.endSoundName = 'death/pico/gameOverEnd-pico';
		if(_song.gameOverChar == null || _song.gameOverChar.trim().length < 1) GameOverSubstate.characterName = deadChar;
    }
}