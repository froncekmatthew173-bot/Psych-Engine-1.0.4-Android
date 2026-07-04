local cut = 0
--------------
local bfI_pos = 0
local limit = 1
local can_choose = "off"
local id = ""
--------------
local case = 0
--------------
local option1 = {
	'About you',
	'Your past',
	'The hall',
	'The lore'
}
local option2 = {
	'Why are you here',
	'Your job',
	'Your family',
	'Your history'
}
local option3 = {
	'About Shaggy',
	"Shaggy's power",
	"Shaggy's past",
	"Shaggy's history"
}

local option1s = 1
local option2s = 1
local option3s = 1
local option4s = 1

local dialLimit = 0


function onCreate()
	makeLuaSprite('bfI', 'zephy/bficon', -280, 500)
	scaleObject('bfI', 0.5, 0.5)
	setProperty('bfI.alpha', 0)
	addLuaSprite('bfI', true)

	makeAnimatedLuaSprite('mask', 'zephy/ph_mask', 200, 0)
	makeAnimatedLuaSprite('eye', 'zephy/ph_mask', 0, 0)
	makeAnimatedLuaSprite('horn', 'zephy/ph_mask', 0, 0)
	makeAnimatedLuaSprite('mouth', 'zephy/ph_mask', 0, 0)
	screenCenter('mask', 'x')

	if checkFileExists('Shaggy/savefiles/frame.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 2 then
		addAnimationByPrefix('mask', 'a', 'frame_f', 24, true)
	else
		setProperty('mask.alpha', 0.7)
		addAnimationByPrefix('mask', 'a', 'frame_e', 24, true)
	end

	if checkFileExists('Shaggy/savefiles/horn.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 2 then
		addAnimationByPrefix('horn', 'a', 'horn_f', 24, true)
	else
		setProperty('horn.alpha', 0.7)
		addAnimationByPrefix('horn', 'a', 'horn_e', 24, true)

	end

	if checkFileExists('Shaggy/savefiles/eye.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 2 then
		for i = 0, 10 do
			addAnimationByIndices('eye', i, 'eye_f', i, 24)
		end
	else
		setProperty('eye.alpha', 0.7)
		for i = 0, 10 do
			addAnimationByIndices('eye', i, 'eye_e', i, 24)
		end
	end

	if checkFileExists('Shaggy/savefiles/mouth.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 2 then
		for i = 0, 10 do
			addAnimationByIndices('mouth', i, 'mouth_f', i, 24)
		end
	else
		setProperty('mouth.alpha', 0.7)
		for i = 0, 10 do
			addAnimationByIndices('mouth', i, 'mouth_e', i, 24)
		end
	end

	if checkFileExists('Shaggy/savefiles/refused.txt', false) then
		setProperty('mask.angle', 40)
		playAnim('eye', 8)
		playAnim('mouth', 8)
	end

	setObjectCamera('mask', 'hud');
	setObjectCamera('mouth', 'hud');
	setObjectCamera('eye', 'hud');
	setObjectCamera('horn', 'hud');
	

	addLuaSprite('mask', true)
	addLuaSprite('horn', true)
	addLuaSprite('eye', true)
	addLuaSprite('mouth', true)

	doTweenY('mask1', 'mask', 60, 2, 'sineInOut')


	if checkFileExists('Shaggy/savefiles/accepted.txt', false) then
		case = 2
		precacheSound(zephyrus/phantomMenu)
		precacheSound(zephyrus/phantomMenuScary)
	elseif checkFileExists('Shaggy/savefiles/refused.txt', false) then
		case = 1
	end
end

function onCreatePost()
	for i = 1, 5 do
		makeLuaText('choice'..i, '', 999, 80, 350 + 50 * i)
		setTextFont('choice'..i, "pixel.ttf")
		setTextSize('choice'..i, 32)
		setTextAlignment("choice"..i, 'left')
		addLuaText('choice'..i)
	end
	makeLuaSprite('frame_orb', 'zephy/partSmall', 600,900)
	setObjectCamera('frame_orb', 'hud')
	scaleObject('frame_orb', getRandomFloat(1.4, 1.6), getRandomFloat(1.4, 1.6))
	addLuaSprite('frame_orb', true)
	
	makeLuaSprite('mouth_orb', 'zephy/partSmall', 200,930)
	setObjectCamera('mouth_orb', 'hud')
	scaleObject('mouth_orb', getRandomFloat(1.4, 1.6), getRandomFloat(1.4, 1.6))
	addLuaSprite('mouth_orb', true)

	makeLuaSprite('horn_orb', 'zephy/partSmall', -100,1000)
	setObjectCamera('horn_orb', 'hud')
	scaleObject('horn_orb', getRandomFloat(1.4, 1.6), getRandomFloat(1.4, 1.6))
	addLuaSprite('horn_orb', true)

	makeLuaSprite('eye_orb', 'zephy/partSmall', 1000,1000)
	setObjectCamera('eye_orb', 'hud')
	scaleObject('eye_orb', getRandomFloat(1.4, 1.6), getRandomFloat(1.4, 1.6))
	addLuaSprite('eye_orb', true)

	if tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) > 0 then
		dialLimit = dialLimit + 1
	end
	if tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) > 0 then
		dialLimit = dialLimit + 1
	end
	if tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) > 0 then
		dialLimit = dialLimit + 1
	end
	if tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) > 0 then
		dialLimit = dialLimit + 1
	end
	triggerEvent('dialogue.setSkin', 'zephyrus', '');
end


function onStartCountdown()
	return onZephyrus()
end


function onUpdate()
	setProperty('horn.x', (getProperty('mask.x') + 0))
	setProperty('horn.y', (getProperty('mask.y') + 0))
	setProperty('eye.x', (getProperty('mask.x') + 0))
	setProperty('eye.y', (getProperty('mask.y') + 0))
	setProperty('mouth.x', (getProperty('mask.x') + 0))
	setProperty('mouth.y', (getProperty('mask.y') + 0))
	setProperty('horn.angle', getProperty('mask.angle'))
	setProperty('eye.angle', getProperty('mask.angle'))
	setProperty('mouth.angle', getProperty('mask.angle'))
	if case == 0 or case == 1 then
		choice1(can_choose, limit, id)
	elseif case == 2 then
		choice2(can_choose, limit, id)
	end
	if luaSoundExists('good_menu') then
		gmenu_sound = getSoundVolume('good_menu')
	end
	if option1s > dialLimit then
		if dialLimit <= 1 then
			option1s = 1
		else
			option1s = 4
		end
	end
	if option2s > dialLimit then
		if dialLimit <= 1 then
			option2s = 1
		else
			option2s = 4
		end
	end
	if option3s > dialLimit then
		if dialLimit <= 1 then
			option3s = 1
		else
			option3s = 4
		end
	end
end

function onZephyrus()
	cut = cut + 1
	if case == 0 then
		if cut == 1 then
			playSound('zephyrus/phantomIntro', 1, 'menu_intro')
			pauseSound('menu_intro')
			triggerEvent('startDialogue', 'intro/intro1', '');
			return Function_Stop;
		elseif cut == 2 then
			setTextString("choice1", "Accept")
			setTextString("choice2", "Who are you")
			can_choose = "on"
			limit = 1
			id = "accept_intro"
			return Function_Stop;



		elseif cut == 4 then
			setTextString("choice1", "Accept")
			setTextString("choice2", "Decline")
			can_choose = "on"
			limit = 1
			id = "confirm_intro"
			return Function_Stop;

		elseif cut == 6 then
			endSong()
			return Function_Stop;

		elseif cut == 10 then
			setTextString("choice1", "Oh okay")
			setTextString("choice2", "Would they beat goku tho")
			can_choose = "on"
			limit = 1
			id = "goku"
			return Function_Stop;

		elseif cut == 11 then
			setTextString("choice1", "Yes")
			setTextString("choice2", "No")
			can_choose = "on"
			limit = 1
			id = "repeat_story_shag"
			return Function_Stop;

		elseif cut == 12 then
			setTextString("choice1", "Yes")
			setTextString("choice2", "No")
			can_choose = "on"
			limit = 1
			id = "repeat_story_past"
			return Function_Stop;

		elseif cut == 13 then
			setTextString("choice1", "Yes")
			setTextString("choice2", "No")
			can_choose = "on"
			limit = 1
			id = "repeat_story_lore"
			return Function_Stop;

		elseif cut == 14 then
			setTextString("choice1", "Understood")
			setTextString("choice2", "I can't")
			can_choose = "on"
			limit = 1
			id = "frame_burried"
			return Function_Stop;

		elseif cut == 15 then
			setTextString("choice1", "Yes")
			setTextString("choice2", "No")
			can_choose = "on"
			limit = 1
			id = "laser"
			return Function_Stop;
		end
	end
	if case == 1 then
		if cut == 1 then
			playSound('zephyrus/phantomIntro', 1, 'menu_intro')
			pauseSound('menu_intro')
			triggerEvent('startDialogue', 'intro/re-enter', '');
			return Function_Stop;

		elseif cut == 2 then
			setTextString("choice1", "I'll accept the deal")
			setTextString("choice2", "No")
			can_choose = "on"
			limit = 1
			id = "return_confirm"
			return Function_Stop;
		end
	end

	if case == 2 then
		if cut == 1 then
			triggerEvent('startDialogue', 'welcome/welcome'..getRandomInt(1, 8), '');
			cut = 1
			if tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 1 then
				cut = 8
			end
			return Function_Stop;
		elseif cut == 2 then



			if not luaSoundExists('good_menu') then
				playSound('zephyrus/phantomMenu', 10, 'good_menu')
				playSound('zephyrus/phantomMenuScary', 0, 'scary_menu')
			end
			setTextString("choice1", option1[option1s])
			setTextString("choice2", option2[option2s])
			setTextString("choice3", option3[option3s])
			setTextString("choice4", "Your parts")
			setTextString('choice5', "Exit")
			can_choose = "on"
			limit = 4
			id = "return_confirm"
			return Function_Stop;

		elseif cut == 5 then
			if tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 1 then
				triggerEvent('startDialogue', 'forgot', '');
				cut = 8
			else
				endSong()
			end
			return Function_Stop;

		elseif cut == 9 then
			dialLimitOld = dialLimit
			if tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 1 then
				saveFile('Shaggy/savefiles/frame.txt', "2", false)
				doTweenX('frame_orn_scale_x', 'frame_orb.scale', 0, 3, 'linear')
				doTweenY('frame_orb_scale_y', 'frame_orb.scale', 0, 3, 'linear')
				doTweenX('frame_orb_move_x', 'frame_orb', getProperty('mask.x')+80, 1, 'sineInOut')
				doTweenY('frame_orn_move_y', 'frame_orb', getProperty('mask.y')+120, 1, 'sineInOut')
			end
			if tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 1 then
				saveFile('Shaggy/savefiles/mouth.txt', "2", false)
				doTweenX('mouth_orb_scale_x', 'mouth_orb.scale', 0, 3, 'linear')
				doTweenY('mouth_orb_scale_y', 'mouth_orb.scale', 0, 3, 'linear')
				doTweenX('mouth_orb_move_x', 'mouth_orb', getProperty('mask.x')+80, 1, 'sineInOut')
				doTweenY('mouth_orb_move_y', 'mouth_orb', getProperty('mask.y')+120, 1, 'sineInOut')
			end
			if tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 1 then
				saveFile('Shaggy/savefiles/horn.txt', "2", false)
				doTweenX('horn_orb_scale_x', 'horn_orb.scale', 0, 3, 'cubeIn')
				doTweenY('horn_orb_scale_y', 'horn_orb.scale', 0, 3, 'cubeIn')
				doTweenX('horn_orb_move_x', 'horn_orb', getProperty('mask.x')+80, 1, 'sineInOut')
				doTweenY('horn_orb_move_y', 'horn_orb', getProperty('mask.y')+120, 1, 'sineInOut')
			end
			if tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 1 then
				saveFile('Shaggy/savefiles/eye.txt', "2", false)
				doTweenX('eye_orb_scale_x', 'eye_orb.scale', 0, 3, 'cubeIn')
				doTweenY('eye_orb_scale_y', 'eye_orb.scale', 0, 3, 'cubeIn')
				doTweenX('eye_orb_move_x', 'eye_orb', getProperty('mask.x')+80, 1, 'sineInOut')
				doTweenY('eye_orb_move_y', 'eye_orb', getProperty('mask.y')+120, 1, 'sineInOut')
			end

			runTimer('orb_fly', 3.5)
				
			return Function_Stop;

		elseif cut == 10 then
			cut = 1
			if dialLimit == 1 and dialLimitOld == 1 then
				triggerEvent('startDialogue', 'give/3More', '');
				cut = 4
			elseif dialLimit == 4 and dialLimitOld == 0 then
				triggerEvent('startDialogue', 'give/AllStart', '');
				saveFile('Shaggy/savefiles/talla.txt', "", false)
				cut = 4
			elseif dialLimitOld == 0 and dialLimit > 1 and dialLimit < 4 then
				triggerEvent('startDialogue', 'give/Lot', '');
				cut = 4


			elseif dialLimit == 2 then
				triggerEvent('startDialogue', 'give/2More', '');

			elseif dialLimit == 3 then
				triggerEvent('startDialogue', 'give/1More', '');

			elseif dialLimit == 4 then
				saveFile('Shaggy/savefiles/talla.txt', "", false)
				playSound('zephyrus/phantomMenu', 1, 'good_menu')
				playSound('zephyrus/phantomMenuScary', 0, 'scary_menu')
				triggerEvent('startDialogue', 'give/0More', '');

			end
			
			return Function_Stop;
		end
	end

	if cut == 99 then
		--stuff ig
	end
end


function choice1(start, limit, id)
	if start == "on" then
		setProperty('bfI.alpha', 1)
		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.DOWN') and (getProperty('bfI.alpha') > 0.9) and bfI_pos < limit then
			playSound('scrollMenu', 1)
			setProperty('bfI.y', (getProperty('bfI.y') + 50))
			bfI_pos = bfI_pos + 1
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.UP') and (getProperty('bfI.alpha') > 0.9) and bfI_pos > 0 then
			playSound('scrollMenu', 1)
			setProperty('bfI.y', (getProperty('bfI.y') - 50))
			bfI_pos = bfI_pos - 1
		end

		if keyJustPressed('accept') then
			setProperty('bfI.alpha', 0)
			setProperty('bfI.y', 500)
			for i = 1, 4 do
				setTextString("choice"..i, "")
			end
			if case == 0 then
				if id == "accept_intro" then
					if bfI_pos == 1 then
						cut = 3
					elseif bfI_pos == 0 then
						case = 2
						cut = 1
						saveFile('Shaggy/savefiles/accepted.txt', "egg", false)
					end
				elseif id == "confirm_intro" then
					if bfI_pos == 0 then
						case = 2
						cut = 1
						saveFile('Shaggy/savefiles/accepted.txt', "egg", false)
					elseif bfI_pos == 1 then
						cut = 5
						saveFile('Shaggy/savefiles/refused.txt', "egg", false)
					end

					
				elseif id == "goku" then
					case = 2
					cut = 1
				elseif id == "repeat_story_shag" then
					case = 2
					cut = 1
					if bfI_pos == 0 then
						option3s = 1
					end
				elseif id == "repeat_story_past" then
					case = 2
					cut = 1
					if bfI_pos == 0 then
						option2s = 1
					end
				elseif id == "repeat_story_lore" then
					case = 2
					cut = 1
					if bfI_pos == 0 then
						option1s = 1
					end
				end
			elseif case == 1 then
				if id == "return_confirm" then
					if bfI_pos == 0 then
						deleteFile('Shaggy/savefiles/refused.txt', false)
						saveFile('Shaggy/savefiles/accepted.txt', "egg", false)
						case = 2
						cut = 1
					elseif bfI_pos == 1 then
						case = 0
						cut = 5
					end
				end
			end
			can_choose = False
			if id == "repeat_story_lore" or id == "repeat_story_past" or id == "repeat_story_shag" then
				triggerEvent('startDialogue', 'repeat/'..id..bfI_pos, '');
			elseif id == "accept_intro" or id == "confirm_intro" or id == "return_confirm" then
				triggerEvent('startDialogue', 'intro/'..id..bfI_pos, '');
			elseif id == "goku" then
				triggerEvent('startDialogue', 'goku/'..id..bfI_pos, '');
			elseif id == "frame_burried" or id == "laser" then
				case = 2
				cut = 1
				triggerEvent('startDialogue', 'parts/followups/'..id..bfI_pos, '');
			else
				triggerEvent('startDialogue', id..bfI_pos, '');
			end
			bfI_pos = 0
		end
	end
end

function choice2(start, limit, id)
	if start == "on" then
		setProperty('bfI.alpha', 1)
		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.DOWN') and (getProperty('bfI.alpha') > 0.9) and bfI_pos < limit then
			playSound('scrollMenu', 1)
			setProperty('bfI.y', (getProperty('bfI.y') + 50))
			bfI_pos = bfI_pos + 1
		end

		if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.UP') and (getProperty('bfI.alpha') > 0.9) and bfI_pos > 0 then
			playSound('scrollMenu', 1)
			setProperty('bfI.y', (getProperty('bfI.y') - 50))
			bfI_pos = bfI_pos - 1
		end

		if keyJustPressed('accept') then
			setProperty('bfI.alpha', 0)
			setProperty('bfI.y', 500)
			for i = 1, 5 do
				setTextString("choice"..i, "")
			end
			can_choose = False
			if bfI_pos == 0 then
				cut = 1
				if option1s == 1 then
					triggerEvent('startDialogue', 'lore/About you', '');
					option1s = 2
				elseif option1s == 2 then
					triggerEvent('startDialogue', 'lore/Your past', '');
					option1s = 3
				elseif option1s == 3 then
					triggerEvent('startDialogue', 'lore/The hall', '');
					option1s = 4
				elseif option1s == 4 then
					triggerEvent('startDialogue', 'repeat', '');
					case = 0
					cut = 12
				end
			elseif bfI_pos == 1 then
				cut = 1
				if option2s == 1 then
					triggerEvent('startDialogue', 'past/Why are you here', '');
					option2s = 2
				elseif option2s == 2 then
					triggerEvent('startDialogue', 'past/Your job', '');
					option2s = 3
				elseif option2s == 3 then
					triggerEvent('startDialogue', 'past/Your family', '');
					option2s = 4
				elseif option2s == 4 then
					triggerEvent('startDialogue', 'repeat', '');
					case = 0
					cut = 11
				end
			elseif bfI_pos == 2 then
				cut = 1
				if option3s == 1 then
					triggerEvent('startDialogue', 'shaggy/About Shaggy', '');
					option3s = 2
				elseif option3s == 2 then
					triggerEvent('startDialogue', "shaggy/Shaggy's power", '');
					option3s = 3
					case = 0
					cut = 9
				elseif option3s == 3 then
					triggerEvent('startDialogue', "shaggy/Shaggy's past", '');
					option3s = 4
				elseif option3s == 4 then
					triggerEvent('startDialogue', 'repeat', '');
					case = 0
					cut = 10
				end

			elseif bfI_pos == 3 then
				cut = 1

				if checkFileExists('Shaggy/savefiles/talla.txt', false) then
					if tonumber(getTextFromFile('Shaggy/savefiles/god.txt', false)) == 2 then
						triggerEvent('startDialogue', "parts/finished", '');
					elseif tonumber(getTextFromFile('Shaggy/savefiles/god.txt', false)) == 1 then
						saveFile('Shaggy/savefiles/god.txt', "2", false)
						triggerEvent('startDialogue', "parts/finishedGOD2", '');
					elseif tonumber(getTextFromFile('Shaggy/savefiles/god.txt', false)) == 0 then
						triggerEvent('startDialogue', "parts/finishedGOD1", '');
					end
				elseif dialLimit == 4 then
					triggerEvent('startDialogue', "parts/notSure", '');
				elseif tonumber(getTextFromFile('Shaggy/savefiles/intro-part.txt', false)) == 0 then
					saveFile('Shaggy/savefiles/intro-part.txt', "1", false)
					triggerEvent('startDialogue', "parts/intro", '');
				elseif tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 0 then
					triggerEvent('startDialogue', "parts/mouth"..option4s, '');
				elseif tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 0 then
					triggerEvent('startDialogue', "parts/frame"..option4s, '');
					case = 0
					cut = 13
				elseif tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 0 then
					triggerEvent('startDialogue', "parts/horn"..option4s, '');
				elseif tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 0 then
					triggerEvent('startDialogue', "parts/eye"..option4s, '');
					if option4s == 1 then
						case = 0
						cut = 14
					end




				end
				if option4s == 1 then
					option4s = 2
				end


			elseif bfI_pos == 4 then
				triggerEvent('startDialogue', 'exit/exit'..getRandomInt(1, 7), '');
				cut = 4
			end
			bfI_pos = 0
		end
	end
end


function onTimerCompleted(tag)
	if tag == "orb_fly" then
		cameraFlash("other", 'FFFFFF', 2, true)
		UpdateZephy()
		playSound('zephyrus/maskColl')
		runTimer('wait_2.5_s', 2.5)
	elseif tag == "wait_2.5_s" then
		startCountdown()
	end
end


function onSoundFinished(tag)
	if tag == "good_menu" then
		playSound('zephyrus/phantomMenu', gmenu_sound, 'good_menu')
		playSound('zephyrus/phantomMenuScary', getSoundVolume('scary_menu'), 'scary_menu')
	elseif tag == "menu_intro" then
		playSound('zephyrus/phantomIntro', 1, 'menu_intro')
	end
end

function UpdateZephy()
	removeLuaSprite('mask')
	removeLuaSprite('horn')
	removeLuaSprite('mouth')
	removeLuaSprite('eye')

	makeAnimatedLuaSprite('mask', 'zephy/ph_mask', 200, 0)
	makeAnimatedLuaSprite('eye', 'zephy/ph_mask', 0, 0)
	makeAnimatedLuaSprite('horn', 'zephy/ph_mask', 0, 0)
	makeAnimatedLuaSprite('mouth', 'zephy/ph_mask', 0, 0)
	screenCenter('mask', 'x')

	if checkFileExists('Shaggy/savefiles/frame.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 2 then
		addAnimationByPrefix('mask', 'a', 'frame_f', 24, true)
	else
		setProperty('mask.alpha', 0.7)
		addAnimationByPrefix('mask', 'a', 'frame_e', 24, true)
	end

	if checkFileExists('Shaggy/savefiles/horn.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 2 then
		addAnimationByPrefix('horn', 'a', 'horn_f', 24, true)
	else
		setProperty('horn.alpha', 0.7)
		addAnimationByPrefix('horn', 'a', 'horn_e', 24, true)

	end

	if checkFileExists('Shaggy/savefiles/eye.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 2 then
		for i = 0, 10 do
			addAnimationByIndices('eye', i, 'eye_f', i, 24)
		end
	else
		setProperty('eye.alpha', 0.7)
		for i = 0, 10 do
			addAnimationByIndices('eye', i, 'eye_e', i, 24)
		end
	end

	if checkFileExists('Shaggy/savefiles/mouth.txt', false) and tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 2 then
		for i = 0, 10 do
			addAnimationByIndices('mouth', i, 'mouth_f', i, 24)
		end
	else
		setProperty('mouth.alpha', 0.7)
		for i = 0, 10 do
			addAnimationByIndices('mouth', i, 'mouth_e', i, 24)
		end
	end

	setObjectCamera('mask', 'hud');
	setObjectCamera('mouth', 'hud');
	setObjectCamera('eye', 'hud');
	setObjectCamera('horn', 'hud');
	

	addLuaSprite('mask', true)
	addLuaSprite('horn', true)
	addLuaSprite('eye', true)
	addLuaSprite('mouth', true)
end