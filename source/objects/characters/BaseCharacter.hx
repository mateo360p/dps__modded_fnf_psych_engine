package objects.characters;

typedef FakeOutAssets = {
    var char:String;
    var sound:String;
}

enum CharType {
    BF;
    GF;
    DAD;
    OTHER; // idk just in case
}
/**
    This class is used for events and special stuff!!!.

    if u want to modify the actual buddy or data, go to `Character.hx`!
 */
class BaseCharacter extends FunkyObject {
    /**
     * The image with the data and other stuff!
     */
    public var char:Character; // The actual image, data, etc chits

    /**
     * Probability in 1/[prob] to get a fakeout

     * If the char has a fakeout, it will play before dying

     * if 0 or less, or null, the fakeout is disabled
     * if 1, the fakeout is always played
     */
    @:isVar public var fakeOutProb(default, set):Int = 0;

    public var charType:CharType = OTHER;

    /**
     * If null, no fakeout :D
     */
    public var fakeOutAssets:FakeOutAssets = null;

    public function new(_character:Character) {
        super(CHARACTER);
        this.char = _character;
    }

    override public function create() {
        //FlxG.sound.play(Paths.sound((PlayState.DEF_HEY_SOUND)), PlayState.heyVolume); // Just for testing
    }

    function set_fakeOutProb(value:Null<Int>):Int {
        if (value == null || value < 0) return 0;
        fakeOutProb = value;
        return value;
    }
}