package objects;

import openfl.utils.Assets;
import haxe.Json;
import flixel.graphics.FlxGraphic;

typedef MenuCharacterFile = {
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipX:Bool;
	var antialiasing:Null<Bool>;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;
	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf') {
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
				var characterPath:String = 'images/menucharacters/' + character + '.json';

				var path:String = Paths.getPath(characterPath, TEXT);
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					// Codename Engine fallback: data/weeks/characters/<character>.xml
					if(Mods.isCodenameMod())
					{
						var codenameXmlPath:String = Paths.mods(Mods.currentModDirectory + '/data/weeks/characters/' + character + '.xml');
						if(FileSystem.exists(codenameXmlPath))
						{
							try
							{
								var xmlContent:String = File.getContent(codenameXmlPath);
								var charScale:Float = 1;
								var posX:Int = 0;
								var posY:Int = 0;
								var idleAnim:String = null;
								var confirmAnim:String = null;

								// Parse the XML manually (simple enough)
								// <char scale="0.6" x="260" y="70">
								if(xmlContent.indexOf('scale=') != -1)
								{
									var scaleMatch = ~/scale="([^"]+)"/;
									if(scaleMatch.match(xmlContent)) charScale = Std.parseFloat(scaleMatch.matched(1));
								}
								if(xmlContent.indexOf(' x=') != -1)
								{
									var xMatch = ~/ x="([^"]+)"/;
									if(xMatch.match(xmlContent)) posX = Std.parseInt(xMatch.matched(1));
								}
								if(xmlContent.indexOf(' y=') != -1)
								{
									var yMatch = ~/ y="([^"]+)"/;
									if(yMatch.match(xmlContent)) posY = Std.parseInt(yMatch.matched(1));
								}

								// Parse anims: <anim name="idle" anim="cookie idle" fps="12" loop="true"/>
								var animPattern = ~/anim\s+name="([^"]+)"\s+anim="([^"]+)"/;
								for(line in xmlContent.split("\n"))
								{
									if(animPattern.match(line))
									{
										var animName:String = animPattern.matched(1);
										var animPrefix:String = animPattern.matched(2);
										if(animName == "idle") idleAnim = animPrefix;
										else if(animName == "confirm") confirmAnim = animPrefix;
									}
								}

								// Load sprite from menus/storymenu/characters/
								var codenameSprite:String = 'menus/storymenu/characters/' + character;
								var codenameGraphic:FlxGraphic = Paths.image(codenameSprite);
								if(codenameGraphic != null)
								{
									frames = Paths.getSparrowAtlas(codenameSprite);
									var fps:Int = 24;
									var fpsMatch = ~/fps="(\d+)"/;
									if(fpsMatch.match(xmlContent)) fps = Std.parseInt(fpsMatch.matched(1));

									if(idleAnim != null)
										animation.addByPrefix('idle', idleAnim, fps, true);
									if(confirmAnim != null)
									{
										animation.addByPrefix('confirm', confirmAnim, fps, false);
										hasConfirmAnimation = true;
									}

									scale.set(charScale, charScale);
									updateHitbox();
									offset.set(posX, posY);
									if(animation.getByName('idle') != null)
										animation.play('idle');
									antialiasing = ClientPrefs.data.antialiasing;
									return;
								}
							}
							catch(e:Dynamic)
							{
								trace('Error loading Codename week character "$character": $e');
							}
						}
					}
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
					if (animation.getByName('confirm') != null) //check for invalid animation
						hasConfirmAnimation = true;
				}
				flipX = (charFile.flipX == true);

				if(charFile.scale != 1)
				{
					scale.set(charFile.scale, charFile.scale);
					updateHitbox();
				}
				offset.set(charFile.position[0], charFile.position[1]);
				animation.play('idle');

				antialiasing = (charFile.antialiasing != false && ClientPrefs.data.antialiasing);
		}
	}
}
