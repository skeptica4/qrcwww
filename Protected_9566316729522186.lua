-- Lightweight Game Script v2.1
local F=loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/Fluentvv/refs/heads/main/fluent.lua"))()
local SM=loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local IM=loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local plr=game.Players.LocalPlayer
local uis=game:GetService("UserInputService")
local rs=game:GetService("RunService")
local cam=workspace.CurrentCamera
local isMobile=uis.TouchEnabled and not uis.KeyboardEnabled

local cfg={t=false,m=false,mm=false,b=false,fr=500,bs=9999,sa=0,wn=true,dl=false,wp="Custom"}
local presets={["High Speed"]={fr=1000,bs=15000,sp=0},["Rapid Fire"]={fr=2000,bs=9999,sp=0},["Sniper"]={fr=100,bs=20000,sp=0},["Shotgun"]={fr=300,bs=8000,sp=5},["Custom"]={fr=500,bs=9999,sp=0}}
local state={cw=nil,th={t=0,l=0,m=0},ma=false,ba=false}
local ex={Landmine=1,Man=1,Turret=1,Stonehedge=1,Sprayer=1,Sentinel=1,Refugee=1,PDC=1,MADS=1,Lifeline=1,Hallucinator=1,Governor=1,FAST_point=1,Barrier=1,Platform=1,Administrator=1}
for i=1,11 do if i~=8 then ex["dead guy "..i]=1 end end
local wl={"Akimbo","Voltaic Impact","Gunslingers","Burst Rifle","Stonewall","Steelforge","DMR","Gift of Fire","Armour Peeler","Medical Bow","Recurve","Vitabow","Rifle","Bolter","Harpoon Gun","RPG","Rocket Stormer","Shockwave Device","Shotgun","Hallsweeper","Sprinter's Streak","SMG","Loose Trigger","Twinface","Mastermind's Rifle","Shovel","Overcharger","Rallying Cry","Machete","Handaxes","Torqueblade"}

local function n(t,c,s,d)F:Notify({Title=t,Content=c,SubContent=s,Duration=d or 3})end
local function gc()local c=plr.Character return c,c and c:FindFirstChild("HumanoidRootPart")end
local function gmp()local m=uis:GetMouseLocation()local r=cam:ViewportPointToRay(m.X,m.Y)local r2=workspace:Raycast(cam.CFrame.Position,r.Direction*1000)return r2 and r2.Position end

local function tp()local c,hrp=gc()if not hrp then return end local p,fd=hrp.Position,hrp.CFrame.LookVector for _,m in ipairs(workspace:GetChildren())do if m:IsA("Model")then local h= m:FindFirstChildOfClass("Humanoid")local pp=m.PrimaryPart or m:FindFirstChild("HumanoidRootPart")if h and pp and h.Health>0 and not game.Players:GetPlayerFromCharacter(m)and not ex[m.Name]then pp.CFrame=CFrame.new(p+fd*(m.Name=="Tank"and 13 or 5.7))*CFrame.Angles(0,math.rad(hrp.Orientation.Y),0)end end end end
local function dl()local l=workspace:FindFirstChild("Landmine")if l then l:Destroy()end end
local function wm(ia)local c,w=gc(),state.cw if not c or not w then n("Error","No weapon",nil,3)return end local tool=c:FindFirstChild(w)if not tool then n("Error","Missing",nil,3)return end tool:SetAttribute("Firerate",cfg.fr)tool:SetAttribute("BulletSpeed",cfg.bs)tool:SetAttribute("Spread",cfg.sa)if ia and not tool:GetAttribute("InfAmmo")then tool:SetAttribute("InfAmmo",true)tool:GetAttributeChangedSignal("Ammo"):Connect(function()tool:SetAttribute("Ammo",999)end)tool:SetAttribute("Ammo",999)end n("Modified",w,string.format("FR:%d|BS:%d|SP:%d",cfg.fr,cfg.bs,cfg.sa)..(ia and "|∞"or""),4)end
local function fm(pos)local mk=plr.Backpack:FindFirstChild("Mercy Kill")or plr.Character:FindFirstChild("Mercy Kill")if mk and mk:FindFirstChild("VerifyHit")then mk.VerifyHit:FireServer(nil,pos)end end
local function fb(pos)local lux=workspace:FindFirstChild("luxsncc")if lux then local bolter=lux:FindFirstChild("Bolter")if bolter and bolter:FindFirstChild("VerifyCoinHit")then bolter.VerifyCoinHit:FireServer(pos)end end end

local wc=nil
local function we(tool)if tool and table.find(wl,tool.Name)then state.cw=tool.Name if cfg.wn then n("Equipped",tool.Name,nil,2)end end end
local function wu()state.cw=nil end
local function sc(c)if not c then return end if wc then wc:Disconnect()end wc=c.ChildAdded:Connect(function(t)if t:IsA("Tool")then we(t)end end)for _,t in pairs(c:GetChildren())do if t:IsA("Tool")then we(t)break end end end
sc(plr.Character)plr.CharacterAdded:Connect(sc)

rs.Heartbeat:Connect(function(dt)
if cfg.t then state.th.t=state.th.t+dt if state.th.t>=0.1 then state.th.t=0 tp()end end
if cfg.dl then state.th.l=state.th.l+dt if state.th.l>=0.5 then state.th.l=0 dl()end end
if cfg.mm and state.ma then state.th.m=state.th.m+dt if state.th.m>=0.1 then state.th.m=0 local pos= gmp()if pos then fm(pos)end end end
if cfg.b and state.ba then local pos=gmp()if pos then fb(pos)end end
end)

if not isMobile then
uis.InputBegan:Connect(function(i,g)if g then return end
if i.KeyCode==Enum.KeyCode.Semicolon then if cfg.mm then state.ma=true elseif cfg.m then local _,hrp=gc()if hrp then for i=1,3 do fm(hrp.Position)task.wait(0.17)end end end end
if i.KeyCode==Enum.KeyCode.Q then state.ba=true end
end)
uis.InputEnded:Connect(function(i)if i.KeyCode==Enum.KeyCode.Semicolon then state.ma=false elseif i.KeyCode==Enum.KeyCode.Q then state.ba=false end end)
end

local w=F:CreateWindow({Title=isMobile and "Script"or"Game Script",SubTitle=isMobile and"Mobile"or"Optimized",TabWidth=isMobile and 120 or 160,Size=isMobile and UDim2.fromOffset(400,380)or UDim2.fromOffset(580,460),Acrylic=false,Theme="Aqua",MinimizeKey=Enum.KeyCode.LeftControl})
local tabs={main=w:AddTab({Title="Main",Icon="code-xml"}),misc=w:AddTab({Title="Misc",Icon="menu"}),settings=w:AddTab({Title="Teleport",Icon="wrench"}),set=w:AddTab({Title="Settings",Icon="settings-2"})}

tabs.main:AddToggle("t",{Title="NPC Teleport",Description=isMobile and"Pull NPCs"or"Auto teleport NPCs to you",Default=false}):OnChanged(function(v)cfg.t=v n("NPC TP",v and"On"or"Off",v and"Teleporting",2)end)
tabs.main:AddDropdown("wp",{Title="Weapon Preset",Description="Quick configs",Values={"High Speed","Rapid Fire","Sniper","Shotgun","Custom"},Multi=false,Default=5}):OnChanged(function(v)if presets[v]then local p=presets[v]cfg.fr=p.fr cfg.bs=p.bs cfg.sa=p.sp F.Options.fr:SetValue(p.fr)F.Options.bs:SetValue(p.bs)F.Options.sa:SetValue(p.sp)cfg.wp=v n("Preset",v,string.format("FR:%d|BS:%d|SP:%d",p.fr,p.bs,p.sp),3)end end)
local frs=tabs.main:AddSlider("fr",{Title="Fire Rate",Description="RPM",Default=500,Min=50,Max=2000,Rounding=10,Callback=function(v)cfg.fr=v cfg.wp="Custom"F.Options.wp:SetValue("Custom")end})
tabs.main:AddInput("fri",{Title="Fire Rate",Default="500",Numeric=true,Finished=true,Placeholder="Manual",Callback=function(v)local n=tonumber(v)if n and n>=50 and n<=2000 then cfg.fr=n frs:SetValue(n)cfg.wp="Custom"F.Options.wp:SetValue("Custom")end end})
local bss=tabs.main:AddSlider("bs",{Title="Bullet Speed",Description="Velocity",Default=9999,Min=1000,Max=20000,Rounding=100,Callback=function(v)cfg.bs=v cfg.wp="Custom"F.Options.wp:SetValue("Custom")end})
tabs.main:AddInput("bsi",{Title="Bullet Speed",Default="9999",Numeric=true,Finished=true,Placeholder="Manual",Callback=function(v)local n=tonumber(v)if n and n>=1000 and n<=20000 then cfg.bs=n bss:SetValue(n)cfg.wp="Custom"F.Options.wp:SetValue("Custom")end end})
local sas=tabs.main:AddSlider("sa",{Title="Weapon Spread",Description="0=perfect",Default=0,Min=0,Max=10,Rounding=0.1,Callback=function(v)cfg.sa=v cfg.wp="Custom"F.Options.wp:SetValue("Custom")end})
tabs.main:AddInput("sai",{Title="Spread",Default="0",Numeric=true,Finished=true,Placeholder="Manual",Callback=function(v)local n=tonumber(v)if n and n>=0 and n<=10 then cfg.sa=n sas:SetValue(n)cfg.wp="Custom"F.Options.wp:SetValue("Custom")end end})
tabs.main:AddButton({Title="Apply Mods",Description="Apply to weapon",Callback=function()wm(false)end})
tabs.main:AddButton({Title="Apply+∞Ammo",Description="Stats+ammo",Callback=function()wm(true)end})
tabs.main:AddToggle("wn",{Title="Weapon Alerts",Description="Show on equip",Default=true}):OnChanged(function(v)cfg.wn=v end)
if not isMobile then tabs.main:AddParagraph({Title="Shortcuts",Content=";-Mercy Kill\nQ-Bolter"})end

tabs.misc:AddToggle("m",{Title="Mercy(self)",Description=isMobile and"At position"or"Press ; for 3 shots",Default=false}):OnChanged(function(v)cfg.m=v if v then cfg.mm=false F.Options.mm:SetValue(false)end end)
if isMobile then tabs.misc:AddButton({Title="Mercy(self)",Description="Fire 3 shots",Callback=function()local _,hrp=gc()if hrp then for i=1,3 do fm(hrp.Position)task.wait(0.17)end n("Mercy","3 shots","Self",2)end end})end
tabs.misc:AddToggle("mm",{Title="Mercy(mouse)",Description=isMobile and"At cursor"or"Hold ; rapid-fire",Default=false}):OnChanged(function(v)cfg.mm=v if v then cfg.m=false F.Options.m:SetValue(false)end end)
tabs.misc:AddToggle("b",{Title="Bolter Auto",Description=isMobile and"At cursor"or"Hold Q",Default=false}):OnChanged(function(v)cfg.b=v end)
tabs.misc:AddToggle("dl",{Title="Destroy Landmines",Description="Auto remove",Default=false}):OnChanged(function(v)cfg.dl=v n("Landmine",v and"On"or"Off",v and"Removing",2)end)
tabs.misc:AddButton({Title="Dev Tools",Description="Load utils",Callback=function()w:Dialog({Title="Dev Tools",Content="Select:",Buttons={{Title="Dark Dex",Callback=function()loadstring(game:HttpGet("https://raw.githubusercontent.com/skeptica4/aaaaaaaaaaaaaa/main/darkdex"))()n("Dev","Dark Dex",nil,3)end},{Title="Remote Spy",Callback=function()loadstring(game:HttpGet("https://github.com/exxtremestuffs/SimpleSpySource/raw/master/SimpleSpy.lua"))()n("Dev","Remote Spy",nil,3)end},{Title="Cancel",Callback=function()end}}})end})

tabs.settings:AddParagraph({Title="Quick Travel"})
tabs.settings:AddButton({Title="→Lobby",Description="Return to lobby",Callback=function()local _,hrp=gc()if hrp then hrp.CFrame=CFrame.new(-3,-101.5,-12.5)n("Teleported","Lobby",nil,2)else n("Error","Failed","No character",3)end end})
tabs.settings:AddButton({Title="→Map Spawn",Description="Go to spawn",Callback=function()local c=gc()if c then local hrp=c:WaitForChild("HumanoidRootPart")local sp=workspace.Map:FindFirstChild("PlayerSpawns")if sp and sp:FindFirstChild("SpawnLocation")then hrp.CFrame=sp.SpawnLocation.CFrame+Vector3.new(0,3,0)n("Teleported","Spawn",nil,2)else n("Error","Failed","No spawn",3)end end end})

SM:SetLibrary(F)IM:SetLibrary(F)SM:IgnoreThemeSettings()SM:SetFolder("FluentScriptHub/game")IM:SetFolder("FluentScriptHub")IM:BuildInterfaceSection(tabs.set)SM:BuildConfigSection(tabs.set)

w:SelectTab(1)n("Loaded",isMobile and"Mobile"or"Desktop","v2.1",5)SM:LoadAutoloadConfig()
