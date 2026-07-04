function onEvent(name,v1,v2)
    if name == 'Camera Flash' then
        local color = detectColor(string.lower(v1))
        cameraFlash('game',color,v2,true)
    end
end
function detectColor(color)
    if color == 'white' then
        return 'FFFFFF'
    elseif color == 'black' then
        return '0'
    elseif color == 'red' then
        return 'FF0000'
    elseif color == 'green' then
        return '00FF00'
    elseif color == 'yellow' then
    end
    return color
end