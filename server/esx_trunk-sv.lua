ESX = nil
local arrayWeight = Config.localWeight

TriggerEvent(
    "esx:getSharedObject",
    function(obj)
        ESX = obj
    end
)

MySQL.ready(
    function()
        MySQL.Async.execute("DELETE FROM `trunk_inventory` WHERE `owned` = 0", {})
    end
)

function getItemWeight(item)
    local weight = 0
    local itemWeight = 0
    if item ~= nil then
        itemWeight = Config.DefaultWeight
        if arrayWeight[item] ~= nil then
            itemWeight = arrayWeight[item]
        end
    end
    return itemWeight
end

function getInventoryWeight(inventory)
    local weight = 0
    local itemWeight = 0
    if inventory ~= nil then
        for i = 1, #inventory, 1 do
            if inventory[i] ~= nil then
                itemWeight = Config.DefaultWeight
                if arrayWeight[inventory[i].name] ~= nil then
                    itemWeight = arrayWeight[inventory[i].name]
                end
                weight = weight + (itemWeight * (inventory[i].count or 1))
            end
        end
    end
    return weight
end

function getTotalInventoryWeight(plate)
    local total
    TriggerEvent(
        "esx_inventoryhud_trunk:getSharedDataStore",
        plate,
        function(store)
            local W_weapons = getInventoryWeight(store.get("weapons") or {})
            local W_coffre = getInventoryWeight(store.get("coffre") or {})
            local W_blackMoney = 0
            local blackAccount = (store.get("black_money")) or 0
            if blackAccount ~= 0 then
                W_blackMoney = blackAccount[1].amount / 10
            end
            total = W_weapons + W_coffre + W_blackMoney
        end
    )
    return total
end

ESX.RegisterServerCallback(
    "esx_inventoryhud_trunk:getInventoryV",
    function(source, cb, plate)
        TriggerEvent(
            "esx_inventoryhud_trunk:getSharedDataStore",
            plate,
            function(store)
                local blackMoney = 0
                local items = {}
                local weapons = {}
                weapons = (store.get("weapons") or {})

                local blackAccount = (store.get("black_money")) or 0
                if blackAccount ~= 0 then
                    blackMoney = blackAccount[1].amount
                end

                local coffre = (store.get("coffre") or {})
                for i = 1, #coffre, 1 do
                    table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
                end

                local weight = getTotalInventoryWeight(plate)
                cb(
                    {
                        blackMoney = blackMoney,
                        items = items,
                        weapons = weapons,
                        weight = weight
                    }
                )
            end
        )
    end
)

RegisterServerEvent("esx_inventoryhud_trunk:getItem")
AddEventHandler(
    "esx_inventoryhud_trunk:getItem",
    function(plate, type, item, count, max, owned)
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(_source)

        if type == "item_standard" then
            local targetItem = xPlayer.getInventoryItem(item)
            if targetItem.limit == -1 or ((targetItem.count + count) <= targetItem.limit) then
                TriggerEvent(
                    "esx_inventoryhud_trunk:getSharedDataStore",
                    plate,
                    function(store)
                        local coffre = (store.get("coffre") or {})
                        for i = 1, #coffre, 1 do
                            if coffre[i].name == item then
                                if (coffre[i].count >= count and count > 0) then
                                    if coffre[i].canMove == nil or coffre[i].canMove then
                                        xPlayer.addInventoryItem(item, count)
                                        if (coffre[i].count - count) == 0 then
                                            table.remove(coffre, i)
                                        else
                                            coffre[i].count = coffre[i].count - count
                                        end
                                    end
                                    break
                                else
                                    TriggerClientEvent(
                                        "pNotify:SendNotification",
                                        _source,
                                        {
                                            text = _U("invalid_quantity"),
                                            type = "error",
                                            queue = "trunk",
                                            timeout = 3000,
                                            layout = "bottomCenter"
                                        }
                                    )
                                end
                            end
                        end

                        store.set("coffre", coffre)

                        local blackMoney = 0
                        local items = {}
                        local weapons = {}
                        weapons = (store.get("weapons") or {})

                        local blackAccount = (store.get("black_money")) or 0
                        if blackAccount ~= 0 then
                            blackMoney = blackAccount[1].amount
                        end

                        local coffre = (store.get("coffre") or {})
                        for i = 1, #coffre, 1 do
                            table.insert(
                                items,
                                {
                                    name = coffre[i].name,
                                    count = coffre[i].count,
                                    label = ESX.GetItemLabel(coffre[i].name)
                                }
                            )
                        end

                        local weight = getTotalInventoryWeight(plate)

                        text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
                        data = {plate = plate, max = max, myVeh = owned, text = text}
                        TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
                    end
                )
            else
                TriggerClientEvent(
                    "pNotify:SendNotification",
                    _source,
                    {
                        text = _U("player_inv_no_space"),
                        type = "error",
                        queue = "trunk",
                        timeout = 3000,
                        layout = "bottomCenter"
                    }
                )
            end
        elseif type == "item_account" then
            TriggerEvent(
                "esx_inventoryhud_trunk:getSharedDataStore",
                plate,
                function(store)
                    local blackMoney = store.get("black_money")
                    if (blackMoney[1].amount >= count and count > 0) then
                        blackMoney[1].amount = blackMoney[1].amount - count
                        store.set("black_money", blackMoney)
                        xPlayer.addAccountMoney(item, count)

                        local blackMoney = 0
                        local items = {}
                        local weapons = {}
                        weapons = (store.get("weapons") or {})

                        local blackAccount = (store.get("black_money")) or 0
                        if blackAccount ~= 0 then
                            blackMoney = blackAccount[1].amount
                        end

                        local coffre = (store.get("coffre") or {})
                        for i = 1, #coffre, 1 do
                            table.insert(
                                items,
                                {
                                    name = coffre[i].name,
                                    count = coffre[i].count,
                                    label = ESX.GetItemLabel(coffre[i].name)
                                }
                            )
                        end

                        local weight = getTotalInventoryWeight(plate)

                        text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
                        data = {plate = plate, max = max, myVeh = owned, text = text}
                        TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
                    else
                        TriggerClientEvent(
                            "pNotify:SendNotification",
                            _source,
                            {
                                text = _U("invalid_amount"),
                                type = "error",
                                queue = "trunk",
                                timeout = 3000,
                                layout = "bottomCenter"
                            }
                        )
                    end
                end
            )
        elseif type == "item_weapon" then
            if xPlayer.hasWeapon(item) then
                TriggerClientEvent(
                    "pNotify:SendNotification",
                    _source,
                    {
                        text = "Tuto zbraň u sebe už máš",
                        type = "error",
                        timeout = 3000
                    }
                )
            else
                TriggerEvent(
                    "esx_inventoryhud_trunk:getSharedDataStore",
                    plate,
                    function(store)
                        local storeWeapons = store.get("weapons")

                        if storeWeapons == nil then
                            storeWeapons = {}
                        end

                        local weaponName = nil
                        local ammo = nil
                        local components = {}

                        for i = 1, #storeWeapons, 1 do
                            if storeWeapons[i].name == item then
                                weaponName = storeWeapons[i].name
                                ammo = storeWeapons[i].ammo

                                if storeWeapons[i].components ~= nil then
                                    components = storeWeapons[i].components
                                end

                                table.remove(storeWeapons, i)

                                break
                            end
                        end

                        store.set("weapons", storeWeapons)

                        xPlayer.addWeapon(weaponName, ammo)

                        for i = 1, #components do
                            xPlayer.addWeaponComponent(weaponName, components[i])
                        end

                        local blackMoney = 0
                        local items = {}
                        local weapons = {}
                        weapons = (store.get("weapons") or {})

                        local blackAccount = (store.get("black_money")) or 0
                        if blackAccount ~= 0 then
                            blackMoney = blackAccount[1].amount
                        end

                        local coffre = (store.get("coffre") or {})
                        for i = 1, #coffre, 1 do
                            table.insert(
                                items,
                                {
                                    name = coffre[i].name,
                                    count = coffre[i].count,
                                    label = ESX.GetItemLabel(coffre[i].name)
                                }
                            )
                        end

                        local weight = getTotalInventoryWeight(plate)

                        text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
                        data = {plate = plate, max = max, myVeh = owned, text = text}
                        TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
                    end
                )
            end
        end
    end
)

RegisterServerEvent("esx_inventoryhud_trunk:putItem")
AddEventHandler(
    "esx_inventoryhud_trunk:putItem",
    function(plate, type, item, count, max, owned, label)
        local _source = source
        local xPlayer = ESX.GetPlayerFromId(_source)

        if type == "item_standard" then
            local playerItemCount = xPlayer.getInventoryItem(item).count

            if (playerItemCount >= count and count > 0) then
                TriggerEvent(
                    "esx_inventoryhud_trunk:getSharedDataStore",
                    plate,
                    function(store)
                        local found = false
                        local coffre = (store.get("coffre") or {})

                        for i = 1, #coffre, 1 do
                            if coffre[i].name == item then
                                coffre[i].count = coffre[i].count + count
                                found = true
                            end
                        end
                        if not found then
                            table.insert(
                                coffre,
                                {
                                    name = item,
                                    count = count
                                }
                            )
                        end
                        if (getTotalInventoryWeight(plate) + (getItemWeight(item) * count)) > max then
                            TriggerClientEvent(
                                "pNotify:SendNotification",
                                _source,
                                {
                                    text = _U("insufficient_space"),
                                    type = "error",
                                    queue = "trunk",
                                    timeout = 3000,
                                    layout = "bottomCenter"
                                }
                            )
                        else
                            -- Checks passed, storing the item.
                            store.set("coffre", coffre)
                            xPlayer.removeInventoryItem(item, count)

                            MySQL.Async.execute(
                                "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
                                {
                                    ["@plate"] = plate,
                                    ["@owned"] = owned
                                }
                            )
                        end
                    end
                )
            else
                TriggerClientEvent(
                    "pNotify:SendNotification",
                    _source,
                    {
                        text = _U("invalid_quantity"),
                        type = "error",
                        queue = "trunk",
                        timeout = 3000,
                        layout = "bottomCenter"
                    }
                )
            end
        end

        if type == "item_account" then
            local playerAccountMoney = xPlayer.getAccount(item).money

            if (playerAccountMoney >= count and count > 0) then
                TriggerEvent(
                    "esx_inventoryhud_trunk:getSharedDataStore",
                    plate,
                    function(store)
                        local blackMoney = (store.get("black_money") or nil)
                        if blackMoney ~= nil then
                            blackMoney[1].amount = blackMoney[1].amount + count
                        else
                            blackMoney = {}
                            table.insert(blackMoney, {amount = count})
                        end

                        if (getTotalInventoryWeight(plate) + blackMoney[1].amount / 10) > max then
                            TriggerClientEvent(
                                "pNotify:SendNotification",
                                _source,
                                {
                                    text = _U("insufficient_space"),
                                    type = "error",
                                    queue = "trunk",
                                    timeout = 3000,
                                    layout = "bottomCenter"
                                }
                            )
                        else
                            -- Checks passed. Storing the item.
                            xPlayer.removeAccountMoney(item, count)
                            store.set("black_money", blackMoney)

                            MySQL.Async.execute(
                                "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
                                {
                                    ["@plate"] = plate,
                                    ["@owned"] = owned
                                }
                            )
                        end
                    end
                )
            else
                TriggerClientEvent(
                    "pNotify:SendNotification",
                    _source,
                    {
                        text = _U("invalid_amount"),
                        type = "error",
                        queue = "trunk",
                        timeout = 3000,
                        layout = "bottomCenter"
                    }
                )
            end
        end

        if type == "item_weapon" then
            TriggerEvent(
                "esx_inventoryhud_trunk:getSharedDataStore",
                plate,
                function(store)
                    local storeWeapons = store.get("weapons")

                    if storeWeapons == nil then
                        storeWeapons = {}
                    end

                    local pos, playerWeapon = xPlayer.getWeapon(item)

                    local components = playerWeapon.components
                    if components == nil then
                        components = {}
                    end

                    table.insert(
                        storeWeapons,
                        {
                            name = item,
                            label = label,
                            ammo = count,
                            components = components
                        }
                    )

                    if (getTotalInventoryWeight(plate) + (getItemWeight(item))) > max then
                        TriggerClientEvent(
                            "pNotify:SendNotification",
                            _source,
                            {
                                text = _U("invalid_amount"),
                                type = "error",
                                queue = "trunk",
                                timeout = 3000,
                                layout = "bottomCenter"
                            }
                        )
                    else
                        store.set("weapons", storeWeapons)
                        xPlayer.removeWeapon(item)

                        MySQL.Async.execute(
                            "UPDATE trunk_inventory SET owned = @owned WHERE plate = @plate",
                            {
                                ["@plate"] = plate,
                                ["@owned"] = owned
                            }
                        )
                    end
                end
            )
        end

        TriggerEvent(
            "esx_inventoryhud_trunk:getSharedDataStore",
            plate,
            function(store)
                local blackMoney = 0
                local items = {}
                local weapons = {}
                weapons = (store.get("weapons") or {})

                local blackAccount = (store.get("black_money")) or 0
                if blackAccount ~= 0 then
                    blackMoney = blackAccount[1].amount
                end

                local coffre = (store.get("coffre") or {})
                for i = 1, #coffre, 1 do
                    table.insert(items, {name = coffre[i].name, count = coffre[i].count, label = ESX.GetItemLabel(coffre[i].name)})
                end

                local weight = getTotalInventoryWeight(plate)

                text = _U("trunk_info", plate, (weight / 1000), (max / 1000))
                data = {plate = plate, max = max, myVeh = owned, text = text}
                TriggerClientEvent("esx_inventoryhud:refreshTrunkInventory", _source, data, blackMoney, items, weapons)
            end
        )
    end
)

ESX.RegisterServerCallback(
    "esx_inventoryhud_trunk:getPlayerInventory",
    function(source, cb)
        local xPlayer = ESX.GetPlayerFromId(source)
        local blackMoney = xPlayer.getAccount("black_money").money
        local items = xPlayer.inventory

        cb(
            {
                blackMoney = blackMoney,
                items = items
            }
        )
    end
)
