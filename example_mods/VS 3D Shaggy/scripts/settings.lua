function onCreatePost()
	fps = getPropertyFromClass('ClientPrefs', 'framerate')
	setPropertyFromClass('ClientPrefs', 'framerate', 60)
end

function onBeatHit()
	if dadName == 'shaggy' or dadName == 'rshaggy' or dadName == 'sans-shaggy' or dadName == 'FD-Shaggy' or dadName == 'FD-Shaggy-God' or dadName == 'super-shaggy' then
		if curBeat % 4 == 1 then
			triggerEvent('Alt Idle Animation', 'dad', '-alt')
		elseif curBeat % 4 == 3 then
			triggerEvent('Alt Idle Animation', 'dad', '')
		end
	end
end

function onCountdownTick(counter)
	if dadName == 'shaggy' or dadName == 'rshaggy' or dadName == 'sans-shaggy' or dadName == 'FD-Shaggy' then
		if counter == 1 then
			triggerEvent('Alt Idle Animation', 'dad', '-alt')
		end
		if counter == 3 then
			triggerEvent('Alt Idle Animation', 'dad', '')
		end
	end
end


function onDestroy()
	setPropertyFromClass('ClientPrefs', 'framerate', fps)
	return bugFix()
end

function bugFix()
	triggerEvent('Change Mania', 4, 4)
end