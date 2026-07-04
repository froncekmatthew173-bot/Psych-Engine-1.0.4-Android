function onUpdate(elapsed)
        if curBeat >= 1 then
	started = true
	songPos = getSongPosition()
	local currentBeat = (songPos/5000)*(curBpm/60)
	doTweenY('opponentmove', 'dad', 150 - 150*math.sin((currentBeat+12*12)*math.pi), 2)
        end
	health = getProperty('health')
end