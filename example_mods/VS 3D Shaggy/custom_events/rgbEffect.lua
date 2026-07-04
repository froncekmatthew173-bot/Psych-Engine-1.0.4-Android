local shaderName = "rgb effect2"
local update = false

function onEvent(name, value1, value2)
	if name == "rgbEffect" then


	end
end

local crap = 1
function onUpdate(elapsed)
	if update then
		setShaderFloat("rgb effect2", "iTime", crap)
		crap = crap + 10.328
	end
end