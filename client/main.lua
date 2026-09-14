local PlayerData = {}
local onDuty = false
local cuffed = false
local escorted = false
local escorter = nil

local function notify(message)
    ESX.ShowNotification(message)
end

local function isPolice()
    return PlayerData.job and PlayerData.job.name == Config.JobName
end

local function closestPlayer(maxDistance)
    local player, distance = ESX.Game.GetClosestPlayer()
    if player == -1 or distance > (maxDistance or Config.InteractionDistance) then
        return nil
    end
    return GetPlayerServerId(player)
end

local function canPoliceAction()
    if not isPolice() then notify('Du er ikke politibetjent.') return false end
    if Config.RequireDuty and not onDuty then notify('Du er ikke på tjeneste.') return false end
    return true
end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('zema_police:server:requestDuty')
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    if job.name ~= Config.JobName then onDuty = false end
end)

RegisterNetEvent('zema_police:client:setDuty', function(state, callsign)
    onDuty = state
    notify(state and ('Du er på tjeneste (' .. (callsign or Config.DefaultCallsign) .. ').') or 'Du er gået af tjeneste.')
end)

RegisterNetEvent('zema_police:client:setCuffed', function(state)
    cuffed = state
    local ped = PlayerPedId()
    SetEnableHandcuffs(ped, state)
    SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    if not state then ClearPedTasks(ped) end
end)

RegisterNetEvent('zema_police:client:setEscort', function(state, officer)
    escorted = state
    escorter = officer
    if not state then DetachEntity(PlayerPedId(), true, false) end
end)

RegisterNetEvent('zema_police:client:putInVehicle', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = ESX.Game.GetClosestVehicle(coords)
    if vehicle ~= 0 and #(coords - GetEntityCoords(vehicle)) <= 5.0 then
        for seat = GetVehicleMaxNumberOfPassengers(vehicle) - 1, 0, -1 do
            if IsVehicleSeatFree(vehicle, seat) then TaskWarpPedIntoVehicle(ped, vehicle, seat) return end
        end
    end
end)

RegisterNetEvent('zema_police:client:removeFromVehicle', function()
    local ped = PlayerPedId()
    if IsPedSittingInAnyVehicle(ped) then TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16) end
end)

CreateThread(function()
    while true do
        local wait = 1000
        if cuffed then
            wait = 0
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
        end
        if escorted and escorter then
            wait = 0
            local player = GetPlayerFromServerId(escorter)
            if player ~= -1 then
                local officerPed = GetPlayerPed(player)
                if not IsEntityAttachedToEntity(PlayerPedId(), officerPed) then
                    AttachEntityToEntity(PlayerPedId(), officerPed, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                end
            end
        end
        Wait(wait)
    end
end)

RegisterCommand(Config.Commands.duty, function()
    if isPolice() then TriggerServerEvent('zema_police:server:toggleDuty') end
end)

RegisterCommand(Config.Commands.cuff, function()
    if not canPoliceAction() then return end
    local target = closestPlayer()
    if target then TriggerServerEvent('zema_police:server:toggleCuff', target) else notify('Ingen person tæt på.') end
end)

RegisterCommand(Config.Commands.escort, function()
    if not canPoliceAction() then return end
    local target = closestPlayer()
    if target then TriggerServerEvent('zema_police:server:toggleEscort', target) else notify('Ingen person tæt på.') end
end)

RegisterCommand(Config.Commands.vehicle, function()
    if not canPoliceAction() then return end
    local target = closestPlayer()
    if target then TriggerServerEvent('zema_police:server:putInVehicle', target) end
end)

RegisterCommand(Config.Commands.removeVehicle, function()
    if not canPoliceAction() then return end
    local target = closestPlayer(5.0)
    if target then TriggerServerEvent('zema_police:server:removeFromVehicle', target) end
end)

CreateThread(function()
    while not ESX.PlayerLoaded do Wait(250) end
    PlayerData = ESX.GetPlayerData()
    TriggerServerEvent('zema_police:server:requestDuty')
end)
