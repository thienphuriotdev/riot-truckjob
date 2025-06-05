-- Khởi tạo UI
function InitializeUI()
    -- Sẽ được gọi từ client/main.lua khi cần hiển thị UI
end

-- Thiết lập UI với dữ liệu về loại xe và trailer
function SetupUI()
    -- Lấy danh sách xe tải
    local truckList = {}
    for _, truck in pairs(Config.VehicleTypes.LocalTrucks) do
        table.insert(truckList, {
            name = truck.name,
            model = truck.model,
            label = truck.label,
            type = truck.type
        })
    end
    
    -- Lấy danh sách trailer container
    local trailerList = {}
    for _, trailer in pairs(Config.VehicleTypes.Trailers) do
        table.insert(trailerList, {
            name = trailer.name,
            model = trailer.model,
            label = trailer.label,
            type = trailer.type
        })
    end
    
    -- In ra console để debug
    print("^2[DEBUG] SetupUI:")
    print("^2[DEBUG] Truck List:")
    for i, truck in ipairs(truckList) do
        print("^2[DEBUG] Truck " .. i .. ": " .. truck.name .. " (" .. truck.model .. ")")
    end
    
    print("^2[DEBUG] Trailer List:")
    for i, trailer in ipairs(trailerList) do
        print("^2[DEBUG] Trailer " .. i .. ": " .. trailer.name .. " (" .. trailer.model .. ")")
    end
    
    -- Gửi dữ liệu đến UI
    print("^2[DEBUG] Sending data to UI")
    SendNUIMessage({
        action = "setupData",
        trucks = truckList,
        trailers = trailerList
    })
    
    print("^2[DEBUG] SetupUI completed")
    
    -- Thêm delay để đảm bảo UI có đủ thời gian cập nhật
    Citizen.Wait(200)
end

-- Khi resource khởi động, thiết lập UI
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    Wait(1000) -- Đợi để đảm bảo config đã được load
    print("Resource started, setting up UI")
    SetupUI()
end)

-- Khi người chơi spawn, thiết lập UI
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000) -- Đợi để đảm bảo config đã được load
    print("Player loaded, setting up UI")
    SetupUI()
end) 