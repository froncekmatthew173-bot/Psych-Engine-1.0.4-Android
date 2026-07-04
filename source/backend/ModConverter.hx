package backend;

import sys.io.File;
import sys.FileSystem;
import haxe.Json;
import haxe.io.Path;

/**
 * Mod Converter - Converts FNF mods from other engines to Psych Engine format.
 *
 * Supported source engines:
 *   - Codename Engine (primary target)
 *   - Kade Engine / Vanilla FNF (mostly compatible already)
 *   - FNF Multi / Whitty-style mods
 *
 * Usage:
 *   ModConverter.convert("path/to/source/mod", "path/to/output/mod");
 *
 * What gets converted:
 *   - Characters: XML → JSON (Codename format)
 *   - Stages: XML → JSON (Codename format)
 *   - Weeks: XML → JSON (Codename format)
 *   - Charts: Codename strumLines → Psych sections
 *   - Song folders: Codename songs/<name>/ → Psych-compatible layout
 *   - Story menu images: Codename menus/storymenu/weeks/ → Psych storymenu/
 *   - Menu characters: Codename data/weeks/characters/ → Psych menucharacters/
 *   - Note skins: Codename game/notes/ → Psych noteSkins/
 *   - Assets are copied as-is where possible
 */
#if MODS_ALLOWED
class ModConverter
{
    public static var logCallback:String->Void = null;

    static function log(msg:String)
    {
        trace('[ModConverter] $msg');
        if (logCallback != null) logCallback(msg);
    }

    // ─── Engine Detection ──────────────────────────────────────────────

    public static function detectEngine(modPath:String):String
    {
        var indicators:Map<String, Int> = [
            "codename" => 0,
            "kade" => 0,
            "psych" => 0,
            "whitty" => 0
        ];

        // Codename indicators
        if (FileSystem.exists(Path.join([modPath, "data", "stages"])) && hasXmlFiles(Path.join([modPath, "data", "stages"])))
            indicators["codename"] += 2;
        if (FileSystem.exists(Path.join([modPath, "data", "characters"])) && hasXmlFiles(Path.join([modPath, "data", "characters"])))
            indicators["codename"] += 2;
        if (FileSystem.exists(Path.join([modPath, "data", "weeks", "weeks"])))
            indicators["codename"] += 2;
        if (FileSystem.exists(Path.join([modPath, "data", "global.hx"])))
            indicators["codename"] += 1;
        if (FileSystem.exists(Path.join([modPath, "songs"])) && hasSongSubdirs(Path.join([modPath, "songs"]), "song"))
            indicators["codename"] += 2;
        if (FileSystem.exists(Path.join([modPath, "songs"])) && hasSongSubdirs(Path.join([modPath, "songs"]), "charts"))
            indicators["codename"] += 2;

        // Psych indicators
        if (FileSystem.exists(Path.join([modPath, "pack.json"])))
            indicators["psych"] += 1;
        if (FileSystem.exists(Path.join([modPath, "weeks"])) && !FileSystem.exists(Path.join([modPath, "data", "weeks", "weeks"])))
            indicators["psych"] += 2;
        if (hasJsonFilesIn(Path.join([modPath, "data", "characters"])))
            indicators["psych"] += 2;
        if (FileSystem.exists(Path.join([modPath, "scripts"])))
            indicators["psych"] += 1;

        // Kade / Vanilla indicators
        if (FileSystem.exists(Path.join([modPath, "data"])) && !FileSystem.exists(Path.join([modPath, "data", "stages"])))
            indicators["kade"] += 1;
        if (FileSystem.exists(Path.join([modPath, "modpack.ini"])))
            indicators["kade"] += 1;

        // Find winner
        var bestEngine:String = "unknown";
        var bestScore:Int = 0;
        for (engine => score in indicators)
        {
            if (score > bestScore)
            {
                bestScore = score;
                bestEngine = engine;
            }
        }
        return bestEngine;
    }

    // ─── Main Conversion ───────────────────────────────────────────────

    public static function convert(sourcePath:String, outputPath:String, ?engine:String):Bool
    {
        if (!FileSystem.exists(sourcePath))
        {
            log('ERROR: Source path does not exist: $sourcePath');
            return false;
        }

        if (engine == null) engine = detectEngine(sourcePath);
        log('Detected engine: $engine');
        log('Source: $sourcePath');
        log('Output: $outputPath');

        // Create output directory
        if (!FileSystem.exists(outputPath))
            FileSystem.createDirectory(outputPath);

        var success:Bool = true;

        switch (engine)
        {
            case "codename":
                success = convertCodenameMod(sourcePath, outputPath);
            case "kade":
                success = convertKadeMod(sourcePath, outputPath);
            case "whitty":
                success = convertWhittyMod(sourcePath, outputPath);
            case "psych":
                log("Mod is already Psych Engine format. Copying as-is.");
                success = copyDirectory(sourcePath, outputPath);
            default:
                log('Unknown engine "$engine". Attempting Codename conversion...');
                success = convertCodenameMod(sourcePath, outputPath);
        }

        if (success) log('Conversion complete! Output at: $outputPath');
        else log('Conversion failed or partially completed.');

        return success;
    }

    // ─── Codename Engine Conversion ────────────────────────────────────

    static function convertCodenameMod(source:String, output:String):Bool
    {
        var ok = true;

        // 1. Copy pack.json / pack.png if present
        copyFileIfExists(source, output, "pack.json");
        copyFileIfExists(source, output, "pack.png");

        // 2. Convert characters: data/characters/*.xml → data/characters/*.json
        log("Converting characters...");
        var charsDir = Path.join([source, "data", "characters"]);
        if (FileSystem.exists(charsDir))
        {
            var outCharsDir = Path.join([output, "data", "characters"]);
            ensureDir(outCharsDir);
            for (file in FileSystem.readDirectory(charsDir))
            {
                if (file.endsWith(".xml"))
                {
                    var name = file.substr(0, file.length - 4);
                    try
                    {
                        var xmlContent = File.getContent(Path.join([charsDir, file]));
                        var json = CodenameCompat.convertCharacterXml(xmlContent);
                        if (json != null)
                        {
                            var jsonStr = Json.stringify(json, null, "\t");
                            File.saveContent(Path.join([outCharsDir, name + ".json"]), jsonStr);
                            log('  Converted character: $name');
                        }
                        else
                        {
                            log('  WARNING: Failed to convert character: $name');
                            ok = false;
                        }
                    }
                    catch (e:Dynamic)
                    {
                        log('  ERROR converting character $name: $e');
                        ok = false;
                    }
                }
                else if (file.endsWith(".json"))
                {
                    // Already Psych format, copy as-is
                    copyFile(Path.join([charsDir, file]), Path.join([outCharsDir, file]));
                }
            }
        }

        // 3. Convert stages: data/stages/*.xml → data/stages/*.json
        log("Converting stages...");
        var stagesDir = Path.join([source, "data", "stages"]);
        if (FileSystem.exists(stagesDir))
        {
            var outStagesDir = Path.join([output, "data", "stages"]);
            ensureDir(outStagesDir);
            for (file in FileSystem.readDirectory(stagesDir))
            {
                if (file.endsWith(".xml"))
                {
                    var name = file.substr(0, file.length - 4);
                    try
                    {
                        var xmlContent = File.getContent(Path.join([stagesDir, file]));
                        var json = CodenameCompat.convertStageXml(xmlContent);
                        if (json != null)
                        {
                            var jsonStr = Json.stringify(json, null, "\t");
                            File.saveContent(Path.join([outStagesDir, name + ".json"]), jsonStr);
                            log('  Converted stage: $name');
                        }
                        else
                        {
                            log('  WARNING: Failed to convert stage: $name');
                            ok = false;
                        }
                    }
                    catch (e:Dynamic)
                    {
                        log('  ERROR converting stage $name: $e');
                        ok = false;
                    }
                }
                else if (file.endsWith(".json"))
                {
                    copyFile(Path.join([stagesDir, file]), Path.join([outStagesDir, file]));
                }
            }
        }

        // 4. Convert weeks: data/weeks/weeks/*.xml → weeks/*.json
        log("Converting weeks...");
        var weeksXmlDir = Path.join([source, "data", "weeks", "weeks"]);
        if (FileSystem.exists(weeksXmlDir))
        {
            var outWeeksDir = Path.join([output, "weeks"]);
            ensureDir(outWeeksDir);
            for (file in FileSystem.readDirectory(weeksXmlDir))
            {
                if (file.endsWith(".xml"))
                {
                    var name = file.substr(0, file.length - 4);
                    try
                    {
                        var xmlContent = File.getContent(Path.join([weeksXmlDir, file]));
                        var json = CodenameCompat.convertWeekXml(xmlContent);
                        if (json != null)
                        {
                            var jsonStr = Json.stringify(json, null, "\t");
                            File.saveContent(Path.join([outWeeksDir, name + ".json"]), jsonStr);
                            log('  Converted week: $name');
                        }
                        else
                        {
                            log('  WARNING: Failed to convert week: $name');
                            ok = false;
                        }
                    }
                    catch (e:Dynamic)
                    {
                        log('  ERROR converting week $name: $e');
                        ok = false;
                    }
                }
            }
        }

        // Also copy weekList.txt if present
        copyFileIfExists(source, output, "data/weeks/weeks.txt", "weeks/weekList.txt");

        // 5. Convert songs
        log("Converting songs...");
        var songsDir = Path.join([source, "songs"]);
        if (FileSystem.exists(songsDir))
        {
            for (songFolder in FileSystem.readDirectory(songsDir))
            {
                var songPath = Path.join([songsDir, songFolder]);
                if (FileSystem.isDirectory(songPath))
                {
                    convertCodenameSong(source, output, songFolder);
                }
                else if (songFolder.endsWith(".hx"))
                {
                    // Global song scripts, copy to data/scripts/
                    var outScriptsDir = Path.join([output, "data", "scripts"]);
                    ensureDir(outScriptsDir);
                    copyFile(Path.join([songsDir, songFolder]), Path.join([outScriptsDir, "song_" + songFolder]));
                }
            }
        }

        // 6. Copy events (data/events/) - same format in both engines
        log("Copying events...");
        copyDirectoryIfExists(source, output, "data/events");

        // 7. Copy custom note types (data/notes/)
        log("Copying note types...");
        copyDirectoryIfExists(source, output, "data/notes");

        // 8. Copy scripts (data/scripts/)
        log("Copying scripts...");
        copyDirectoryIfExists(source, output, "data/scripts");

        // 9. Copy global.hx
        copyFileIfExists(source, output, "data/global.hx");

        // 10. Copy state overrides (data/states/) - these are HScript, keep as-is
        log("Copying state overrides...");
        copyDirectoryIfExists(source, output, "data/states");

        // 11. Copy config
        copyDirectoryIfExists(source, output, "data/config");

        // 12. Copy dialogue
        copyDirectoryIfExists(source, output, "data/dialogue");

        // 13. Convert images
        log("Copying images...");
        convertCodenameImages(source, output);

        // 14. Copy sounds and music
        log("Copying sounds...");
        copyDirectoryIfExists(source, output, "sounds");
        copyDirectoryIfExists(source, output, "music");

        // 15. Copy videos
        copyDirectoryIfExists(source, output, "videos");

        // 16. Copy shaders
        copyDirectoryIfExists(source, output, "shaders");

        // 17. Copy fonts
        copyDirectoryIfExists(source, output, "fonts");

        // 18. Write conversion metadata
        var meta = {
            convertedFrom: "codename_engine",
            convertedAt: Date.now().toString(),
            engineVersion: "1.0"
        };
        File.saveContent(Path.join([output, ".converter_meta.json"]), Json.stringify(meta, null, "\t"));

        return ok;
    }

    static function convertCodenameSong(source:String, output:String, songName:String):Void
    {
        var songSource = Path.join([source, "songs", songName]);
        var outSongData = Path.join([output, "data", songName]);
        ensureDir(outSongData);

        // Convert charts: songs/<name>/charts/*.json → data/<name>/<diff>.json
        var chartsDir = Path.join([songSource, "charts"]);
        if (FileSystem.exists(chartsDir))
        {
            for (file in FileSystem.readDirectory(chartsDir))
            {
                if (file.endsWith(".json"))
                {
                    try
                    {
                        var diffName = file.substr(0, file.length - 5);
                        var rawJson = File.getContent(Path.join([chartsDir, file]));
                        var converted = CodenameCompat.convertChartJson(rawJson, songName);
                        if (converted != null)
                        {
                            var jsonStr = Json.stringify(converted, null, "\t");
                            File.saveContent(Path.join([outSongData, diffName + ".json"]), jsonStr);
                            log('  Converted chart: $songName/$diffName');
                        }
                        else
                        {
                            // Copy raw if conversion fails
                            copyFile(Path.join([chartsDir, file]), Path.join([outSongData, diffName + ".json"]));
                            log('  WARNING: Chart conversion returned null for $songName/$diffName, copied raw');
                        }
                    }
                    catch (e:Dynamic)
                    {
                        log('  ERROR converting chart $songName/$file: $e');
                        copyFile(Path.join([chartsDir, file]), Path.join([outSongData, file]));
                    }
                }
            }
        }

        // Merge events from events.json into chart files
        var eventsPath = Path.join([songSource, "events.json"]);
        if (FileSystem.exists(eventsPath))
        {
            try
            {
                var eventsJson:Dynamic = Json.parse(File.getContent(eventsPath));
                if (Reflect.hasField(eventsJson, "events"))
                {
                    // Add events to each chart
                    for (file in FileSystem.readDirectory(outSongData))
                    {
                        if (file.endsWith(".json"))
                        {
                            try
                            {
                                var chartPath = Path.join([outSongData, file]);
                                var chart:Dynamic = Json.parse(File.getContent(chartPath));
                                if (chart != null)
                                {
                                    if (!Reflect.hasField(chart, "events") || chart.events == null)
                                        chart.events = [];
                                    var existing:Array<Dynamic> = chart.events;
                                    for (evt in (Reflect.field(eventsJson, "events") : Array<Dynamic>))
                                        existing.push(evt);
                                    File.saveContent(chartPath, Json.stringify(chart, null, "\t"));
                                }
                            }
                            catch (e:Dynamic) {}
                        }
                    }
                }
            }
            catch (e:Dynamic)
            {
                log('  WARNING: Could not merge events.json for $songName: $e');
            }
        }

        // Copy song audio: songs/<name>/song/Inst.ogg → songs/<name>/Inst.ogg
        // Psych looks for songs/<name>/Inst.ogg
        var instOgg = Path.join([songSource, "song", "Inst.ogg"]);
        var instDirect = Path.join([songSource, "Inst.ogg"]);
        if (FileSystem.exists(instOgg) && !FileSystem.exists(instDirect))
        {
            var outSongDir = Path.join([output, "songs", songName]);
            ensureDir(outSongDir);
            copyFile(instOgg, Path.join([outSongDir, "Inst.ogg"]));
        }

        // Copy voices: songs/<name>/song/Voices*.ogg → songs/<name>/Voices*.ogg
        var songSubdir = Path.join([songSource, "song"]);
        if (FileSystem.exists(songSubdir))
        {
            var outSongDir = Path.join([output, "songs", songName]);
            ensureDir(outSongDir);
            for (file in FileSystem.readDirectory(songSubdir))
            {
                if (file.endsWith(".ogg") && file != "Inst.ogg")
                {
                    copyFile(Path.join([songSubdir, file]), Path.join([outSongDir, file]));
                }
            }
        }

        // Also copy any voices at song root (VS 3D Shaggy style)
        for (file in FileSystem.readDirectory(songSource))
        {
            if (file.startsWith("voices-") && file.endsWith(".ogg"))
            {
                var outSongDir = Path.join([output, "songs", songName]);
                ensureDir(outSongDir);
                copyFile(Path.join([songSource, file]), Path.join([outSongDir, file]));
            }
        }

        // Copy song scripts
        var scriptsDir = Path.join([songSource, "scripts"]);
        if (FileSystem.exists(scriptsDir))
        {
            var outSongScripts = Path.join([output, "data", songName, "scripts"]);
            ensureDir(outSongScripts);
            for (file in FileSystem.readDirectory(scriptsDir))
            {
                copyFile(Path.join([scriptsDir, file]), Path.join([outSongScripts, file]));
            }
        }

        // Copy cutscenes
        for (file in FileSystem.readDirectory(songSource))
        {
            if (file.endsWith(".mp4") || file.endsWith(".webm"))
            {
                var outSongDir = Path.join([output, "songs", songName]);
                ensureDir(outSongDir);
                copyFile(Path.join([songSource, file]), Path.join([outSongDir, file]));
            }
        }

        // Copy meta.json
        copyFileIfExists(songSource, output, 'songs/$songName/meta.json');
    }

    static function convertCodenameImages(source:String, output:String):Void
    {
        var imagesDir = Path.join([source, "images"]);
        if (!FileSystem.exists(imagesDir)) return;

        var outImagesDir = Path.join([output, "images"]);
        ensureDir(outImagesDir);

        for (entry in FileSystem.readDirectory(imagesDir))
        {
            var srcPath = Path.join([imagesDir, entry]);
            var dstPath = Path.join([outImagesDir, entry]);

            if (entry == "game")
            {
                // Codename: images/game/notes/ → Psych: images/noteSkins/
                var gameDir = srcPath;
                if (FileSystem.isDirectory(gameDir))
                {
                    for (sub in FileSystem.readDirectory(gameDir))
                    {
                        if (sub == "notes")
                        {
                            var notesDir = Path.join([gameDir, sub]);
                            var outNoteSkins = Path.join([outImagesDir, "noteSkins"]);
                            ensureDir(outNoteSkins);
                            for (noteFile in FileSystem.readDirectory(notesDir))
                            {
                                copyFile(Path.join([notesDir, noteFile]), Path.join([outNoteSkins, noteFile]));
                            }
                            log('  Remapped game/notes/ → noteSkins/');
                        }
                    }
                }
            }
            else if (entry == "menus")
            {
                // Codename: images/menus/storymenu/weeks/ → Psych: images/storymenu/
                convertStoryMenuImages(srcPath, outImagesDir);
                // Copy rest of menus as-is
                copyDirectory(srcPath, dstPath);
            }
            else if (entry == "stages")
            {
                // Codename: images/stages/<name>/ → Psych: images/stages/<name>/
                copyDirectory(srcPath, dstPath);
            }
            else
            {
                // Copy everything else as-is (characters, icons, etc.)
                if (FileSystem.isDirectory(srcPath))
                    copyDirectory(srcPath, dstPath);
                else
                    copyFile(srcPath, dstPath);
            }
        }
    }

    static function convertStoryMenuImages(menusSrc:String, outImagesDir:String):Void
    {
        var weeksSrc = Path.join([menusSrc, "storymenu", "weeks"]);
        if (FileSystem.exists(weeksSrc))
        {
            var outStorymenu = Path.join([outImagesDir, "storymenu"]);
            ensureDir(outStorymenu);
            for (file in FileSystem.readDirectory(weeksSrc))
            {
                copyFile(Path.join([weeksSrc, file]), Path.join([outStorymenu, file]));
            }
            log('  Remapped menus/storymenu/weeks/ → storymenu/');
        }

        // Convert menu characters: data/weeks/characters/ → menucharacters/
        // (These need JSON conversion, handled separately)
    }

    // ─── Kade / Vanilla FNF Conversion ─────────────────────────────────

    static function convertKadeMod(source:String, output:String):Bool
    {
        // Kade/Vanilla mods are mostly compatible. Just copy the data.
        log("Kade/Vanilla mod detected. Copying with minimal restructuring...");

        // Copy everything
        copyDirectory(source, output);

        // Ensure Psych-compatible pack.json exists
        var packPath = Path.join([output, "pack.json"]);
        if (!FileSystem.exists(packPath))
        {
            var folderName = Path.directory(source);
            var pack = {
                name: folderName,
                description: "Converted from Kade/Vanilla FNF mod",
                restart: false
            };
            File.saveContent(packPath, Json.stringify(pack, null, "\t"));
            log("  Created pack.json");
        }

        return true;
    }

    // ─── Whitty / FNF Multi Conversion ─────────────────────────────────

    static function convertWhittyMod(source:String, output:String):Bool
    {
        // Whitty mods use Lua. Copy everything and convert what we can.
        log("Whitty/FNF Multi mod detected. Converting...");

        // Same as Codename in many ways
        var ok = convertCodenameMod(source, output);

        // Also copy any top-level Lua scripts
        for (file in FileSystem.readDirectory(source))
        {
            if (file.endsWith(".lua"))
            {
                var outScriptsDir = Path.join([output, "scripts"]);
                ensureDir(outScriptsDir);
                copyFile(Path.join([source, file]), Path.join([outScriptsDir, file]));
            }
        }

        // Copy custom_events/
        copyDirectoryIfExists(source, output, "custom_events");

        return ok;
    }

    // ─── Utility Functions ─────────────────────────────────────────────

    static function copyFile(src:String, dst:String):Void
    {
        try
        {
            ensureDir(Path.directory(dst));
            if (FileSystem.exists(src))
                File.saveBytes(dst, sys.io.File.getBytes(src));
        }
        catch (e:Dynamic)
        {
            log('  WARNING: Failed to copy $src → $dst: $e');
        }
    }

    static function copyFileIfExists(source:String, output:String, relPath:String, ?outRelPath:String):Void
    {
        if (outRelPath == null) outRelPath = relPath;
        var src = Path.join([source, relPath]);
        var dst = Path.join([output, outRelPath]);
        if (FileSystem.exists(src) && !FileSystem.isDirectory(src))
            copyFile(src, dst);
    }

    static function copyDirectory(src:String, dst:String):Bool
    {
        if (!FileSystem.exists(src)) return false;
        ensureDir(dst);
        for (entry in FileSystem.readDirectory(src))
        {
            var srcPath = Path.join([src, entry]);
            var dstPath = Path.join([dst, entry]);
            if (FileSystem.isDirectory(srcPath))
                copyDirectory(srcPath, dstPath);
            else
                copyFile(srcPath, dstPath);
        }
        return true;
    }

    static function copyDirectoryIfExists(source:String, output:String, relPath:String):Void
    {
        var src = Path.join([source, relPath]);
        var dst = Path.join([output, relPath]);
        if (FileSystem.exists(src) && FileSystem.isDirectory(src))
            copyDirectory(src, dst);
    }

    static function ensureDir(path:String):Void
    {
        if (!FileSystem.exists(path))
            FileSystem.createDirectory(path);
    }

    static function hasXmlFiles(dir:String):Bool
    {
        if (!FileSystem.exists(dir)) return false;
        for (file in FileSystem.readDirectory(dir))
            if (file.endsWith(".xml")) return true;
        return false;
    }

    static function hasJsonFilesIn(dir:String):Bool
    {
        if (!FileSystem.exists(dir)) return false;
        for (file in FileSystem.readDirectory(dir))
            if (file.endsWith(".json")) return true;
        return false;
    }

    static function hasSongSubdirs(dir:String, subName:String):Bool
    {
        if (!FileSystem.exists(dir)) return false;
        for (entry in FileSystem.readDirectory(dir))
        {
            var songDir = Path.join([dir, entry]);
            if (FileSystem.isDirectory(songDir) && FileSystem.exists(Path.join([songDir, subName])))
                return true;
        }
        return false;
    }
}
#end
