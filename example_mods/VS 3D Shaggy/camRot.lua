rotCam = 2
local rotCamSpd = 1
local rotCamRange = 10
local rotCamInd = 0

local collected = false
local wSize = 0


function onCreate()
	makeLuaSprite('horn', 'zephy/part/horn', 0, 0)
	setObjectCamera('horn', 'camOther')
	addLuaSprite('horn', true)

	makeLuaSprite('mouse', 'zephy/part/picker', 0, 0)
	setObjectCamera('mouse', 'camOther')
	addLuaSprite('mouse', true)

	makeLuaSprite('fx', 'zephy/fx', 0, 0)
	setObjectCamera('fx', 'camOther')
	setProperty('fx.alpha', 0)
	addLuaSprite('fx', true)

	makeLuaSprite('orb', 'zephy/partSmall', 0, 0)
	setObjectCamera('orb', 'camOther')
	setProperty('orb.alpha', 0)
	addLuaSprite('orb', true)
end

function onCreatePost()
	if not isStoryMode or botplay or tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) > 0 then
		setProperty('mouse.visible', false)
	end
end

function onUpdate()
	if rotCam then
		setProperty('horn.visible', true)
		setProperty('mouse.alpha', 1)
		rotCamInd = rotCamInd + 1
		setProperty('camGame.angle',  math.sin(rotCamInd / 100 * rotCamSpd) * rotCamRange)
		setProperty('camHUD.angle',  math.sin(rotCamInd / 100 * rotCamSpd) * -rotCamRange)
		if not isStoryMode or botplay or tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) > 0 then
			setProperty('mouse.alpha', 1)
		end
	else
		setProperty('horn.visible', false)
		setProperty('mouse.alpha', 0)
		rotCamInd = 0
		setProperty('camGame.angle', 0)
		setProperty('camHUD.angle', 0)
	end

	wSize = getProperty('camGame.width') / 2
	setProperty('mouse.x',getMouseX('camOther'));
	setProperty('mouse.y',getMouseY('camOther'));
	setProperty('horn.x', wSize + (wSize - 200) * math.cos(-getProperty('camGame.angle') * math.pi / 180))
	setProperty('horn.y', -math.sin(-getProperty('camGame.angle') * math.pi / 180) * wSize * 1.3 - 130)
	setProperty('horn.angle', getProperty('camGame.angle'))


	if getProperty('horn.alpha') > 0 and not collected and mouseClicked('left') and (getProperty('mouse.y') < getProperty('horn.y') + 100) and (getProperty('mouse.y') > getProperty('horn.y')) and (getProperty('mouse.x') < getProperty('horn.x') + 100) and (getProperty('mouse.x') > getProperty('horn.x')) then
		collected = true
		setProperty('orb.x', getProperty('mouse.x'))
		setProperty('orb.y', getProperty('mouse.y'))

		setProperty('fx.x', getProperty('orb.x')-100)
		setProperty('fx.y', getProperty('orb.y')-100)
		cancelTween('horn_fall')
		cancelTween('horn_speen')
		playSound('zephyrus/maskColl')
		setProperty('fx.alpha', 1)
		setProperty('orb.alpha', 1)
		setProperty('horn.alpha', 0)
		setProperty('mouse.alpha', 0)
		doTweenX('fx_growX', 'fx.scale', 1.3, 1, 'linear')
		doTweenY('fx_growY', 'fx.scale', 1.3, 1, 'linear')
		doTweenAlpha('bye_fx', 'fx', 0, 1, 'linear')
		doTweenX('orb_flyX', 'orb', getMidpointX('boyfriend'), 2, 'cubeIn')
		doTweenY('orb_flyY', 'orb', getMidpointY('boyfriend'), 2, 'sineInOut')
		saveFile('Shaggy/savefiles/horn.txt', "1", false)
	end
end

function onBeatHit()
	if curBeat == 328 or curBeat == 552 then
		rotCam = true
		rotCamSpd = 2
		rotCamRange = 5
	elseif curBeat == 424 or curBeat == 616 then
		rotCam = false
	end
end



function onTweenCompleted(tag)
	if tag == 'horn_fall1' then
		doTweenY('horn_fall1', 'horn', getProperty('boyfriend.y') + 300, 1.8, 'cubeIn')
	end
	if tag == "orb_flyY" then
		doTweenX('orb_shrinkX', 'orb.scale', 0, 3, 'linear')
		doTweenY('orb_shrinkY', 'orb.scale', 0, 3, 'linear')
	end
end


