RegisterNetEvent("Network:Registerped")
AddEventHandler("Network:Registerped", function(netid,pedid,task,...)
    local t = {...}
    print("Received new ped named "..pedid.." netid: "..netid.." task: "..task)
    TriggerClientEvent("Network:ReceiveNewPed", -1, netid, pedid, task,table.unpack(t))
end)