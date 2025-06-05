Config = {}

-- Vị trí NPC và Blip
Config.NPCLocation = vector4(822.84, -2958.86, 6.02, 270.01)
Config.NPCModel = "s_m_m_trucker_01"
Config.NPCName = "Chú Tư Xe Tải"

-- Cấu hình Blip trên bản đồ
Config.Blip = {
    sprite = 477,
    color = 5,
    scale = 0.8,
    name = "Công việc tài xế xe tải"
}

-- Vị trí spawn xe (vị trí cũ, giữ lại cho khả năng tương thích)
Config.VehicleSpawnLocation = vector4(856.74, -2943.04, 6.14, 46.75)

-- Vị trí spawn xe thuê (nhiều điểm dự phòng)
Config.TruckSpawnLocations = {
    vector4(856.74, -2943.04, 6.14, 46.75),   -- Vị trí chính
    vector4(863.3, -2942.84, 6.13, 46.93),   -- Vị trí dự phòng 1
    vector4(869.73, -2942.33, 6.14, 53.35),  -- Vị trí dự phòng 2
    vector4(877.78, -2942.2, 6.14, 45.56),
    vector4(887.35, -2942.31, 6.14, 46.35)    -- Vị trí dự phòng 3
}

-- Vị trí spawn trailer container (nhiều điểm dự phòng)
Config.TrailerSpawnLocations = {
    vector4(860.68, -2912.19, 6.14, 179.17),  -- Vị trí chính
    vector4(867.74, -2912.57, 6.13, 180.63),  -- Vị trí dự phòng 1
    vector4(874.69, -2912.39, 6.14, 177.97),  -- Vị trí dự phòng 2
    vector4(882.08, -2912.2, 6.14, 181.45),
    vector4(887.76, -2911.98, 6.14, 181.57)   -- Vị trí dự phòng 3
}

-- Khoảng cách kiểm tra vị trí spawn (mét)
Config.SpawnCheckRadius = 5.0

-- Số lần thử tìm vị trí spawn thay thế
Config.MaxSpawnAttempts = 10

-- Tiền công theo km
Config.PayPerKm = {
    LocalTruck = 150, -- Tiền công cho xe thuê
    Container = 800,   -- Tiền công cho xe container
}

-- Khoảng cách cho phép để hoàn thành công việc (mét)
Config.ReturnDistance = 15.0  -- Phải trong khoảng 15m từ NPC để hoàn thành công việc

-- Các loại xe
Config.VehicleTypes = {
    LocalTrucks = {
        {name = "Mule 2", model = "mule2", label = "Xe tải Mule ", type = "city"},
        {name = "Mule 3", model = "mule3", label = "Xe tải Mule ", type = "city"},
        {name = "Mule 4", model = "mule4", label = "Xe tải Mule ", type = "city"},
        {name = "Pounder", model = "pounder", label = "Xe tải Pounder", type = "highway"},
        {name = "Benson", model = "benson", label = "Xe tải Benson", type = "highway"}
    },
    Trailers = {
        -- {name = "Army Trailer", model = "armytrailer2", label = "Trailer Xe kéo", type = "container"},
        {name = "Car Trailer", model = "tr4", label = "Trailer chở xe", type = "container"},
        {name = "Log Trailer", model = "trailerlogs", label = "Trailer chở gỗ", type = "container"},
        {name = "Container Trailer", model = "trailers3", label = "Trailer thực phẩm", type = "container"},
        -- {name = "Small Container", model = "tr3", label = "Container chở thuyền", type = "container"},
        {name = "Bale Trailer", model = "tvtrailer", label = "Trailer TV", type = "container"},
        {name = "Tanker", model = "tanker", label = "Tanker ", type = "container"}
    }
}

-- Điểm giao hàng trong thành phố
Config.CityDeliveryPoints = {
    vector3(130.36, -3088.54, 5.89),
    vector3(-613.88, -1083.25, 22.18),
    vector3(-727.52, -912.07, 19.01),
    vector3(-1399.67, -585.23, 30.22),
    vector3(1153.7, -333.69, 68.67),
    vector3(453.36, -769.41, 27.36),
    vector3(-390.29, -118.03, 38.6)
}

-- Điểm giao hàng ngoài thành phố
Config.HighwayDeliveryPoints = {
    vector3(1206.83, 2703.87, 38.0),
    vector3(1970.52, 3748.71, 32.32),
    vector3(2655.37, 3276.24, 55.25),
    vector3(2550.16, 342.67, 108.46),
    vector3(-2066.42, -305.19, 13.15),
    vector3(-3045.51, 599.31, 7.46),
    vector3(-1823.02, 777.68, 137.6)
}

-- Điểm giao hàng container (xa)
Config.ContainerDeliveryPoints = {
    vector3(2663.38, 3259.01, 55.24),
    vector3(1718.45, 6418.26, 33.48),
    vector3(-78.9, 6426.41, 31.49),
    vector3(177.86, 6625.27, 31.69),
    vector3(-2528.9, 2322.51, 33.06),
    vector3(1693.91, 4915.92, 42.08)
}

-- Điểm trả xe (về chỗ NPC)
Config.ReturnPoint = vector3(822.84, -2958.86, 6.02)

-- Thông báo
Config.Messages = {
    StartJob = "Bạn đã bắt đầu công việc lái xe tải.",
    EndJob = "Bạn đã hoàn thành công việc và nhận được $%s.",
    CancelJob = "Bạn đã hủy công việc.",
    DeliverGoods = "Giữ [H] để giao hàng.",
    GoToDeliveryPoint = "Hãy lái xe đến điểm giao hàng được đánh dấu trên bản đồ.",
    ReturnToDepot = "Hãy quay về điểm xuất phát để nhận tiền công.",
    InvalidVehicle = "Bạn không đang ở trong xe công việc.",
    VehicleSpawned = "Xe của bạn đã được tạo tại bãi đỗ. Chìa khóa đã được giao cho bạn.",
    TooFarAway = "Bạn cần ở gần NPC để hoàn thành công việc.",
    SpawnBlocked = "Vị trí spawn xe đang bị chiếm, sẽ tìm vị trí thay thế."
} 