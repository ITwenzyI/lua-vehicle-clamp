ESX = exports["es_extended"]:getSharedObject()
local clampedPlates = {}
local clampModel = Config.ClampProp or "prop_cone_float_1"
local activeClamps = {}
local lastNotify = 0

-- Update clamp state from server
RegisterNetEvent("clamp:updateClamp")
AddEventHandler("clamp:updateClamp", function(plate, state)
    plate = string.upper(plate)
    clampedPlates[plate] = state
end)

-- Command to open the clamp menu
RegisterCommand("clamp", function()
    ESX.TriggerServerCallback("clamp:canUseMenu", function(allowed)
        if not allowed then
            TriggerEvent("notifications", "#ff0000", "Error", "You don't have permission.")
            return
        end
        openClampMenu()
    end)
end, false)

-- Menu to enter plate and choose clamp action
function openClampMenu()
    ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'plate_input', {
        title = 'Enter license plate'
    }, function(data, menu)
        if not data.value or data.value == "" then
            TriggerEvent("notifications", "#ff0000", "Error", "You must enter a license plate.")
            return
        end
        local plate = string.upper(data.value)
        ESX.TriggerServerCallback("clamp:checkPlate", function(clamped)
            menu.close()
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'clamp_action', {
                title = 'Clamp options for ' .. plate,
                align = 'top-left',
                elements = {
                    {label = clamped and '❌ Remove Clamp' or '✅ Apply Clamp', value = clamped and 'remove' or 'set'}
                }
            }, function(data2, menu2)
                TriggerServerEvent("clamp:setClamp", plate, data2.current.value == 'set')
                menu2.close()
            end, function(data2, menu2)
                menu2.close()
            end)
        end, plate)
    end, function(data, menu)
        menu.close()
    end)
end

-- Table to track which vehicles were blocked by this script
local blockedByClamp = {}

-- Main clamp enforcement logic (prevent driving if clamped)
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local plate = GetVehicleNumberPlateText(veh):gsub("^%s*(.-)%s*$", "%1")
            plate = string.upper(plate)
            if clampedPlates[plate] then
                SetVehicleEngineOn(veh, false, true, true)
                SetVehicleUndriveable(veh, true)
                FreezeEntityPosition(veh, true)

                -- Disable driving controls
                DisableControlAction(0, 71, true) -- W
                DisableControlAction(0, 72, true) -- S
                DisableControlAction(0, 63, true) -- A
                DisableControlAction(0, 64, true) -- D
                DisableControlAction(0, 21, true) -- SHIFT

                blockedByClamp[veh] = true

                if GetGameTimer() - lastNotify > 10000 then
                    TriggerEvent("notifications", "#ff0000", "Clamp", "This vehicle is clamped and cannot be driven.")
                    lastNotify = GetGameTimer()
                end
            else
                if blockedByClamp[veh] then
                    -- Only unfreeze if previously frozen by this script
                    SetVehicleEngineOn(veh, true, true, true)
                    SetVehicleUndriveable(veh, false)
                    FreezeEntityPosition(veh, false)
                    EnableControlAction(0, 71, true)
                    EnableControlAction(0, 72, true)
                    EnableControlAction(0, 63, true)
                    EnableControlAction(0, 64, true)
                    EnableControlAction(0, 21, true)

                    blockedByClamp[veh] = nil
                end
            end
        end
    end
end)

-- Prop (visual clamp) logic
CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            local plate = GetVehicleNumberPlateText(veh):gsub("^%s*(.-)%s*$", "%1")
            plate = string.upper(plate)

            if clampedPlates[plate] and not activeClamps[veh] then
                RequestModel(clampModel)
                while not HasModelLoaded(clampModel) do Wait(50) end

                local coords = GetOffsetFromEntityInWorldCoords(veh, 0.0, 2.5, 0.0)
                local obj = CreateObject(clampModel, coords.x, coords.y, coords.z, true, true, false)
                SetEntityCoords(obj, coords.x, coords.y, coords.z + 0.2)
                SetEntityHeading(obj, GetEntityHeading(veh))
                SetEntityAsMissionEntity(obj, true, true)
                activeClamps[veh] = obj
            elseif not clampedPlates[plate] and activeClamps[veh] then
                DeleteEntity(activeClamps[veh])
                activeClamps[veh] = nil
            end
        end
    end
end)

-- Sync clamp data when client (re)starts the resource
AddEventHandler("onClientResourceStart", function(res)
    if res == GetCurrentResourceName() then
        ESX.TriggerServerCallback("clamp:getAllClampedPlates", function(data)
            clampedPlates = data
        end)
    end
end)
