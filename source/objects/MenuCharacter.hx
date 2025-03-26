package objects;

import openfl.utils.Assets;
import haxe.Json;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var confirm_offsets:Array<Int>;
	var flipX:Bool;
	var antialiasing:Null<Bool>;
}

class MenuCharacter extends Character
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	public var confirmOffsets:Array<Int> = null;
	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, y:Float, character:String = 'bf', type:Int)
	{
		super(x, y);

		changeMenuCharacter(character, type);
	}

	override public function changeCharacter(character:String) {
		// Nothing :O
	}

	public function changeMenuCharacter(?character:String = 'bf', type:Int) {
		if(character == null) character = '';
		if(character == this.character) return;

		this.character = character;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();
		
		color = FlxColor.WHITE;
		alpha = 1;

		hasConfirmAnimation = false;
		switch(character) {
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				var characterPath:String = 'images/menucharacters/data/' + character + '.json';

				var path:String = Paths.getPath(characterPath, TEXT);
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
					color = FlxColor.BLACK;
					alpha = 0.6;
				}

				var charFile:MenuCharacterFile = null;
				try
				{
					#if MODS_ALLOWED
					charFile = Json.parse(File.getContent(path));
					#else
					charFile = Json.parse(Assets.getText(path));
					#end
				}
				catch(e:Dynamic)
				{
					trace('Error loading menu character file of "$character": $e');
				}

				frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				animation.addByPrefix('idle', charFile.idle_anim, 24);

				var confirmAnim:String = charFile.confirm_anim;
				if(confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim)
				{
					animation.addByPrefix('confirm', confirmAnim, 24, false);
					if (animation.getByName('confirm') != null) { //check for invalid animation
						hasConfirmAnimation = true;
						confirmOffsets = charFile.confirm_offsets;
					}
				}
				flipX = (charFile.flipX == true);

				if(charFile.scale != 1)
				{
					scale.set(charFile.scale, charFile.scale);
					updateHitbox();
				}
				var init:Float = (FlxG.width * 0.25) * (1 + type) - 150;
				setPosition(init + charFile.position[0], 70 + charFile.position[1]);
				animation.play('idle');

				antialiasing = (charFile.antialiasing != false && ClientPrefs.data.antialiasing);
		}
	}
}
