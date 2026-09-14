local PlayerData, onDuty, cuffed, escorted, escorter = {}, false, false, false, nil

local function notify(message) ESX.ShowNotification(message) end
local function isPolice() return PlayerData.job and PlayerData.job.name == Config.JobName end
local function closestPlayer(maxDistance)
    local player, distance = ESX.Game.GetClosestPlayer()
    if player == -1 or distance > (maxDistance or Config.InteractionDistance) then return nil end
    return GetPlayerServerId(player)
end
local function canPoliceAction()
    if not isPolice() then notify('Du er ikke politibetjent.') return false end
    if Config.RequireDuty and not onDuty then notify('Du er ikke på tjeneste.') return false end
    return true
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer) PlayerData = xPlayer TriggerServerEvent('zema_police:server:requestDuty') end)
RegisterNetEvent('esx:setJob', function(job) PlayerData.job = job if job.name ~= Config.JobName then onDuty = false end end)
RegisterNetEvent('zema_police:client:notify', notify)
RegisterNetEvent('zema_police:client:setDuty', function(state, callsign) onDuty = state notify(state and ('Du er på tjeneste (' .. (callsign or Config.DefaultCallsign) .. ').') or 'Du er gået af tjeneste.') end)
RegisterNetEvent('zema_police:client:setCuffed', function(state)
    cuffed = state
    local ped = PlayerPedId()
    SetEnableHandcuffs(ped, state)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    if not state then ClearPedTasks(ped) end
end)
RegisterNetEvent('zema_police:client:setEscort', function(state, officer) escorted, escorter = state, officer if not state then DetachEntity(PlayerPedId(), true, false) end end)
RegisterNetEvent('zema_police:client:putInVehicle', function()
    local ped, coords = PlayerPedId(), GetEntityCoords(PlayerPedId())
    local vehicle = ESX.Game.GetClosestVehicle(coords)
    if vehicle ~= 0 and #(coords - GetEntityCoords(vehicle)) <= 5.0 then
        for seat = GetVehicleMaxNumberOfPassengers(vehicle) - 1, 0, -1 do if IsVehicleSeatFree(vehicle, seat) then TaskWarpPedIntoVehicle(ped, vehicle, seat) return end end
    end
end)
RegisterNetEvent('zema_police:client:removeFromVehicle', function() local ped = PlayerPedId() if IsPedSittingInAnyVehicle(ped) then TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16) end end)

CreateThread(function()
    while true do
        local wait = 1000
        if cuffed then
            wait = 0
            for _, control in ipairs({24,25,21,22,23,75}) do DisableControlAction(0, control, true) end
        end
        if escorted and escorter then
            wait = 0
            local player = GetPlayerFromServerId(escorter)
            if player ~= -1 then
                local officerPed = GetPlayerPed(player)
                if not IsEntityAttachedToEntity(PlayerPedId(), officerPed) then AttachEntityToEntity(PlayerPedId(), officerPed, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true) end
            end
        end
        Wait(wait)
    end
end)

RegisterCommand(Config.Commands.duty, function() if isPolice() then TriggerServerEvent('zema_police:server:toggleDuty') end end)
RegisterCommand(Config.Commands.cuff, function() if not canPoliceAction() then return end local t=closestPlayer() if t then TriggerServerEvent('zema_police:server:toggleCuff',t) else notify('Ingen person tæt på.') end end)
RegisterCommand(Config.Commands.escort, function() if not canPoliceAction() then return end local t=closestPlayer() if t then TriggerServerEvent('zema_police:server:toggleEscort',t) else notify('Ingen person tæt på.') end end)
RegisterCommand(Config.Commands.vehicle, function() if not canPoliceAction() then return end local t=closestPlayer() if t then TriggerServerEvent('zema_police:server:putInVehicle',t) end end)
RegisterCommand(Config.Commands.removeVehicle, function() if not canPoliceAction() then return end local t=closestPlayer(5.0) if t then TriggerServerEvent('zema_police:server:removeFromVehicle',t) end end)

RegisterCommand(Config.Commands.id, function()
    if not canPoliceAction() then return end
    local target = closestPlayer()
    if not target then return notify('Ingen person tæt på.') end
    ESX.TriggerServerCallback('zema_police:getIdentity', function(data)
        if not data then return notify('Kunne ikke hente identitet.') end
        notify(('Navn: %s~n~Job: %s~n~ID: %s'):format(data.name, data.job, data.identifier))
    end, target)
end)

RegisterCommand(Config.Commands.search, function()
    if not canPoliceAction() then return end
    local target = closestPlayer()
    if not target then return notify('Ingen person tæt på.') end
    ESX.TriggerServerCallback('zema_police:getInventory', function(items)
        if not items then return notify('Kunne ikke visitere personen.') end
        local found = {}
        for _, item in pairs(items) do
            local count = item.count or item.amount or 0
            if count > 0 then found[#found+1] = ('%sx %s'):format(count, item.label or item.name or 'Ukendt') end
        end
        notify(#found > 0 and ('Fundet:~n~' .. table.concat(found, ', ')) or 'Ingen genstande fundet.')
    end, target)
end)

RegisterCommand(Config.Commands.fine, function(_, args)
    if not canPoliceAction() then return end
    local target = closestPlayer()
    local amount = tonumber(args[1])
    local reason = table.concat(args, ' ', 2)
    if not target then return notify('Ingen person tæt på.') end
    if not amount or amount < 1 or reason == '' then return notify('Brug: /fine [beløb] [årsag]') end
    TriggerServerEvent('zema_police:server:issueFine', target, amount, reason)
end)

RegisterCommand(Config.Commands.plate, function(_, args)
    if not canPoliceAction() then return end
    local plate = table.concat(args, ' ')
    if plate == '' then
        local vehicle = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
        if vehicle ~= 0 then plate = GetVehicleNumberPlateText(vehicle) end
    end
    if plate == '' then return notify('Ingen nummerplade angivet eller køretøj fundet.') end
    ESX.TriggerServerCallback('zema_police:getVehicleByPlate', function(data)
        if not data then return notify('Opslag mislykkedes.') end
        if not data.registered then return notify(('Nummerplade %s er ikke registreret.'):format(data.plate)) end
        local flag = (#data.flags > 0) and ('~n~MARKERING: ' .. (data.flags[1].reason or data.flags[1].flag)) or ''
        notify(('Plade: %s~n~Ejer: %s%s'):format(data.plate, data.owner or 'Ukendt', flag))
    end, plate)
end)

CreateThread(function() while not ESX.PlayerLoaded do Wait(250) end PlayerData = ESX.GetPlayerData() TriggerServerEvent('zema_police:server:requestDuty') end)
