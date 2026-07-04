package backend;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import haxe.Json;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:String;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "face", [146, 113, 253]], ["Fresh", "face", [146, 113, 253]], ["Dad Battle", "face", [146, 113, 253]]],
			#if BASE_GAME_FILES
			weekCharacters: ['dad', 'bf', 'gf'],
			#else
			weekCharacters: ['bf', 'bf', 'gf'],
			#end
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String) {
		// here ya go - MiguelItsOut
		for (field in Reflect.fields(weekFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getSharedPath()];
		var originalLength:Int = directories.length;

		for (mod in Mods.parseList().enabled)
			directories.push(Paths.mods(mod + '/'));
		#else
		var directories:Array<String> = [Paths.getSharedPath()];
		var originalLength:Int = directories.length;
		#end

		var sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('weeks/weekList.txt'));
		for (i in 0...sexList.length) {
			for (j in 0...directories.length) {
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if(!weeksLoaded.exists(sexList[i])) {
					var week:WeekFile = getWeekFile(fileToCheck);
					if(week != null) {
						var weekFile:WeekData = new WeekData(week, sexList[i]);

						#if MODS_ALLOWED
						if(j >= originalLength) {
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length-1);
						}
						#end

						if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay))) {
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in Paths.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}

			// Scan for Codename Engine XML week files in data/weeks/weeks/
			var codenameWeekDir:String = directories[i] + 'data/weeks/weeks/';
			if(FileSystem.exists(codenameWeekDir))
			{
				for (file in Paths.readDirectory(codenameWeekDir))
				{
					var path = haxe.io.Path.join([codenameWeekDir, file]);
					if (!FileSystem.isDirectory(path) && file.endsWith('.xml'))
					{
						var weekName:String = file.substr(0, file.length - 4);
						if(!weeksLoaded.exists(weekName))
						{
							addWeek(weekName, path, directories[i], i, originalLength);
						}
					}
				}
			}

			// Also scan Codename songs/ folder for meta.json files to create freeplay entries
			var codenameSongsDir:String = directories[i] + 'songs/';
			if(FileSystem.exists(codenameSongsDir))
			{
				for (songFolder in Paths.readDirectory(codenameSongsDir))
				{
					var songFolderPath:String = haxe.io.Path.join([codenameSongsDir, songFolder]);
					if(FileSystem.isDirectory(songFolderPath))
					{
						var metaPath:String = haxe.io.Path.join([songFolderPath, 'meta.json']);
						if(FileSystem.exists(metaPath))
						{
							// Create a week entry for this song if it doesn't exist
							var weekName:String = 'codename_' + songFolder;
							if(!weeksLoaded.exists(weekName))
							{
								try
								{
									var metaContent:String = File.getContent(metaPath);
									var meta:Dynamic = CodenameCompat.convertMetaJson(metaContent);
									if(meta != null)
									{
										var weekFile:WeekFile = {
											songs: [[meta.songName, "face", [146, 113, 253]]],
											weekCharacters: ["", "bf", ""],
											weekBackground: "stage",
											weekBefore: "",
											storyName: meta.displayName,
											weekName: meta.displayName,
											startUnlocked: true,
											hiddenUntilUnlocked: false,
											hideStoryMode: false,
											hideFreeplay: false,
											difficulties: ""
										};

										var weekData:WeekData = new WeekData(weekFile, weekName);
										if(i >= originalLength)
										{
											weekData.folder = directories[i].substring(Paths.mods().length, directories[i].length-1);
										}

										if((PlayState.isStoryMode && !weekData.hideStoryMode) || (!PlayState.isStoryMode && !weekData.hideFreeplay))
										{
											weeksLoaded.set(weekName, weekData);
											weeksList.push(weekName);
										}
									}
								}
								catch(e:Dynamic)
								{
									trace('Error loading Codename song meta for "$songFolder": $e');
								}
							}
						}
					}
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length-1);
					#end
				}
				if((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			// If path is already an XML file (from Codename week scan), convert directly
			if(path.endsWith('.xml'))
			{
				try
				{
					var xmlContent:String = File.getContent(path);
					var convertedJson:Dynamic = CodenameCompat.convertWeekXml(xmlContent);
					if(convertedJson != null)
						return cast convertedJson;
				}
				catch(e:Dynamic)
				{
					trace('Error converting Codename week XML: $e');
				}
				return null;
			}
			rawJson = File.getContent(path);
		}

		// Check for Codename Engine XML week file
		if(rawJson == null || rawJson.length == 0)
		{
			// Convert JSON path to XML path (weeks/name.json -> data/weeks/weeks/name.xml)
			var xmlPath:String = path.replace('weeks/', 'data/weeks/weeks/').replace('.json', '.xml');
			if(FileSystem.exists(xmlPath))
			{
				try
				{
					var xmlContent:String = File.getContent(xmlPath);
					var convertedJson:Dynamic = CodenameCompat.convertWeekXml(xmlContent);
					if(convertedJson != null)
						return cast convertedJson;
				}
				catch(e:Dynamic)
				{
					trace('Error converting Codename week XML: $e');
				}
			}
		}
		#else
		if(OpenFlAssets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		#end

		if(rawJson != null && rawJson.length > 0) {
			return cast tjson.TJSON.parse(rawJson);
		}
		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Mods.currentModDirectory = data.folder;
		}
	}
}
