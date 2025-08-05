local Voice = exports['pma-voice']
local Config = require 'config'
local frequencyStep = 1
local thisUserIsUnableToReadDocumentation = false

local isOpened = false
local requestedFrequency = nil
local lastVolume = nil
local resourceName = GetCurrentResourceName()
local isTalkingOnRadio = false
local radioPropInRightHand = false
local radioPropInLeftHand = false

---@return number
local function getRadioVolume()
    local volume = Voice:getRadioVolume()
    return thisUserIsUnableToReadDocumentation and volume * 100 or volume
end


local function handleRadioProp()
    local anims = {
        hand = {
            dict = "ultra@walkie_talkie",
            name = "walkie_talkie"
        },
        text = {
            dict = "cellphone@",
            name = "cellphone_text_in"
        },
        textVehicle = {
            dict = "cellphone@in_car@ds",
            name = "cellphone_text_in"
        },
        shoulder = {
            dict = "random@arrests",
            name = "generic_radio_enter"
        }
    }
    local anim
    if isOpened then
        if isTalkingOnRadio then
            anim = anims.hand
        else
            if cache.vehicle then
                anim = anims.textVehicle
            else
                anim = anims.text
            end
        end
    else
        if isTalkingOnRadio then
            anim = anims.shoulder
        end
    end
    if not anim then
        for _, v in pairs(anims) do
            if IsEntityPlayingAnim(cache.ped, v.dict, v.name, 3) then
                StopAnimTask(cache.ped, v.dict, v.name, 5.0)
            end
        end
    else
        if not IsEntityPlayingAnim(cache.ped, anim.dict, anim.name, 3) then
            lib.requestAnimDict(anim.dict)
            TaskPlayAnim(cache.ped, anim.dict, anim.name, 5.0, 2.0, -1, 50, 2.0, false, false, false)
            RemoveAnimDict(anim.dict)
        end
    end

    if isOpened then
        if isTalkingOnRadio then
            if not radioPropInLeftHand then
                TriggerServerEvent("ceeb_globals:deleteProp", resourceName, "radio")
                TriggerServerEvent("ceeb_globals:createProp", resourceName, {
                    model = "prop_cs_hand_radio",
                    bone = 18905,
                    pos = vec3(0.140000, 0.030000, 0.030000),
                    rot = vec3(-105.877000, -10.943200, -33.721200),
                    rotOrder = 0,
                }, "radio")
                radioPropInLeftHand = true
                radioPropInRightHand = false
            end
        else
            if not radioPropInRightHand then
                TriggerServerEvent("ceeb_globals:deleteProp", resourceName, "radio")
                TriggerServerEvent("ceeb_globals:createProp", resourceName, {
                    model = "prop_cs_hand_radio",
                    bone = 28422,
                    pos = vec3(0.0, 0.0, 0.0),
                    rot = vec3(0.0, 0.0, 0.0),
                    rotOrder = 0,
                }, "radio")
                radioPropInRightHand = true
                radioPropInLeftHand = false
            end
        end
    else
        if radioPropInLeftHand or radioPropInRightHand then
            TriggerServerEvent("ceeb_globals:deleteProp", resourceName, "radio")
            radioPropInLeftHand = false
            radioPropInRightHand = false
        end
    end
end

CreateThread(function()
    local step = tostring(Config.frequencyStep)
    local pos = step:find('%.')
    frequencyStep = pos and #step:sub(pos + 1) or 0

    -- Check if server has correct version of pma-voice because certain users are special and can't read documentation.
    -- This is the only way because the is no version variable in pma-voice and the latest release is too outdated.
    local volume = Voice:getRadioVolume()
    if volume > 0 and volume < 1 then
        thisUserIsUnableToReadDocumentation = true
    end
end)

local function openRadio()
    if isOpened then return end
    isOpened = true

    TriggerEvent('ox_inventory:disarm', true)

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SetCursorLocation(0.917, 0.873)
    SendNUIMessage({ action = 'openUi' })

    while isOpened do
        DisableAllControlActions(0)
        EnableControlAction(0, 21, true)  -- INPUT_SPRINT
        EnableControlAction(0, 22, true)  -- INPUT_JUMP
        EnableControlAction(0, 30, true)  -- INPUT_MOVE_LR
        EnableControlAction(0, 31, true)  -- INPUT_MOVE_UD
        EnableControlAction(0, 59, true)  -- INPUT_VEH_MOVE_LR
        EnableControlAction(0, 71, true)  -- INPUT_VEH_ACCELERATE
        EnableControlAction(0, 72, true)  -- INPUT_VEH_BRAKE
        EnableControlAction(0, 249, true) -- INPUT_PUSH_TO_TALK
        handleRadioProp()
        Wait(0)
    end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    handleRadioProp()
end



---@param frequency number
---@return number
local function roundFrequency(frequency)
    local mult = 10 ^ frequencyStep
    return math.floor(frequency * mult + 0.5) / mult
end

---@param frequency number
---@return false | number
local function joinFrequency(frequency)
    frequency = roundFrequency(frequency)

    if frequency > 0 and frequency <= Config.maximumFrequencies then
        Voice:setVoiceProperty('radioEnabled', true)
        Voice:setRadioChannel(frequency)

        if not Config.restrictedChannels[frequency] then
            -- lib.notify({
            --     type = 'success',
            --     description = locale('channel_join', frequency),
            -- })
        end

        return frequency
    end

    lib.notify({
        type = 'error',
        description = locale('channel_unavailable'),
    })

    return false
end

local function leaveFrequency()
    Voice:removePlayerFromRadio()
    Voice:setVoiceProperty('radioEnabled', false)
end

local function closeUi()
    isOpened = false
    requestedFrequency = nil
end

RegisterNUICallback('ready', function(_, cb)
    cb(1)
    local volume = math.floor(getRadioVolume())
    SendNUIMessage({ action = volume == 0 and 'mute' or 'unmute' })
    SendNUIMessage({ action = 'volume', data = math.floor(getRadioVolume()) })
end)

RegisterNUICallback('closeUi', function(_, cb)
    cb(1)
    closeUi()
end)

---@param frequency number
---@param cb fun(frequency: false | number)
RegisterNUICallback('joinFrequency', function(frequency, cb)
    local result = joinFrequency(frequency)
    cb(result)
end)

RegisterNUICallback('leaveFrequency', function(_, cb)
    cb(1)

    leaveFrequency()

    -- lib.notify({
    --     type = 'success',
    --     description = locale('channel_disconnect'),
    -- })
end)

RegisterNUICallback('volumeUp', function(_, cb)
    cb(1)

    local currentVolume = lastVolume or getRadioVolume()

    if lastVolume then
        lastVolume = nil
        -- lib.notify({
        --     type = 'info',
        --     description = locale('volume_unmute'),
        --     duration = 1000,
        -- })
        SendNUIMessage({ action = 'unmute' })
    end

    if currentVolume >= 100 then
        return
        -- return lib.notify({
        --     type = 'error',
        --     description = locale('volume_max'),
        --     duration = 2500,
        -- })
    end

    local volume = math.clamp(currentVolume + Config.volumeStep, Config.volumeStep, 100)

    Voice:setRadioVolume(volume)
    SendNUIMessage({ action = 'volume', data = math.floor(volume) })
    -- lib.notify({
    --     type = 'info',
    --     description = locale('volume_up', math.floor(volume)),
    --     duration = 1500,
    --     icon = 'volume-high',
    -- })
end)

RegisterNUICallback('volumeDown', function(_, cb)
    cb(1)

    local currentVolume = lastVolume or getRadioVolume()

    if lastVolume then
        lastVolume = nil
        -- lib.notify({
        --     type = 'info',
        --     description = locale('volume_unmute'),
        --     duration = 1000,
        -- })
    end

    if currentVolume <= Config.volumeStep then
        return
        -- return lib.notify({
        --     type = 'error',
        --     description = locale('volume_min'),
        --     duration = 2500,
        -- })
    end

    local volume = math.clamp(currentVolume - Config.volumeStep, Config.volumeStep, 100)

    Voice:setRadioVolume(volume)
    SendNUIMessage({ action = 'volume', data = math.floor(volume) })
    -- lib.notify({
    --     type = 'info',
    --     description = locale('volume_down', math.floor(volume)),
    --     duration = 1500,
    --     icon = 'volume-low',
    -- })
end)

RegisterNUICallback('volumeMute', function(_, cb)
    cb(1)

    if lastVolume then
        Voice:setRadioVolume(lastVolume)
        lastVolume = nil
        SendNUIMessage({ action = 'unmute' })
        -- lib.notify({
        --     type = 'success',
        --     description = locale('volume_unmute'),
        --     icon = 'volume-high',
        -- })
    else
        lastVolume = getRadioVolume()
        Voice:setRadioVolume(0)
        SendNUIMessage({ action = 'mute' })
        -- lib.notify({
        --     type = 'error',
        --     description = locale('volume_mute'),
        --     icon = 'volume-xmark',
        -- })
    end
end)

---@param presetId number
---@param cb fun(frequency: false | number)
RegisterNUICallback('presetJoin', function(presetId, cb)
    local frequency = tonumber(GetResourceKvpString('ac_radio:preset_' .. presetId))

    if not frequency then
        cb(false)
        return lib.notify({
            type = 'error',
            description = locale('preset_not_found'),
        })
    end

    local result = joinFrequency(frequency)
    cb(result)
end)

---@param frequency? number
RegisterNUICallback('presetRequest', function(frequency, cb)
    cb(1)

    if frequency then
        requestedFrequency = roundFrequency(frequency)
        lib.notify({
            type = 'info',
            description = locale('preset_choose'),
            duration = 10000,
        })
    end
end)

---@param presetId number
RegisterNUICallback('presetSet', function(presetId, cb)
    cb(1)

    if not requestedFrequency then return end

    SetResourceKvp('ac_radio:preset_' .. presetId, tostring(requestedFrequency))

    lib.notify({
        type = 'success',
        description = locale('preset_set', requestedFrequency),
    })

    requestedFrequency = nil
end)



-- commands
if Config.useCommand then
    TriggerEvent('chat:addSuggestion', '/radio', locale('command_open'))
    RegisterCommand('radio', openRadio, false)

    if Config.commandKey then
        exports.TMA:RegisterKeyMapping('radio', locale('keymap_open'), 'keyboard', Config.commandKey)
    end
end

TriggerEvent('chat:addSuggestion', '/radio:clear', locale('command_clear'))
RegisterCommand('radio:clear', function()
    for i = 1, 2 do DeleteResourceKvp('ac_radio:preset_' .. i) end
    lib.notify({
        type = 'success',
        description = locale('preset_clear'),
    })
end, false)

-- events and exports
RegisterNetEvent('ac_radio:disableRadio', function()
    closeUi()
    SendNUIMessage({ action = 'closeUi' })
    Voice:setVoiceProperty('radioEnabled', false)
end)

RegisterNetEvent('ac_radio:openRadio', openRadio)
exports('openRadio', openRadio)
exports('leaveRadio', leaveFrequency)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        leaveFrequency()
        if isOpened then
            ClearPedTasksImmediately(cache.ped)
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
    end
end)

AddStateBagChangeHandler("radioActive", ("player:%s"):format(cache.serverId), function(bagName, key, value, _, replicated)
    isTalkingOnRadio = value
    if value then
        CreateThread(function()
            while isTalkingOnRadio do
                handleRadioProp()
                Wait(0)
            end
        end)
    else
        handleRadioProp()
    end
end)
