package psychlua;

/**
 * Codename Engine API shim layer.
 * Provides stub implementations for common Codename Engine APIs
 * so that some Codename scripts can at least load without crashing.
 * 
 * These are NOT full implementations - they're compatibility stubs
 * that allow partial mod functionality.
 */
class CodenameShim
{
    /**
     * Check if a script contains Codename Engine-specific APIs
     * that are not supported in Psych Engine.
     */
    public static function detectCodenameApis(scriptContent:String):Array<String>
    {
        var unsupportedApis:Array<String> = [];

        // Check for Codename-specific imports
        if (scriptContent.contains("funkin.backend"))
            unsupportedApis.push("funkin.backend.* imports (Codename Engine backend)");

        if (scriptContent.contains("funkin.modchart"))
            unsupportedApis.push("funkin.modchart.* imports (Codename modchart system)");

        // Check for Codename-specific APIs
        if (scriptContent.contains("strumLines"))
            unsupportedApis.push("strumLines (Codename StrumLine system)");

        if (scriptContent.contains("scripts.call("))
            unsupportedApis.push("scripts.call() (Codename script calling)");

        if (scriptContent.contains("newState("))
            unsupportedApis.push("newState() (Codename state creation)");

        if (scriptContent.contains("WindowUtils"))
            unsupportedApis.push("WindowUtils (Codename window utilities)");

        if (scriptContent.contains("NativeAPI"))
            unsupportedApis.push("NativeAPI (Codename native API)");

        if (scriptContent.contains("FunkinSprite"))
            unsupportedApis.push("FunkinSprite (Codename sprite class)");

        if (scriptContent.contains("Options.colorHealthBar"))
            unsupportedApis.push("Options.colorHealthBar (Codename options)");

        if (scriptContent.contains("stage?.characterPoses"))
            unsupportedApis.push("stage.characterPoses (Codename stage API)");

        if (scriptContent.contains("StickerHandler"))
            unsupportedApis.push("StickerHandler (Codename sticker system)");

        if (scriptContent.contains("animateAtlas"))
            unsupportedApis.push("animateAtlas (Codename FlxAnimate integration)");

        if (scriptContent.contains("lastAnimContext"))
            unsupportedApis.push("lastAnimContext (Codename animation context)");

        if (scriptContent.contains("drawComplex("))
            unsupportedApis.push("drawComplex() (Codename rendering)");

        if (scriptContent.contains("createColoredEmptyBar"))
            unsupportedApis.push("createColoredEmptyBar (Codename health bar)");

        if (scriptContent.contains("createColoredFilledBar"))
            unsupportedApis.push("createColoredFilledBar (Codename health bar)");

        if (scriptContent.contains("getIcon()"))
            unsupportedApis.push("getIcon() (Codename icon system)");

        if (scriptContent.contains("iconColor"))
            unsupportedApis.push("iconColor (Codename icon color)");

        if (scriptContent.contains("iconP1.setIcon"))
            unsupportedApis.push("iconP1.setIcon() (Codename icon system)");

        if (scriptContent.contains("deleteNote("))
            unsupportedApis.push("deleteNote() (Codename note deletion)");

        if (scriptContent.contains("cancel()"))
            unsupportedApis.push("cancel() (Codename event cancellation in HScript)");

        return unsupportedApis;
    }

    /**
     * Check if a script is likely a Codename state script
     * (replaces entire game states).
     */
    public static function isCodenameStateScript(scriptPath:String):Bool
    {
        // Codename state scripts are in data/states/ and override game states
        return scriptPath.contains("/data/stages/") ||
               scriptPath.contains("\\data\\states\\") ||
               scriptPath.endsWith("State.hx") && scriptPath.contains("data/states/");
    }

    /**
     * Get a warning message for Codename-only features.
     */
    public static function getCodenameWarning(api:String):String
    {
        return 'WARNING: Codename Engine API "$api" is not supported in Psych Engine. ' +
               'This script may not work correctly. Consider converting to Psych Engine format.';
    }

    /**
     * Determine if a script should be skipped entirely
     * (too many unsupported APIs to be useful).
     */
    public static function shouldSkipScript(scriptContent:String):Bool
    {
        var unsupported = detectCodenameApis(scriptContent);

        // Skip if it has too many unsupported APIs
        if (unsupported.length >= 5) return true;

        // Skip if it imports Codename backend
        if (scriptContent.contains("funkin.backend")) return true;

        // Skip if it uses state replacement
        if (scriptContent.contains("newState(")) return true;

        return false;
    }
}
