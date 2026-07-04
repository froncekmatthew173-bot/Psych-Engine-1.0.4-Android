local allowCountdown = false
local stops = 0;
function onStartCountdown()
setCameraFollowPoint(800.0, 600.0)
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if not allowCountdown and isStoryMode and not seenCutscene then
        
		setProperty('inCutscene', false);

    if stops == 0 then
        characterPlayAnim('dad', 'intro-static', true)
	makeLuaSprite('black', nil, 0, 0)
	makeGraphic('black', screenWidth * 2, screenHeight * 2, '000000');
	screenCenter('black')
	setObjectCamera('black', 'camOther');
        runTimer('dial1', 0.8)
    end

    if stops == 1 then
        runTimer('magic', 0.5)
    end

        stops = stops + 1
		return Function_Stop;
	end
	return Function_Continue;
end

function onTimerCompleted(tag)
	if tag == 'magic' then
		runTimer('end', 1)
		characterPlayAnim('dad', 'intro', true)
	end
	if tag ==  'dial1' then
		triggerEvent('startDialogue', 'dialogue', '');
	end
	if tag == 'end' then
		allowCountdown = true;
		startCountdown()
	end
end	

function onTweenCompleted(tag)
	if tag == 'fadeOut' then
		removeLuaSprite('black', true)
	end
end