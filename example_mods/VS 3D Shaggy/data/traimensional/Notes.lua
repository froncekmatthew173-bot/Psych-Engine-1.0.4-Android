local threeDCharacters = {
    ['shaggy'] = true,
    ['shaggy-3d'] = true,
    ['shaggy-god'] = true,
    ['bf'] = true,
    ['bf2'] = true,
    ['eevee'] = true
}

local dad3D = false
local bf3D = false

local lastDad = ''
local lastBF = ''

local function is3DCharacter(char)
    return threeDCharacters[string.lower(char or '')] == true
end

local function updateStrums()
    local total = getProperty('strumLineNotes.length')
    local split = math.floor(total / 2)

    for i = 0, total - 1 do
        local isOpponent = i < split
        local texture

        if isOpponent then
            texture = dad3D and '3d' or ''
        else
            texture = bf3D and '3d2' or ''
            setPropertyFromGroup('strumLineNotes', i, 'antialiasing', true)
        end

        local currentTexture = getPropertyFromGroup('strumLineNotes', i, 'texture')

        if currentTexture ~= texture then
            setPropertyFromGroup('strumLineNotes', i, 'texture', texture)
        end
    end
end

local function updateUnspawnNotes()
    for i = 0, getProperty('unspawnNotes.length') - 1 do
        local mustPress = getPropertyFromGroup('unspawnNotes', i, 'mustPress')

        if mustPress then
            setPropertyFromGroup(
                'unspawnNotes',
                i,
                'texture',
                bf3D and '3d2' or ''
            )
            setPropertyFromGroup('unspawnNotes', i, 'antialiasing', true)
        else
            setPropertyFromGroup(
                'unspawnNotes',
                i,
                'texture',
                dad3D and '3d' or ''
            )
        end
    end
end

local function updateStrumPositions()
    local total = getProperty('strumLineNotes.length')
    local split = math.floor(total / 2)

    local dadCenter = 412
    local bfCenter = 932

    for i = 0, total - 1 do
        local isOpponent = i < split

        if isOpponent then
            local sideIndex = i
            local x = dadCenter + ((sideIndex - (split - 1) / 2) * noteSpacing)

            setPropertyFromGroup('strumLineNotes', i, 'x', x)
        else
            local sideIndex = i - split
            local playerKeys = total - split

            local x = bfCenter + ((sideIndex - (playerKeys - 1) / 2) * noteSpacing)

            setPropertyFromGroup('strumLineNotes', i, 'x', x)
            setPropertyFromGroup('strumLineNotes', i, 'antialiasing', true)
        end
    end
end

local function refreshNotes()
    dad3D = is3DCharacter(getProperty('dad.curCharacter'))
    bf3D = is3DCharacter(getProperty('boyfriend.curCharacter'))

    updateStrums()
    updateUnspawnNotes()
    updateStrumPositions()
end

function onCreatePost()
    lastDad = getProperty('dad.curCharacter')
    lastBF = getProperty('boyfriend.curCharacter')
    refreshNotes()
end

function onUpdatePost()
    local dad = getProperty('dad.curCharacter')
    local bf = getProperty('boyfriend.curCharacter')

    if dad ~= lastDad or bf ~= lastBF then
        lastDad = dad
        lastBF = bf
        refreshNotes()
    end
end

function onEvent(name, v1, v2)
    if name == 'Set Key Count' then
        runTimer('refresh3DNotes', 0.05)
    end
end

function onTimerCompleted(tag)
    if tag == 'refresh3DNotes' then
        refreshNotes()
    end
end