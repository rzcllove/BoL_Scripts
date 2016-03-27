--[[


        d888888b d888888b d88888b .88b  d88.      .d8888. db   d8b   db  .d8b.  d8888b. d8888b. d88888b d8888b.
          `88'   `~~88~~' 88'     88'YbdP`88      88'  YP 88   I8I   88 d8' `8b 88  `8D 88  `8D 88'     88  `8D
           88       88    88ooooo 88  88  88      `8bo.   88   I8I   88 88ooo88 88oodD' 88oodD' 88ooooo 88oobY'
           88       88    88~~~~~ 88  88  88        `Y8b. Y8   I8I   88 88~~~88 88~~~   88~~~   88~~~~~ 88`8b
          .88.      88    88.     88  88  88      db   8D `8b d8'8b d8' 88   88 88      88      88.     88 `88.
        Y888888P    YP    Y88888P YP  YP  YP      `8888Y'  `8b8' `8d8'  YP   YP 88      88      Y88888P 88   YD


	Item Swapper - Swap items from your inventory using the Numpad!

	Changelog:
		March 27, 2016:
			- Added an Auto-Updater.

		March 23, 2016:
			- Updated for 6.6.

		March 14, 2016:
			- Re-wrote the Script as a Class (For my upcoming Auto-Updater).
			- Added Bol-Tools Tracker.

		March 11, 2016:
			- Updated for 6.5HF.

		March 09, 2016:
			- Updated for 6.5.

		March 07, 2016:
			- Re-wrote the tables to make it look better.
			- Now it will support Mini-Patches as well.

		March 04, 2016:
			- Improved SwapItem Function:
				- It won't send packets if both inventory slots are empty.
				- It will automatically check if the first slot you choose is empty and reverse swap the items.

		March 02, 2016:
			- Fixed a little mistake, the script was not working anymore.

		February 29, 2016:
			- Added a version check so the game won't crash if the Script is used on an "Outdated" Version of the game.

		February 28, 2016:
			- First Release.

]]--

local Script =
{
	Name = "Item Swapper",
	Version = 1.9
}

local function Print(string)
	print("<font color=\"#35445A\">" .. Script.Name .. ":</font> <font color=\"#3A99D9\">" .. string .. "</font>")
end

if not VIP_USER then
	Print("Sorry, this script is VIP Only!")
	return
end

class "Updater"
function Updater:__init(LocalVersion, Host, Path, LocalPath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion, CallbackError)
	self.LocalVersion = LocalVersion
	self.Host = Host
	self.VersionPath = '/BoL/TCPUpdater/GetScript5.php?script=' .. self:Base64Encode(self.Host .. Path .. '.ver') .. '&rand=' .. math.random(99999999)
	self.ScriptPath = '/BoL/TCPUpdater/GetScript5.php?script=' .. self:Base64Encode(self.Host .. Path .. '.lua') .. '&rand=' .. math.random(99999999)
	self.LocalPath = LocalPath
	self.CallbackUpdate = CallbackUpdate
	self.CallbackNoUpdate = CallbackNoUpdate
	self.CallbackNewVersion = CallbackNewVersion
	self.CallbackError = CallbackError
	
	AddDrawCallback(function()
		self:OnDraw()
	end)
	
	self:CreateSocket(self.VersionPath)
	self.DownloadStatus = 'Connecting to Server..'
	self.Progress = 0
	AddTickCallback(function()
		self:GetOnlineVersion()
	end)
end

function Updater:OnDraw()
	if (self.DownloadStatus == 'Downloading Script:' or self.DownloadStatus == 'Downloading Version:') and self.Progress == 100 then
		return
	end
	
	local LoadingBar =
	{
		X = math.round(0.91 * WINDOW_W),
		Y = math.round(0.73 * WINDOW_H),
		Height = math.round(0.01666666666 * WINDOW_H),
		Width = math.round(0.171875 * WINDOW_W),
		Border = 1,
		HeaderFontSize = math.round(0.01666666666 * WINDOW_H),
		ProgressFontSize = math.round(0.01125 * WINDOW_H),
		BackgroundColor = 0xFF3A99D9,
		ForegroundColor = 0xFF35445A
	}
	
	DrawText(self.DownloadStatus, LoadingBar.HeaderFontSize, LoadingBar.X - 0.5 * LoadingBar.Width, LoadingBar.Y - LoadingBar.Height - LoadingBar.Border, LoadingBar.BackgroundColor)
	DrawLine(LoadingBar.X, LoadingBar.Y, LoadingBar.X, LoadingBar.Y + LoadingBar.Height, LoadingBar.Width, LoadingBar.BackgroundColor)
	if self.Progress > 0 then
		local Width = 0.01 * ((LoadingBar.Width - 2 * LoadingBar.Border) * self.Progress)
		local Offset = 0.5 * (LoadingBar.Width - Width)
		DrawLine(LoadingBar.X - Offset + LoadingBar.Border, LoadingBar.Y + LoadingBar.Border, LoadingBar.X - Offset + LoadingBar.Border, LoadingBar.Y + LoadingBar.Height - LoadingBar.Border, Width, LoadingBar.ForegroundColor)
	end
	
	DrawText(self.Progress .. '%', LoadingBar.ProgressFontSize, LoadingBar.X - 2 * LoadingBar.Border, LoadingBar.Y + LoadingBar.Border, self.Progress < 50 and LoadingBar.ForegroundColor or LoadingBar.BackgroundColor)
end

function Updater:CreateSocket(url)
	if not self.LuaSocket then
		self.LuaSocket = require("socket")
	else
		self.Socket:close()
		self.Socket = nil
		self.Size = nil
		self.RecvStarted = false
	end
	
	self.LuaSocket = require("socket")
	self.Socket = self.LuaSocket.tcp()
	self.Socket:settimeout(0, 'b')
	self.Socket:settimeout(99999999, 't')
	self.Socket:connect('sx-bol.eu', 80)
	self.Url = url
	self.Started = false
	self.LastPrint = ""
	self.File = ""
end

function Updater:Base64Encode(data)
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x)
		local r, b = '', x:byte()
		for i = 8, 1, -1 do
			r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0')
		end
		
		return r;
	end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then
			return ''
		end
		
		local c = 0
		for i = 1, 6 do
			c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
		end
		
		return b:sub(c + 1, c + 1)
	end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

function Updater:GetOnlineVersion()
	if self.GotScriptVersion then
		return
	end

	self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
	if self.Status == 'timeout' and not self.Started then
		self.Started = true
		self.Socket:send("GET " .. self.Url .. " HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
	end
	
	if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
		self.RecvStarted = true
		self.DownloadStatus = 'Downloading Version:'
		self.Progress = 0
	end

	self.File = self.File .. (self.Receive or self.Snipped)
	if self.File:find('</s'..'ize>') then
		if not self.Size then
			self.Size = tonumber(self.File:sub(self.File:find('<si' .. 'ze>') + 6, self.File:find('</si' .. 'ze>') - 1))
		end
		
		if self.File:find('<scr' .. 'ipt>') then
			local _,ScriptFind = self.File:find('<scr' .. 'ipt>')
			local ScriptEnd = self.File:find('</scr' .. 'ipt>')
			if ScriptEnd then
				ScriptEnd = ScriptEnd - 1
			end
			
			local DownloadedSize = self.File:sub(ScriptFind + 1, ScriptEnd or -1):len()
			self.Progress = math.round(100 / self.Size * DownloadedSize, 2)
		end
	end
	
	if self.File:find('</scr' .. 'ipt>') then
		local a, b = self.File:find('\r\n\r\n')
		self.File = self.File:sub(a, -1)
		self.NewFile = ''
		for line, content in ipairs(self.File:split('\n')) do
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
		end
		
		local HeaderEnd, ContentStart = self.File:find('<scr' .. 'ipt>')
		local ContentEnd, _ = self.File:find('</sc' .. 'ript>')
		if not ContentStart or not ContentEnd then
			if self.CallbackError and type(self.CallbackError) == 'function' then
				self.CallbackError()
			end
		else
			self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1, ContentEnd - 1)))
			self.OnlineVersion = tonumber(self.OnlineVersion)
			if self.OnlineVersion > self.LocalVersion then
				if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
					self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
				end
				
				self:CreateSocket(self.ScriptPath)
				self.DownloadStatus = 'Connecting to Server..'
				self.Progress = 0
				AddTickCallback(function()
					self:DownloadUpdate()
				end)
			else
				if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
					self.CallbackNoUpdate(self.LocalVersion)
				end
			end
		end
		
		self.GotScriptVersion = true
	end
end

function Updater:DownloadUpdate()
	if self.GotScriptUpdate then
		return
	end
	
	self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
	if self.Status == 'timeout' and not self.Started then
		self.Started = true
		self.Socket:send("GET " .. self.Url .. " HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
	end
	
	if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
		self.RecvStarted = true
		self.DownloadStatus = 'Downloading Script:'
		self.Progress = 0
	end

	self.File = self.File .. (self.Receive or self.Snipped)
	if self.File:find('</si' .. 'ze>') then
		if not self.Size then
			self.Size = tonumber(self.File:sub(self.File:find('<si' .. 'ze>') + 6, self.File:find('</si' .. 'ze>') - 1))
		end
		
		if self.File:find('<scr' .. 'ipt>') then
			local _, ScriptFind = self.File:find('<scr' .. 'ipt>')
			local ScriptEnd = self.File:find('</scr' .. 'ipt>')
			if ScriptEnd then
				ScriptEnd = ScriptEnd - 1
			end
			
			local DownloadedSize = self.File:sub(ScriptFind + 1, ScriptEnd or -1):len()
			self.Progress = math.round(100 / self.Size * DownloadedSize, 2)
		end
	end
	
	if self.File:find('</scr' .. 'ipt>') then
		local a, b = self.File:find('\r\n\r\n')
		self.File = self.File:sub(a,-1)
		self.NewFile = ''
		for line, content in ipairs(self.File:split('\n')) do
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
		end
		
		local HeaderEnd, ContentStart = self.NewFile:find('<sc' .. 'ript>')
		local ContentEnd, _ = self.NewFile:find('</scr' .. 'ipt>')
		if not ContentStart or not ContentEnd then
			if self.CallbackError and type(self.CallbackError) == 'function' then
				self.CallbackError()
			end
		else
			local newf = self.NewFile:sub(ContentStart + 1, ContentEnd - 1)
			local newf = newf:gsub('\r','')
			if newf:len() ~= self.Size then
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
				
				return
			end
			
			local newf = Base64Decode(newf)
			if type(load(newf)) ~= 'function' then
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
			else
				local f = io.open(self.LocalPath,"w+b")
				f:write(newf)
				f:close()
				if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
					self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
				end
			end
		end
		
		self.GotScriptUpdate = true
	end
end

AddLoadCallback(function()
	local UpdaterInfo =
	{
		Version = Script.Version,
		Host = 'raw.githubusercontent.com',
		Path = '/RoachxD/BoL_Scripts/master/' .. Script.Name:gsub(' ', '%%20'),
		LocalPath = SCRIPT_PATH .. '/' .. Script.Name .. '.lua',
		CallbackUpdate = function(newVersion, oldVersion)
			Print("Updated to r" .. newVersion .. ", please 2xF9 to reload!")
		end,
		CallbackNoUpdate = function(version)
			Print("No updates found!")
			ItemSwapper()
		end,
		CallbackNewVersion = function(version)
			Print("New release found (r" .. version .. "), please wait until it's downloaded!")
		end,
		CallbackError = function(version)
			Print("Download failed, please try again!")
			Print("If the problem persists please contact script's author!")
			ItemSwapper()
		end
	}
	
	Updater(UpdaterInfo.Version, UpdaterInfo.Host, UpdaterInfo.Path, UpdaterInfo.LocalPath, UpdaterInfo.CallbackUpdate, UpdaterInfo.CallbackNoUpdate, UpdaterInfo.CallbackNewVersion, UpdaterInfo.CallbackError)
end)

class "ItemSwapper"
function ItemSwapper:__init()
	self.GameVersion = GetGameVersion():sub(1, 9)
	self.Packet =
	{
		['6.6.137.4'] =
		{
			Header = 0x139,
			vTable = 0xEC1164,
			SourceSlotTable =
			{
				[1] = 0xF8, [2] = 0x4F, [3] = 0x14,
				[4] = 0x9E, [5] = 0x24, [6] = 0x50
			},
			TargetSlotTable =
			{
				[1] = 0x2C, [2] = 0xD9, [3] = 0x7F,
				[4] = 0xF4, [5] = 0xF1, [6] = 0x8D
			}
		},
		['6.5.0.280'] =
		{
			Header = 0x121,
			vTable = 0xED67EC,
			SourceSlotTable =
			{
				[1] = 0x56, [2] = 0x17, [3] = 0x42,
				[4] = 0x6D, [5] = 0x74, [6] = 0xC5
			},
			TargetSlotTable =
			{
				[1] = 0x48, [2] = 0x80, [3] = 0x81,
				[4] = 0x2C, [5] = 0xD4, [6] = 0x84
			}
		},
		['6.5.0.277'] =
		{
			Header = 0x121,
			vTable = 0xEF4D68,
			SourceSlotTable =
			{
				[1] = 0x56, [2] = 0x17, [3] = 0x42,
				[4] = 0x6D, [5] = 0x74, [6] = 0xC5
			},
			TargetSlotTable =
			{
				[1] = 0x48, [2] = 0x80, [3] = 0x81,
				[4] = 0x2C, [5] = 0xD4, [6] = 0x84
			}
		},
		['6.4.0.250'] =
		{
			Header = 0x51,
			vTable = 0xE52AB4,
			SourceSlotTable =
			{
				[1] = 0x9C, [2] = 0x7C, [3] = 0xA5,
				[4] = 0xC4, [5] = 0xBF, [6] = 0x92
			},
			TargetSlotTable =
			{
				[1] = 0x8B, [2] = 0xB6, [3] = 0x40,
				[4] = 0xC7, [5] = 0x18, [6] = 0xD4
			}
		}
	}

	self.Keys =
	{
		FirstKey = 0x60,
		SlotKeys =
		{
			[1] = 0x64, [2] = 0x65, [3] = 0x66,
			[4] = 0x61, [5] = 0x62, [6] = 0x63
		}
	}
	
	self:OnLoad()
	
	-- Bol-Tools Tracker
	assert(load(Base64Decode("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"), nil, "bt", _ENV))()
	TrackerLoad("gbyMzEMM2CMOJnZr")
end

function ItemSwapper:OnLoad()
	self.Config = scriptConfig(Script.Name .. ": Info", "IS")
	self.Config:addParam("KeysInfo", "Keys info:", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("NumPad0", "Numpad 0: Reset Key", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad1", "Numpad 1: Item Slot 4", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad2", "Numpad 2: Item Slot 5", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad3", "Numpad 3: Item Slot 6", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad4", "Numpad 4: Item Slot 1", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad5", "Numpad 5: Item Slot 2", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Numpad6", "Numpad 6: Item Slot 3", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("Sep", "", SCRIPT_PARAM_INFO, "")
	self.Config:addParam("NumLock", "Num Lock must be Active!", SCRIPT_PARAM_INFO, "")
	
	Print("Successfully loaded r" .. Script.Version .. ", have fun!")
	if self.Packet[self.GameVersion] == nil then
		Print("The script is outdated for this version of the game (" .. self.GameVersion .. ")!")
	end
	
	AddMsgCallback(function(msg, key)
		self:OnWndMsg(msg, key)
	end)
end

function ItemSwapper:OnWndMsg(msg, key)
	if msg == 0x100 and key == 0x60 then
		self.Keys.FirstKey = 0x60;
	end
	
	if msg ~= 0x100 or self:IndexOf(self.Keys.SlotKeys, key) == nil then
		return
	end
	
	if self.Keys.FirstKey == 0x60 then
		self.Keys.FirstKey = key
	end

	if self.Keys.FirstKey == key then
		return
	end
	
	self:SwapItem(self:IndexOf(self.Keys.SlotKeys, self.Keys.FirstKey), self:IndexOf(self.Keys.SlotKeys, key))
	self.Keys.FirstKey = 0x60
end

function ItemSwapper:IndexOf(table, value)
	for i = 1, #table do
		if table[i] == value then
			return i
		end
	end
	
	return nil
end

function ItemSwapper:SwapItem(sourceSlotId, targetSlotId)
	if self.Packet[self.GameVersion].SourceSlotTable == nil or self.Packet[self.GameVersion].TargetSlotTable == nil then
		return
	end
	
	if GetInventorySlotIsEmpty(sourceSlotId + 5) and GetInventorySlotIsEmpty(targetSlotId + 5) then
		return
	end
	
	if GetInventorySlotIsEmpty(sourceSlotId + 5) and not GetInventorySlotIsEmpty(targetSlotId + 5) then
		sourceSlotId, targetSlotId = targetSlotId, sourceSlotId
	end
	
	local CustomPacket = CLoLPacket(self.Packet[self.GameVersion].Header)
	CustomPacket.vTable = self.Packet[self.GameVersion].vTable
	CustomPacket:EncodeF(myHero.networkID)
	CustomPacket:Encode1(self.Packet[self.GameVersion].SourceSlotTable[sourceSlotId])
	CustomPacket:Encode1(self.Packet[self.GameVersion].TargetSlotTable[targetSlotId])
	SendPacket(CustomPacket)
end
