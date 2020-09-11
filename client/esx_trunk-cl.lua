ESX = nil
local currentVehicle = nil

Citizen.CreateThread(
    function()
        while ESX == nil do
            TriggerEvent(
                "esx:getSharedObject",
                function(obj)
                    ESX = obj
                end
            )
            Citizen.Wait(0)
        end
    end
)

function getVehicleInDirection(range)
    local coordA = GetEntityCoords(GetPlayerPed(-1), 1)
    local coordB = GetOffsetFromEntityInWorldCoords(GetPlayerPed(-1), 0.0, range, 0.0)

    local rayHandle = CastRayPointToPoint(coordA.x, coordA.y, coordA.z, coordB.x, coordB.y, coordB.z, 10, GetPlayerPed(-1), 0)
    local a, b, c, d, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

function openmenuvehicle()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local vehicle = nil

    if IsPedInAnyVehicle(playerPed, false) then
        vehicle = GetVehiclePedIsIn(playerPed, false)
    else
        vehicle = getVehicleInDirection(3.0)

        if not DoesEntityExist(vehicle) then
            vehicle = GetClosestVehicle(coords, 3.0, 0, 70)
        end
    end

    if DoesEntityExist(vehicle) then
        local lockStatus = GetVehicleDoorLockStatus(vehicle)
        if lockStatus == 0 or lockStatus == 1 then
            local trunkpos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, "boot"))
            local distanceToTrunk = GetDistanceBetweenCoords(coords, trunkpos, 1)

            if distanceToTrunk <= 2.0 or (trunkpos.x + trunkpos.y + trunkpos.z) == 0.0 then
                TriggerEvent(
                    "mythic_progbar:client:progress",
                    {
                        name = "Open_Trunk",
                        duration = Config.OpenTime,
                        label = _U("trunk_opening"),
                        useWhileDead = false,
                        canCancel = true,
                        controlDisables = {
                            disableMovement = true,
                            disableCarMovement = true,
                            disableMouse = false,
                            disableCombat = true
                        }
                    },
                    function(status)
                        if not status then
                            currentVehicle = vehicle
                            SetVehicleDoorOpen(vehicle, 5, false, false)
                            local class = GetVehicleClass(vehicle)
                            OpenCoffreInventoryMenu(GetVehicleNumberPlateText(vehicle), Config.VehicleLimit[class])
                        end
                    end
                )
            else
                exports.pNotify:SendNotification({text = _U("trunk_nonear"), type = "error", timeout = 5000})
            end
        else
            exports.pNotify:SendNotification({text = _U("trunk_locked"), type = "error", timeout = 5000})
        end
    else
        exports.pNotify:SendNotification({text = _U("no_veh_nearby"), type = "error", timeout = 5000})
    end
end

local count = 0

Citizen.CreateThread(
    function()
        while true do
            Wait(1)
            if IsControlJustReleased(0, Config.OpenKey) and currentVehicle == nil and not IsPedInAnyVehicle(PlayerPedId(), true) then
                openmenuvehicle()
            end
        end
    end
)

function OpenCoffreInventoryMenu(plate, max)
    ESX.TriggerServerCallback(
        "esx_inventoryhud_trunk:getInventoryV",
        function(inventory)
            text = _U("trunk_info", plate, (inventory.weight / 1000), (max / 1000))
            data = {plate = plate, max = max, text = text}
            TriggerEvent("esx_inventoryhud:openTrunkInventory", data, inventory.blackMoney, inventory.items, inventory.weapons)
        end,
        plate
    )
end

RegisterNetEvent("esx_inventoryhud:onClosedInventory")
AddEventHandler(
    "esx_inventoryhud:onClosedInventory",
    function(type)
        if type == "trunk" then
            closeTrunk()
        end
    end
)

function closeTrunk()
    if currentVehicle ~= nil then
        SetVehicleDoorShut(currentVehicle, 5, false)
    end

    currentVehicle = nil
end

Citizen.CreateThread(
    function()
        while true do
            Wait(500)
            if currentVehicle ~= nil and DoesEntityExist(currentVehicle) then
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local vehicleCoords = GetEntityCoords(currentVehicle)
                local distance = GetDistanceBetweenCoords(coords, vehicleCoords, 1)

                if distance > 4.0 then
                    TriggerEvent("esx_inventoryhud:closeInventory")
                end
            end
        end
    end
)
