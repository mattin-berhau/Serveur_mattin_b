local config = lib.require('config')
local UTILS = lib.require('modules.utils')
local LAST_CAM_UTILS = lib.require('modules.lastcam')

local SetFollowPedCamViewMode   = SetFollowPedCamViewMode
local IsControlJustReleased     = IsControlJustReleased
local IsControlJustPressed      = IsControlJustPressed
local DisableControlAction      = DisableControlAction

local function weaponLoop(weapon)
    Wait(500)
    local sleep = 1
    CreateThread(function()
        while cache.weapon do
            if not cache.vehicle then
                sleep = 1

                if IsControlJustPressed(0, 25) then
                    LAST_CAM_UTILS.setLastCam()
                elseif IsControlJustReleased(0, 25) then
                    LAST_CAM_UTILS.resetPlayerCam(false)
                end

                local isAiming = UTILS.isPlayerAiming()
                if isAiming then
                    if not cache.vehicle and FPPWeapon then
                        SetFollowPedCamViewMode(4)
                    end

                    DisableControlAction(0, 0, true)
                end
            else
                sleep = 1000 -- Allow the vehicle loop to control fpp until exiting the vehicle
            end

            Wait(sleep)
        end
    end)
end

lib.onCache('weapon', function(value)
    FPPWeapon, FPPVehicleWeapon = UTILS.isWeaponFPP(value)

    if not config.forceAimingFPP then return end
    if not FPPWeapon then return end

    if not cache.weapon and value then
        weaponLoop(value)
    else
        FPPWeapon, FPPVehicleWeapon = false, false
    end
end)