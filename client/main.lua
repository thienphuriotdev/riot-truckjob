local QBCore = exports['qb-core']:GetCoreObject()

local isWorking = false
local currentVehicle = nil
local currentTrailer = nil
local currentJobType = nil 
local currentJobVehicleType = nil 
local currentBlip = nil
local deliveryBlip = nil
local returnBlip = nil
local deliveryPoint = nil
local startPoint = nil
local distanceTraveled = 0
local lastPosition = nil
local hasDelivered = false
local lastJobTime = 0
local cooldownTime = 10 


Citizen.CreateThread(function()
    local blip = AddBlipForCoord(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z)
    SetBlipSprite(blip, Config.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Blip.scale)
    SetBlipColour(blip, Config.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.name)
    EndTextCommandSetBlipName(blip)

    RequestModel(GetHashKey(Config.NPCModel))
    while not HasModelLoaded(GetHashKey(Config.NPCModel)) do
        Wait(1)
    end
    
    local ped = CreatePed(4, GetHashKey(Config.NPCModel), Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z - 1, Config.NPCLocation.w, false, true)
    SetEntityHeading(ped, Config.NPCLocation.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['dt-target']:AddTargetEntity(ped, {
        options = {
            {
                label = "Tìm việc lái xe tải",
                icon = "fas fa-truck",
                action = function()
                    if (GetGameTimer() / 1000) < lastJobTime + (cooldownTime * 60) and lastJobTime > 0 then
                        local remainingTime = math.ceil((lastJobTime + (cooldownTime * 60) - (GetGameTimer() / 1000)) / 60)
                        QBCore.Functions.Notify("Bạn phải đợi " .. remainingTime .. " phút nữa mới có thể nhận việc.", "error")
                        return
                    end
                    
                    if not isWorking then
                        OpenTruckJobMenu()
                    else
                        OpenReturnMenu()
                    end
                end
            }
        },
        distance = 2.0
    })

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z))
            
            if distance < 10.0 then
                local npcCoords = vector3(Config.NPCLocation.x, Config.NPCLocation.y, Config.NPCLocation.z + 1.0)
                DrawText3D(npcCoords.x, npcCoords.y, npcCoords.z, "Chú Tư Xe Tải")
            else
                Citizen.Wait(1000)
            end
        end
    end)
end)

function PlayAnimation(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(1)
    end
    TaskPlayAnim(PlayerPedId(), animDict, animName, 8.0, -8.0, duration, 49, 0, false, false, false)
    RemoveAnimDict(animDict)
end

function OpenTruckJobMenu()
    PlayAnimation("mp_common", "givetake1_a", 2000)
    SetupUI()
    Citizen.Wait(100)
    
    SendNUIMessage({
        action = "open",
        jobMenu = true
    })
    SetNuiFocus(true, true)
end

function OpenReturnMenu()
    PlayAnimation("mp_common", "givetake1_a", 2000)
    
    SendNUIMessage({
        action = "open",
        returnMenu = true
    })
    SetNuiFocus(true, true)
end

function SetVehicleFuel(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local fuelSet = false
    if GetResourceState('lc_fuel') == 'started' then
        exports["lc_fuel"]:SetFuel(vehicle, 100)
        fuelSet = true
    elseif GetResourceState('LegacyFuel') == 'started' then
        exports["LegacyFuel"]:SetFuel(vehicle, 100)
        fuelSet = true
    elseif GetResourceState('ps-fuel') == 'started' then
        exports['ps-fuel']:SetFuel(vehicle, 100)
        fuelSet = true
    elseif GetResourceState('cdn-fuel') == 'started' then
        exports['cdn-fuel']:SetFuel(vehicle, 100)
        fuelSet = true
    elseif GetResourceState('ox_fuel') == 'started' then
        if Entity(vehicle) and Entity(vehicle).state then
            Entity(vehicle).state.fuel = 100
            fuelSet = true
        end
    end
    if not fuelSet then
        SetVehicleFuelLevel(vehicle, 100.0)
    end
end

function SetVehicleKeys(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    local plate = GetVehicleNumberPlateText(vehicle)

    TriggerEvent("vehiclekeys:client:SetOwner", plate)
    TriggerServerEvent("vehiclekeys:server:SetVehicleOwner", plate)

    if exports['qb-vehiclekeys'] then
        if exports['qb-vehiclekeys'].SetVehicleKey then
            exports['qb-vehiclekeys']:SetVehicleKey(plate, true)
        elseif exports['qb-vehiclekeys'].giveKeys then
            exports['qb-vehiclekeys']:giveKeys(plate)
        end
    end
end

function FindSafeSpawnPoint(spawnLocationsList)
    if not spawnLocationsList or #spawnLocationsList == 0 then
        print("Lỗi: Danh sách spawn point trống")
        return Config.VehicleSpawnLocation
    end
    
    for _, spawnPoint in ipairs(spawnLocationsList) do
        local spawnPos = vector3(spawnPoint.x, spawnPoint.y, spawnPoint.z)
        local heading = spawnPoint.w
        local isOccupied = IsPositionOccupied(spawnPos.x, spawnPos.y, spawnPos.z, Config.SpawnCheckRadius, false, true, false, false, false, 0, false)
        
        if not isOccupied then
            return vector4(spawnPos.x, spawnPos.y, spawnPos.z, heading)
        end
    end

    local baseSpawnPoint = spawnLocationsList[1] 
    local basePos = vector3(baseSpawnPoint.x, baseSpawnPoint.y, baseSpawnPoint.z)
    local heading = baseSpawnPoint.w

    for attempt = 1, Config.MaxSpawnAttempts do
        local offsetX = math.random(-10, 10)
        local offsetY = math.random(-10, 10)
        
        local testPos = vector3(basePos.x + offsetX, basePos.y + offsetY, basePos.z)

        local _, zPos = GetGroundZFor_3dCoord(testPos.x, testPos.y, testPos.z + 10.0, false)
        
        if zPos then
            testPos = vector3(testPos.x, testPos.y, zPos)
            local isOccupied = IsPositionOccupied(testPos.x, testPos.y, testPos.z, Config.SpawnCheckRadius, false, true, false, false, false, 0, false)
            
            if not isOccupied then
                return vector4(testPos.x, testPos.y, testPos.z, heading)
            end
        end
    end

    QBCore.Functions.Notify(Config.Messages.SpawnBlocked, "warning")
    return spawnLocationsList[1]
end

function StartTruckJob(vehicleType, vehicleModel)
    isWorking = true
    currentJobType = 'truck'
    currentJobVehicleType = vehicleType
    hasDelivered = false
    RequestModel(GetHashKey(vehicleModel))
    while not HasModelLoaded(GetHashKey(vehicleModel)) do
        Wait(1)
    end

    local spawnCoords = FindSafeSpawnPoint(Config.TruckSpawnLocations)
    currentVehicle = CreateVehicle(GetHashKey(vehicleModel), spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(currentVehicle, true, true)

    SetVehicleKeys(currentVehicle)
    SetVehicleFuel(currentVehicle)

    QBCore.Functions.Notify(Config.Messages.VehicleSpawned, 'success')
    QBCore.Functions.Notify(Config.Messages.StartJob, 'primary')

    local deliveryPoints = (vehicleType == 'city') and Config.CityDeliveryPoints or Config.HighwayDeliveryPoints
    deliveryPoint = deliveryPoints[math.random(#deliveryPoints)]

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Điểm giao hàng")
    EndTextCommandSetBlipName(deliveryBlip)

    startPoint = GetEntityCoords(PlayerPedId())
    lastPosition = startPoint
    TrackDistance()
    CheckDelivery()
end


function StartContainerJob(trailerModel)
    isWorking = true
    currentJobType = 'container'
    currentJobVehicleType = 'container'
    hasDelivered = false

    RequestModel(GetHashKey(trailerModel))
    while not HasModelLoaded(GetHashKey(trailerModel)) do
        Wait(1)
    end

    local spawnCoords = FindSafeSpawnPoint(Config.TrailerSpawnLocations)
    currentTrailer = CreateVehicle(GetHashKey(trailerModel), spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetEntityAsMissionEntity(currentTrailer, true, true)

    QBCore.Functions.Notify(Config.Messages.VehicleSpawned, 'success')
    QBCore.Functions.Notify(Config.Messages.StartJob, 'primary')

    deliveryPoint = Config.ContainerDeliveryPoints[math.random(#Config.ContainerDeliveryPoints)]

    if deliveryBlip then RemoveBlip(deliveryBlip) end
    deliveryBlip = AddBlipForCoord(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z)
    SetBlipSprite(deliveryBlip, 501)
    SetBlipColour(deliveryBlip, 5)
    SetBlipRoute(deliveryBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Điểm giao hàng")
    EndTextCommandSetBlipName(deliveryBlip)

    startPoint = GetEntityCoords(PlayerPedId())
    lastPosition = startPoint

    TrackDistance()
    CheckDelivery()
end

function TrackDistance()
    Citizen.CreateThread(function()
        while isWorking do
            Citizen.Wait(1000)
            if lastPosition then
                local currentPosition = GetEntityCoords(PlayerPedId())
                local distance = #(currentPosition - lastPosition)
                if distance > 5.0 then 
                    distanceTraveled = distanceTraveled + distance
                    lastPosition = currentPosition
                end
            end
        end
    end)
end

function CheckDelivery()
    Citizen.CreateThread(function()
        while isWorking and not hasDelivered do
            Citizen.Wait(0)
            
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local distance = #(coords - deliveryPoint)
            
            if distance < 30.0 then
                DrawMarker(1, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0, 0, 0, 0, 0, 0, 4.0, 4.0, 1.0, 138, 43, 226, 100, false, true, 2, false, nil, nil, false)
                
                if distance < 5.0 then
                    DrawText3D(deliveryPoint.x, deliveryPoint.y, deliveryPoint.z, Config.Messages.DeliverGoods)
                    
                    local vehicle = GetVehiclePedIsIn(playerPed, false)
                    
                    if IsControlPressed(0, 74) and vehicle ~= 0 then
                        if currentJobType == 'truck' and vehicle == currentVehicle then
                            hasDelivered = true
                            DeliverTruck()
                        elseif currentJobType == 'container' then
                            if GetEntityAttachedTo(currentTrailer) == vehicle then
                                hasDelivered = true
                                DeliverContainer()
                            else
                                QBCore.Functions.Notify("Bạn cần kéo trailer đến điểm giao hàng", "error")
                            end
                        end
                    end
                end
            end
        end
    end)
end

function DeliverTruck()

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if DoesEntityExist(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, true)
    end

    TaskLeaveVehicle(playerPed, vehicle, 0)
    Citizen.Wait(2000)

    PlayAnimation("mini@repair", "fixing_a_player", 5000)

    Citizen.Wait(1000)
    PlayAnimation("anim@heists@prison_heiststation@cop_reactions", "cop_b_idle", 3000)

    if deliveryBlip then RemoveBlip(deliveryBlip) end

    QBCore.Functions.Notify("Đã giao hàng thành công! Hãy quay về điểm xuất phát để nhận tiền công.", "success")

    if returnBlip then RemoveBlip(returnBlip) end
    returnBlip = AddBlipForCoord(Config.ReturnPoint.x, Config.ReturnPoint.y, Config.ReturnPoint.z)
    SetBlipSprite(returnBlip, 38)
    SetBlipColour(returnBlip, 5)
    SetBlipRoute(returnBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Điểm trả xe")
    EndTextCommandSetBlipName(returnBlip)

end

function DeliverContainer()

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if DoesEntityExist(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, true)
    end
    TaskLeaveVehicle(playerPed, vehicle, 0)
    Citizen.Wait(2000)
    
    PlayAnimation("mini@repair", "fixing_a_ped", 5000)
    
    Citizen.Wait(1000)
    PlayAnimation("missheistdockssetup1clipboard@base", "base", 3000)
    
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    
    if DoesEntityExist(currentTrailer) then
        DeleteEntity(currentTrailer)
        currentTrailer = nil
    end
    
    QBCore.Functions.Notify("Đã giao hàng thành công! Hãy quay về điểm xuất phát để nhận tiền công.", "success")
    
    if returnBlip then RemoveBlip(returnBlip) end
    returnBlip = AddBlipForCoord(Config.ReturnPoint.x, Config.ReturnPoint.y, Config.ReturnPoint.z)
    SetBlipSprite(returnBlip, 38)
    SetBlipColour(returnBlip, 5)
    SetBlipRoute(returnBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Điểm trả xe")
    EndTextCommandSetBlipName(returnBlip)
end

function CompleteJob()
    if not isWorking then
        QBCore.Functions.Notify("Bạn không có công việc nào đang thực hiện.", "error")
        return
    end

    if not Config or not Config.ReturnPoint then
        QBCore.Functions.Notify("Có lỗi xảy ra khi hoàn thành công việc.", "error")
        print("Lỗi: Config.ReturnPoint không tồn tại")
        return
    end
    
    local returnPoint = Config.ReturnPoint
    if type(returnPoint) == "vector4" then
        returnPoint = vector3(returnPoint.x, returnPoint.y, returnPoint.z)
    end
    
    local playerPos = GetEntityCoords(PlayerPedId())
    local returnDistance = #(playerPos - returnPoint)
    
    if returnDistance > Config.ReturnDistance then
        QBCore.Functions.Notify(Config.Messages.TooFarAway, "error")
        return
    end
    
    if not hasDelivered then
        PlayAnimation("anim@amb@casino@hangout@ped_male@stand@02b@idles", "idle_a", 3000)
        
        lastJobTime = GetGameTimer() / 1000
        QBCore.Functions.Notify("Bịp à, chưa giao hàng mà đòi lương?", "error")
        
        if currentVehicle then
            if DoesEntityExist(currentVehicle) then
                DeleteEntity(currentVehicle)
            end
            currentVehicle = nil
        end
        
        if currentTrailer then
            if DoesEntityExist(currentTrailer) then
                DeleteEntity(currentTrailer)
            end
            currentTrailer = nil
        end
        
        if deliveryBlip then RemoveBlip(deliveryBlip) end
        if returnBlip then RemoveBlip(returnBlip) end
        
        isWorking = false
        currentJobType = nil
        currentJobVehicleType = nil
        deliveryPoint = nil
        startPoint = nil
        distanceTraveled = 0
        lastPosition = nil
        hasDelivered = false
        
        return
    end
    
    PlayAnimation("mp_common", "givetake1_a", 2000)
    Citizen.Wait(1000)
    
    PlayAnimation("anim@mp_player_intcelebrationmale@thumbs_up", "thumbs_up", 2000)
    
    local distanceKm = distanceTraveled / 1000
    local payRate = (currentJobType == 'truck') and Config.PayPerKm.LocalTruck or Config.PayPerKm.Container
    local payment = math.floor(distanceKm * payRate)
    
    if payment < 0 then payment = 0 end
    
    if currentJobType == 'truck' and currentVehicle then
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
        end
        currentVehicle = nil
    end
    
    if currentTrailer then
        if DoesEntityExist(currentTrailer) then
            DeleteEntity(currentTrailer)
        end
        currentTrailer = nil
    end
    
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    if returnBlip then RemoveBlip(returnBlip) end
    
    if payment > 0 then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "cash", 0.3)
    end
    
    TriggerServerEvent('riot-truckjob:server:PayDriver', payment)
    
    isWorking = false
    currentJobType = nil
    currentJobVehicleType = nil
    deliveryPoint = nil
    startPoint = nil
    distanceTraveled = 0
    lastPosition = nil
    hasDelivered = false
    
    QBCore.Functions.Notify(string.format(Config.Messages.EndJob, payment), "success")
end

function CancelJob()
    if not isWorking then
        QBCore.Functions.Notify("Bạn không có công việc nào đang thực hiện.", "error")
        return
    end
    
    PlayAnimation("gestures@m@standing@casual", "gesture_damn", 2000)
    
    if currentVehicle then
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
        end
        currentVehicle = nil
    end
    
    if currentTrailer then
        if DoesEntityExist(currentTrailer) then
            DeleteEntity(currentTrailer)
        end
        currentTrailer = nil
    end
    
    if deliveryBlip then RemoveBlip(deliveryBlip) end
    if returnBlip then RemoveBlip(returnBlip) end
    
    isWorking = false
    currentJobType = nil
    currentJobVehicleType = nil
    deliveryPoint = nil
    startPoint = nil
    distanceTraveled = 0
    lastPosition = nil
    hasDelivered = false
    
    QBCore.Functions.Notify(Config.Messages.CancelJob, "error")
end

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- NUI Callbacks
RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startTruckJob', function(data, cb)
    SetNuiFocus(false, false)
    StartTruckJob(data.vehicleType, data.vehicleModel)
    cb('ok')
end)

RegisterNUICallback('startContainerJob', function(data, cb)
    SetNuiFocus(false, false)
    StartContainerJob(data.trailerModel)
    cb('ok')
end)

RegisterNUICallback('completeJob', function(data, cb)
    SetNuiFocus(false, false)
    CompleteJob()
    cb('ok')
end)

RegisterNUICallback('cancelJob', function(data, cb)
    SetNuiFocus(false, false)
    CancelJob()
    cb('ok')
end)

RegisterNetEvent('riot-truckjob:client:Notify')
AddEventHandler('riot-truckjob:client:Notify', function(message, type)
    QBCore.Functions.Notify(message, type)
end) 