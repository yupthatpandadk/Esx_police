local Duty = {}
local Cuffed = {}
local Escorted = {}

local function getPolice(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then return nil end
    return xPlayer
end

local function canAct(source)
    return getPolice(source) and (not Config.RequireDuty or Duty[source] == true)
end

local function validTarget(source, target)
    target = tonumber(target)
    if not target or target == source or not GetPlayerName(target) then return nil end
    local a, b = GetPlayerPed(source), GetPlayerPed(target)
    if a == 0 or b == 0 then return nil end
    local ac, bc = GetEntityCoords(a), GetEntityCoords(b)
    if #(ac - bc) > 6.0 then return nil end
    return target
end

RegisterNetEvent('zema_police:server:requestDuty', function()
    local src = source
    TriggerClientEvent('zema_police:client:setDuty', src, Duty[src] == true, Config.DefaultCallsign)
end)

RegisterNetEvent('zema_police:server:toggleDuty', function()
    local src = source
    if not getPolice(src) then return end
    Duty[src] = not Duty[src]
    TriggerClientEvent('zema_police:client:setDuty', src, Duty[src], Config.DefaultCallsign)
end)

RegisterNetEvent('zema_police:server:toggleCuff', function(target)
    local src = source
    if not canAct(src) then return end
    target = validTarget(src, target)
    if not target then return end
    Cuffed[target] = not Cuffed[target]
    TriggerClientEvent('zema_police:client:setCuffed', target, Cuffed[target])
end)

RegisterNetEvent('zema_police:server:toggleEscort', function(target)
    local src = source
    if not canAct(src) then return end
    target = validTarget(src, target)
    if not target or not Cuffed[target] then return end
    if Escorted[target] then
        Escorted[target] = nil
        TriggerClientEvent('zema_police:client:setEscort', target, false)
    else
        Escorted[target] = src
        TriggerClientEvent('zema_police:client:setEscort', target, true, src)
    end
end)

RegisterNetEvent('zema_police:server:putInVehicle', function(target)
    local src = source
    if not canAct(src) then return end
    target = validTarget(src, target)
    if target and Cuffed[target] then TriggerClientEvent('zema_police:client:putInVehicle', target) end
end)

RegisterNetEvent('zema_police:server:removeFromVehicle', function(target)
    local src = source
    if not canAct(src) then return end
    target = validTarget(src, target)
    if target then TriggerClientEvent('zema_police:client:removeFromVehicle', target) end
end)

AddEventHandler('playerDropped', function()
    local src = source
    Duty[src], Cuffed[src], Escorted[src] = nil, nil, nil
    for target, officer in pairs(Escorted) do
        if officer == src then
            Escorted[target] = nil
            TriggerClientEvent('zema_police:client:setEscort', target, false)
        end
    end
end)

exports('IsOfficerOnDuty', function(source)
    return Duty[tonumber(source)] == true
end)

exports('IsPlayerCuffed', function(source)
    return Cuffed[tonumber(source)] == true
end)
