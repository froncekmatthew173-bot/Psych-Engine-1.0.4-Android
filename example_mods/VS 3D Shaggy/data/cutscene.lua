function onCreate()
	if isStoryMode then
		makeLuaSprite('black', nil, 0, 0)
		makeGraphic('black', screenWidth * 2, screenHeight * 2, '000000');
		screenCenter('black')
		setObjectCamera('black', 'camOther');
	end
end

local allowCountdown = false
function onStartCountdown()
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if (not allowCountdown and isStoryMode and not seenCutscene) then --
		setProperty('inCutscene', true);
		addLuaSprite('black', true)
		doTweenAlpha('byelol', 'black', 0, 0.8, 'linear')
		allowCountdown = true;
		seenCutscene = true;
		return Function_Stop;
	end
	return Function_Continue;
end

function onTweenCompleted(tag)
	if tag == 'byelol' then 
		removeLuaSprite('black', true)
		triggerEvent('startDialogue', 'dialogue', '')
	end
end