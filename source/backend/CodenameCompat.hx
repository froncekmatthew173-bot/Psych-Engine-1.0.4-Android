package backend;

import haxe.Json;
import haxe.xml.Access;

#if MODS_ALLOWED
#if !js
import sys.FileSystem;
import sys.io.File;
#end
#end

/**
 * Codename Engine compatibility layer for Psych Engine.
 * Handles detection, parsing, and conversion of Codename Engine mod formats.
 */
class CodenameCompat
{
    /**
     * Check if a mod folder is a Codename Engine mod.
     * Detects by looking for Codename-specific folder structure (data/stages/*.xml, songs/, etc.)
     */
    public static function isCodenameMod(modFolder:String):Bool
    {
        #if MODS_ALLOWED
        if (modFolder == null || modFolder.length == 0) return false;

        var modPath:String = Paths.mods(modFolder);
        if (!FileSystem.exists(modPath) || !FileSystem.isDirectory(modPath)) return false;

        // Check for Codename-specific folders/files
        var codenameIndicators:Array<String> = [
            'songs/',           // Codename uses songs/ instead of data/ for song audio
            'data/stages/',     // Codename stores stage XMLs here
            'data/characters/', // Codename stores character XMLs here
            'data/weeks/',      // Codename stores week XMLs here
            'data/config/',     // Codename config folder
            'data/events/',     // Codename custom events
        ];

        var foundIndicators:Int = 0;
        for (ind in codenameIndicators)
        {
            if (FileSystem.exists(modPath + ind))
                foundIndicators++;
        }

        // If we find 2+ Codename-specific folders, it's likely a Codename mod
        return foundIndicators >= 2;
        #else
        return false;
        #end
    }

    /**
     * Get the Codename Engine song path for a given song name.
     * Codename format: songs/<name>/song/Inst.ogg
     */
    public static function getCodenameSongPath(songName:String):String
    {
        var formatted:String = Paths.formatToSongPath(songName);
        return 'songs/$formatted';
    }

    /**
     * Get Codename chart path for a song and difficulty.
     * Codename format: songs/<name>/charts/<difficulty>.json
     */
    public static function getCodenameChartPath(songName:String, difficulty:String):String
    {
        var formatted:String = Paths.formatToSongPath(songName);
        var diff:String = difficulty.toLowerCase();
        return 'songs/$formatted/charts/$diff.json';
    }

    /**
     * Get Codename meta.json path for a song.
     * Codename format: songs/<name>/meta.json
     */
    public static function getCodenameMetaPath(songName:String):String
    {
        var formatted:String = Paths.formatToSongPath(songName);
        return 'songs/$formatted/meta.json';
    }

    /**
     * Convert a Codename Engine character XML to Psych Engine character JSON format.
     * Returns null if parsing fails.
     */
    public static function convertCharacterXml(xmlData:String):Dynamic
    {
        try
        {
            var xml:Xml = Xml.parse(xmlData);
            var root:Access = new Access(xml.firstElement());

            var result:Dynamic = {
                animations: [],
                image: root.has.resolve("sprite") ? root.att.resolve("sprite") : "",
                scale: root.has.resolve("scale") ? Std.parseFloat(root.att.resolve("scale")) : 1,
                sing_duration: root.has.resolve("holdTime") ? Std.parseFloat(root.att.resolve("holdTime")) : 4,
                healthicon: root.has.resolve("icon") ? root.att.resolve("icon") : "",
                position: [0.0, 0.0],
                camera_position: [0.0, 0.0],
                flip_x: root.has.resolve("flipX") ? root.att.resolve("flipX") == "true" : false,
                no_antialiasing: root.has.resolve("antialiasing") ? root.att.resolve("antialiasing") == "false" : false,
                healthbar_colors: [161, 161, 161]
            };

            // Parse healthbar color from hex
            if (root.has.resolve("color"))
            {
                var colorStr:String = root.att.resolve("color");
                if (colorStr.startsWith("#"))
                    colorStr = colorStr.substring(1);
                try
                {
                    var color:Null<Int> = Std.parseInt("0x" + colorStr);
                    if (color != null)
                    {
                        var r:Int = (color >> 16) & 0xFF;
                        var g:Int = (color >> 8) & 0xFF;
                        var b:Int = color & 0xFF;
                        result.healthbar_colors = [r, g, b];
                    }
                }
                catch(e:Dynamic) {}
            }

            // Parse position
            if (root.has.resolve("x"))
                result.position[0] = Std.parseFloat(root.att.resolve("x"));
            if (root.has.resolve("y"))
                result.position[1] = Std.parseFloat(root.att.resolve("y"));

            // Parse camera offsets
            if (root.has.resolve("camx"))
                result.camera_position[0] = Std.parseFloat(root.att.resolve("camx"));
            if (root.has.resolve("camy"))
                result.camera_position[1] = Std.parseFloat(root.att.resolve("camy"));

            // Parse animations
            for (animNode in root.nodes.resolve("anim"))
            {
                var anim:Dynamic = {
                    name: animNode.has.resolve("name") ? animNode.att.resolve("name") : "",
                    anim: animNode.has.resolve("anim") ? animNode.att.resolve("anim") : "",
                    fps: animNode.has.resolve("fps") ? Std.parseInt(animNode.att.resolve("fps")) : 24,
                    loop: animNode.has.resolve("loop") ? animNode.att.resolve("loop") == "true" : false,
                    indices: [],
                    offsets: [0, 0]
                };

                // Parse indices (format: "1..5" or "1,2,3,4,5")
                if (animNode.has.resolve("indices"))
                {
                    var indicesStr:String = animNode.att.resolve("indices");
                    anim.indices = parseIndices(indicesStr);
                }

                // Parse offsets
                if (animNode.has.resolve("x"))
                    anim.offsets[0] = Std.parseInt(animNode.att.resolve("x"));
                if (animNode.has.resolve("y"))
                    anim.offsets[1] = Std.parseInt(animNode.att.resolve("y"));

                result.animations.push(anim);
            }

            // Generate healthicon from name if not set
            if (result.healthicon == "")
            {
                var charName:String = root.has.resolve("name") ? root.att.resolve("name") : "face";
                result.healthicon = charName;
            }

            return result;
        }
        catch(e:Dynamic)
        {
            trace('Error parsing Codename character XML: $e');
            return null;
        }
    }

    /**
     * Parse indices string (supports range format "1..5" and comma-separated "1,2,3")
     */
    static function parseIndices(str:String):Array<Int>
    {
        var indices:Array<Int> = [];
        if (str == null || str.length == 0) return indices;

        // Check for range format
        if (str.contains(".."))
        {
            var parts:Array<String> = str.split("..");
            if (parts.length == 2)
            {
                var start:Int = Std.parseInt(parts[0].trim());
                var end:Int = Std.parseInt(parts[1].trim());
                if (!Math.isNaN(start) && !Math.isNaN(end))
                {
                    for (i in start...end + 1)
                        indices.push(i);
                }
            }
        }
        else
        {
            // Comma-separated
            var parts:Array<String> = str.split(",");
            for (p in parts)
            {
                var val:Int = Std.parseInt(p.trim());
                if (!Math.isNaN(val))
                    indices.push(val);
            }
        }
        return indices;
    }

    /**
     * Convert a Codename Engine stage XML to Psych Engine stage JSON format.
     * Returns null if parsing fails.
     */
    public static function convertStageXml(xmlData:String):Dynamic
    {
        try
        {
            var xml:Xml = Xml.parse(xmlData);
            var root:Access = new Access(xml.firstElement());

            var result:Dynamic = {
                directory: "",
                defaultZoom: root.has.resolve("zoom") ? Std.parseFloat(root.att.resolve("zoom")) : 0.9,
                isPixelStage: false,
                stageUI: "normal",
                boyfriend: [770, 100],
                girlfriend: [400, 130],
                opponent: [100, 100],
                hide_girlfriend: false,
                camera_boyfriend: [0, 0],
                camera_opponent: [0, 0],
                camera_girlfriend: [0, 0],
                camera_speed: 1,
                objects: []
            };

            // Parse folder for image directory
            if (root.has.resolve("folder"))
                result.directory = root.att.resolve("folder");

            // Parse camera start position
            if (root.has.resolve("startCamPosX"))
                result.camera_opponent[0] = Std.parseFloat(root.att.resolve("startCamPosX"));
            if (root.has.resolve("startCamPosY"))
                result.camera_opponent[1] = Std.parseFloat(root.att.resolve("startCamPosY"));

            var objectIndex:Int = 0;

            // Parse child nodes
            for (child in root.elements)
            {
                var nodeName:String = child.name;

                switch(nodeName)
                {
                    case "sprite", "spr", "sparrow":
                        var obj:Dynamic = {
                            type: "sprite",
                            name: child.has.resolve("name") ? child.att.resolve("name") : "object" + objectIndex,
                            x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 0,
                            y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 0,
                            image: child.has.resolve("sprite") ? child.att.resolve("sprite") : "",
                            scroll: [1.0, 1.0],
                            scale: [1.0, 1.0],
                            antialiasing: true,
                            color: "#FFFFFF",
                            alpha: 1.0
                        };

                        if (child.has.resolve("scroll"))
                        {
                            var scrollVal:Float = Std.parseFloat(child.att.resolve("scroll"));
                            obj.scroll = [scrollVal, scrollVal];
                        }
                        if (child.has.resolve("scrollx"))
                            obj.scroll[0] = Std.parseFloat(child.att.resolve("scrollx"));
                        if (child.has.resolve("scrolly"))
                            obj.scroll[1] = Std.parseFloat(child.att.resolve("scrolly"));

                        if (child.has.resolve("scale"))
                        {
                            var scaleVal:Float = Std.parseFloat(child.att.resolve("scale"));
                            obj.scale = [scaleVal, scaleVal];
                        }
                        if (child.has.resolve("scalex"))
                            obj.scale[0] = Std.parseFloat(child.att.resolve("scalex"));
                        if (child.has.resolve("scaley"))
                            obj.scale[1] = Std.parseFloat(child.att.resolve("scaley"));

                        if (child.has.resolve("antialiasing"))
                            obj.antialiasing = child.att.resolve("antialiasing") != "false";
                        if (child.has.resolve("color"))
                            obj.color = child.att.resolve("color");
                        if (child.has.resolve("alpha"))
                            obj.alpha = Std.parseFloat(child.att.resolve("alpha"));

                        // Check if it's animated (has child anim nodes or type="beat")
                        var animNodes:Array<Access> = [];
                        for (subChild in child.elements)
                        {
                            if (subChild.name == "anim")
                                animNodes.push(subChild);
                        }

                        if (animNodes.length > 0 || (child.has.resolve("type") && child.att.resolve("type") == "beat"))
                        {
                            obj.type = "animatedSprite";
                            obj.animations = [];
                            obj.firstAnimation = "";

                            for (animNode in animNodes)
                            {
                                var anim:Dynamic = {
                                    name: animNode.has.resolve("name") ? animNode.att.resolve("name") : "",
                                    anim: animNode.has.resolve("anim") ? animNode.att.resolve("anim") : "",
                                    fps: animNode.has.resolve("fps") ? Std.parseInt(animNode.att.resolve("fps")) : 24,
                                    loop: animNode.has.resolve("loop") ? animNode.att.resolve("loop") == "true" : false,
                                    indices: [],
                                    offsets: [0, 0]
                                };

                                if (animNode.has.resolve("indices"))
                                    anim.indices = parseIndices(animNode.att.resolve("indices"));
                                if (animNode.has.resolve("x"))
                                    anim.offsets[0] = Std.parseInt(animNode.att.resolve("x"));
                                if (animNode.has.resolve("y"))
                                    anim.offsets[1] = Std.parseInt(animNode.att.resolve("y"));

                                if (obj.firstAnimation == "")
                                    obj.firstAnimation = anim.name;

                                obj.animations.push(anim);
                            }
                        }

                        result.objects.push(obj);
                        objectIndex++;

                    case "solid", "box":
                        var obj:Dynamic = {
                            type: "square",
                            name: child.has.resolve("name") ? child.att.resolve("name") : "solid" + objectIndex,
                            x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 0,
                            y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 0,
                            color: child.has.resolve("color") ? child.att.resolve("color") : "#FFFFFF",
                            scroll: [0.0, 0.0],
                            scale: [1.0, 1.0]
                        };

                        if (child.has.resolve("width") && child.has.resolve("height"))
                        {
                            var w:Float = Std.parseFloat(child.att.resolve("width"));
                            var h:Float = Std.parseFloat(child.att.resolve("height"));
                            obj.scale = [w, h];
                        }

                        result.objects.push(obj);
                        objectIndex++;

                    case "boyfriend", "bf", "player":
                        var obj:Dynamic = {
                            type: "boyfriend",
                            x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 770,
                            y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 100
                        };
                        result.boyfriend = [obj.x, obj.y];
                        result.objects.push(obj);
                        objectIndex++;

                    case "girlfriend", "gf":
                        var obj:Dynamic = {
                            type: "gf",
                            x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 400,
                            y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 130
                        };
                        result.girlfriend = [obj.x, obj.y];
                        result.objects.push(obj);
                        objectIndex++;

                    case "dad", "opponent":
                        var obj:Dynamic = {
                            type: "dad",
                            x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 100,
                            y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 100
                        };
                        result.opponent = [obj.x, obj.y];
                        result.objects.push(obj);
                        objectIndex++;

                    case "character", "char":
                        // Custom character positioning - store as a note for special handling
                        var charName:String = child.has.resolve("name") ? child.att.resolve("name") : "";
                        if (charName.length > 0)
                        {
                            var obj:Dynamic = {
                                type: "character",
                                name: charName,
                                x: child.has.resolve("x") ? Std.parseFloat(child.att.resolve("x")) : 0,
                                y: child.has.resolve("y") ? Std.parseFloat(child.att.resolve("y")) : 0
                            };
                            result.objects.push(obj);
                            objectIndex++;
                        }
                }
            }

            return result;
        }
        catch(e:Dynamic)
        {
            trace('Error parsing Codename stage XML: $e');
            return null;
        }
    }

    /**
     * Convert a Codename Engine week XML to Psych Engine week JSON format.
     * Returns null if parsing fails.
     */
    public static function convertWeekXml(xmlData:String):Dynamic
    {
        try
        {
            var xml:Xml = Xml.parse(xmlData);
            var root:Access = new Access(xml.firstElement());

            var result:Dynamic = {
                songs: [],
                weekCharacters: ["", "", ""],
                weekBackground: "stage",
                weekBefore: "",
                storyName: "",
                weekName: root.has.resolve("name") ? root.att.resolve("name") : "Custom Week",
                startUnlocked: true,
                hiddenUntilUnlocked: false,
                hideStoryMode: false,
                hideFreeplay: false,
                difficulties: ""
            };

            // Parse chars attribute (format: "pico,bf,gf")
            if (root.has.resolve("chars"))
            {
                var charsStr:String = root.att.resolve("chars");
                var chars:Array<String> = charsStr.split(",");
                // Codename order is opponent,bf,gf
                while (chars.length < 3) chars.push("bf");
                result.weekCharacters = [chars[0].trim(), chars[1].trim(), chars[2].trim()];
            }

            // Parse sprite for background
            if (root.has.resolve("sprite"))
                result.weekBackground = root.att.resolve("sprite");

            // Parse songs
            for (songNode in root.nodes.resolve("song"))
            {
                var songName:String = songNode.innerData.trim();
                if (songName.length > 0)
                {
                    // Codename format: just song name, we add default icon and color
                    result.songs.push(untyped [songName, "face", [146, 113, 253]]);
                }
            }

            // Parse difficulties
            var difficulties:Array<String> = [];
            for (diffNode in root.nodes.resolve("difficulty"))
            {
                if (diffNode.has.resolve("name"))
                {
                    var diffName:String = diffNode.att.resolve("name");
                    difficulties.push(diffName);
                }
            }
            if (difficulties.length > 0)
            {
                // Convert to Psych format (comma-separated, exclude default "Normal")
                var diffStr:String = difficulties.filter(d -> d.toLowerCase() != "normal").join(", ");
                result.difficulties = diffStr;
            }

            return result;
        }
        catch(e:Dynamic)
        {
            trace('Error parsing Codename week XML: $e');
            return null;
        }
    }

    /**
     * Detect if a chart JSON is in Codename Engine format.
     */
    public static function isCodenameChart(chartJson:Dynamic):Bool
    {
        if (Reflect.hasField(chartJson, "codenameChart"))
            return Reflect.field(chartJson, "codenameChart") == true;
        if (Reflect.hasField(chartJson, "strumLines"))
            return true;
        if (Reflect.hasField(chartJson, "chartVersion"))
            return true;
        return false;
    }

    /**
     * Convert a Codename Engine chart JSON to Psych Engine chart format.
     * Handles the Codename strumLines format with {id, sLen, time, type} notes.
     */
    public static function convertChartJson(jsonData:String, songName:String):Dynamic
    {
        try
        {
            var rawChart:Dynamic = Json.parse(jsonData);

            // Check if it's already a Psych chart
            if (Reflect.hasField(rawChart, "format") && Reflect.field(rawChart, "format").startsWith("psych"))
                return rawChart;

            // If it has "song" wrapper, unwrap it
            if (Reflect.hasField(rawChart, "song"))
            {
                var subSong:Dynamic = Reflect.field(rawChart, "song");
                if (subSong != null && Type.typeof(subSong) == TObject)
                    rawChart = subSong;
            }

            // Build Psych-compatible chart
            var result:Dynamic = {
                song: songName,
                notes: [],
                events: [],
                bpm: 100,
                needsVoices: true,
                speed: 1,
                player1: "bf",
                player2: "dad",
                gfVersion: "gf",
                stage: "stage",
                format: "psych_v1"
            };

            // Copy basic fields
            if (Reflect.hasField(rawChart, "bpm"))
                result.bpm = Reflect.field(rawChart, "bpm");
            if (Reflect.hasField(rawChart, "speed"))
                result.speed = Reflect.field(rawChart, "speed");
            if (Reflect.hasField(rawChart, "scrollSpeed"))
                result.speed = Reflect.field(rawChart, "scrollSpeed");
            if (Reflect.hasField(rawChart, "player1"))
                result.player1 = Reflect.field(rawChart, "player1");
            if (Reflect.hasField(rawChart, "player2"))
                result.player2 = Reflect.field(rawChart, "player2");
            if (Reflect.hasField(rawChart, "gfVersion"))
                result.gfVersion = Reflect.field(rawChart, "gfVersion");
            if (Reflect.hasField(rawChart, "stage"))
                result.stage = Reflect.field(rawChart, "stage");
            if (Reflect.hasField(rawChart, "needsVoices"))
                result.needsVoices = Reflect.field(rawChart, "needsVoices");

            // Detect Codename strumLines format
            if (Reflect.hasField(rawChart, "strumLines"))
            {
                trace('Converting Codename strumLines chart for: $songName');
                var strumLines:Array<Dynamic> = Reflect.field(rawChart, "strumLines");
                // Extract characters from strumLines
                if (strumLines != null)
                {
                    for (sl in strumLines)
                    {
                        if (sl == null) continue;
                        var pos:String = Reflect.hasField(sl, "position") ? Reflect.field(sl, "position") : "";
                        var chars:Array<Dynamic> = Reflect.hasField(sl, "characters") ? Reflect.field(sl, "characters") : null;
                        if (chars != null && chars.length > 0)
                        {
                            var charName:String = "" + chars[0];
                            switch (pos)
                            {
                                case "dad" | "opponent":
                                    result.player2 = charName;
                                case "boyfriend" | "bf":
                                    result.player1 = charName;
                                case "girlfriend" | "gf":
                                    result.gfVersion = charName;
                            }
                        }
                    }
                }
                convertStrumLinesChart(rawChart, result);
            }
            else if (Reflect.hasField(rawChart, "notes"))
            {
                // Legacy format or already section-based
                convertSectionBasedChart(rawChart, result);
            }

            // Convert events (Codename format: {params, time, name})
            if (Reflect.hasField(rawChart, "events"))
            {
                var rawEvents:Array<Dynamic> = Reflect.field(rawChart, "events");
                if (rawEvents != null)
                {
                    for (event in rawEvents)
                    {
                        if (event != null)
                        {
                            // Codename event format: {params: [...], time: ms, name: "EventName"}
                            if (Type.typeof(event) == TObject && Reflect.hasField(event, "name") && Reflect.hasField(event, "time"))
                            {
                                var time:Float = Reflect.field(event, "time");
                                var name:String = Reflect.field(event, "name");
                                var params:Array<Dynamic> = Reflect.hasField(event, "params") ? Reflect.field(event, "params") : [];

                                // Convert to Psych format: [time, [[eventName, param1, param2, ...]]]
                                var psychParams:Array<Dynamic> = [name];
                                for (p in params)
                                    psychParams.push(p);
                                result.events.push(untyped [time, [psychParams]]);
                            }
                            // Psych format: [time, [[name, val1, val2]]]
                            else if (Std.isOfType(event, Array))
                            {
                                result.events.push(event);
                            }
                        }
                    }
                }
            }

            return result;
        }
        catch(e:Dynamic)
        {
            trace('Error converting Codename chart: $e');
            return null;
        }
    }

    /**
     * Convert Codename strumLines format to Psych section format.
     * Codename strumLines: [{keyCount, position, notes: [{id, sLen, time, type}]}]
     * Psych sections: [{sectionNotes: [[time, lane, sustain, type]], mustHitSection, sectionBeats}]
     */
    static function convertStrumLinesChart(rawChart:Dynamic, result:Dynamic):Void
    {
        var strumLines:Array<Dynamic> = Reflect.field(rawChart, "strumLines");
        if (strumLines == null || strumLines.length == 0) return;

        // Collect all notes from all strumlines
        var allNotes:Array<Dynamic> = [];

        for (strumLineIdx in 0...strumLines.length)
        {
            var strumLine:Dynamic = strumLines[strumLineIdx];
            if (strumLine == null) continue;

            var position:String = Reflect.hasField(strumLine, "position") ? Reflect.field(strumLine, "position") : "dad";
            var keyCount:Int = Reflect.hasField(strumLine, "keyCount") ? Reflect.field(strumLine, "keyCount") : 4;

            // Determine if this strumline is for opponent or player
            var isOpponent:Bool = (position == "dad" || position == "opponent");

            if (Reflect.hasField(strumLine, "notes"))
            {
                var notes:Array<Dynamic> = Reflect.field(strumLine, "notes");
                if (notes != null)
                {
                    for (note in notes)
                    {
                        if (note == null) continue;

                        // Codename note format: {id, sLen, time, type}
                        var id:Int = Reflect.hasField(note, "id") ? Reflect.field(note, "id") : 0;
                        var sLen:Float = Reflect.hasField(note, "sLen") ? Reflect.field(note, "sLen") : 0;
                        var time:Float = Reflect.hasField(note, "time") ? Reflect.field(note, "time") : 0;
                        var type:Int = Reflect.hasField(note, "type") ? Reflect.field(note, "type") : 0;

                        // Convert lane: Codename uses 0-3 per strumline
                        // Psych uses 0-3 for opponent, 4-7 for player
                        var psychLane:Int;
                        if (isOpponent)
                            psychLane = id; // 0-3 for opponent
                        else
                            psychLane = id + 4; // 4-7 for player

                        // Convert note type
                        var noteType:String = "";
                        if (type == 1) noteType = "Hurt Note"; // Common Codename custom note type

                        allNotes.push({
                            time: time,
                            lane: psychLane,
                            sustain: sLen,
                            type: noteType,
                            isOpponent: isOpponent
                        });
                    }
                }
            }
        }

        // Sort all notes by time
        allNotes.sort(function(a, b) {
            if (a.time < b.time) return -1;
            if (a.time > b.time) return 1;
            return 0;
        });

        // Group notes into 4-beat sections
        var bpm:Float = result.bpm;
        if (bpm <= 0) bpm = 100;
        var stepCrochet:Float = (60000 / bpm) / 4; // ms per step
        var sectionLength:Float = stepCrochet * 16; // 4 beats = 16 steps

        if (allNotes.length == 0) return;

        var minTime:Float = allNotes[0].time;
        var maxTime:Float = allNotes[allNotes.length - 1].time;

        var currentTime:Float = minTime;
        while (currentTime <= maxTime + sectionLength)
        {
            var section:Dynamic = {
                sectionNotes: [],
                sectionBeats: 4,
                mustHitSection: false,
                altAnim: false,
                spamAnim: false,
                gfSection: false
            };

            // Find notes in this section
            var sectionEnd:Float = currentTime + sectionLength;
            var hasPlayerNotes:Bool = false;

            for (note in allNotes)
            {
                if (note.time >= currentTime && note.time < sectionEnd)
                {
                    section.sectionNotes.push(untyped [note.time, note.lane, note.sustain, note.type]);
                    if (!note.isOpponent) hasPlayerNotes = true;
                }
            }

            // Determine camera focus based on which side has more notes
            section.mustHitSection = hasPlayerNotes;

            if (section.sectionNotes.length > 0)
                result.notes.push(section);

            currentTime += sectionLength;
        }
    }

    /**
     * Convert section-based chart (non-strumLines format).
     */
    static function convertSectionBasedChart(rawChart:Dynamic, result:Dynamic):Void
    {
        if (!Reflect.hasField(rawChart, "notes")) return;

        var rawNotes:Array<Dynamic> = Reflect.field(rawChart, "notes");
        if (rawNotes == null) return;

        for (rawSection in rawNotes)
        {
            var section:Dynamic = {
                sectionNotes: [],
                sectionBeats: 4,
                mustHitSection: true,
                altAnim: false,
                spamAnim: false,
                gfSection: false
            };

            if (Reflect.hasField(rawSection, "sectionBeats"))
                section.sectionBeats = Reflect.field(rawSection, "sectionBeats");
            else if (Reflect.hasField(rawSection, "lengthInSteps"))
                section.sectionBeats = Reflect.field(rawSection, "lengthInSteps") / 4;

            if (Reflect.hasField(rawSection, "mustHitSection"))
                section.mustHitSection = Reflect.field(rawSection, "mustHitSection");
            if (Reflect.hasField(rawSection, "altAnim"))
                section.altAnim = Reflect.field(rawSection, "altAnim");
            if (Reflect.hasField(rawSection, "spamAnim"))
                section.spamAnim = Reflect.field(rawSection, "spamAnim");
            if (Reflect.hasField(rawSection, "gfSection"))
                section.gfSection = Reflect.field(rawSection, "gfSection");

            // Convert notes
            if (Reflect.hasField(rawSection, "sectionNotes"))
            {
                var rawSectionNotes:Array<Dynamic> = Reflect.field(rawSection, "sectionNotes");
                for (noteData in rawSectionNotes)
                {
                    if (noteData != null)
                    {
                        if (Std.isOfType(noteData, Array))
                        {
                            section.sectionNotes.push(noteData.copy());
                        }
                        else if (Type.typeof(noteData) == TObject)
                        {
                            // Codename object format: {id, sLen, time, type}
                            var time:Float = Reflect.hasField(noteData, "time") ? Reflect.field(noteData, "time") :
                                            (Reflect.hasField(noteData, "strumTime") ? Reflect.field(noteData, "strumTime") : 0);
                            var lane:Int = Reflect.hasField(noteData, "id") ? Reflect.field(noteData, "id") :
                                          (Reflect.hasField(noteData, "noteData") ? Reflect.field(noteData, "noteData") : 0);
                            var dur:Float = Reflect.hasField(noteData, "sLen") ? Reflect.field(noteData, "sLen") :
                                           (Reflect.hasField(noteData, "sustainLength") ? Reflect.field(noteData, "sustainLength") : 0);
                            section.sectionNotes.push(untyped [time, lane, dur, ""]);
                        }
                    }
                }
            }

            result.notes.push(section);
        }
    }

    /**
     * Convert a Codename Engine meta.json to a Psych-compatible format.
     * Returns metadata about the song.
     */
    public static function convertMetaJson(jsonData:String):Dynamic
    {
        try
        {
            var rawMeta:Dynamic = Json.parse(jsonData);
            var result:Dynamic = {
                songName: "",
                displayName: "",
                artist: "",
                difficulties: ["easy", "normal", "hard"],
                bpm: 100,
                speed: 1
            };

            if (Reflect.hasField(rawMeta, "name"))
                result.songName = Reflect.field(rawMeta, "name");
            if (Reflect.hasField(rawMeta, "displayName"))
                result.displayName = Reflect.field(rawMeta, "displayName");
            else
                result.displayName = result.songName;
            if (Reflect.hasField(rawMeta, "artist"))
                result.artist = Reflect.field(rawMeta, "artist");
            if (Reflect.hasField(rawMeta, "bpm"))
                result.bpm = Reflect.field(rawMeta, "bpm");
            if (Reflect.hasField(rawMeta, "speed"))
                result.speed = Reflect.field(rawMeta, "speed");

            if (Reflect.hasField(rawMeta, "difficulties"))
            {
                var diffs:Array<Dynamic> = Reflect.field(rawMeta, "difficulties");
                if (diffs != null)
                {
                    result.difficulties = [];
                    for (d in diffs)
                        result.difficulties.push(Std.string(d).toLowerCase());
                }
            }

            return result;
        }
        catch(e:Dynamic)
        {
            trace('Error parsing Codename meta.json: $e');
            return null;
        }
    }

    /**
     * Get Codename Engine song script paths for a given song.
     * Codename format: songs/<name>/scripts/*.hx
     */
    public static function getCodenameSongScripts(songName:String):Array<String>
    {
        var scripts:Array<String> = [];
        #if MODS_ALLOWED
        #if !js
        var formatted:String = Paths.formatToSongPath(songName);
        var scriptsPath:String = Paths.mods(Mods.currentModDirectory + '/songs/$formatted/scripts/');

        if (FileSystem.exists(scriptsPath))
        {
            for (file in Paths.readDirectory(scriptsPath))
            {
                if (file.endsWith(".hx") || file.endsWith(".lua"))
                    scripts.push(scriptsPath + file);
            }
        }
        #end
        #end
        return scripts;
    }

    /**
     * Get Codename Engine global script paths.
     * Codename format: data/charts/*.hx (global song scripts)
     */
    public static function getCodenameGlobalScripts():Array<String>
    {
        var scripts:Array<String> = [];
        #if MODS_ALLOWED
        #if !js
        var scriptsPath:String = Paths.mods(Mods.currentModDirectory + '/data/charts/');

        if (FileSystem.exists(scriptsPath))
        {
            for (file in Paths.readDirectory(scriptsPath))
            {
                if (file.endsWith(".hx") || file.endsWith(".lua"))
                    scripts.push(scriptsPath + file);
            }
        }
        #end
        #end
        return scripts;
    }
}
