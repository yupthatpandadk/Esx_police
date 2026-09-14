local Duty, Cuffed, Escorted = {}, {}, {}

local function getPolice(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then return nil end
    return xPlayer
end

local function canAct(src)
    return getPolice(src) and (not Config.RequireDuty or Duty[src] == true)
end

local function validTarget(src, target, maxDistance)
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return nil end
    local a, b = GetPlayerPed(src), GetPlayerPed(target)
    if a == 0 or b == 0 then return nil end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > (maxDistance or 6.0) then return nil end
    return target
end

local function fullName(xPlayer)
    if xPlayer.getName then return xPlayer.getName() end
    return GetPlayerName(xPlayer.source) or 'Ukendt'
end

RegisterNetEvent('zema_police:server:requestDuty', function()
    local src = source
    TriggerClientEvent('zema_police:client:setDuty', src, Duty[src] == true, Config.DefaultCallsign)
end)

RegisterNetEvent('zema_police:server:toggleDuty', function()
    local src = source
    local xPlayer = getPolice(src)
    if not xPlayer then return end
    Duty[src] = not Duty[src]
    if Duty[src] then
        MySQL.insert.await('INSERT INTO zema_police_officers (identifier, callsign, last_duty) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE last_duty = NOW()', { xPlayer.identifier, Config.DefaultCallsign })
    end
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

ESX.RegisterServerCallback('zema_police:getIdentity', function(src, cb, target)
    if not canAct(src) then return cb(nil) end
    target = validTarget(src, target)
    if not target then return cb(nil) end
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return cb(nil) end
    cb({ name = fullName(xTarget), identifier = xTarget.identifier, job = xTarget.job and xTarget.job.label or 'Ukendt' })
end)

ESX.RegisterServerCallback('zema_police:getInventory', function(src, cb, target)
    if not canAct(src) then return cb(nil) end
    target = validTarget(src, target)
    if not target then return cb(nil) end
    if GetResourceState('ox_inventory') == 'started' and Config.Inventory ~= 'esx' then
        local inventory = exports.ox_inventory:GetInventory(target, false)
        return cb(inventory and inventory.items or {})
    end
    local xTarget = ESX.GetPlayerFromId(target)
    cb(xTarget and xTarget.getInventory and xTarget.getInventory() or {})
end)

RegisterNetEvent('zema_police:server:issueFine', function(target, amount, reason)
    local src = source
    local officer = getPolice(src)
    if not officer or (Config.RequireDuty and not Duty[src]) then return end
    target = validTarget(src, target)
    amount = math.floor(tonumber(amount) or 0)
    reason = tostring(reason or 'Bøde')
    if not target or amount < 1 or amount > Config.MaxFine or #reason > 150 then return end
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return end
    local account = xTarget.getAccount('bank')
    if not account or account.money < amount then
        TriggerClientEvent('zema_police:client:notify', src, 'Borgeren har ikke nok på bankkontoen.')
        return
    end
    xTarget.removeAccountMoney('bank', amount, 'Police fine')
    MySQL.insert('INSERT INTO zema_police_reports (author_identifier, author_name, type, title, description) VALUES (?, ?, ?, ?, ?)', {
        officer.identifier, fullName(officer), 'fine', ('Bøde: %s kr.'):format(amount), ('%s | Modtager: %s (%s)'):format(reason, fullName(xTarget), xTarget.identifier)
    })
    TriggerClientEvent('zema_police:client:notify', src, ('Bøde udstedt: %s kr.'):format(amount))
    TriggerClientEvent('zema_police:client:notify', target, ('Du har modtaget en bøde på %s kr. - %s'):format(amount, reason))
end)

ESX.RegisterServerCallback('zema_police:getVehicleByPlate', function(src, cb, plate)
    if not canAct(src) then return cb(nil) end
    plate = tostring(plate or ''):upper():gsub('^%s*(.-)%s*$', '%1')
    if plate == '' or #plate > 16 then return cb(nil) end
    local row = MySQL.single.await('SELECT owner, plate, vehicle FROM owned_vehicles WHERE TRIM(UPPER(plate)) = ? LIMIT 1', { plate })
    local flags = MySQL.query.await('SELECT flag, reason, created_at FROM zema_police_vehicle_flags WHERE plate = ?', { plate }) or {}
    if not row then return cb({ plate = plate, registered = false, flags = flags }) end
    local owner = MySQL.single.await('SELECT firstname, lastname FROM users WHERE identifier = ? LIMIT 1', { row.owner })
    cb({ plate = plate, registered = true, owner = owner and ((owner.firstname or '') .. ' ' .. (owner.lastname or '')) or row.owner, ownerIdentifier = row.owner, flags = flags })
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

exports('IsOfficerOnDuty', function(src) return Duty[tonumber(src)] == true end)
exports('IsPlayerCuffed', function(src) return Cuffed[tonumber(src)] == true end)
