local UTILS = lib.load('modules.utils')
local lastCam

local SetFollowPedCamViewMode = SetFollowPedCamViewMode
local GetFollowPedCamViewMode = GetFollowPedCamViewMode

-- util functions for getting/setting player's last cam
local lastCamUtils = {}

-- Get player's last camera
function lastCamUtils.getLastCam()
    return lastCam
end

-- Set player's last camera
function lastCamUtils.setLastCam(cam)
    local fullReset = (cam == 'reset')
    local playerCam = UTILS.getPlayerCam()
    if playerCam == lastCam and not fullReset then return end

    local setCam = fullReset and nil or ((not cache.vehicle) and GetFollowPedCamViewMode() or UTILS.getCamByVehicleType())
    lastCam = setCam

    return setCam
end

-- Reset player's camera
function lastCamUtils.resetPlayerCam(fullReset)
    if not lastCam then return end

    if cache.vehicle then
        UTILS.setCamByVehicleType(lastCam)
    else
        SetFollowPedCamViewMode(lastCam)
    end

    local playerCam = UTILS.getPlayerCam()
    while playerCam ~= lastCam do
        Wait(1)
    end

    if fullReset then
        lastCamUtils.setLastCam('reset')
    end

    return lastCam
end

return lastCamUtils