import lime.graphics.Image;
import funkin.backend.utils.NativeAPI;

static var StickerHandler = null;
function new() {
}

import funkin.backend.utils.WindowUtils;

function destroy(){
    WindowUtils.winTitle = "Friday Night Funkin' - Codename Engine";
}

function getLastStateShown(skipSubStates:Bool = false) {
    if (!skipSubStates) {
        var curSubState = FlxG.state.subState;
        var foundSubState = null;

        while (curSubState != null) {
            if (curSubState != null)
                foundSubState = curSubState;

            curSubState = curSubState.subState;
        }

        if (foundSubState != null)
            return foundSubState;  // Started from a substate
    }

    return FlxG.state;
}

function postStateSwitch() {
    if (StickerHandler.__doOut)
    {
        StickerHandler.__doTransition(false, function() {});
        StickerHandler.__doOut = false;
        StickerHandler.inProgress = false;
    }
}

static var redirectStates:Map<FlxState, String> = [
    FreeplayState => "FD/FreeplayCustomState",
    MainMenuState => "FD/MainMenuState",
    TitleState => "FD/TitleState",
];
function update(){
    if (FlxG.save.data.devMode) {
        if (FlxG.keys.justPressed.F5)
            FlxG.resetState();
        if (FlxG.keys.justPressed.F6)
            NativeAPI.allocConsole();
    }
}
function preStateSwitch() {
    window.setIcon(Image.fromBytes(Assets.getBytes(Paths.image('icon'))));
	for (redirectState in redirectStates.keys())
		if (FlxG.game._requestedState is redirectState)
			FlxG.game._requestedState = newState(redirectStates.get(redirectState));
}

function postUpdate() {
    if (FlxG.keys.justPressed.R) {
        FlxG.switchState(new StoryMenuState());
    }
}