package substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxGroup;
import flixel.ui.FlxButton;
import sys.FileSystem;

import backend.ModConverter;
import backend.Paths;
import backend.Mods;

class ModConverterSubState extends MusicBeatSubstate
{
	var statusText:FlxText;
	var logText:FlxText;
	var logLines:Array<String> = [];
	var sourceInput:FlxText;
	var outputInput:FlxText;
	var curSelected:Int = 0;
    var options:Array<String> = ["Source: ", "Output: ", "Detect Engine", "Convert Mod", "Back"];
    var menuItems:FlxGroup = new FlxGroup();

    // Buttons
    var btnDetect:FlxButton;
    var btnConvert:FlxButton;
    var btnBack:FlxButton;

    var sourcePath:String = "";
    var outputPath:String = "";
    var detectedEngine:String = "unknown";

    var detecting:Bool = false;
    var converting:Bool = false;
    var convertDone:Bool = false;

    override public function create()
    {
        super.create();

        var bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.7;
        add(bg);

        var title = new FlxText(0, 20, FlxG.width, "MOD CONVERTER", 24);
        title.alignment = CENTER;
        title.color = FlxColor.WHITE;
        add(title);

        sourceInput = new FlxText(40, 70, FlxG.width - 80, "Source: (click Convert to set)", 16);
        sourceInput.color = FlxColor.CYAN;
        add(sourceInput);

        outputInput = new FlxText(40, 100, FlxG.width - 80, "Output: (click Convert to set)", 16);
        outputInput.color = FlxColor.GREEN;
        add(outputInput);

        statusText = new FlxText(40, 140, FlxG.width - 80, "Ready. Select options below.", 14);
        statusText.color = FlxColor.YELLOW;
        add(statusText);

        // Buttons row
        btnDetect = new flixel.ui.FlxButton(40, 110, "Detect Engine", function() {
            // emulate ENTER on Detect Engine
            if (sourcePath.length > 0)
            {
                detecting = true;
                addLog("Detecting engine for: " + sourcePath);
                detectedEngine = ModConverter.detectEngine(sourcePath);
                addLog("Detected engine: " + detectedEngine);
                statusText.text = "Detected: " + detectedEngine;
                detecting = false;
            }
            else statusText.text = "Set source path first!";
        });

        btnConvert = new flixel.ui.FlxButton(260, 110, "Convert Mod", function() {
            if (sourcePath.length > 0 && outputPath.length > 0)
            {
                converting = true;
                addLog("Starting conversion...");
                statusText.text = "Converting... check log.";

                ModConverter.logCallback = function(msg:String) {
                    addLog(msg);
                    return msg;
                };

                var success = ModConverter.convert(sourcePath, outputPath);
                converting = false;

                if (success)
                    statusText.text = "Conversion complete! Output: " + outputPath;
                else
                    statusText.text = "Conversion failed. Check log.";
            }
            else statusText.text = "Set both source and output paths!";
        });

        btnBack = new flixel.ui.FlxButton(520, 110, "Back", function() {
            close();
        });

        add(btnDetect);
        add(btnConvert);
        add(btnBack);

        logText = new FlxText(40, 180, FlxG.width - 80, "", 11);
        logText.color = FlxColor.WHITE;
        logText.scrollFactor.set();
        add(logText);


        // Scan for mod folders in the mods directory
        var modsPath:String = Paths.mods();
        if (FileSystem.exists(modsPath))
        {
            var modFolders:Array<String> = [];
            for (entry in FileSystem.readDirectory(modsPath))
            {
                var fullPath = haxe.io.Path.join([modsPath, entry]);
                if (FileSystem.isDirectory(fullPath) && !entry.startsWith("."))
                    modFolders.push(entry);
            }

            // Build menu with mod folders
            options = [];
            for (mod in modFolders)
                options.push(mod);
            options.push("Back");
        }
    }

    function addLog(msg:String):Void
    {
        logLines.push(msg);
        if (logLines.length > 20)
            logLines.shift();
        logText.text = logLines.join("\n");
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // Disable interactive buttons while working
        if (btnDetect != null)
        {
            btnDetect.active = !(detecting || converting);
            btnConvert.active = !(detecting || converting);
            btnBack.active = !(detecting || converting);
        }

        if (detecting || converting) return;


        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
        {
            close();
            return;
        }

        if (FlxG.keys.justPressed.UP)
        {
            curSelected--;
            if (curSelected < 0) curSelected = options.length - 1;
        }
        if (FlxG.keys.justPressed.DOWN)
        {
            curSelected++;
            if (curSelected >= options.length) curSelected = 0;
        }

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
        {
            var selected = options[curSelected];
            if (selected == "Back")
            {
                close();
                return;
            }
            else if (selected == "Detect Engine")
            {
                if (sourcePath.length > 0)
                {
                    detecting = true;
                    addLog("Detecting engine for: " + sourcePath);
                    detectedEngine = ModConverter.detectEngine(sourcePath);
                    addLog("Detected engine: " + detectedEngine);
                    statusText.text = "Detected: " + detectedEngine;
                    detecting = false;
                }
                else
                {
                    statusText.text = "Set source path first!";
                }
            }
            else if (selected == "Convert Mod")
            {
                if (sourcePath.length > 0 && outputPath.length > 0)
                {
                    converting = true;
                    convertDone = false;
                    addLog("Starting conversion...");
                    statusText.text = "Converting... check log.";

                    ModConverter.logCallback = function(msg:String) {
                        addLog(msg);
                        return msg;
                    };

                    var success = ModConverter.convert(sourcePath, outputPath);
                    convertDone = true;
                    converting = false;

                    if (success)
                        statusText.text = "Conversion complete! Output: " + outputPath;
                    else
                        statusText.text = "Conversion failed. Check log.";
                }
                else
                {
                    statusText.text = "Set both source and output paths!";
                }
            }
            else
            {
                // Selected a mod folder - use as source
                sourcePath = haxe.io.Path.join([Paths.mods(), selected]);
                outputPath = haxe.io.Path.join([Paths.mods(), selected + "_psych"]);
                sourceInput.text = "Source: " + sourcePath;
                outputInput.text = "Output: " + outputPath;
                statusText.text = "Selected: " + selected + " (output: " + selected + "_psych)";

                // Auto-detect
                detectedEngine = ModConverter.detectEngine(sourcePath);
                addLog("Auto-detected engine for " + selected + ": " + detectedEngine);
            }
        }

        // Update display
        updateMenuDisplay();
    }

    function updateMenuDisplay():Void
    {
        // Basic keyboard fallback already handles selection logic.
        // Buttons are handled via FlxButton callbacks.
    }

}
