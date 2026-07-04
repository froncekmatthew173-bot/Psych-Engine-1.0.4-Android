local shadname = "glitchEffect";
-- Object settings
local objName = 'van'

local startX = -300        -- starting X (off-screen left)
local endX = 1600          -- end X (off-screen right, adjust for your resolution)
local startY = 300         -- base Y position
local floatAmplitude = 20  -- pixels up/down
local floatSpeed = 2       -- vertical bob speed
local moveSpeed = 200      -- horizontal speed (pixels per second)

-- INTERNAL
local elapsedTime = 0
local objWidth = 0
local screenW = 1280 -- default Psych Engine width, change if using widescreen
function onCreate()
    initLuaShader(shadname)

	makeLuaSprite('sprite1', 'background', -762, -531);
	scaleObject('sprite1', 10,10,true)
    setProperty('sprite1.antialiasing', false)
	setSpriteShader('sprite1', shadname)

	makeLuaSprite('sprite3', 'pyramids', -409, -254);
	scaleObject('sprite3', 4,4,true)
    setProperty('sprite3.antialiasing', false)
	setSpriteShader('sprite3', shadname)


	makeLuaSprite('bg', 'hills', -1310, 561);
    setProperty('bg.antialiasing', false)
	scaleObject('bg', 2.5,2.5,true)

        addLuaSprite('sprite1');
        addLuaSprite('sprite3');
	addLuaSprite('bg');
	setShaderFloat('sprite1', 'uWaveAmplitude', 0.1)
	setShaderFloat('sprite1', 'uFrequency', 5)
	setShaderFloat('sprite1', 'uSpeed', 2)
	setShaderFloat('sprite3', 'uWaveAmplitude', 0.1)
	setShaderFloat('sprite3', 'uFrequency', 5)
	setShaderFloat('sprite3', 'uSpeed', 2)
end
function onUpdatePost(elapsed)
	setShaderFloat('sprite1', 'uTime', os.clock())
	setShaderFloat('sprite3', 'uTime', os.clock())
end

function onUpdate(elapsed)
    elapsedTime = elapsedTime + elapsed

    -- Bobbing motion
    local bobY = startY + math.sin(elapsedTime * floatSpeed) * floatAmplitude
    setProperty(objName .. '.y', bobY)

    -- Move horizontally
    local newX = getProperty(objName .. '.x') + moveSpeed * elapsed
    setProperty(objName .. '.x', newX)

    -- Reset only when the object is fully offscreen right
    if newX > screenW then
        if newX - startX > screenW + objWidth then
            setProperty(objName .. '.x', startX)
            elapsedTime = 0
        end
    end
end