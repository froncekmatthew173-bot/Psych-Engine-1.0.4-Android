package backend;

import haxe.Json;
import lime.utils.Assets;

import objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var spamAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		// prevent any saving errors by fixing the path on Windows (being the only OS to ever use backslashes instead of forward slashes for paths)
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		if(FileSystem.exists(_lastPath))
			rawData = File.getContent(_lastPath);
		else
		{
			// Check for Codename Engine chart format: songs/<name>/charts/<difficulty>.json
			// Extract difficulty from jsonInput (e.g., "song-hard" -> "hard")
			var diff:String = formattedSong;
			var songName:String = formattedFolder;

			// If jsonInput contains the song name + difficulty, split them
			if(formattedSong.startsWith(formattedFolder + "-"))
			{
				songName = formattedFolder;
				diff = formattedSong.substr(formattedFolder.length + 1);
			}
			else if(formattedFolder != formattedSong)
			{
				songName = formattedFolder;
				diff = formattedSong;
			}

			// Try Codename format: songs/<name>/charts/<difficulty>.json
			var codenamePath:String = Paths.mods(Mods.currentModDirectory + '/songs/$songName/charts/$diff.json');
			if(FileSystem.exists(codenamePath))
			{
				rawData = File.getContent(codenamePath);
				_lastPath = codenamePath;
			}
			else
			{
				// Try global mods
				for(mod in Mods.getGlobalMods())
				{
					var modCodenamePath:String = Paths.mods('$mod/songs/$songName/charts/$diff.json');
					if(FileSystem.exists(modCodenamePath))
					{
						rawData = File.getContent(modCodenamePath);
						_lastPath = modCodenamePath;
						break;
					}
				}
			}

			// Also try with "normal" difficulty as default
			if(rawData == null)
			{
				var normalPath:String = Paths.mods(Mods.currentModDirectory + '/songs/$songName/charts/normal.json');
				if(FileSystem.exists(normalPath))
				{
					rawData = File.getContent(normalPath);
					_lastPath = normalPath;
				}
			}

			// Merge events from separate events.json if it exists (Codename format)
			if(rawData != null)
			{
				var eventsPath:String = Paths.mods(Mods.currentModDirectory + '/songs/$songName/events.json');
				if(FileSystem.exists(eventsPath))
				{
					try
					{
						var eventsData:String = File.getContent(eventsPath);
						var eventsJson:Dynamic = haxe.Json.parse(eventsData);
						var songJson:Dynamic = haxe.Json.parse(rawData);
						if(Reflect.hasField(songJson, "song"))
							songJson = Reflect.field(songJson, "song");
						// Merge events
						if(Reflect.hasField(eventsJson, "events"))
						{
							var existingEvents:Array<Dynamic> = Reflect.hasField(songJson, "events") ? Reflect.field(songJson, "events") : [];
							var newEvents:Array<Dynamic> = Reflect.field(eventsJson, "events");
							for(evt in newEvents)
								existingEvents.push(evt);
							Reflect.setField(songJson, "events", existingEvents);
						}
						rawData = haxe.Json.stringify(songJson);
					}
					catch(e:Dynamic)
					{
						trace('Error merging Codename events.json: $e');
					}
				}
			}
		}
		#else
			rawData = Assets.getText(_lastPath);
		#end

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if(fmt == null) fmt = songJson.format = 'unknown';

			switch(convertTo)
			{
				case 'psych_v1':
					if(!fmt.startsWith('psych_v1')) //Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}

		// Check if this is a Codename Engine chart (no format field or different structure)
		if(songJson.format == null || (!songJson.format.startsWith('psych') && !songJson.format.startsWith('codename')))
		{
			// Try to convert from Codename format
			var converted:Dynamic = CodenameCompat.convertChartJson(rawData, nameForError);
			if(converted != null)
			{
				trace('Converted Codename chart for $nameForError to Psych format');
				songJson = cast converted;
				songJson.format = 'psych_v1_convert';
			}
		}

		// If notes are still null after conversion (e.g. strumLines format not handled by built-in convert), try Codename conversion
		var notesArr:Array<Dynamic> = songJson.notes;
		if(notesArr == null || notesArr.length == 0)
		{
			trace('Notes null/empty after initial conversion for $nameForError, trying Codename compat...');
			var converted:Dynamic = CodenameCompat.convertChartJson(rawData, nameForError);
			if(converted != null)
			{
				trace('Converted Codename chart for $nameForError to Psych format (fallback)');
				songJson = cast converted;
				songJson.format = 'psych_v1_convert';
			}
		}

		return songJson;
	}
}
