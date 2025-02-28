package objects;

import flxanimate.effects.FlxTint;
import openfl.filters.ConvolutionFilter;
import flxanimate.data.AnimationData.DropShadowFilter;
import openfl.display.BitmapData;
import shaders.StrokeShader;
import flixel.FlxSprite;

/**
 * DO NOT CONFUSE THIS WITH THE HEALTH ICON!!!
 * This one is used in the Player Selection State :D
 * Note: These are pixelated
 */
class PlayerIcon extends FlxSprite {
    public var locked(default, set):Bool = false;

    public var dropShadowFilter:DropShadowFilter;
    public var noDropShadow:BitmapData;
    public var withDropShadow:BitmapData;

    public var index:Int;

    var strokeShader:StrokeShader;
    var convolutionFilter:ConvolutionFilter;

    public var _lock:Lock;

    public function new(x:Float, y:Float, player:String, index:Int, locked:Bool = false) {
        super(x, y);
        this.index = index;
        this.active = false;

        this.makeGraphic(64, 64, 0x00000000);
        setPlayer(player, locked);

        antialiasing = false;
        strokeShader = new StrokeShader();
    }

    public function setPlayer(char:String, isLocked:Bool) {
        createLock();
        this.locked = isLocked;
        var isAnimated = openfl.utils.Assets.exists(Paths.getSharedPath('images/charSelect/playerAssets/' + char + '/icon.xml'));

        if (!isAnimated) {
            loadGraphic(Paths.image('charSelect/playerAssets/' + char + '/icon'));
        } else {
            this.frames = Paths.getSparrowAtlas('charSelect/playerAssets/' + char + '/icon');
            this.active = true;
            this.animation.addByPrefix('idle', 'idle0', 10, true);
            this.animation.addByPrefix('confirm', 'confirm0', 10, false);
            this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);

            this.animation.finishCallback = function(name:String):Void {
                trace('Finish pixel animation: ${name}');
                if (name == 'confirm') this.animation.play('confirm-hold');
            };

            this.animation.play('idle');
        }
        this.scale.x = this.scale.y = 2;
        updateHitbox();
        //this.origin.x = 100;
    }

    function createLock() {
        _lock = new Lock(this.x, this.y, this.index);
        MusicBeatState.getState().add(_lock); // Huh, this is akward
    }

    function set_locked(value:Bool):Bool {
        /*this.visible = !value;
        this._lock.visible = value;*/
        return locked = value;
    }
}

class Lock extends FlxAtlasSprite
{
    var colors:Array<FlxColor> = [
        0x31F2A5, 0x20ECCD, 0x24D9E8,
        0x20ECCD, 0x20C8D4, 0x209BDD,
        0x209BDD, 0x2362C9, 0x243FB9
    ]; // lock colors, in a nx3 matrix format; -- uhhhh alright

    override public function new(x:Float = 0, y:Float = 0, index:Int)
    {
        super(x, y, Paths.getSharedPath("images/charSelect/lock"));

        var tint:FlxTint = new FlxTint(colors[index], 1);
        var arr:Array<String> = ["lock", "lock top 1", "lock top 2", "lock top 3", "lock base fuck it"];

        var func = function(name) {
            var symbol = anim.symbolDictionary[name];
            if (symbol != null && symbol.timeline.get("color") != null) symbol.timeline.get("color").get(0).colorEffect = tint;
        }

        for (symbol in arr) func(symbol);

        playAnimation("idle");
    }
}