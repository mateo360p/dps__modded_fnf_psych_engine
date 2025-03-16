package objects;

class SelectionPlayer extends SelectionCharacter {
    public var speaker:String = "none";
    public var iconPositionArray:Array<Float> = [0, 0];

    public function new(x:Float, y:Float, player:String) {
        super(x, y, player);
    }

    override public function loadCharacterFile(json:Dynamic)
    {
        super.loadCharacterFile(json);
        if (json.speaker != null) speaker = json.speaker; // Adding gf/nene
        else speaker = "none";
        if (json.icon_position != null) iconPositionArray = json.icon_position;
        else iconPositionArray = [0, 0];
    }
}