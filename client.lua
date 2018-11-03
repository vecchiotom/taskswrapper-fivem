local Peds = {}
TaskWrapper = {}

local charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do table.insert(charset, string.char(i)) end
for i = 65,  90 do table.insert(charset, string.char(i)) end
for i = 97, 122 do table.insert(charset, string.char(i)) end

function string.random(length)
    math.randomseed(GetGameTimer())
    
    if length > 0 then
        return string.random(length - 1) .. charset[math.random(1, #charset)]
    else
        return ""
    end
end

function TaskWrapper.SetPedTask(ped,task, ...)
    print("initiating... Entity ID: "..tostring(ped))
    local t = {...}
        
        local netid = NetworkGetNetworkIdFromEntity(ped)
        local attempts = 0
        while not NetworkDoesNetworkIdExist(netid) and attempts < 10 do
            Citizen.Wait(50)
            netid = NetworkGetNetworkIdFromEntity(ped)
            NetworkRegisterEntityAsNetworked(ped)
            SetEntityAsMissionEntity(ped)
            SetNetworkIdCanMigrate(netid,true)
            SetNetworkIdExistsOnAllMachines(netid,true)
            NetworkRequestControlOfEntity(ped)
            attempts = attempts + 1
        end
        if attempts >= 10 then
            Citizen.Trace("Failed to register ped on net")
        else
            local pedid = string.random(10)
            TriggerServerEvent("Network:Registerped",netid,pedid,task,table.unpack(t))
            Citizen.Trace("Registered "..pedid.." on net as NetID: "..netid)
            return pedid
            --[[ DecorRegister("AssignedTask", 3)
            while not DecorIsRegisteredAsType(task, 3) do
                Wait(0)
            end
            DecorSetFloat(ped, "AssignedTask", TaskHashes[task]) ]]
        end
end
exports("SetPedTask",TaskWrapper.SetPedTask)

function TaskWrapper.ClearPedTask(pedid)
    for i,v in ipairs(Peds) do
        if v.netid == pedid then
            Peds[i]=nil
        end
    end
end
exports("ClearPedTask",TaskWrapper.ClearPedTask)

RegisterNetEvent("Network:ReceiveNewPed")
AddEventHandler("Network:ReceiveNewPed", function(netid,pedid,task,...)
    Peds[pedid] = {netid=netid,task=task,args={...}}
    print("Received new ped: "..pedid)
end)

CreateThread(function()
    while true do
        Wait(50)
        for pedid,pedinfos in pairs(Peds) do
            if NetworkDoesNetworkIdExist(pedinfos.netid) and NetworkHasControlOfEntity(NetToPed(pedinfos.netid)) then
                if GetScriptTaskStatus(NetToPed(pedinfos.netid),TaskHashes[pedinfos.task]) == 7 and not IsPedDeadOrDying(NetToPed(pedinfos.netid),1) then
                    print("assigning "..FormatTaskString(pedinfos.task).." to "..pedid)
                    -- & 0xFFFFFFFF
                    _G[FormatTaskString(pedinfos.task)](NetToPed(pedinfos.netid),table.unpack(pedinfos.args))
                    collectgarbage()
                end
            end
        end
    end
end)




--[[ function table_invert(t)
    local s={}
    for k,v in pairs(t) do
        s[v]=k
    end
    return s
end ]]

function FormatTaskString(s)
    s = string.gsub(s,"_", " ")
    s = string.lower(s)
    s = string.gsub(s,"(%l)(%w*)", function(a,b) return string.upper(a)..b end)
    s = string.gsub(s," ","")
    return s 
end 
