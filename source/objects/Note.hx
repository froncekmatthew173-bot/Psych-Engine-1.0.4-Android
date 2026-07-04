package objects;

import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String,
	?params:Array<Dynamic>
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

/**
 * The note object used as a data structure to spawn and manage notes during gameplay.
 * 
 * If you want to make a custom note type, you should search for: "function set_noteType"
**/
class Note extends FlxSprite
{
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var strumTime:Float = 0;
	public var noteData:Int = 0;
	public var maniaKeyCount:Int = 4;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var threeDColArray:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'alt A'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var texture(default, set):String = null;
	public var loadedTexture(default, null):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		//trace('fuck cock');
		return value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);

		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		if(is3DNoteTexture(loadedTexture) || (PlayState.SONG != null && is3DNoteTexture(PlayState.SONG.arrowSkin)))
		{
			rgbShader.enabled = true;
			noteSplashData.useRGBShader = false;
			return;
		}

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData];

		if (arr != null && noteData > -1 && noteData <= arr.length)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
		else
		{
			rgbShader.r = 0xFFFF0000;
			rgbShader.g = 0xFF00FF00;
			rgbShader.b = 0xFF0000FF;
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
		defaultRGB();

		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
			noteType = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null, ?keyCount:Int = 4)
	{
		super();

		animation = new PsychAnimationController(this);

		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;

		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;

		this.noteData = noteData;
		this.maniaKeyCount = keyCount;

		if(noteData > -1)
		{
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			texture = '';

			x += swagWidth * (noteData);
			var noteProfile:Array<String> = getProfileForTexture(loadedTexture, maniaKeyCount);
			if(!isSustainNote && noteData < noteProfile.length) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = noteProfile[noteData % noteProfile.length];
				var scrollAnim:String = animToPlay + 'Scroll';
				if(animation.exists(scrollAnim))
					animation.play(scrollAnim);
			}
		}

		// trace(prevNote);

		if(prevNote != null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			alpha = 1;
			multAlpha = 1;
			hitsoundDisabled = true;
			if(ClientPrefs.data.downScroll) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			var sustainProfile:Array<String> = getProfileForTexture(loadedTexture, maniaKeyCount);
			var tailAnim:String = sustainProfile[noteData % sustainProfile.length] + 'tail';
			if(animation.exists(tailAnim))
				animation.play(tailAnim);

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage)
				offsetX += 30;

			if (prevNote.isSustainNote)
			{
				var prevProfile:Array<String> = getProfileForTexture(prevNote.loadedTexture, prevNote.maniaKeyCount);
				var holdAnim:String = prevProfile[prevNote.noteData % prevProfile.length] + 'hold';
				if(prevNote.animation.exists(holdAnim))
					prevNote.animation.play(holdAnim);

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;

				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); //Auto adjust note size
				}
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}

			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[noteData % ClientPrefs.data.arrowRGB.length] : ClientPrefs.data.arrowRGBPixel[noteData % ClientPrefs.data.arrowRGBPixel.length];
			
			if (arr != null && noteData > -1 && noteData <= arr.length)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
			else
			{
				newRGB.r = 0xFFFF0000;
				newRGB.g = 0xFF00FF00;
				newRGB.b = 0xFF0000FF;
			}
			
			globalRgbShaders[noteData] = newRGB;
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String; //optimization
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0; //dont mess with this
	public function reloadNote(texture:String = '', postfix:String = '') {
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';
		loadedTexture = skin;
		if(is3DNoteTexture(loadedTexture))
		{
			rgbShader.enabled = true;
			noteSplashData.useRGBShader = false;
		}

		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / 4), Math.floor(graphic.height / 5));
			}
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;

			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(is3DNoteTexture(loadedTexture))
				antialiasing = false;
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}

		if(isSustainNote) {
			scale.y = lastScaleY;
			pixelPerfectRender = true;
			antialiasing = false;
		}
		updateHitbox();

		if(animName != null && animation.exists(animName))
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		var profile:Array<String> = getProfileForTexture(loadedTexture, maniaKeyCount);
		if (profile[noteData] == null)
			return;

		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true); // this fixes some retarded typo from the original note .FLA
			var usesLetterAtlas:Bool = isLetterProfile(profile[noteData]);
			if (usesLetterAtlas) {
				if(!addFirstMatchingAnimation(profile[noteData] + 'tail', [
					profile[noteData] + ' hold end0000',
					profile[noteData] + ' hold end',
					profile[noteData] + ' tail0000',
					profile[noteData] + ' tail'
				])) return;
				if(!addFirstMatchingAnimation(profile[noteData] + 'hold', [
					profile[noteData] + ' hold piece0000',
					profile[noteData] + ' hold piece',
					profile[noteData] + ' hold0000',
					profile[noteData] + ' hold'
				])) return;
			}
			else {
				if(!addFirstMatchingAnimation(profile[noteData] + 'tail', [
					profile[noteData] + ' hold end0000',
					profile[noteData] + ' hold end',
					profile[noteData] + ' tail0000',
					profile[noteData] + ' tail',
					'pruple end hold'
				])) return;
				if(!addFirstMatchingAnimation(profile[noteData] + 'hold', [
					profile[noteData] + ' hold piece0000',
					profile[noteData] + ' hold piece',
					profile[noteData] + ' hold0000',
					profile[noteData] + ' hold'
				])) return;
			}
		}
		else animation.addByPrefix(profile[noteData] + 'Scroll', profile[noteData] + '0');

		setGraphicSize(Std.int(width * getKeyScale(maniaKeyCount)));
		updateHitbox();
	}

	public static function is3DNoteTexture(texture:String):Bool
		return texture != null && texture.toLowerCase().contains('3d');

	public static function getProfileForTexture(texture:String, ?keyCount:Int = 4):Array<String>
	{
		if(!is3DNoteTexture(texture))
			return get2DProfile(keyCount);

		return get3DProfile(keyCount);
	}

	public static function get2DProfile(?keyCount:Int = 4):Array<String>
	{
		return switch(keyCount)
		{
			case 1: ['E'];
			case 2: ['A', 'D'];
			case 3: ['A', 'E', 'D'];
			case 4: ['purple', 'blue', 'green', 'red'];
			case 5: ['A', 'B', 'E', 'C', 'D'];
			case 6: ['A', 'C', 'D', 'F', 'B', 'I'];
			case 7: ['A', 'C', 'D', 'E', 'F', 'B', 'I'];
			case 8: ['A', 'B', 'C', 'D', 'F', 'G', 'H', 'I'];
			case 9: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];
			default: ['purple', 'blue', 'green', 'red'];
		}
	}

	static function isLetterProfile(prefix:String):Bool
	{
		if(prefix == null || prefix.length == 0)
			return false;

		return prefix.startsWith('alt ') || ~/^[A-I]$/.match(prefix);
	}

	public static function getLaneColorIndex(texture:String, ?keyCount:Int = 4, ?lane:Int = 0):Int
	{
		var profile:Array<String> = getProfileForTexture(texture, keyCount);
		if(profile == null || profile.length == 0)
			return Std.int(Math.abs(lane)) % 4;

		var key:String = profile[Std.int(Math.abs(lane)) % profile.length];
		return switch(key)
		{
			case 'A' | 'F' | 'alt A' | 'purple': 0;
			case 'B' | 'G' | 'blue': 1;
			case 'C' | 'H' | 'green': 2;
			case 'D' | 'I' | 'red': 3;
			case 'E': 0;
			default: Std.int(Math.abs(lane)) % 4;
		}
	}

	public static function get3DProfile(?keyCount:Int = 4):Array<String>
	{
		return switch(keyCount)
		{
			case 1: threeDProfile([4]);
			case 2: threeDProfile([0, 3]);
			case 3: threeDProfile([0, 4, 3]);
			case 4: threeDProfile([0, 1, 2, 3]);
			case 5: threeDProfile([0, 1, 4, 2, 3]);
			case 6: threeDProfile([9, 2, 3, 5, 1, 8]);
			case 7: threeDProfile([0, 2, 3, 4, 5, 1, 8]);
			case 8: threeDProfile([0, 1, 2, 3, 5, 6, 7, 8]);
			case 9: threeDProfile([0, 1, 2, 3, 4, 5, 6, 7, 8]);
			default: threeDProfile([0, 1, 2, 3]);
		}
	}

	static function threeDProfile(indices:Array<Int>):Array<String>
	{
		var profile:Array<String> = [];
		for(index in indices)
			profile.push(threeDColArray[index]);
		return profile;
	}

	public static function getSingAnimations(?keyCount:Int = 4):Array<String>
	{
		return switch(keyCount)
		{
			case 1: ['singUP'];
			case 2: ['singLEFT', 'singRIGHT'];
			case 3: ['singLEFT', 'singUP', 'singRIGHT'];
			case 4: ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			case 5: ['singLEFT', 'singDOWN', 'singSPACE', 'singUP', 'singRIGHT'];
			case 6: ['singLEFT-alt', 'singUP', 'singRIGHT', 'singLEFT', 'singDOWN', 'singRIGHT-alt'];
			case 7: ['singLEFT', 'singUP', 'singRIGHT', 'singUP', 'singLEFT', 'singDOWN', 'singRIGHT'];
			case 8: ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			case 9: ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT', 'singUP', 'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
			default: ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
		}
	}

	public static function getKeyScale(?keyCount:Int = 4):Float
	{
		return switch(keyCount)
		{
			case 1: 0.7;
			case 2: 0.7;
			case 3: 0.7;
			case 4: 0.7;
			case 5: 0.65;
			case 6: 0.6;
			case 7: 0.55;
			case 8: 0.5;
			case 9: 0.46;
			default: 0.7;
		}
	}

	function loadPixelNoteAnims() {
		if (colArray[noteData] == null)
			return;

		if(isSustainNote)
		{
			animation.add(colArray[noteData] + 'tail', [noteData + 4], 24, true);
			animation.add(colArray[noteData] + 'hold', [noteData], 24, true);
		} else animation.add(colArray[noteData] + 'Scroll', [noteData + 4], 24, true);
	}

	function addFirstMatchingAnimation(name:String, prefixes:Array<String>, framerate:Float = 24, doLoop:Bool = true):Bool
	{
		for(prefix in prefixes)
			if(attemptToAddAnimationByPrefix(name, prefix, framerate, doLoop))
				return true;
		return false;
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true):Bool
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return false;

		animation.addByPrefix(name, prefix, framerate, doLoop);
		return true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	public function followStrumNote(myStrum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		var strumX:Float = myStrum.x;
		var strumY:Float = myStrum.y;
		var strumAngle:Float = myStrum.angle;
		var strumAlpha:Float = myStrum.alpha;
		var strumDirection:Float = myStrum.direction;

		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed);
		if (!myStrum.downScroll) distance *= -1;

		var angleDir = strumDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumDirection - 90 + strumAngle + offsetAngle;

		if(copyAlpha)
			alpha = strumAlpha * multAlpha;

		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;

		if(copyY)
		{
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
			if(myStrum.downScroll && isSustainNote)
			{
				if(PlayState.isPixelStage)
				{
					y -= PlayState.daPixelZoom * 9.5;
				}
				y -= (frameHeight * scale.y) - (Note.swagWidth / 2);
			}

			// Sustain bodies are stacked from separate sprites. Keeping their render position
			// on whole pixels prevents the thin seams caused by fractional overlap at segment joins.
			if(isSustainNote)
				y = Math.round(y);
		}
	}

	public function clipToStrumNote(myStrum:StrumNote)
	{
		var center:Float = myStrum.y + offsetY + Note.swagWidth / 2;
		if((mustPress || !ignoreNote) && (wasGoodHit || (prevNote.wasGoodHit && !canBeHit)))
		{
			var swagRect:FlxRect = clipRect;
			if(swagRect == null) swagRect = new FlxRect(0, 0, frameWidth, frameHeight);

			if (myStrum.downScroll)
			{
				if(y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			}
			else if (y + offset.y * scale.y <= center)
			{
				swagRect.y = (center - y) / scale.y;
				swagRect.width = width / scale.x;
				swagRect.height = (height / scale.y) - swagRect.y;
			}
			clipRect = swagRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}