package objects;

class SelectionPlayer extends SelectionCharacter {
    public var speaker:String = "gf";
    public var iconPositionArray:Array<Float> = [0, 0];

    public function new(x:Float, y:Float, player:String) {
        super(x, y, player, false);
    }

    override public function prepareAnimations(json:Dynamic) {
        super.prepareAnimations(json);
        // Slide anim chit
        playerAnimArr.push(json.animSlide);
        animList.push("slide");
    }

    override public function loadCharacterFile(json:Dynamic)
    {
        super.loadCharacterFile(json);
        speaker = json.speaker; // Adding gf/nene
        iconPositionArray = json.icon_position;
    }
}