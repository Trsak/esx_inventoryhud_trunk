ESX = nil
Items = {}
local DataStoresIndex = {}
local DataStores = {}
local SharedDataStores = {}

TriggerEvent(
    "esx:getSharedObject",
    function(obj)
        ESX = obj
    end
)

MySQL.ready(
    function()
        MySQL.Async.fetchAll(
            "SELECT * FROM trunk_inventory",
            {},
            function(result)
                local data = nil
                if result ~= nil and #result ~= 0 then
                    for i = 1, #result, 1 do
                        local plate = result[i].plate
                        local owned = result[i].owned
                        local data = (result[i].data == nil and {} or json.decode(result[i].data))
                        local dataStore = CreateDataStore(plate, owned, data)
                        SharedDataStores[plate] = dataStore
                    end
                end
            end
        )
    end
)

function loadInvent(plate)
    MySQL.Async.fetchAll(
        "SELECT * FROM trunk_inventory WHERE plate = @plate LIMIT 1",
        {
            ["@plate"] = plate
        },
        function(result)
            local data = nil
            if #result ~= 0 then
                for i = 1, #result, 1 do
                    local plate = result[i].plate
                    local owned = result[i].owned
                    local data = (result[i].data == nil and {} or json.decode(result[i].data))
                    local dataStore = CreateDataStore(plate, owned, data)
                    SharedDataStores[plate] = dataStore
                end
            end
        end
    )
end

function MakeDataStore(plate, cb)
    local data = {}

    MySQL.Async.fetchAll(
        "SELECT 1 FROM owned_vehicles WHERE plate = @plate LIMIT 1",
        {
            ["@plate"] = plate
        },
        function(result)
            local owned = false

            if result ~= nil and result[1] ~= nil then
                owned = true
            end

            local dataStore = CreateDataStore(plate, owned, data)
            SharedDataStores[plate] = dataStore

            MySQL.Async.execute(
                "INSERT INTO trunk_inventory (plate, data, owned) VALUES (@plate, '{}', @owned)",
                {
                    ["@plate"] = plate,
                    ["@owned"] = owned
                }
            )

            loadInvent(plate)
            cb(SharedDataStores[plate])
        end
    )
end

function GetSharedDataStore(plate, cb)
    if SharedDataStores[plate] == nil then
        MakeDataStore(
            plate,
            function(res)
                cb(res)
            end
        )
    else
        cb(SharedDataStores[plate])
    end
end

AddEventHandler(
    "esx_inventoryhud_trunk:getSharedDataStore",
    function(plate, cb)
        GetSharedDataStore(
            plate,
            function(store)
                cb(store)
            end
        )
    end
)