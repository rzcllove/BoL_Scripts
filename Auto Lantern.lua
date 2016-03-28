--[[


		 .d8b.  db    db d888888b  .d88b.       db       .d8b.  d8b   db d888888b d88888b d8888b. d8b   db
		d8' `8b 88    88 `~~88~~' .8P  Y8.      88      d8' `8b 888o  88 `~~88~~' 88'     88  `8D 888o  88
		88ooo88 88    88    88    88    88      88      88ooo88 88V8o 88    88    88ooooo 88oobY' 88V8o 88
		88~~~88 88    88    88    88    88      88      88~~~88 88 V8o88    88    88~~~~~ 88`8b   88 V8o88
		88   88 88b  d88    88    `8b  d8'      88booo. 88   88 88  V888    88    88.     88 `88. 88  V888
		YP   YP ~Y8888P'    YP     `Y88P'       Y88888P YP   YP VP   V8P    YP    Y88888P 88   YD VP   V8P


	Auto Lantern - Grab the lantern with ease!

	Changelog:
		March 28, 2016 [r1.5]:
			- Fixed the Data Tables, no more usage of IndexOf Function!

		March 28, 2016 [r1.4]:
			- Fixed the bug, now it should work!
	
		March 28, 2016 [r1.3]:
			- Added Bol-Tools Tracker.

		March 28, 2016 [r1.2]:
			- Removed OnDeleteObj Callback as it was useless.

		March 28, 2016 [r1.1]:
			- Added a check to see if Thresh is part of your team, so the script won't load if he isn't.
			- Improved a bit the menu.

		March 28, 2016 [r1.0]:
			- First Release.

]]--

local Script =
{
	Name = "Auto Lantern",
	Version = 1.5
}

local function Print(string)
	print("<font color=\"#3C8430\">" .. Script.Name .. ":</font> <font color=\"#DE540B\">" .. string .. "</font>")
end

if not VIP_USER then
	Print("Sorry, this script is VIP Only!")
	return
end

class "ALUpdater"
function ALUpdater:__init(LocalVersion, Host, Path, LocalPath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion, CallbackError)
	self.LocalVersion = LocalVersion
	self.Host = Host
	self.VersionPath = '/BoL/TCPUpdater/GetScript5.php?script=' .. self:Base64Encode(self.Host .. Path .. '.ver') .. '&rand=' .. math.random(99999999)
	self.ScriptPath = '/BoL/TCPUpdater/GetScript5.php?script=' .. self:Base64Encode(self.Host .. Path .. '.lua') .. '&rand=' .. math.random(99999999)
	self.LocalPath = LocalPath
	self.CallbackUpdate = CallbackUpdate
	self.CallbackNoUpdate = CallbackNoUpdate
	self.CallbackNewVersion = CallbackNewVersion
	self.CallbackError = CallbackError
	
	self.OffsetY = _G.OffsetY and _G.OffsetY or 0
	_G.OffsetY = _G.OffsetY and _G.OffsetY + math.round(0.08333333333 * WINDOW_H) or math.round(0.08333333333 * WINDOW_H)
	
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

function ALUpdater:OnDraw()
	if (self.DownloadStatus == 'Downloading Script:' or self.DownloadStatus == 'Downloading Version:') and self.Progress == 100 then
		return
	end
	
	local LoadingBar =
	{
		X = math.round(0.91 * WINDOW_W),
		Y = math.round(0.73 * WINDOW_H) - self.OffsetY,
		Height = math.round(0.01666666666 * WINDOW_H),
		Width = math.round(0.171875 * WINDOW_W),
		Border = 1,
		HeaderFontSize = math.round(0.01666666666 * WINDOW_H),
		ProgressFontSize = math.round(0.01125 * WINDOW_H),
		BackgroundColor = 0xFF3C8430,
		ForegroundColor = 0xFFDE540B
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

function ALUpdater:CreateSocket(url)
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

function ALUpdater:Base64Encode(data)
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

function ALUpdater:GetOnlineVersion()
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
	if self.File:find('</size>') then
		if not self.Size then
			self.Size = tonumber(self.File:sub(self.File:find('<size>') + 6, self.File:find('</size>') - 1))
		end
		
		if self.File:find('<script>') then
			local _,ScriptFind = self.File:find('<script>')
			local ScriptEnd = self.File:find('</script>')
			if ScriptEnd then
				ScriptEnd = ScriptEnd - 1
			end
			
			local DownloadedSize = self.File:sub(ScriptFind + 1, ScriptEnd or -1):len()
			self.Progress = math.round(100 / self.Size * DownloadedSize, 2)
		end
	end
	
	if self.File:find('</script>') then
		local a, b = self.File:find('\r\n\r\n')
		self.File = self.File:sub(a, -1)
		self.NewFile = ''
		for line, content in ipairs(self.File:split('\n')) do
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
		end
		
		local HeaderEnd, ContentStart = self.File:find('<script>')
		local ContentEnd, _ = self.File:find('</script>')
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

function ALUpdater:DownloadUpdate()
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
	if self.File:find('</size>') then
		if not self.Size then
			self.Size = tonumber(self.File:sub(self.File:find('<size>') + 6, self.File:find('</size>') - 1))
		end
		
		if self.File:find('<script>') then
			local _, ScriptFind = self.File:find('<script>')
			local ScriptEnd = self.File:find('</script>')
			if ScriptEnd then
				ScriptEnd = ScriptEnd - 1
			end
			
			local DownloadedSize = self.File:sub(ScriptFind + 1, ScriptEnd or -1):len()
			self.Progress = math.round(100 / self.Size * DownloadedSize, 2)
		end
	end
	
	if self.File:find('</script>') then
		local a, b = self.File:find('\r\n\r\n')
		self.File = self.File:sub(a,-1)
		self.NewFile = ''
		for line, content in ipairs(self.File:split('\n')) do
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
		end
		
		local HeaderEnd, ContentStart = self.NewFile:find('<script>')
		local ContentEnd, _ = self.NewFile:find('</script>')
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
			Print("Updated to r" .. string.format("%.1f", newVersion) .. ", please 2xF9 to reload!")
		end,
		CallbackNoUpdate = function(version)
			Print("No updates found!")
			AutoLantern()
		end,
		CallbackNewVersion = function(version)
			Print("New release found (r" .. string.format("%.1f", version) .. "), please wait until it's downloaded!")
		end,
		CallbackError = function(version)
			Print("Download failed, please try again!")
			Print("If the problem persists please contact script's author!")
			AutoLantern()
		end
	}
	
	ALUpdater(UpdaterInfo.Version, UpdaterInfo.Host, UpdaterInfo.Path, UpdaterInfo.LocalPath, UpdaterInfo.CallbackUpdate, UpdaterInfo.CallbackNoUpdate, UpdaterInfo.CallbackNewVersion, UpdaterInfo.CallbackError)
end)

class "AutoLantern"
function AutoLantern:__init()
	self.GameVersion = GetGameVersion():sub(1, 9)
	self.Packet =
	{
		['6.6.137.4'] =
		{
			Header = 0x1E,
			vTable = 0xEA7E78,
			DataTable =
			{
				[0x01] = 0x4F, [0x02] = 0x14, [0x03] = 0x9E, [0x04] = 0x24, [0x05] = 0x50, [0x06] = 0xF6, [0x07] = 0x78, [0x08] = 0x83,
				[0x09] = 0x75, [0x0A] = 0xC2, [0x0B] = 0xB9, [0x0C] = 0x6E, [0x0D] = 0x5B, [0x0E] = 0xC8, [0x0F] = 0xBB, [0x10] = 0x45,
				[0x11] = 0xC9, [0x12] = 0xA1, [0x13] = 0x69, [0x14] = 0x5E, [0x15] = 0xA6, [0x16] = 0x82, [0x17] = 0x9D, [0x18] = 0x17,
				[0x19] = 0x09, [0x1A] = 0x65, [0x1B] = 0x55, [0x1C] = 0xFD, [0x1D] = 0xDC, [0x1E] = 0x27, [0x1F] = 0xB2, [0x20] = 0x36,
				[0x21] = 0x28, [0x22] = 0x71, [0x23] = 0x19, [0x24] = 0xB0, [0x25] = 0x8E, [0x26] = 0x67, [0x27] = 0x53, [0x28] = 0x47,
				[0x29] = 0x1C, [0x2A] = 0xF5, [0x2B] = 0xE4, [0x2C] = 0x90, [0x2D] = 0xB7, [0x2E] = 0xFB, [0x2F] = 0x3A, [0x30] = 0x85,
				[0x31] = 0x66, [0x32] = 0x8F, [0x33] = 0xF4, [0x34] = 0x6C, [0x35] = 0x20, [0x37] = 0xCD, [0x38] = 0xD3, [0x39] = 0xB6,
				[0x3A] = 0xC3, [0x3B] = 0xF3, [0x3C] = 0x2B, [0x3D] = 0x8A, [0x3E] = 0xB3, [0x3F] = 0xE0, [0x40] = 0x60, [0x41] = 0xA8,
				[0x42] = 0x37, [0x43] = 0x1E, [0x44] = 0xBE, [0x45] = 0x5F, [0x46] = 0x29, [0x47] = 0x74, [0x48] = 0x1B, [0x49] = 0xE9,
				[0x4A] = 0xB8, [0x4B] = 0xC0, [0x4C] = 0xF2, [0x4D] = 0x3D, [0x4E] = 0x61, [0x4F] = 0xFA, [0x50] = 0x35, [0x51] = 0x4C,
				[0x52] = 0xEF, [0x53] = 0x2A, [0x54] = 0x3B, [0x55] = 0xFC, [0x56] = 0x04, [0x57] = 0x16, [0x58] = 0xA7, [0x59] = 0x32,
				[0x5A] = 0x80, [0x5B] = 0x70, [0x5C] = 0xAA, [0x5D] = 0xD4, [0x5E] = 0x98, [0x5F] = 0xB4, [0x60] = 0xD2, [0x61] = 0xAC,
				[0x62] = 0xEC, [0x63] = 0x64, [0x64] = 0xE2, [0x65] = 0xD6, [0x66] = 0x15, [0x67] = 0xA2, [0x68] = 0xFF, [0x69] = 0x1D,
				[0x6A] = 0x48, [0x6B] = 0x97, [0x6C] = 0x33, [0x6D] = 0x41, [0x6E] = 0x9C, [0x6F] = 0x58, [0x70] = 0x62, [0x71] = 0x2C,
				[0x72] = 0x0E, [0x73] = 0xD7, [0x74] = 0x46, [0x75] = 0xA4, [0x76] = 0xCA, [0x77] = 0xE7, [0x78] = 0x7C, [0x79] = 0x30,
				[0x7A] = 0x1A, [0x7B] = 0x12, [0x7C] = 0xD5, [0x7D] = 0x91, [0x7E] = 0x68, [0x7F] = 0x3C, [0x80] = 0x9B, [0x81] = 0xF1,
				[0x82] = 0x08, [0x83] = 0x10, [0x84] = 0x6A, [0x85] = 0x52, [0x86] = 0xD0, [0x87] = 0x39, [0x88] = 0x4D, [0x89] = 0xBF,
				[0x8A] = 0x73, [0x8B] = 0xC6, [0x8C] = 0xE3, [0x8D] = 0x06, [0x8E] = 0x49, [0x8F] = 0x18, [0x90] = 0xEB, [0x91] = 0x1F,
				[0x92] = 0x38, [0x93] = 0xDA, [0x94] = 0x3F, [0x95] = 0xDD, [0x96] = 0x84, [0x97] = 0x44, [0x98] = 0xBD, [0x99] = 0x94,
				[0x9A] = 0x0A, [0x9B] = 0x9A, [0x9C] = 0x31, [0x9D] = 0x81, [0x9E] = 0x34, [0x9F] = 0xF9, [0xA0] = 0x4E, [0xA1] = 0xBA,
				[0xA2] = 0x13, [0xA3] = 0xAF, [0xA4] = 0x7D, [0xA5] = 0x76, [0xA6] = 0x89, [0xA7] = 0x5A, [0xA8] = 0x3E, [0xA9] = 0x26,
				[0xAA] = 0xBC, [0xAB] = 0x77, [0xAC] = 0x0D, [0xAD] = 0x79, [0xAE] = 0x86, [0xAF] = 0x8B, [0xB0] = 0xC7, [0xB1] = 0x92,
				[0xB2] = 0x72, [0xB3] = 0x22, [0xB4] = 0x2F, [0xB5] = 0x59, [0xB6] = 0xE1, [0xB7] = 0xFE, [0xB8] = 0x88, [0xB9] = 0x8C,
				[0xBA] = 0xD8, [0xBB] = 0xB1, [0xBC] = 0x21, [0xBD] = 0xC5, [0xBE] = 0x51, [0xBF] = 0xC1, [0xC0] = 0xD1, [0xC1] = 0xEA,
				[0xC2] = 0xA5, [0xC3] = 0xA3, [0xC4] = 0x87, [0xC5] = 0x93, [0xC6] = 0x9F, [0xC7] = 0x54, [0xC8] = 0xEE, [0xC9] = 0x99,
				[0xCA] = 0x01, [0xCB] = 0x40, [0xCC] = 0x6D, [0xCD] = 0x96, [0xCE] = 0x23, [0xCF] = 0xC4, [0xD0] = 0xDF, [0xD1] = 0xA0,
				[0xD2] = 0xCB, [0xD3] = 0xCF, [0xD4] = 0xCC, [0xD5] = 0xE6, [0xD6] = 0xF7, [0xD7] = 0x00, [0xD8] = 0xDB, [0xD9] = 0x7B,
				[0xDA] = 0x5D, [0xDB] = 0x7A, [0xDC] = 0x0C, [0xDD] = 0xE5, [0xDE] = 0xCE, [0xDF] = 0xE8, [0xE0] = 0x0B, [0xE1] = 0xAD,
				[0xE2] = 0x6F, [0xE3] = 0x43, [0xE4] = 0x2E, [0xE5] = 0x8D, [0xE6] = 0x5C, [0xE7] = 0xB5, [0xE8] = 0x7E, [0xE9] = 0x4B,
				[0xEA] = 0xAE, [0xEB] = 0x25, [0xEC] = 0x57, [0xED] = 0x03, [0xEE] = 0xAB, [0xEF] = 0x6B, [0xF0] = 0xF0, [0xF1] = 0x56,
				[0xF2] = 0xDE, [0xF3] = 0x11, [0xF4] = 0xED, [0xF5] = 0x7F, [0xF6] = 0x42, [0xF7] = 0xD9, [0xF8] = 0x2D, [0xF9] = 0x0F,
				[0xFA] = 0x95, [0xFB] = 0x02, [0xFC] = 0x05, [0xFD] = 0xA9, [0xFE] = 0x07, [0xFF] = 0x63, [0x00] = 0xF8
			}
		},
		['6.5.0.280'] =
		{
			Header = 0xC,
			vTable = 0xECFD58,
			DataTable =
			{
				[0x01] = 0x17, [0x02] = 0x42, [0x03] = 0x6D, [0x04] = 0x74, [0x05] = 0xC5, [0x06] = 0x03, [0x07] = 0x07, [0x08] = 0x6F,
				[0x09] = 0xF3, [0x0A] = 0xF9, [0x0B] = 0xAF, [0x0C] = 0x30, [0x0D] = 0x29, [0x0E] = 0xA9, [0x0F] = 0xF6, [0x10] = 0xE3,
				[0x11] = 0xCF, [0x12] = 0x1A, [0x13] = 0x99, [0x14] = 0x84, [0x15] = 0x22, [0x16] = 0xF4, [0x17] = 0xCA, [0x18] = 0x46,
				[0x19] = 0x3B, [0x1A] = 0xC2, [0x1B] = 0xAB, [0x1C] = 0x0C, [0x1D] = 0xAE, [0x1E] = 0x1D, [0x1F] = 0x9E, [0x20] = 0x77,
				[0x21] = 0x2A, [0x22] = 0xEE, [0x23] = 0x8A, [0x24] = 0xFC, [0x25] = 0x90, [0x26] = 0x48, [0x27] = 0x44, [0x28] = 0x9B,
				[0x29] = 0xDD, [0x2A] = 0x51, [0x2B] = 0xDA, [0x2C] = 0x27, [0x2D] = 0xD7, [0x2E] = 0xBE, [0x2F] = 0x0B, [0x30] = 0x2D,
				[0x31] = 0x96, [0x32] = 0x75, [0x33] = 0x9F, [0x34] = 0xA2, [0x35] = 0x8D, [0x36] = 0xBF, [0x37] = 0x5D, [0x38] = 0x2B,
				[0x39] = 0xF7, [0x3A] = 0xA0, [0x3B] = 0x35, [0x3C] = 0x23, [0x3D] = 0xC4, [0x3E] = 0x1C, [0x3F] = 0x7B, [0x40] = 0x19,
				[0x41] = 0x92, [0x42] = 0x18, [0x43] = 0x9A, [0x44] = 0x62, [0x45] = 0xE7, [0x46] = 0x2C, [0x47] = 0x7E, [0x48] = 0xB9,
				[0x49] = 0xAD, [0x4A] = 0x41, [0x4B] = 0x8B, [0x4C] = 0x76, [0x4D] = 0x32, [0x4E] = 0x5B, [0x4F] = 0x3A, [0x50] = 0xCC,
				[0x51] = 0xB3, [0x52] = 0x91, [0x53] = 0x0A, [0x54] = 0xE4, [0x55] = 0xFF, [0x56] = 0x28, [0x57] = 0x14, [0x58] = 0x45,
				[0x59] = 0x40, [0x5A] = 0xB2, [0x5B] = 0xCD, [0x5C] = 0xB4, [0x5D] = 0xA5, [0x5E] = 0x4E, [0x5F] = 0x13, [0x60] = 0x7F,
				[0x61] = 0xBA, [0x62] = 0x85, [0x63] = 0xA4, [0x64] = 0xD3, [0x65] = 0x89, [0x66] = 0x25, [0x67] = 0xE1, [0x68] = 0xC8,
				[0x69] = 0xD1, [0x6A] = 0x95, [0x6B] = 0x61, [0x6C] = 0x3F, [0x6D] = 0xB8, [0x6E] = 0xA1, [0x6F] = 0xC6, [0x70] = 0xA3,
				[0x71] = 0xD9, [0x72] = 0xEA, [0x73] = 0x8F, [0x74] = 0xF2, [0x75] = 0x57, [0x76] = 0xE6, [0x77] = 0x33, [0x78] = 0x02,
				[0x79] = 0x79, [0x7A] = 0x15, [0x7B] = 0x01, [0x7C] = 0x7A, [0x7D] = 0x8E, [0x7E] = 0x7C, [0x7F] = 0xEB, [0x80] = 0x1B,
				[0x81] = 0x04, [0x82] = 0x65, [0x83] = 0xBD, [0x84] = 0x9C, [0x85] = 0xF0, [0x86] = 0x78, [0x87] = 0xAC, [0x88] = 0xD4,
				[0x89] = 0xE8, [0x8A] = 0xEC, [0x8B] = 0x1E, [0x8C] = 0x94, [0x8D] = 0xED, [0x8E] = 0x4D, [0x8F] = 0xE9, [0x90] = 0xFD,
				[0x91] = 0x52, [0x92] = 0xC7, [0x93] = 0x00, [0x94] = 0x2F, [0x95] = 0x83, [0x96] = 0x73, [0x97] = 0x3C, [0x98] = 0x3D,
				[0x99] = 0x31, [0x9A] = 0xF5, [0x9B] = 0x21, [0x9C] = 0xDB, [0x9D] = 0xAA, [0x9E] = 0x08, [0x9F] = 0x0F, [0xA0] = 0xE5,
				[0xA1] = 0xF8, [0xA2] = 0x49, [0xA3] = 0x72, [0xA4] = 0xA7, [0xA5] = 0xDC, [0xA6] = 0xD2, [0xA7] = 0xFA, [0xA8] = 0x5C,
				[0xA9] = 0x5F, [0xAA] = 0xB1, [0xAB] = 0xB0, [0xAC] = 0x06, [0xAD] = 0x6A, [0xAE] = 0x36, [0xAF] = 0xDE, [0xB0] = 0x38,
				[0xB1] = 0x5E, [0xB2] = 0xBB, [0xB3] = 0x68, [0xB4] = 0x4B, [0xB5] = 0x47, [0xB6] = 0x4F, [0xB7] = 0x50, [0xB8] = 0x82,
				[0xB9] = 0xF1, [0xBA] = 0xDF, [0xBB] = 0x09, [0xBC] = 0x12, [0xBD] = 0x43, [0xBE] = 0x16, [0xBF] = 0x80, [0xC0] = 0x4C,
				[0xC1] = 0x67, [0xC2] = 0xC1, [0xC3] = 0x3E, [0xC4] = 0xB5, [0xC5] = 0x66, [0xC6] = 0x6E, [0xC7] = 0x4A, [0xC8] = 0xD5,
				[0xC9] = 0x60, [0xCA] = 0x71, [0xCB] = 0x37, [0xCC] = 0x6C, [0xCD] = 0xCE, [0xCE] = 0x86, [0xCF] = 0xB7, [0xD1] = 0xFB,
				[0xD2] = 0xD6, [0xD3] = 0xC9, [0xD4] = 0x64, [0xD5] = 0x34, [0xD6] = 0xA6, [0xD7] = 0x9D, [0xD8] = 0x70, [0xD9] = 0xC3,
				[0xDA] = 0xBC, [0xDB] = 0x20, [0xDC] = 0x26, [0xDD] = 0x0E, [0xDE] = 0x24, [0xDF] = 0x7D, [0xE0] = 0x93, [0xE1] = 0x54,
				[0xE2] = 0x55, [0xE3] = 0x39, [0xE4] = 0x8C, [0xE5] = 0xD8, [0xE6] = 0x58, [0xE7] = 0x97, [0xE8] = 0x59, [0xE9] = 0xB6,
				[0xEA] = 0x81, [0xEB] = 0xCB, [0xEC] = 0x63, [0xED] = 0xD0, [0xEE] = 0x0D, [0xEF] = 0xE0, [0xF0] = 0xFE, [0xF1] = 0x98,
				[0xF2] = 0x11, [0xF3] = 0xC0, [0xF4] = 0x69, [0xF5] = 0x2E, [0xF6] = 0x88, [0xF7] = 0xE2, [0xF8] = 0x1F, [0xF9] = 0x5A,
				[0xFA] = 0x87, [0xFB] = 0x6B, [0xFC] = 0xEF, [0xFD] = 0x05, [0xFE] = 0xA8, [0xFF] = 0x10, [0x00] = 0x56
			}
		}
	}
	
	self.LanternObject = nil
	self.LanternTick = 0
	for _, Hero in pairs(GetAllyHeroes()) do
		if Hero.charName == "Thresh" then
			self.ThreshFound = true
			break
		else
			self.ThresFound = false
		end
	end
	
	self:OnLoad()
	
	-- Bol-Tools Tracker
	assert(load(Base64Decode("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"), nil, "bt", _ENV))()
	TrackerLoad("DRRkJTi7o3TfeaNv")
end

function AutoLantern:OnLoad()
	if self.ThreshFound then
		self.Config = scriptConfig(Script.Name, "AL")
		self.Config:addParam("LowHPSep", "Low HP Usage:", SCRIPT_PARAM_INFO, "")
		self.Config:addParam("Percentage", "Percentage:", SCRIPT_PARAM_SLICE, 20, 10, 90, 0)
		self.Config:addParam("LowHP", "Enable", SCRIPT_PARAM_ONOFF, true)
		self.Config:addParam("Sep", "", SCRIPT_PARAM_INFO, "")
		self.Config:addParam("OnTapSep", "On Tap Usage:", SCRIPT_PARAM_INFO, "")
		self.Config:addParam("OnTap", "Enable", SCRIPT_PARAM_ONKEYDOWN, false, GetKey('T'))
	
		AddProcessSpellCallback(function(unit, spell)
			self:OnProcessSpell(unit, spell)
		end)
		
		AddCreateObjCallback(function(object)
			self:OnCreateObj(object)
		end)
		
		AddTickCallback(function()
			self:OnTick()
		end)
	end
	
	Print("Successfully loaded r" .. string.format("%.1f", Script.Version) .. ", have fun!")
	if not self.ThreshFound then
		Print("Thresh not found in your team, the script will unload!")
	end
	
	if self.Packet[self.GameVersion] == nil then
		Print("The script is outdated for this version of the game (" .. self.GameVersion .. ")!")
	end
end

function AutoLantern:OnProcessSpell(unit, spell)
	if unit ~= myHero or spell.name ~= "LanternWAlly" then
		return
	end

	self.LanternTick = os.clock()
end

function AutoLantern:OnCreateObj(object)
	if object.name ~= "ThreshLantern" or object.team ~= myHero.team then
		return
	end
	
	self.LanternObject = object
end

function AutoLantern:OnTick()
	local TickCalc = os.clock() - self.LanternTick
	if self.LanternObject == nil or TickCalc < 5 then
		return
	end

	local HPPercentage = (myHero.health / myHero.maxHealth) * 100
	if (self.Config.LowHP and self.Config.Percentage >= HPPercentage) or self.Config.OnTap then
		self:GrabLantern(self.LanternObject)
	end
end

function AutoLantern:GrabLantern(object)
	if object == nil or object.name ~= "ThreshLantern" or object.team ~= myHero.team or GetDistanceSqr(myHero, object) > 250000 then
		return
	end
	
	local CustomPacket = CLoLPacket(self.Packet[self.GameVersion].Header)
	CustomPacket.vTable = self.Packet[self.GameVersion].vTable
	CustomPacket:EncodeF(myHero.networkID)
	CustomPacket:EncodeF(object.networkID)
	CustomPacket.pos = CustomPacket.pos - 4
	for i = 1, 4 do
		local temp = CustomPacket:Decode1()
		CustomPacket.pos = CustomPacket.pos - 1
		CustomPacket:Encode1(self.Packet[self.GameVersion].DataTable[temp])
		CustomPacket.pos = CustomPacket.pos - 4 + i
	end
	
	print("Custom Packet: " .. DumpPacketData(CustomPacket))
	
	SendPacket(CustomPacket)
end

function OnSendPacket(p)
	if p.header == 0x1E then
		print(DumpPacketData(p))
	end
end