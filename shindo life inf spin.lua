--[[
Bloodlines idk:

narumakiruby
sharingan
boil
crystal
dust
explosion
sand
ice
golddust
scorch
lava
ironsand
sound
mud
storm
byakugan
kamakipurple
ketsuryugan
kaguya
namikaze
raionrengoku
uzumaki
shirogane
nara
senjuwood
yukiice
kamizuru
horsemankorashi
kamaki
tenseigan
rinnegan
clay
blacklightning
paper
itachisharingan
aduritewood
byakugangold
inuzuka
namikazegod
jashin
akimichi
whitelightning
obitosharingan
sasukesharingan
ink
forgedsengoku
bubble
aburame
azimsenko
kenichi
saberu
dangan
riser
renshiki
shindairengoku
frost
seishin
sengoku
hair
inferno
minakazeazure
sarutobi
mechaspirit
lightjokei
odinsaberu
hoshigaki
pikapika
goldjokei
giovannishizen
snakegreen
snakewhite
jotaroshizen
devarengoku
emerald
devasengoku
typhoon
ghostazarashi
infernoazarashi
xenodokei
narumaki
narumakiyang
wood
tsunami
varietymud
forgedrengoku
bolt
raionsengoku
blood
renshikigold
smoke
borumaki
borumakigold
shisuisharingan
sarachiasharingan
minakaze
sarachiasharingangold
shindaiakuma
shindairengokuyang
ryujikenichi
vine
ryujikenichiwhite
jayramazure
raionazure
bankaiinferno
jayramaki
satorirengoku
satorigold
riserinferno
dokuscorpion
dokutengoku
namikazegodazure
alphiramashizen
darkjokei
spiderman
toshiroice
kagoku
kagokuplatinum
sengokuinferno
morbius
menza
tengokuplatinum
obirengoku
batman
narumakisixpaths
raiongaiden
jinshikiekg
sengokugaiden
]]


repeat task.wait() until game:isLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer:FindFirstChild("startevent")


tpsrv = game:GetService("TeleportService")
print("Creating variables")
game:GetService("Players").LocalPlayer.startevent:FireServer("band", "\128")

elementwanted = {"boil", "lightning", "fire", "ice", "sand", "crystal", "explosion"} -- put the bloodlines u want here
slot = "kg2" -- slot, u can change to kg2, kg3, kg4
print("Starting")
getgenv().atspn = true

while getgenv().atspn do
    wait(.3)
    for _, v in pairs(elementwanted) do
        print("Rolled: \n ----" .. game:GetService("Players").LocalPlayer.statz.main[slot].Value)
        if game:GetService("Players").LocalPlayer.statz.main[slot].Value == v then
            print("Got what u wanted!")
            game:GetService("Players").LocalPlayer.startevent:FireServer("band", "Eye")
            wait(1)
            game.Players.LocalPlayer:Kick("Got "..game:GetService("Players").LocalPlayer.statz.main[slot].Value.. "!")
            return
        end
    end
    if game:GetService("Players").LocalPlayer.statz.spins.Value <= 1 then
        tpsrv:Teleport(game.PlaceId, game.Players.LocalPlayer)
        end
    game:GetService("Players").LocalPlayer.startevent:FireServer("spin", slot)
end
