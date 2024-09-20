local getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, lower, gsub, match = getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, string.lower, string.gsub, string.match


if getgenv().AntiKick then
return
end


local cloneref = cloneref or function(...) 
return ...
end

local clonefunction = clonefunction or function(...)
return ...
end

local Players, LocalPlayer, StarterGui = cloneref(game:GetService("Players")), cloneref(game:GetService("Players").LocalPlayer), cloneref(game:GetService("StarterGui"))

local SetCore = clonefunction(StarterGui.SetCore)
local FindFirstChild = clonefunction(game.FindFirstChild)

local CompareInstances = (CompareInstances and function(Instance1, Instance2)
if typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance" then
return CompareInstances(Instance1, Instance2)
end
end)
or
function(Instance1, Instance2)
return (typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance")
end

local CanCastToSTDString = function(...)
return pcall(FindFirstChild, game, ...)
end


getgenv().AntiKick = {
Enabled = true, 
CheckCaller = true 
}


local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
local self, message = ...
local method = getnamecallmethod()

if ((getgenv().AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayer) and gsub(method, "^%l", string.upper) == "Kick" and AntiKick.Enabled then
if CanCastToSTDString(message) then
return
end
end

return OldNamecall(...)
end))

local OldFunction; OldFunction = hookfunction(LocalPlayer.Kick, function(...)
local self, Message = ...

if ((AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayer) and AntiKick.Enabled then
if CanCastToSTDString(Message) then
return
end
end
end))
