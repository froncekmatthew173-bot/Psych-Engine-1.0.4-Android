package objects;

import backend.animation.PsychAnimationController;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var keyCount:Int = 4;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int, ?keyCount:Int = 4) {
		animation = new PsychAnimationController(this);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData % ClientPrefs.data.arrowRGB.length];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData % ClientPrefs.data.arrowRGBPixel.length];
		
		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		noteData = leData;
		this.keyCount = keyCount;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = Note.is3DNoteTexture(texture) ? false : ClientPrefs.data.antialiasing;
			if(Note.is3DNoteTexture(texture))
			{
				useRGBShader = true;
				rgbShader.enabled = false;
			}
			setGraphicSize(Std.int(width * Note.getKeyScale(keyCount)));

			if(Note.is3DNoteTexture(texture))
			{
				var letters:Array<String> = Note.getProfileForTexture(texture, keyCount);
				var key:String = letters[Std.int(Math.abs(noteData)) % letters.length];
				var staticPrefix:String = switch(key)
				{
					case 'A' | 'F' | 'purple': 'arrowLEFT';
					case 'B' | 'G' | 'blue': 'arrowDOWN';
					case 'C' | 'H' | 'green': 'arrowUP';
					case 'D' | 'red': 'arrowRIGHT';
					case 'E': 'arrowSPACE';
					case 'I': 'alt arrowright';
					case 'alt A': 'alt arrowLEFT';
					default: 'arrowRIGHT';
				}
				animation.addByPrefix('static', staticPrefix);
				animation.addByPrefix('pressed', key + ' press', 24, false);
				animation.addByPrefix('confirm', key + ' confirm', 24, false);
			}
			else
			{
				var profile:Array<String> = Note.get2DProfile(keyCount);
				var key:String = profile[Std.int(Math.abs(noteData)) % profile.length];
				var staticPrefix:String = switch(key)
				{
					case 'A' | 'F' | 'purple': 'arrowLEFT';
					case 'B' | 'G' | 'blue': 'arrowDOWN';
					case 'C' | 'H' | 'green': 'arrowUP';
					case 'D' | 'red': 'arrowRIGHT';
					case 'E': 'arrowSPACE';
					case 'I': 'alt arrowright';
					case 'alt A': 'alt arrowLEFT';
					default: 'arrowRIGHT';
				}
				var animPrefix:String = switch(key)
				{
					case 'A' | 'F' | 'purple': 'left';
					case 'B' | 'G' | 'blue': 'down';
					case 'C' | 'H' | 'green': 'up';
					case 'D' | 'red': 'right';
					case 'E': 'space';
					case 'I': 'alt right';
					case 'alt A': 'alt left';
					default: 'right';
				}
				animation.addByPrefix('static', staticPrefix);
				animation.addByPrefix('pressed', animPrefix + ' press', 24, false);
				animation.addByPrefix('confirm', animPrefix + ' confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function playerPosition()
	{
		var gap:Float = switch(keyCount)
		{
			case 1: width;
			case 2: width + 30;
			case 3: width + 10;
			case 4: Note.swagWidth;
			case 5: width - 10;
			case 6: width - 20;
			case 7: width - 32;
			case 8: width - 40;
			case 9: width - 45;
			default: Note.swagWidth;
		}
		var xOffset:Float = switch(keyCount)
		{
			case 1: -100;
			case 2: -75;
			case 3: -50;
			case 4: 0;
			case 5: 35;
			case 6: 45;
			case 7: 52;
			case 8: 57;
			case 9: 65;
			default: 0;
		}
		var yOffset:Float = switch(keyCount)
		{
			case 5: 10;
			case 6 | 7: 25;
			case 8 | 9: 40;
			default: 0;
		}
		x += gap * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		x -= xOffset;
		y += yOffset;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader && !Note.is3DNoteTexture(texture))
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
		else rgbShader.enabled = false;
	}
}