cuffedPlayers = {}

function SendToDiscord(name, message)
    local DiscordWebhook = Config.DiscordWebhook
    local embeds = {
        {
            ["title"] = name,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = 65280,
            ["footer"] = {
                ["text"] = os.date("HW Development - %Y-%m-%d | %H:%M:%S")  
            }
        }
    }
    PerformHttpRequest(DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "HW Logs", embeds = embeds}), { ['Content-Type'] = 'application/json' })
end

function DebugPrint(message)
    if Config.Debug then
        print("^0[^1DEBUG^0] " .. message)
    elseif Config.Log then
        SendToDiscord("Debug Log", message)
    end
end

CreateThread(function()
    while ESX == nil do Wait(1000) end
    for i=1, #Config.policeJobs do
        TriggerEvent('esx_society:registerSociety', Config.policeJobs[i], Config.policeJobs[i], 'society_'..Config.policeJobs[i], 'society_'..Config.policeJobs[i], 'society_'..Config.policeJobs[i], {type = 'public'})
        DebugPrint('^5Society registered for job^0: ^3' .. Config.policeJobs[i])
        SendToDiscord('Society Registration', 'Society registered for job: ' .. Config.policeJobs[i])
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    if cuffedPlayers[playerId] then
        cuffedPlayers[playerId] = nil
    end
    DebugPrint('Player dropped and uncuffed: ' .. playerId)
    SendToDiscord('Player Dropped', 'Player dropped and uncuffed: ' .. playerId)
end)

TriggerEvent('esx_society:registerSociety', 'police', 'police', 'society_police', 'society_police', 'society_police', {type = 'public'})

RegisterServerEvent('hw_policejob:attemptTackle')
AddEventHandler('hw_policejob:attemptTackle', function(targetId)
    TriggerClientEvent('hw_policejob:tackled', targetId, source)
    TriggerClientEvent('hw_policejob:tackle', source)
    DebugPrint('^5Succesfully cuffed player: ^2' .. targetId)
    SendToDiscord('Player handcuffed', 'Player: ' .. source .. ' handcuffed player: ' .. targetId)
end)

RegisterServerEvent('hw_policejob:escortPlayer')
AddEventHandler('hw_policejob:escortPlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasJob
    for i=1, #Config.policeJobs do
        if xPlayer.job.name == Config.policeJobs[i] then
            hasJob = xPlayer.job.name
            break
        end
    end
    if hasJob then
        TriggerClientEvent('hw_policejob:setEscort', source, targetId)
        TriggerClientEvent('hw_policejob:escortedPlayer', targetId, source)
        DebugPrint('^5Player: ^3' .. source .. '^5 escorted player: ^2' .. targetId)
        SendToDiscord('Player Escort', 'Player: ' .. source .. ' got escorted: ' .. targetId)
    end
end)

RegisterServerEvent('hw_policejob:inVehiclePlayer')
AddEventHandler('hw_policejob:inVehiclePlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasJob
    for i=1, #Config.policeJobs do
        if xPlayer.job.name == Config.policeJobs[i] then
            hasJob = xPlayer.job.name
            break
        end
    end
    if hasJob then
        TriggerClientEvent('hw_policejob:stopEscorting', source)
        TriggerClientEvent('hw_policejob:putInVehicle', targetId)
        DebugPrint('^5Player: ^3' .. source .. '^5 has put following player in a vehicle: ^2' .. targetId)
        SendToDiscord('Player Put in Vehicle', 'Player: ' .. source .. ' has put following player in a vehicle: ' .. targetId)
    end
end)

RegisterServerEvent('hw_policejob:outVehiclePlayer')
AddEventHandler('hw_policejob:outVehiclePlayer', function(targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasJob
    for i=1, #Config.policeJobs do
        if xPlayer.job.name == Config.policeJobs[i] then
            hasJob = xPlayer.job.name
            break
        end
    end
    if hasJob then
        TriggerClientEvent('hw_policejob:takeFromVehicle', targetId)
        DebugPrint('^5The following player got taken out of vehicle: ^3' .. targetId)
        SendToDiscord('Player Removed From Vehicle', 'The following player got taken out of vehicle: ' .. targetId)
    end
end)

RegisterServerEvent('hw_policejob:setCuff')
AddEventHandler('hw_policejob:setCuff', function(isCuffed)
    cuffedPlayers[source] = isCuffed
end)

RegisterServerEvent('hw_policejob:handcuffPlayer')
AddEventHandler('hw_policejob:handcuffPlayer', function(target)
    local xPlayer = ESX.GetPlayerFromId(source)
    local hasJob
    for i=1, #Config.policeJobs do
        if xPlayer.job.name == Config.policeJobs[i] then
            hasJob = xPlayer.job.name
            break
        end
    end
    if hasJob then
        if cuffedPlayers[target] then
            TriggerClientEvent('hw_policejob:uncuffAnim', source, target)
            Wait(4000)
            TriggerClientEvent('hw_policejob:uncuff', target)
            DebugPrint('^5Uncuffed the following player: ^3' .. target)
            SendToDiscord('Police Arrest', '^5Uncuffed the following player: ^3' .. target)
        else
            TriggerClientEvent('hw_policejob:arrested', target, source)
            TriggerClientEvent('hw_policejob:arrest', source)
            DebugPrint('^5Handcuffed the following player: ^3' .. target)
            SendToDiscord('Police Arrest', '^5Handcuffed the following player: ^3' .. target)
        end
    end
end)

getPoliceOnline = function()
    local players = ESX.GetPlayers()
    local count = 0
    for i = 1, #players do
        local xPlayer = ESX.GetPlayerFromId(players[i])
        for i=1, #Config.policeJobs do
            if xPlayer.job.name == Config.policeJobs[i] then
                count = count + 1
            end
        end
    end
    return count
end

exports('getPoliceOnline', getPoliceOnline)

lib.callback.register('hw_policejob:getJobLabel', function(source, job)
    if ESX.Jobs?[job]?.label then
        return ESX.Jobs[job].label
    else
        return Strings.police -- If for some reason ESX.Jobs is malfunctioning(Must love ESX...)
    end
end)

lib.callback.register('hw_policejob:isCuffed', function(source, target)
    if cuffedPlayers[target] then
        return true
    else
        return false
    end
end)

lib.callback.register('hw_policejob:getVehicleOwner', function(source, plate)
    local owner
    MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            local identifier = result[1].owner
            MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
                ['@identifier'] = identifier
            }, function(result2)
                if result2[1] then
                    owner = result2[1].firstname..' '..result2[1].lastname
                else
                    owner = false
                end
            end)
        else
            owner = false
        end
    end)
    while owner == nil do
        Wait()
    end
    return owner
end)

lib.callback.register('hw_policejob:canPurchase', function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    local itemData
    if data.grade > #Config.Locations[data.id].armoury.weapons then
        itemData = Config.Locations[data.id].armoury.weapons[#Config.Locations[data.id].armoury.weapons][data.itemId]
        DebugPrint('^5Player: ^3' .. source .. '^5 attempted to purchase an item beyond their grade level.')
        SendToDiscord('Armory Shop', 'Player: ' .. source .. ' attempted to purchase ' .. data.itemId .. ' beyond their grade level.')
    elseif not Config.Locations[data.id].armoury.weapons[data.grade] then
        print('[hw_policejob] : Armory not set up properly for job grade: '..data.grade)
        DebugPrint('^5Armory ^1not ^5set up properly for job grade: ^3'..data.grade)
        SendToDiscord('Armory Shop', 'Armory not set up properly for job grade: '..data.grade)
    else
        itemData = Config.Locations[data.id].armoury.weapons[data.grade][data.itemId]
    end

    if not itemData or not itemData.price then
        if not Config.weaponsAsItems then
            if data.itemId:sub(0, 7) == 'WEAPON_' then
                xPlayer.addWeapon(data.itemId, 200)
            else
                xPlayer.addInventoryItem(data.itemId, data.quantity)
            end
        else
            xPlayer.addInventoryItem(data.itemId, data.quantity)
        end
        DebugPrint('^5Player: ^3' .. source .. '^5 received item ^3' .. data.itemId .. '^5 for ^2free ^5or as part of their job.')
        SendToDiscord('Armory Shop', 'Player: ' .. source .. ' received ' .. data.itemId .. ' for free or as part of their job.')
        return true
    else
        local xBank = xPlayer.getAccount('bank').money
        if xBank < itemData.price then
            DebugPrint('^5Player: ^3' .. source .. '^5 attempted to purchase ^3' .. data.itemId .. '^5 without sufficient funds.')
            SendToDiscord('Armory Shop', 'Player: ' .. source .. ' attempted to purchase ' .. data.itemId .. ' without sufficient funds.')
            return false
        else
            xPlayer.removeAccountMoney('bank', itemData.price)
            if not Config.weaponsAsItems then
                if data.itemId:sub(0, 7) == 'WEAPON_' then
                    xPlayer.addWeapon(data.itemId, 200)
                else
                    xPlayer.addInventoryItem(data.itemId, data.quantity)
                end
            else
                xPlayer.addInventoryItem(data.itemId, data.quantity)
            end
            DebugPrint('^5Player: ^3' .. source .. '^5 successfully purchased ^3' .. data.itemId .. '^5 for ^3$' .. itemData.price)
            SendToDiscord('Armory Shop', 'Player: ' .. source .. ' successfully purchased ' .. data.itemId .. ' for $' .. itemData.price)
            return true
        end
    end
end)
