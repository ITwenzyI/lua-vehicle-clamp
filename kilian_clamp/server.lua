-- Get the ESX shared object
ESX = exports["es_extended"]:getSharedObject()

-- Store clamped vehicles in memory
local clampedVehicles = {}

-- Ensure database table exists and load existing clamped plates on resource start
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS vehicle_clamps (
            plate VARCHAR(12) PRIMARY KEY,
            clamped BOOLEAN NOT NULL DEFAULT FALSE
        );
    ]], {}, function()
        MySQL.query('SELECT * FROM vehicle_clamps WHERE clamped = true', {}, function(results)
            for _, v in pairs(results) do
                clampedVehicles[string.upper(v.plate)] = true
            end
        end)
    end)
end)

-- Event to set or remove a clamp on a vehicle
RegisterNetEvent("clamp:setClamp")
AddEventHandler("clamp:setClamp", function(plate, state)
    local src = source
    plate = string.upper(plate)
    local xPlayer = ESX.GetPlayerFromId(src)
    local name = xPlayer.getName()

    MySQL.update('INSERT INTO vehicle_clamps (plate, clamped) VALUES (?, ?) ON DUPLICATE KEY UPDATE clamped = ?', {
        plate, state, state
    }, function()
        clampedVehicles[plate] = state or nil

        -- Notify all clients about the change
        TriggerClientEvent("clamp:updateClamp", -1, plate, state)

        -- Notify the triggering player
        TriggerClientEvent("notifications", src, "#4a90e2", "Clamp", state and "Clamp applied." or "Clamp removed.")

        -- Send to Discord log if configured
        sendToDiscordLog(plate, name, state)
    end)
end)

-- Callback to check if a vehicle is currently clamped
ESX.RegisterServerCallback("clamp:checkPlate", function(source, cb, plate)
    cb(clampedVehicles[string.upper(plate)] == true)
end)

-- Callback to get all clamped plates (e.g., for police menu)
ESX.RegisterServerCallback("clamp:getAllClampedPlates", function(source, cb)
    cb(clampedVehicles)
end)

-- Callback to check if the player has permission to use the clamp menu
ESX.RegisterServerCallback("clamp:canUseMenu", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.getJob()
    cb(Config.AllowedJobs[job.name] and job.grade >= (Config.RequiredRank[job.name] or 0))
end)

-- Discord logging function
function sendToDiscordLog(plate, name, state)
    if Config.Webhook == "" then return end

    local title = state and "✅ Clamp Applied" or "❌ Clamp Removed"
    local color = state and 3066993 or 15158332

    local message = {
        embeds = { {
            title = title,
            description = ("**Plate:** `%s`\n**By:** `%s`"):format(plate, name),
            color = color,
            footer = { text = "Clamp System • " .. os.date("%d.%m.%Y %H:%M:%S") }
        } }
    }

    PerformHttpRequest(Config.Webhook, function() end, "POST", json.encode(message), { ["Content-Type"] = "application/json" })
end
