local rotCam = "off"
local rotCamSpd = 1
local rotCamRange = 10
local rotCamInd = 0

function onUpdate()
	if rotCam == "on" then
		debugPrint('GAGA')
		rotCamInd = rotCamInd + 1
		setProperty('camGame.angle',  math.sin(rotCamInd / 100 * rotCamSpd) * rotCamRange)
		setProperty('camHUD.angle',  math.sin(rotCamInd / 100 * rotCamSpd) * -rotCamRange)
	else
		rotCamInd = 0
	end
end

function onBeatHit()
	if curBeat == 328 then
		rotCam = "on"
		rotCamSpd = 2
		rotCamRange = 5
	end
end
