package util.polymod;

import objects.scriptables.ScriptableStage;
import objects.scriptables.ScriptableCharacter;
import objects.Character;
import polymod.Polymod;

class PolymodHelper {
    public static function initialize() {
        var params = {
			modRoot: "mods/",
			useScriptedClasses: true
		}

		buildImports();

		Polymod.init(params);
		Polymod.registerAllScriptClasses();
    }

	static function buildImports():Void {
		/* Idk if I should import this ones
		#if DISCORD_ALLOWED
		Polymod.addDefaultImport(DiscordClient);
		#end

		#if LUA_ALLOWED
		Polymod.addDefaultImport(llua.Lua);
		#end

		#if ACHIEVEMENTS_ALLOWED
		Polymod.addDefaultImport(backend.Achievements);
		#end
		*/

		//----------------------------- Def Imports -------------------------------------

		Polymod.addDefaultImport(Paths);
		Polymod.addDefaultImport(Controls);
		Polymod.addDefaultImport(MusicBeatState);
		Polymod.addDefaultImport(MusicBeatSubstate);
		Polymod.addDefaultImport(ClientPrefs);
		Polymod.addDefaultImport(Character);
		Polymod.addDefaultImport(Difficulty);
		Polymod.addDefaultImport(Conductor);
		Polymod.addDefaultImport(FunkyObject);
		Polymod.addDefaultImport(util.PathsUtil);
		Polymod.addDefaultImport(util.CoolUtil);
		Polymod.addDefaultImport(Alphabet);
		Polymod.addDefaultImport(BGSprite);
		Polymod.addDefaultImport(PlayState);
		Polymod.addDefaultImport(LoadingState);
		Polymod.addDefaultImport(Note);
		Polymod.addDefaultImport(NoteSplash);
		Polymod.addDefaultImport(VideoSprite);
		//Polymod.addDefaultImport();

		Polymod.addDefaultImport(ScriptableCharacter);
		Polymod.addDefaultImport(ScriptableStage);

		#if flxanimate
		Polymod.addDefaultImport(PsychFlxAnimate);
		#end

		Polymod.addDefaultImport(substates.GameOverSubstate);
		Polymod.addDefaultImport(substates.PauseSubState);

		Polymod.addDefaultImport(flixel.sound.FlxSound);
		Polymod.addDefaultImport(flixel.FlxG);
		Polymod.addDefaultImport(FlxSprite);
		Polymod.addDefaultImport(FlxCamera);
		Polymod.addDefaultImport(FlxMath);
		//Polymod.addDefaultImport(FlxPoint);
		//Polymod.addDefaultImport(FlxColor);
		Polymod.addDefaultImport(FlxTimer);
		Polymod.addDefaultImport(FlxText);
		Polymod.addDefaultImport(FlxEase);
		Polymod.addDefaultImport(FlxTween);
		Polymod.addDefaultImport(FlxTypedGroup);
		Polymod.addDefaultImport(flixel.group.FlxGroup);
		Polymod.addDefaultImport(flixel.group.FlxSpriteGroup);

		//----------------------------- "Protectives" -------------------------------------

		// Needs explanation?
		Polymod.blacklistImport("Sys");
		Polymod.blacklistImport("lime.system.System");
		Polymod.blacklistImport("lime.system.CFFI");
		Polymod.blacklistImport("lime.utils.Assets");
		Polymod.blacklistImport("lime.system.JNI");
		Polymod.blacklistImport("openfl.system.ApplicationDomain");
		Polymod.blacklistImport("openfl.utils.Assets");
		Polymod.blacklistImport("openfl.desktop.NativeProcess");
		Polymod.blacklistImport("openfl.Lib");

		// This shits can access blacklisted packages!!!
		Polymod.blacklistImport("Unserializer");
		Polymod.blacklistImport("Type");
		Polymod.blacklistImport("Reflect");

		// This can load DLLS, that's not a great idea
		Polymod.blacklistImport("cpp.Lib");
	}
}