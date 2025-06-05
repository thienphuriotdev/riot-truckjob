local QBCore = exports['qb-core']:GetCoreObject()

local MaxPayment = 100000 
local MinPayment = 100   


RegisterNetEvent('riot-truckjob:server:PayDriver', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    
    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('riot-truckjob:client:Notify', src, "Có lỗi xảy ra khi tính tiền công.", "error")
        return
    end
    
   
    if amount > MaxPayment then
        print("CẢNH BÁO: Người chơi " .. Player.PlayerData.name .. " yêu cầu mức tiền cao bất thường: $" .. amount)
        amount = MaxPayment
    elseif amount < MinPayment then
        amount = MinPayment
    end
    
   
    Player.Functions.AddMoney("bank", amount, "trucker-job-payment")
    TriggerClientEvent('riot-truckjob:client:Notify', src, "Bạn đã nhận được $" .. amount .. " vào tài khoản ngân hàng.", "success")
    print("Người chơi " .. Player.PlayerData.name .. " đã nhận $" .. amount .. " từ công việc lái xe tải.")
end) 