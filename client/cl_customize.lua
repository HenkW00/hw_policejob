-- Customize ESX export?
ESX = exports["es_extended"]:getSharedObject()

--Customize notifications
RegisterNetEvent('hw_policejob:notify', function(title, desc, style)
    lib.notify({
        title = title,
        description = desc,
        duration = 3500,
        type = style
    })
end)

--Custom Car lock
addCarKeys = function(plate)
    exports.hw_policejob_carlock:GiveKeys(plate) -- Leave like this if using hw_policejob_carlock
end

--Send to jail
RegisterNetEvent('hw_policejob:sendToJail', function(target, time)
    TriggerServerEvent("HD_Jail:sendToJail", Id, Location, Time, Reason, MenuType)
    print('Jailing '..target..' for '..time..' minutes')
    if Config.Debug then
        print("^0[^1DEBUG^0] Player: ^3" .. target .. "^5 got jailed for: ^3" .. time .. "^5 minutes!^0")
    end
end)

--Impound Vehicle
impoundSuccessful = function(vehicle)
    if not DoesEntityExist(vehicle) then return end
    SetEntityAsMissionEntity(vehicle, false, false)
    DeleteEntity(vehicle)
    if not DoesEntityExist(vehicle) then
        TriggerEvent('hw_policejob:notify', Strings.success, Strings.car_impounded_desc, 'success')
    end
end

--Death check
deathCheck = function(serverId)
    local ped = GetPlayerPed(GetPlayerFromServerId(serverId))
    return IsPedFatallyInjured(ped)
	or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
	or IsEntityPlayingAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 3)
end

--Search player
searchPlayer = function(player)
    if Config.inventory == 'ox' then
        exports.ox_inventory:openNearbyInventory()
        if Config.Debug then
            print("^0[^1DEBUG^0] ^5Opened ^3OX ^5inventory! ")
        end
    elseif Config.inventory == 'qs' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", GetPlayerServerId(player))
        if Config.Debug then
            print("^0[^1DEBUG^0] ^5Opened ^3QS ^5inventory! ")
        end
    elseif Config.inventory == 'mf' then
        local serverId = GetPlayerServerId(player)
        ESX.TriggerServerCallback("esx:getOtherPlayerData",function(data) 
            if type(data) ~= "table" or not data.identifier then
                return
            end
            exports["mf-inventory"]:openOtherInventory(data.identifier)
        end, serverId)
        if Config.Debug then
            print("^0[^1DEBUG^0] ^5Opened ^3MF ^5inventory! ")
        end
    elseif Config.inventory == 'cheeza' then
        TriggerEvent("inventory:openPlayerInventory", GetPlayerServerId(player), true)
        if Config.Debug then
            print("^0[^1DEBUG^0] ^5Opened ^3CHEEZA ^5inventory! ")
        end
    elseif Config.inventory == 'custom' then
        -- INSERT CUSTOM SEARCH PLAYER FOR YOUR INVENTORY
    end
end

exports('searchPlayer', searchPlayer)

-- Customize target
AddEventHandler('hw_policejob:addTarget', function(d)
    if d.targetType == 'AddBoxZone' then
        exports.qtarget:AddBoxZone(d.identifier, d.coords, d.width, d.length, {
            name=d.identifier,
            heading=d.heading,
            debugPoly=false,
            minZ=d.minZ,
            maxZ=d.maxZ
        }, {
            options = d.options,
            job = d.job,
            distance = d.distance
        })
    elseif d.targetType == 'Player' then
        exports.qtarget:Player({
            options = d.options,
            distance = d.distance
        })
    elseif d.targetType == 'Vehicle' then
        exports.qtarget:Vehicle({
            options = d.options,
            distance = d.distance
        })
    end
end)

--Change clothes(Cloakroom)
AddEventHandler('hw_policejob:changeClothes', function(data) 
	ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
        if data == 'civ_wear' then
            if Config.skinScript == 'appearance' then
                    skin.sex = nil
                    exports['fivem-appearance']:setPlayerAppearance(skin)
            else
               TriggerEvent('skinchanger:loadClothes', skin)
            end
        elseif skin.sex == 0 then
			TriggerEvent('skinchanger:loadClothes', skin, data.male)
		elseif skin.sex == 1 then
			TriggerEvent('skinchanger:loadClothes', skin, data.female)
		end
    end)
end)

-- Billing event
AddEventHandler('hw_policejob:finePlayer', function()
    if not hasJob then return end
    local player, dist = ESX.Game.GetClosestPlayer()
    if player == -1 or dist > 3.5 then
        TriggerEvent('hw_policejob:notify', Strings.no_nearby, Strings.no_nearby_desc, 'error')
    else
        local jobLabel = lib.callback.await('hw_policejob:getJobLabel', 100, hasJob)
        local targetId = GetPlayerServerId(player)
        local input = lib.inputDialog('Bill Patient', {'Amount'})
        if not input then return end
        local amount = math.floor(tonumber(input[1]))
        if amount < 1 then
            TriggerEvent('hw_policejob:notify', Strings.invalid_entry, Strings.invalid_entry_desc, 'error')
        elseif Config.billingSystem == 'okok' then
            local data =  {
                target = targetId,
                invoice_value = amount,
                invoice_item = Strings.fines,
                society = 'society_'..hasJob,
                society_name = jobLabel,
                invoice_notes = ''
            }
            TriggerServerEvent('okokBilling:CreateInvoice', data)
        else
            TriggerServerEvent('esx_billing:sendBill', targetId, 'society_'..hasJob, jobLabel, amount)
        end
    end
end)

-- Job menu
openJobMenu = function()
    if not hasJob then return end
    local jobLabel = lib.callback.await('hw_policejob:getJobLabel', 100, hasJob)
    local Options = {}
    if Config.searchPlayers then
        Options[#Options + 1] = {
            title = Strings.search_player,
            description = Strings.search_player_desc,
            icon = 'magnifying-glass',
            arrow = false,
            event = 'hw_policejob:searchPlayer',
        }
    end
    Options[#Options + 1] = {
        title = Strings.check_id,
        description = Strings.check_id_desc,
        icon = 'id-card',
        arrow = true,
        event = 'hw_policejob:checkId',
    }
    if Config.customJail then
        Options[#Options + 1] = {
            title = Strings.jail_player,
            description = Strings.jail_player_desc,
            icon = 'lock',
            arrow = false,
            event = 'hw_policejob:jailPlayer',
        }
    end
    Options[#Options + 1] = {
        title = Strings.handcuff_player,
        description = Strings.handcuff_player_desc,
        icon = 'hands-bound',
        arrow = false,
        event = 'hw_policejob:handcuffPlayer',
    }
    Options[#Options + 1] = {
        title = Strings.escort_player,
        description = Strings.escort_player_desc,
        icon = 'hand-holding-hand',
        arrow = false,
        event = 'hw_policejob:escortPlayer',
    }
    Options[#Options + 1] = {
        title = Strings.put_in_vehicle,
        description = Strings.put_in_vehicle_desc,
        icon = 'arrow-right-to-bracket',
        arrow = false,
        event = 'hw_policejob:inVehiclePlayer',
    }
    Options[#Options + 1] = {
        title = Strings.take_out_vehicle,
        description = Strings.take_out_vehicle_desc,
        icon = 'arrow-right-from-bracket',
        arrow = false,
        event = 'hw_policejob:outVehiclePlayer',
    }
    Options[#Options + 1] = {
        title = Strings.vehicle_interactions,
        description = Strings.vehicle_interactions_desc,
        icon = 'car',
        arrow = true,
        event = 'hw_policejob:vehicleInteractions',
    }
    Options[#Options + 1] = {
        title = Strings.place_object,
        description = Strings.place_object_desc,
        icon = 'box',
        arrow = true,
        event = 'hw_policejob:placeObjects',
    }
    if Config.billingSystem then
        Options[#Options + 1] = {
            title = Strings.fines,
            description = Strings.fines_desc,
            icon = 'file-invoice',
            arrow = false,
            event = 'hw_policejob:finePlayer',
        }
    end
    lib.registerContext({
        id = 'pd_job_menu',
        title = jobLabel,
        options = Options
    })
    lib.showContext('pd_job_menu')
end