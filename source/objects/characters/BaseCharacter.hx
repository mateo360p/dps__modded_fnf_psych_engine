package objects.characters;

/**
    This class is used for events and special stuff!!!.

    if u want to modify the actual buddy or data, go to `Character.hx`!
 */
class BaseCharacter extends FunkyObject {
    /**
     * The image with the data and other stuff!
     */
    public var char:Character; // The actual image, data, etc chits

    public function new(_character:Character) {
        super(CHARACTER);
        this.char = _character;
    }

    override public function create() {
        //FlxG.sound.play(Paths.sound((PlayState.DEF_HEY_SOUND)), PlayState.heyVolume); // Just for testing
    }
}