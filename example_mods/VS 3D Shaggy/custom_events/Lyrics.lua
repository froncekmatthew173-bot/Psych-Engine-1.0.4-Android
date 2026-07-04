function onEvent(name, value1, value2)
    local var string = (value1)
    local var color = (value2)
    if name == "Lyrics" then

        makeLuaText('captions', 'Lyrics go here', 1000, 150, 550)
        setTextString('captions',  '' .. string)
        setTextFont('captions', 'vcr.ttf')
        setTextColor('captions', color)
        setTextSize('captions', 30);
        setTextFont('captions','lyrics.otf')
        addLuaText('captions')
	setObjectCamera('captions', 'other');
        setTextAlignment('captions', 'center')
        --removeLuaText('captions', true)
        if value2 == 'pshaggy' then
        setTextColor('captions', '33724A')
    end
    if value2 == 'rshaggy' then
        setTextColor('captions', 'FF0000')
    end
         if value2 == 'gshaggy' then
        setTextColor('captions', 'FFFFFF')
        end
    end
end