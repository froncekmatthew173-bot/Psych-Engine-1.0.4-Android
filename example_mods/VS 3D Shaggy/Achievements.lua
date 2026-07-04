--multiple achievements unlocked at the same time example


--{tag, name, description, hidden}		--this is for adding the achievements at the start
local achievements = {
	{'ash1', 'The rest is gonna hurt lmao', 'Beat Chapter 1 on Canon with no Misses', false}, 
	{'ash2', 'Goku Ripeoff', 'Beat Chapter 2 on Canon with no Misses', false}, 
	{'ash3', 'Missless God', 'Beat Chapter 3 on Canon with no Misses', false}, 
	{'ash4', 'Get a life', 'Beat Chapter 4 on Canon with no Misses', false}, 
	{'ash5', 'Shaggy = Mario confirmed', 'Beat Chapter 5 on Canon with no Misses', false}, 
	{'ash6', 'Feels like Hell', 'Beat Chapter 6 on Canon with no Misses', false}, 
	{'ash7', "Universe's Conqueror BFF ", 'Beat the secret song', false}
}

function onCreatePost()
	
	for i = 1, #achievements do

		if not (achievementExists(achievements[i][1])) then
			addAchievement(achievements[i][2], achievements[i][3], achievements[i][1], achievements[i][4])
		end
	
	end
	
end



function onEndSong()
	checkForAchievement({'ash1', 'sh2', 'sh3', 'sh4', 'sh5', 'sh6', 'sh7'})
end

function perfectCheck()
	if getPropertyFromClass('PlayState', 'isStoryMode') and getPropertyFromClass('PlayState', 'campaignMisses') <= 1000 and not botplay and difficultyName == "canon" then
		return true
	else
		return false
	end
end

--check unlock
function checkForAchievement(array)

	for i = 1, #array do
	
		local unlock = false
		
		
		---conditions for unlocking the achievement---
		
		--these two are always true (song start and song end)
		if array[i] == 'ash1' then
			if perfectCheck() and not achievementUnlocked('tag')) and week == "chapter1" then
				unlock = true
			end
		end
		
		if array[i] == 'sh2' then
			if perfectCheck() and not achievementUnlocked('tag')) then
				unlock = true
			end
		end
		
		if array[i] == 'sh3' then
			if perfectCheck() and not achievementUnlocked('tag')) then
				unlock = true
			end
		end
		
		if array[i] == 'sh4' then
			if perfectCheck() and not achievementUnlocked('tag')) then
				unlock = true
			end
			
		end

		if array[i] == 'sh5' then
			if perfectCheck() and not achievementUnlocked('tag')) then
				unlock = true
			end
			
		end

		if array[i] == 'sh6' then
			if perfectCheck() and not achievementUnlocked('tag')) then
				unlock = true
			end
			
		end
		

	
	
		--unlock achievement if conditions are met
		if unlock == true and not (achievementUnlocked(array[i])) then
			unlockAchievement(array[i])
			return Function_Stop
		end

	end

	return Function_Continue
	
end



---achievement functions---
function addAchievement(name, description, tag, hidden)
	addHaxeLibrary('Achievements')
	runHaxeCode([[
		Achievements.achievementsStuff[Achievements.achievementsStuff.length] = ["]]..name..[[", "]]..description..[[", "]]..tag..[[", ]]..tostring(hidden)..[[];
	]])
end

function unlockAchievement(tag, show)

	if show == nil then show = true end

	addHaxeLibrary('Achievements')
	addHaxeLibrary('AchievementObject')
	runHaxeCode([[
		//end song when achievement has completed
		function achievementEnd() {
			if (game.endingSong && !game.inCutscene) {
				game.endSong();
			}
		}
	
		if (]]..tostring(show)..[[) {
			var achievementObj = new AchievementObject("]]..tag..[[", game.camOther);
			achievementObj.onFinish = achievementEnd;
			game.add(achievementObj);
		}
		Achievements.unlockAchievement("]]..tag..[[");
	]])
	
end

function achievementExists(tag)

	addHaxeLibrary('Achievements')
	runHaxeCode([[
		var exists = false;
		
		for (achieve in Achievements.achievementsStuff) {
			if (achieve[2] == "]]..tag..[[") exists = true;
		}
		
		game.setOnLuas("tempVarForAchieve", exists)
	]])
	
	local a = _G["tempVarForAchieve"]
	_G["tempVarForAchieve"] = nil
	
	return a
	
end

function achievementUnlocked(tag)

	addHaxeLibrary('Achievements')
	runHaxeCode([[
		var unlocked = Achievements.isAchievementUnlocked("]]..tag..[[");
		game.setOnLuas("tempVarForAchieve2", unlocked)
	]])
	
	local a = _G["tempVarForAchieve2"]
	_G["tempVarForAchieve2"] = nil
	
	return a
	
end