function onUpdate()
	if tonumber(getTextFromFile('Shaggy/savefiles/frame.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/mouth.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/eye.txt', false)) == 1 or tonumber(getTextFromFile('Shaggy/savefiles/horn.txt', false)) == 1 then
		saveFile('Shaggy/weeks/zephyrus.json', [[
{
	"songs": [
		[
			"aaaaa",
			"zshaggy",
			[
				20,
				72,
				0
			]
		]
	],
	"hiddenUntilUnlocked": false,
	"hideFreeplay": true,
	"weekBackground": "",
	"difficulties": "canon",
	"weekCharacters": [
		"",
		"",
		""
	],
	"storyName": "	BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB",
	"weekName": "Custom Week",
	"freeplayColor": [
		146,
		113,
		253
	],
	"hideStoryMode": false,
	"weekBefore": "tutorial",
	"startUnlocked": true
}
		]], false)
		deleteFile('Shaggy/scripts/createZephy.lua', false)
	end
end