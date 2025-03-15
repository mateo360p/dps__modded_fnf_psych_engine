package objects;

import states.FreeplayState;
import openfl.utils.Assets;
import openfl.filters.DropShadowFilter;
import openfl.filters.BitmapFilter;
import backend.FlxFilteredSprite;
import flxanimate.effects.FlxTint;
import openfl.filters.ConvolutionFilter;
import openfl.display.BitmapData;
import shaders.StrokeShader;
import flixel.FlxSprite;

/**
 * DO NOT CONFUSE THIS WITH THE HEALTH ICON!!!
 * This one is used in the Player Selection State :D
 * Note: These are pixelated
 */
class PlayerIcon extends FlxFilteredSprite {
    public var locked(default, set):Bool = false;
    public var scaleTween:FlxTween;

    public var isAnimated:Bool;
    public var index:Int;

    public var _lock:Lock;

    var focusedFilters:Array<BitmapFilter> = [
        new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
        new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
    ];

    public var focused(default, set):Bool = false; // MmmMmMmm maybe make this static?

    public function new(x:Float, y:Float, player:String, index:Int, locked:Bool = false) {
        super(x, y);
        this.index = index;
        this.active = false;

        createLock();
        this.locked = locked;

        //if (player == null) player = FreeplayState.DEF_PLAYER;
        setPlayer(player);

        antialiasing = false;
    }

    public function setPlayer(char:String) {
        isAnimated = Assets.exists(Paths.getSharedPath('images/charSelect/playerAssets/' + char + '/icon.xml'));

        if (!Assets.exists(Paths.getSharedPath('images/charSelect/playerAssets/' + char + '/icon.png'))) {
            this.color = FlxColor.BLACK;
            this.alpha = 0.6;
            return;
        } else {
            this.color = FlxColor.WHITE;
            this.alpha = 1;
        }

        if (!isAnimated) {
            loadGraphic(Paths.image('charSelect/playerAssets/' + char + '/icon'));
        } else {
            this.frames = Paths.getSparrowAtlas('charSelect/playerAssets/' + char + '/icon');
            this.active = true;
            this.animation.addByPrefix('idle', 'idle0', 10, true);
            this.animation.addByPrefix('confirm', 'confirm0', 10, false);
            this.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);
            this.animation.addByPrefix('revert', 'confirm0', 10, false);

            this.animation.finishCallback = function(name:String):Void {
                trace('Finish pixel animation: ${name}');
                if (name == 'confirm') this.animation.play('confirm-hold');
                if (name == 'revert') this.animation.play('idle');
            };

            this.animation.play('idle');
        }
        this.scale.set(2, 2);
        updateHitbox();
    }

    public function playAnimation(confirm:Bool) {
        if (isAnimated) {
            // WAIT WE CAN DO THIS?
            switch (confirm) {
                case true:
                    this.animation.play("confirm");
                case false:
                    this.animation.play("revert", true, true);
            }
        }
    }

    function createLock() {
        _lock = new Lock(this.x, this.y, this.index);
    }

    function set_locked(value:Bool):Bool {
        this.visible = !value;
        this._lock.visible = value;
        return locked = value;
    }

    function set_focused(value:Bool):Bool {
        if (focused == value) return value;

        if (value) {
            this.filters = focusedFilters;
            this._lock.playAnimation("selected");
            scaleTween = FlxTween.tween(this.scale, {x: 2.6, y: 2.6}, 0.1, {ease: FlxEase.elasticOut, onComplete: function(_) _ == null});
        } else {
            this.filters = null;
            this._lock.playAnimation("idle");
            if (scaleTween != null) scaleTween.cancel();
            this.scale.set(2, 2);
        }
        return (focused = value);
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