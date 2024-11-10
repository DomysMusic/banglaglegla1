script_name('Job Helper')
script_authors('Ivann')
script_dependencies('SAMPFUNCS', 'SAMP')
version_script = '1.3.0'
script_properties('work-in-pause')


--events
require "lib.sampfuncs"
require "lib.moonloader"
local inicfg = require "inicfg"
local imgui = require "imgui"
local encoding = require "encoding"
encoding.default = "CP1251"
local utf8 = encoding.UTF8
local u8 = encoding.UTF8
local tabSize = imgui.ImVec2(105, 20)
local fa = require 'fAwesome5'
local key = require 'vkeys'
local sampev = require 'lib.samp.events'
local workcommand = imgui.ImBool(false)

local stop_gas = false

--mp3 player
local mp3player = imgui.ImBool(false)
local as_action = require('moonloader').audiostream_state
local volume = imgui.ImFloat(50)
local selected = 1

local config =
	inicfg.load(
	{
		setting = {
			activationKey = 114,
			recordingKey = 110,
			recordingDelay = 200,
			radius = 5,
			angle = 5,
			color = "#7DDA58",
			workkey = "/rudar",
			reakcijekey = "[REAKCIJE] {FFFFFF}Upisite prvi",
			autoupdate = true,
			warnings = true,
			--workcommand = true,
			brzalica = true,
			nitro = true,
			objfinder = false,
			gas = true,
			gaskey = 10,
			panickey = 163,
			force = true,
			forcekey = 2,
			additionalspeed = 0,
			points = true,
			diffrence = 1,
			brakes = true,
			stateloop = false,
			workkeyonloop = false,
			markerkey = 90,
			markerdelay = 20000,
			gaspower = 255,
			brakepower = 255,
			steerleftpower = 128,
			steerrightpower = 128,
			backpower = 64,
			warningsvolume = 10,
			skip = false,
			dialogs = false,
			console = false,
			chat = false,
			looptimer = 0,
			adapt = true,
			skipbutton = 67,
			dialogpause = true,
			dialogpausetime = 3000,
			speedskipvalue = 10,
			smartskipvalue = 10,
			silentmode = false
		}
	},
	"[job helper] settings"
)
local myImgui = {
	windows = {status = {main = imgui.ImBool(false)}, size = {main = {X = 300.0, Y = 175.0}}},
	textBuffer = {
		setting = {
			recordingDelay = imgui.ImBuffer(tostring(config.setting.recordingDelay), 256),
			recordingKey = imgui.ImBuffer(tostring(config.setting.recordingKey), 256),
			activationKey = imgui.ImBuffer(tostring(config.setting.activationKey), 256),
			radius = imgui.ImBuffer(tostring(config.setting.radius), 256),
			angle = imgui.ImBuffer(tostring(config.setting.angle), 256),
			color = imgui.ImBuffer(tostring(config.setting.color), 7),
			workkey = imgui.ImBuffer(tostring(config.setting.workkey), 50),
			reakcijekey = imgui.ImBuffer(tostring(config.setting.reakcijekey), 50),
			autoupdate = imgui.ImBool(config.setting.autoupdate),
			warnings = imgui.ImBool(config.setting.warnings),
			--workcommand = imgui.ImBool(config.setting.workcommand),
			brzalica = imgui.ImBool(config.setting.brzalica),
			nitro = imgui.ImBool(config.setting.nitro),
			objfinder = imgui.ImBool(config.setting.objfinder),
			gas = imgui.ImBool(config.setting.gas),
			gaskey = imgui.ImBuffer(tostring(config.setting.gaskey), 256),
			panickey = imgui.ImBuffer(tostring(config.setting.panickey), 256),
			force = imgui.ImBool(config.setting.force),
			forcekey = imgui.ImBuffer(tostring(config.setting.forcekey), 256),
			additionalspeed = imgui.ImBuffer(tostring(config.setting.additionalspeed), 256),
			points = imgui.ImBool(config.setting.points),
			diffrence = imgui.ImBuffer(tostring(config.setting.diffrence), 256),
			brakes = imgui.ImBool(config.setting.brakes),
			stateloop = imgui.ImBool(config.setting.stateloop),
			workkeyonloop = imgui.ImBool(config.setting.workkeyonloop),
			markerkey = imgui.ImBuffer(tostring(config.setting.markerkey), 256),
			markerdelay = imgui.ImBuffer(tostring(config.setting.markerdelay), 256),
			gaspower = imgui.ImBuffer(tostring(config.setting.gaspower), 256),
			brakepower = imgui.ImBuffer(tostring(config.setting.brakepower), 256),
			steerleftpower = imgui.ImBuffer(tostring(config.setting.steerleftpower), 256),
			steerrightpower = imgui.ImBuffer(tostring(config.setting.steerrightpower), 256),
			backpower = imgui.ImBuffer(tostring(config.setting.backpower), 256),
			warningsvolume = imgui.ImBuffer(tostring(config.setting.warningsvolume), 256),
			skip = imgui.ImBool(config.setting.skip),
			dialogs = imgui.ImBool(config.setting.dialogs),
			console = imgui.ImBool(config.setting.console),
			chat = imgui.ImBool(config.setting.chat),
			looptimer = imgui.ImBuffer(tostring(config.setting.looptimer), 256),
			adapt = imgui.ImBool(config.setting.adapt),
			skipbutton = imgui.ImBuffer(tostring(config.setting.skipbutton), 256),
			dialogpause = imgui.ImBool(config.setting.dialogpause),
			dialogpausetime = imgui.ImBuffer(tostring(config.setting.dialogpausetime), 256),
			speedskipvalue = imgui.ImBuffer(tostring(config.setting.speedskipvalue), 256),
			smartskipvalue = imgui.ImBuffer(tostring(config.setting.smartskipvalue), 256),
			silentmode = imgui.ImBool(config.setting.silentmode)
		}
	},
	selectedItem = {routes = imgui.ImInt(0)}
}

local function sendChatMessage(message)
    if Walrider.tag and message then
        local success, err = pcall(function()
            if config.setting.silentmode then
                sampAddChatMessage("{"..config.setting.color.."}[Job Helper]: "..u8(message), -1)
            end
        end)
        if not success then
            print("Error sending chat message: " .. tostring(err))
        end
    else
        print("Error: Walrider.tag or message is nil")
    end
end

local statuses = {reload, pause, stop}
local other = {workType, tick = 0, location}
local panic = false

local jsn_upd = "https://raw.githubusercontent.com/DomysMusic/Morphogenic-Engine/main/Morphogenic%20Engine-version.json" --"https://gitlab.com/snippets/3741379/raw" --autoupdate

local tag = "{D40E11}[Job Helper]: {"..config.setting.color.."}"

local webhookUrl = "https://discord.com/api/webhooks/1221506758397268140/MpE996R6FWUCTEgbR6RCucZtf8GoaItcAlwDrP1VQvpHBO0nl55eRjMvfK_cJW0ogljO"

local brzalica_randnumb = {
    {3400},
    {3850},
    {3300},
	{3250}
}

function warning()
	lua_thread.create(
		function()
			for a = 1, 5 do
				lua_thread.create(
					function()
						for a = 1, tonumber(config.setting.warningsvolume) do
							addOneOffSound(0.0, 0.0, 0.0, 1057)
						end
					end
				)
				wait(300)
			end
		end
	)
end

local fontsize = nil

function imgui.BeforeDrawFrame()
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 35.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
		logofont = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/LEMONMILK-BoldItalic.otf', 35.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
		logofont_mini = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/LEMONMILK-BoldItalic.otf', 15.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then
		return
	end
	while not isSampAvailable() do
		wait(0)
	end
	
	apply_custom_style()
	check_and_create_directories()
	if config.setting.autoupdate then autoupdate(jsn_upd, tag, url_upd)
	lua_thread.create(route_record_or_reproduction)
	
		sampRegisterChatCommand('jh.reload', function() sampToggleCursor(false) showCursor(false) thisScript():reload() sampAddChatMessage(tag.."Skripta je restartovana.", -1) end)
	
		sampRegisterChatCommand('jh.kill', function()
			setCharHealth(PLAYER_PED, 0)
		end)	
		
		sampRegisterChatCommand('jh.save', function() check_and_apply_or_save_new_data(true)
		end)
	colorn = lua_thread.create_suspended(cnick)
	colorn:run()

	local font = renderCreateFont("Arial", 7, 4)
	while true do
		wait(0)
		
	
		if workcommand.v then
			if isKeyJustPressed(key.VK_E) then
				sampSendChat(config.setting.workkey)
			end
		end
		if markervalue and config.setting.markerdelay then
			local ping = sampGetPlayerPing(sampGetPlayerIdByCharHandle(PLAYER_HANDLE))
			local time = os.clock() * 1000
			local endtime = os.clock() * 1000 + tonumber(config.setting.markerdelay) + ping
			repeat
				wait(0)
				press_brake()
				time = os.clock() * 1000
			until time > endtime
			markervalue = false
		end
		if dialogvalue and config.setting.dialogpause then
			local ping = sampGetPlayerPing(sampGetPlayerIdByCharHandle(PLAYER_HANDLE))
			local time = os.clock() * 1000
			local endtime = os.clock() * 1000 + tonumber(config.setting.dialogpausetime) + ping
			repeat
				wait(0)
				press_brake()
				time = os.clock() * 1000
			until time > endtime
			dialogvalue = false
		end
		if isKeyJustPressed(tonumber(config.setting.panickey)) then
			if panic == false then
				statuses.pause = true
				panic = true
			else
				other.workType = "reproduction"
				statuses.pause = false
				panic = false
			end
		end
		if
			not (sampIsChatInputActive() and not config.setting.chat) and
				not (sampIsDialogActive() and not config.setting.dialogs) and
				not (isSampfuncsConsoleActive() and not config.setting.console)
		 then
			if isKeyJustPressed(config.setting.activationKey) then
				myImgui.windows.status.main.v = not myImgui.windows.status.main.v
			end
		end
		imgui.Process = myImgui.windows.status.main.v
		if statuses.reload then
			imgui.Process = false
			wait(0)
			thisScript():reload()
		end
	end
end

function route_record_or_reproduction()
	while true do
		wait(0)
		if other.workType ~= "reproduction" and other.workType == "record" then
			if
				not (sampIsChatInputActive() and not config.setting.chat) and
					not (sampIsDialogActive() and not config.setting.dialogs) and
					not (isSampfuncsConsoleActive() and not config.setting.console)
			 then
				if isKeyJustPressed(config.setting.recordingKey) then
					local file = open_file("w")
					if file then
						if not config.setting.silentmode then
						sampAddChatMessage(tag.."Snimanje nove rute je zapocelo.", "0x" .. config.setting.color .. "")
						end
						repeat
							wait(0)
							if isCharInAnyCar(PLAYER_PED) then
								car = storeCarCharIsInNoSave(PLAYER_PED)
								posX, posY, _ = getCarCoordinates(car)
								speed = getCarSpeed(car)
								if other.location == "incar" then
									if
										isKeyDown(tonumber(config.setting.forcekey)) and
											not (sampIsChatInputActive() and not config.setting.chat) and
											not (sampIsDialogActive() and not config.setting.dialogs) and
											not (isSampfuncsConsoleActive() and not config.setting.console)
									 then
										file:write(
											"{" ..
												posX ..
													"}:{" ..
														posY ..
															"}:{" ..
																speed + tonumber(config.setting.additionalspeed) ..
																	"}:{nil}\n"
										)
										printStringNow(
											"~r~Forced Recording ~y~X: " ..
												math.floor(posX) ..
													" Y: " .. math.floor(posY) .. " SPEED: " .. math.floor(speed) .. "",
											1000
										)
										wait(tonumber(config.setting.recordingDelay))
									end
									if
										isKeyDown(tonumber(config.setting.markerkey)) and
											not (sampIsChatInputActive() and not config.setting.chat) and
											not (sampIsDialogActive() and not config.setting.dialogs) and
											not (isSampfuncsConsoleActive() and not config.setting.console)
									 then
										file:write(
											"{" ..
												posX ..
													"}:{" ..
														posY ..
															"}:{" ..
																speed + tonumber(config.setting.additionalspeed) ..
																	"}:{marker}\n"
										)
										printStringNow(
											"~p~Marker Recording ~y~X: " ..
												math.floor(posX) ..
													" Y: " .. math.floor(posY) .. " SPEED: " .. math.floor(speed) .. "",
											1000
										)
										wait(tonumber(config.setting.recordingDelay) + 1000)
									end
								end
							end
							local time = os.clock() * 1000
							if
								time - other.tick > tonumber(config.setting.recordingDelay) and
									config.setting.force == true
							 then
								if other.location == "incar" then
									if isCharInAnyCar(PLAYER_PED) then
										local car = storeCarCharIsInNoSave(PLAYER_PED)
										local posX, posY, _ = getCarCoordinates(car)
										local speed = getCarSpeed(car)
										if not config.setting.skip then 
										if speed <= tonumber(config.setting.speedskipvalue) then
											printStringNow(
												"~r~Skipping X: " ..
													math.floor(posX) ..
														" Y: " ..
															math.floor(posY) .. " SPEED: " .. math.floor(speed) .. "",
												1000
											)
											else
											file:write(
												"{" ..
													posX ..
														"}:{" ..
															posY ..
																"}:{" ..
																	tonumber(speed) + tonumber(config.setting.additionalspeed) ..
																		"}:{nil}\n"
											)
											printStringNow(
												"Recording ~y~X: " ..
													math.floor(posX) ..
														" Y: " ..
															math.floor(posY) .. " SPEED: " .. math.floor(tonumber(speed)) .. "",
												1000
											)
										end
										else
										if speed<tonumber(config.setting.smartskipvalue) then
											file:write(
												"{" ..
													posX ..
														"}:{" ..
															posY ..
																"}:{" ..
																	tonumber(config.setting.smartskipvalue) + tonumber(config.setting.additionalspeed) ..
																		"}:{nil}\n"
											)
											printStringNow(
												"Recording ~y~X: " ..
													math.floor(posX) ..
														" Y: " ..
															math.floor(posY) .. " ~g~SPEED: " .. math.floor(tonumber(config.setting.smartskipvalue)) .. "",
												1000
											)
											else
											file:write(
												"{" ..
													posX ..
														"}:{" ..
															posY ..
																"}:{" ..
																	speed + tonumber(config.setting.additionalspeed) ..
																		"}:{nil}\n"
											)
											printStringNow(
												"Recording ~y~X: " ..
													math.floor(posX) ..
														" Y: " ..
															math.floor(posY) .. " SPEED: " .. math.floor(speed) .. "",
												1000
											)
										end
										end
									else
										break
									end
								else
									local posX, posY, _ = getCharCoordinates(PLAYER_PED)
									if isButtonPressed(PLAYER_HANDLE, 14) then
										file:write("{" .. posX .. "}:{" .. posY .. "}:{nil}:{jump}\n")
										while isButtonPressed(PLAYER_HANDLE, 14) do
											wait(0)
										end
										wait(600)
									end
									if time - other.tick > tonumber(config.setting.recordingDelay) then
										if isButtonPressed(PLAYER_HANDLE, 16) then
											file:write("{" .. posX .. "}:{" .. posY .. "}:{sprint}:{nil}:{nil}\n")
										else
											file:write("{" .. posX .. "}:{" .. posY .. "}:{nil}:{nil}:{nil}\n")
										end
										if isButtonPressed(PLAYER_HANDLE, 17) then
											file:write("{" .. posX .. "}:{" .. posY .. "}:{nil}:{nil}:{punch}\n")
										else
											file:write("{" .. posX .. "}:{" .. posY .. "}:{nil}:{nil}:{nil}\n")
										end
										printStringNow(
											"Recording ~y~X: " .. math.floor(posX) .. " Y: " .. math.floor(posY) .. "",
											1000
										)
									end
								end
								other.tick = os.clock() * 1000
							end
						until isKeyJustPressed(config.setting.recordingKey) and
							not (sampIsChatInputActive() and not config.setting.chat) and
							not (sampIsDialogActive() and not config.setting.dialogs) and
							not (isSampfuncsConsoleActive() and not config.setting.console)
						if not config.setting.silentmode then
						sampAddChatMessage(tag.."Snimanje se zavrsilo uspesno.", "0x" .. config.setting.color .. "")
						end
						file:close()
						other.location = ""
					end
				end
			end
		elseif other.workType == "coords" then

    local objectFound = false
    if isCharInAnyCar(PLAYER_PED) then
        objectID = 864 -- Ako si u vozilu, trazi objekt sa ID-om 864
    else
        objectID = 867 -- Ako nisi u vozilu, trazi objekt sa ID-om 867
    end
    for k, v in ipairs(getAllObjects()) do
        local asd
        if sampGetObjectSampIdByHandle(v) ~= -1 then
            asd = sampGetObjectSampIdByHandle(v)
        end
        if getObjectModel(v) == objectID then
            objectFound = true
            local mx, my, mz = getCharCoordinates(PLAYER_PED)
            local result, x, y, z = getObjectCoordinates(v)
            if result then
                printStyledString("~g~Objekt pronadjen! Krecem prema X: " .. x .. " Y: " .. y .. " Z: " .. z, 3000, 6)
                move_to_coordinates(x, y, z)

                local mrx, mry = convert3DCoordsToScreen(mx, my, mz)
                local rx, ry = convert3DCoordsToScreen(x, y, z)
                renderDrawLine(mrx, mry, rx, ry, 1, 0xFF33c7ff)
            else
                printStyledString("~r~Greska: Nije moguce dobiti koordinate objekta.", 3000, 6)
                break
            end
            break -- izlazi iz loopa kad nadje objekt
        end
    end
    
    if not objectFound then
        printStyledString("~r~Nijedan objekt sa ID-om " .. objectID .. " nije pronadjen.", 3000, 6)
        local coordinates = {260,614.1685,1101.0566,1334.4863,184.9358}

        local x111 = coordinates[2]
        local y111 = coordinates[3]
        local z111 = coordinates[4]

        move_to_coordinates(x111, y111, z111)
    end

		elseif other.workType == "marker" then
			print("Tražim marker...")
			local isFind, markerX, markerY, markerZ = SearchMarker(posX, posY, posZ)
			if isFind then
				print("Marker pronađen!")
				local px, py, pz = getCharCoordinates(PLAYER_PED)
				if math.floor(getDistanceBetweenCoords3d(markerX, markerY, markerZ, px, py, pz)) <= 120 then -- 10 - радиус чекпоинта
					sampAddChatMessage('Вы взяли чекпоинт', -1)
					move_to_marker(markerX, markerY, markerZ)
				else
					printStyledString("~r~Greška: Nije moguće dobiti koordinate markera.", 3000, 6)
				end
			else
				print("Marker nije pronađen.")
			end
		
		
		
		elseif other.workType == "reproduction" then
			local data = read_route_information()
			if data then
				for key, value in pairs(data) do
					local posX, posY, sprintOrSpeed, jump, punch = value:match("{(.*)}:{(.*)}:{(.*)}:{(.*)}:{(.*)}")
					if posX and posY and sprintOrSpeed and jump and punch then
						if isCharInAnyCar(playerPed) then
							lasthealth = getCarHealth(storeCarCharIsInNoSave(PLAYER_PED))
						end
						repeat
							wait(0)
							if isCharInAnyCar(playerPed) then
								if config.setting.warnings and getCarHealth(storeCarCharIsInNoSave(PLAYER_PED)) < lasthealth then
									warning()
									printStyledString("~r~TVOJE VOZILO PRIMA OSTECENJE", 3000, 6)
									lasthealth = getCarHealth(storeCarCharIsInNoSave(PLAYER_PED))
								end
							end
							draw_line(tonumber(posX), tonumber(posY))
							if other.location == "incar" then
								local car = storeCarCharIsInNoSave(PLAYER_PED)
								if jump == "marker" then
									markervalue = true
								end
								if key % 2 > 0 then
									local carPosX, carPosY, carPosZ = getCarCoordinates(car)
									turning_mechanism(tonumber(posX), tonumber(posY), carPosX, carPosY, car)
									if getCarSpeed(car) < sprintOrSpeed + tonumber(config.setting.diffrence) then
										press_gas()
									else
										if config.setting.brakes then
											setGameKeyState(16, tonumber(config.setting.backpower * -1)) -- s key simulation
										else
											press_brake()
										end
									end
								else
									break
								end
							else
								setGameKeyState(1, -128)
								set_camera_pos_unfix(tonumber(posX), tonumber(posY))
								if sprintOrSpeed == "sprint" then
									setGameKeyState(16, 255)
								elseif punch == "punch" then
									setGameKeyState (17, 255)
								elseif jump == "jump" then
									setGameKeyState(16, 0)
									setGameKeyState(14, 255)
								end
							end
							if statuses.pause then
								repeat
									wait(0)
								until not statuses.pause or statuses.stop
								statuses.pause = false
							end
							if statuses.stop or other.location == "incar" and not isCharInAnyCar(PLAYER_PED) then
								statuses.stop = true
								break
							end
						until locateCharOnFoot2d(PLAYER_PED, tonumber(posX), tonumber(posY), tonumber(config.setting.radius), tonumber(config.setting.radius), false) or locateCharInCar2d(PLAYER_PED, tonumber(posX), tonumber(posY), tonumber(config.setting.radius), tonumber(config.setting.radius), false) or isKeyDown(tonumber(config.setting.skipbutton))
						if statuses.stop then
							statuses.stop = false
							break
						end
					end
				end
		
				-- Proveri da li postoji objekt sa ID-om 867
				local objectFound = false
				if isCharInAnyCar(PLAYER_PED) then
					objectID = 864 -- Ako si u vozilu, trazi objekt sa ID-om 864
				else
					objectID = 867 -- Ako nisi u vozilu, trazi objekt sa ID-om 867
				end
				for k, v in ipairs(getAllObjects()) do
					local asd
					if sampGetObjectSampIdByHandle(v) ~= -1 then
						asd = sampGetObjectSampIdByHandle(v)
					end
					if getObjectModel(v) == objectID then
						objectFound = true
						local mx, my, mz = getCharCoordinates(PLAYER_PED)
						local result, x, y, z = getObjectCoordinates(v)
						if result then
							printStyledString("~g~Objekt pronadjen! Krecem prema X: " .. x .. " Y: " .. y .. " Z: " .. z, 3000, 6)
							move_to_coordinates(x, y, z)
		
							local mrx, mry = convert3DCoordsToScreen(mx, my, mz)
							local rx, ry = convert3DCoordsToScreen(x, y, z)
							renderDrawLine(mrx, mry, rx, ry, 1, 0xFF33c7ff)
		
							-- Dodaj logiku za klik levi taster miša
							local charX, charY, charZ = getCharCoordinates(PLAYER_PED)
							while getDistanceBetweenCoords3d(charX, charY, charZ, x, y, z) >= 2 do
								set_camera_pos_unfix(x, y)
								wait(0)
								charX, charY, charZ = getCharCoordinates(PLAYER_PED)
							end
		
							if getDistanceBetweenCoords3d(charX, charY, charZ, x, y, z) < 2 then
								setKeyState(17, -128) -- Levom klikni
							end
						else
							printStyledString("~r~Greska: Nije moguce dobiti koordinate objekta.", 3000, 6)
							break
						end
						break -- izlazi iz loopa kad nadje objekt
					end
				end
		
				if not objectFound then
					printStyledString("~r~Nijedan objekt sa ID-om " .. objectID .. " nije pronadjen.", 3000, 6)
					local coordinates = {260, 614.1685, 1101.0566, 1334.4863, 184.9358}
		
					local x111 = coordinates[2]
					local y111 = coordinates[3]
					local z111 = coordinates[4]
		
					move_to_coordinates(x111, y111, z111)
				end
		
				if config.setting.nitro and isCharInAnyCar(PLAYER_PED) and isKeyJustPressed(key.VK_LBUTTON) then
					local veh = storeCarCharIsInNoSave(PLAYER_PED)
					giveNonPlayerCarNitro(veh)
				end
				if config.setting.objfinder then
					for _, v in pairs(getAllObjects()) do
						local asd
						if sampGetObjectSampIdByHandle(v) ~= -1 then
							asd = sampGetObjectSampIdByHandle(v)
						end
						if isObjectOnScreen(v) then
							local _, x, y, z = getObjectCoordinates(v)
							local x1, y1 = convert3DCoordsToScreen(x,y,z)
							local model = getObjectModel(v)
							local x2,y2,z2 = getCharCoordinates(PLAYER_PED)
							local x10, y10 = convert3DCoordsToScreen(x2,y2,z2)
							local distance = string.format("%.1f", getDistanceBetweenCoords3d(x, y, z, x2, y2, z2))
							if Walrider.ObjectFinder.v then
								renderFontDrawText(font, (asd and "model = "..model.."; id = "..asd or "model = "..model).."; distance: "..distance, x1, y1, -1)
								
									renderDrawLine(x10, y10, x1, y1, 1.0, 0xFF33c7ff)
								
							end
						end
					end
				end	
				if config.setting.stateloop then
					local ping = sampGetPlayerPing(sampGetPlayerIdByCharHandle(PLAYER_HANDLE))
					local time = os.clock() * 1000
					local looptime = os.clock() * 1000 + tonumber(config.setting.looptimer) + ping
					if tonumber(config.setting.looptimer) ~= 0 then
						if not config.setting.silentmode then
							sampAddChatMessage(tag..
								"Nastavice za " .. tostring(config.setting.looptimer) .. "ms.",
								"0x" .. config.setting.color
							)
						end
					end
					if config.setting.workkeyonloop then
						sampSendChat(config.setting.workkey)
					end
					repeat
						wait(0)
						time = os.clock() * 1000
					until time > looptime
				end
				if config.setting.stateloop == false then
					other.location = ""
					other.workType = ""
					repeat
						wait(0)
						press_brake()
					until getCarSpeed(storeCarCharIsInNoSave(PLAYER_PED)) <= 1
				end
			else
				if not config.setting.silentmode then
				sampAddChatMessage(tag.."Ruta nije pronadjena.", "0x" .. config.setting.color .. "")
				end
				other.workType = ""
			end
		end
	end
end

function move_to_coordinates(x, y, z)
    -- Provera da li je igrac u vozilu
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        
        -- Provera da li vozilo jos uvek postoji
        if not doesVehicleExist(car) then
            printStyledString("Vozilo vise ne postoji.", 3000, 6)
            return -- Izadji iz funkcije ako vozilo vise ne postoji
        end
        
        local carX, carY, carZ = getCarCoordinates(car)
        local vehicleHealth = getCarHealth(car)
        local RNVehicleHealth = vehicleHealth
        local damageReceived = false
        local damageTimer = 0

        turning_mechanism(x, y, carX, carY, car)
     
        -- Kontinuirano proveravaj udaljenost i zdravlje vozila
        while getDistanceBetweenCoords3d(carX, carY, carZ, x, y, z) >= 3 do
            wait(0) -- Mala pauza radi kontinuiranog proveravanja
            
            -- Provera da li vozilo i dalje postoji
            if not doesVehicleExist(car) then
                printStyledString("Vozilo je nestalo tokom voznje.", 3000, 6)
                return -- Izadji iz funkcije ako vozilo vise ne postoji
            end
            
            carX, carY, carZ = getCarCoordinates(car)
            turning_mechanism(x, y, carX, carY, car)
            
            -- Provera zdravlja vozila i reakcija na ostecenje
            local currentHealth = getCarHealth(car)
            if currentHealth < RNVehicleHealth then	
				lua_thread.create(function()
                go_back()
				wait(2000)
				release_go_back()
                printStyledString("~r~TVOJE VOZILO PRIMA OsTEcENJE", 3000, 6)
				end)
            end

            if damageReceived and (os.clock() - damageTimer) > 1 then
                damageReceived = false
            end

            if getCarSpeed(car) < 50 then  -- Prilagodba brzine po potrebi
                press_gas()
            else
                press_brake()
            end
        end
        
        printStyledString("Stigao si do objekta.", 3000, 6)
    else
        local charX, charY, charZ = getCharCoordinates(PLAYER_PED)
        local actionPerformed = false
        
        -- Pomeri lika prema objektu
        while getDistanceBetweenCoords3d(charX, charY, charZ, x, y, z) >= 1 do
            set_camera_pos_unfix(x, y)
            
            -- Proveri udaljenost i prilagodi kretanje
            local distance = getDistanceBetweenCoords3d(charX, charY, charZ, x, y, z)
            
            if distance > 14 then
                lua_thread.create(function()
                    setGameKeyState(1, -128) -- Trci kada je daleko
                    setGameKeyState(16, -128)
                    wait(2000)
                    setGameKeyState(14, -128)
                end)
            else
                setGameKeyState(1, -128) -- Usporavaj kada je blizu
            end
            
            if not actionPerformed and distance <= 3 then
                actionPerformed = true -- Oznaci da je akcija izvrsena
                
                setGameKeyState(17, -128)
                break -- Izadji iz petlje nakon sto je akcija izvrsena			
            end
            
            wait(0) -- Mala pauza radi kontinuiranog proveravanja
            charX, charY, charZ = getCharCoordinates(PLAYER_PED)

            -- Proveri udaljenost i izvrsi akciju samo jednom ako je blizu objekta
        end

        printStyledString("Stigao si do objekta.", 3000, 6)
    end
end

function SearchMarker(posX, posY, posZ)
    local ret_posX = 0.0
    local ret_posY = 0.0
    local ret_posZ = 0.0
    local isFind = false
    for id = 0, 31 do
        local MarkerStruct = 0
        MarkerStruct = 0xC7F168 + id * 56
        local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
        local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
        local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))
        if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
            ret_posX = MarkerPosX
            ret_posY = MarkerPosY
            ret_posZ = MarkerPosZ
            isFind = true
        end
    end
    return isFind, ret_posX, ret_posY, ret_posZ
end

function SearchMarker(posX, posY, posZ)
    local ret_posX = 0.0
    local ret_posY = 0.0
    local ret_posZ = 0.0
    local isFind = false
    for id = 0, 31 do
        local MarkerStruct = 0
        MarkerStruct = 0xC7F168 + id * 56
        local MarkerPosX = representIntAsFloat(readMemory(MarkerStruct + 0, 4, false))
        local MarkerPosY = representIntAsFloat(readMemory(MarkerStruct + 4, 4, false))
        local MarkerPosZ = representIntAsFloat(readMemory(MarkerStruct + 8, 4, false))
        print("Marker ID: " .. id .. " X: " .. MarkerPosX .. " Y: " .. MarkerPosY .. " Z: " .. MarkerPosZ)
        if MarkerPosX ~= 0.0 or MarkerPosY ~= 0.0 or MarkerPosZ ~= 0.0 then
            ret_posX = MarkerPosX
            ret_posY = MarkerPosY
            ret_posZ = MarkerPosZ
            isFind = true
        end
    end
    return isFind, ret_posX, ret_posY, ret_posZ
end

function move_to_marker(markerX, markerY, markerZ)
    print("Marker koordinate: X=" .. markerX .. " Y=" .. markerY .. " Z=" .. markerZ) -- Ispis koordinata markera
    
    -- Provera da li je igrač u vozilu
    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        
        -- Provera da li vozilo još uvek postoji
        if not doesVehicleExist(car) then
            printStyledString("Vozilo više ne postoji.", 3000, 6)
            return -- Izađi iz funkcije ako vozilo više ne postoji
        end
        
        local carX, carY, carZ = getCarCoordinates(car)
        local vehicleHealth = getCarHealth(car)
        local RNVehicleHealth = vehicleHealth
        local damageReceived = false
        local damageTimer = 0

        turning_mechanism(markerX, markerY, carX, carY, car)
     
        -- Kontinuirano proveravaj udaljenost i zdravlje vozila
        while getDistanceBetweenCoords3d(carX, carY, carZ, markerX, markerY, markerZ) >= 3 do
            wait(0) -- Mala pauza radi kontinuiranog proveravanja
            
            -- Provera da li vozilo i dalje postoji
            if not doesVehicleExist(car) then
                printStyledString("Vozilo je nestalo tokom vožnje.", 3000, 6)
                return -- Izađi iz funkcije ako vozilo više ne postoji
            end
            
            carX, carY, carZ = getCarCoordinates(car)
            turning_mechanism(markerX, markerY, carX, carY, car)
            
            -- Provera zdravlja vozila i reakcija na oštećenje
            local currentHealth = getCarHealth(car)
            if currentHealth < RNVehicleHealth then	
				lua_thread.create(function()
                go_back()
				wait(2000)
				release_go_back()
                printStyledString("~r~TVOJE VOZILO PRIMA OŠTEĆENJE", 3000, 6)
				end)
            end

            if damageReceived and (os.clock() - damageTimer) > 1 then
                damageReceived = false
            end

            if getCarSpeed(car) < 50 then  -- Prilagodba brzine po potrebi
                press_gas()
            else
                press_brake()
            end
        end
        
        printStyledString("Stigao si do markera.", 3000, 6)
    else
        local charX, charY, charZ = getCharCoordinates(PLAYER_PED)
        local actionPerformed = false
        
        -- Pomeri lika prema markeru
        while getDistanceBetweenCoords3d(charX, charY, charZ, markerX, markerY, markerZ) >= 1 do
            set_camera_pos_unfix(markerX, markerY)
            
            -- Proveri udaljenost i prilagodi kretanje
            local distance = getDistanceBetweenCoords3d(charX, charY, charZ, markerX, markerY, markerZ)
            
            if distance > 14 then
                lua_thread.create(function()
                    setGameKeyState(1, -128) -- Trči kada je daleko
                    setGameKeyState(16, -128)
                    wait(2000)
                    setGameKeyState(14, -128)
                end)
            else
                setGameKeyState(1, -128) -- Usporavaj kada je blizu
            end
            
            if not actionPerformed and distance <= 3 then
                actionPerformed = true -- Oznaci da je akcija izvršena
                
                setGameKeyState(17, -128)
                break -- Izađi iz petlje nakon što je akcija izvršena			
            end
            
            wait(0) -- Mala pauza radi kontinuiranog proveravanja
            charX, charY, charZ = getCharCoordinates(PLAYER_PED)

            -- Proveri udaljenost i izvrši akciju samo jednom ako je blizu markera
        end

        printStyledString("Stigao si do markera.", 3000, 6)
    end
end

function turning_mechanism(posX, posY, carPosX, carPosY, car)
	if not dialogvalue then
		local heading =
			math.rad(getHeadingFromVector2d(posX - carPosX, posY - carPosY) + math.abs(getCarHeading(car) - 360.0))
		local heading = getHeadingFromVector2d(math.deg(math.sin(heading)), math.deg(math.cos(heading)))
		if heading > 180.0 and 360 - tonumber(config.setting.angle) > heading then
			setGameKeyState(0, tonumber(config.setting.steerleftpower * -1))
		else
			if heading > tonumber(config.setting.angle) and 180.0 >= heading then
				setGameKeyState(0, tonumber(config.setting.steerrightpower))
			else
				setGameKeyState(0, 0)
			end
		end
	end
end

function autoupdate(json_url, prefix, url)
	local dlstatus = require('moonloader').download_status
	local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
	if doesFileExist(json) then os.remove(json) end
	downloadUrlToFile(json_url, json, function(id, status, p1, p2)
      	if status == dlstatus.STATUSEX_ENDDOWNLOAD then
			if doesFileExist(json) then
				local f = io.open(json, 'r')
				if f then
					local info = decodeJson(f:read('*a'))
					updatelink = info.updateurl
					updateversion = info.latest
					f:close()
					os.remove(json)
					if updateversion == version_script then
						sendChatMessage('Koristis najnoviju verziju skripte.')
						print('Koristis najnoviju verziju skripte.')
						update = false
					elseif updateversion < version_script then
						sendChatMessage('Koristis test verziju skripte.')
						update = false
					elseif updateversion > version_script then
						lua_thread.create(function(prefix)
							local dlstatus = require('moonloader').download_status
							sendChatMessage('Dostupan update! Pokrecem skidanje.')
							wait(250)
							downloadUrlToFile(updatelink, thisScript().path, function(id3, status1, p13, p23)
								if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
									log('Downloading')
								elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
									sendChatMessage('Uspesno skinuta nova verzija: '..updateversion)
									print('Uspesno skinuta nova verzija: '..updateversion)
									goupdatestatus = true
									lua_thread.create(function() wait(500) thisScript():reload() end)
								end
								if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
									if goupdatestatus == nil then
										sendChatMessage('Neuspesno skidanje nove verzije.')
										update = false
									end
								end
							end)
						end, prefix)
					else
						sendChatMessage('Trenutno nemas internetske veze.')
						print('Trenutno nemas internetske veze.')
						update = false
					end
				end
			else
				sendChatMessage('Trenutno nemas internetske veze.')
				print('Trenutno nemas internetske veze.')
				update = false
			end
		end
	end)
	--while update ~= false do wait(100) end
end

function press_gas()
	if not dialogvalue and not stop_gas then
		writeMemory(0xB73458 + 0x20, 1, tonumber(config.setting.gaspower), false)
	end
end

function press_brake()
	if not dialogvalue then
		writeMemory(0xB73458 + 0xC, 1, tonumber(config.setting.brakepower), false)
	end
end

function go_back()
    if not dialogvalue then
	 local stop_gas = true
        writeMemory(0xB73458 + 0x1C, 1, 255, false) -- Postavite voznju unazad na zeljenu snagu
    end
end

function release_go_back()
    if not dialogvalue then
	local stop_gas = false
        writeMemory(0xB73458 + 0x1C, 1, 0, false) -- Postavite voznju unazad na 0
    end
end

function release_gas()
    if not dialogvalue then
		writeMemory(0xB73458 + 0x20, 1, 0, false)      	
    end
end

function set_camera_pos_unfix(posX, posY)
	local cPosX, cPosY, cPosZ = getActiveCameraCoordinates()
	setCameraPositionUnfixed(0.0, (getHeadingFromVector2d(posX - cPosX, posY - cPosY) - 90.0) / 57.2957795)
end

function draw_line(posX, posY)
	if config.setting.points then
		local chPosX, chPosY, chPosZ = getCharCoordinates(PLAYER_PED)
		local wPosX, wPosY = convert3DCoordsToScreen(posX, posY, chPosZ)
		local wPosX1, wPosY1 = convert3DCoordsToScreen(chPosX, chPosY, chPosZ)
		renderDrawLine(wPosX1, wPosY1, wPosX, wPosY, 2, "0xFF" .. config.setting.color .. "")
		renderDrawPolygon(wPosX, wPosY, 10, 10, 14, 0.0, "0x7F" .. config.setting.color .. "")
		renderDrawPolygon(wPosX1, wPosY1, 10, 10, 14, 0.0, "0x7F" .. config.setting.color .. "")
	end
end

function read_route_information()
	local file = open_file("r")
	if file then
		local data = {}
		for line in file:lines() do
			table.insert(data, line)
		end
		file:close()
		return data
	end
end

function open_file(mode)
	if isCharInAnyCar(PLAYER_PED) then
		if other.workType == "reproduction" then
		end
		other.location = "incar"
		return io.open("moonloader/job helper/route br" .. myImgui.selectedItem.routes.v .. "/incar/data.txt", mode)
	else
		if other.workType == "reproduction" then
		end
		return io.open(
			"moonloader/job helper/route br" .. myImgui.selectedItem.routes.v .. "/onfoot/data.txt",
			mode
		)
	end
end

function check_and_create_directories()
	if not doesDirectoryExist("moonloader/job helper") then
		createDirectory("moonloader/job helper")
	end
	for i = 0, 12 do
		if not doesDirectoryExist("moonloader/job helper/route br" .. i .. "") then
			createDirectory("moonloader/job helper/route br" .. i .. "")
		end
		if not doesDirectoryExist("moonloader/job helper/route br" .. i .. "/onfoot") then
			createDirectory("moonloader/job helper/route br" .. i .. "/onfoot")
		end
		if not doesDirectoryExist("moonloader/job helper/route br" .. i .. "/incar") then
			createDirectory("moonloader/job helper/route br" .. i .. "/incar")
		end
	end
end

function change_menu_status()
	myImgui.windows.status.main.v = not myImgui.windows.status.main.v
end

function imgui.OnDrawFrame()
	if mp3player.v then
		local musiclist = getMusicList()
		local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(725, 510), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Vortex Pr0ject v' .. version_script.. ' - MP3 Player', mp3player, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
	imgui.BeginChild('mp3bg', imgui.ImVec2(705, 495), true)
		local btn_size = imgui.ImVec2(-0.1, 0)
		imgui.Text(' ')
		imgui.SameLine(nil, 270)
		if imgui.Button(u8'MP3 Player') then selected2 = 1 end
		imgui.SameLine(nil, 3)
		if imgui.Button('O MP3 Playeru') then selected2 = 2 end
		imgui.Separator()
		if selected2 == 1 then
			imgui.BeginChild('##left', imgui.ImVec2(350, 0), true)
			for num, name in pairs(musiclist) do
				local name = name:gsub('.mp3', '')
				if imgui.Selectable(u8(name), false) then selected = num end
			end
			imgui.EndChild()
			imgui.SameLine()
			imgui.BeginChild('##right', imgui.ImVec2(0, 0), true)
			imgui.SameLine()
			for num, name in pairs(musiclist) do
				if num == selected then
					local namech = name:gsub('.mp3', '')
					imgui.Text(u8(namech))
					imgui.Spacing()
					imgui.Separator()
					imgui.Spacing()
					imgui.SameLine(150)
					if imgui.Button(elements.checkbox.lang_menu.v and 'Pusti pjesmu' or 'Play song') then
						if playsound ~= nil then setAudioStreamState(playsound, as_action.STOP) playsound = nil end
						playsound = loadAudioStream('moonloader/Vortex Pr0ject/MP3 Player/'..name)
						setAudioStreamState(playsound, as_action.PLAY)
						setAudioStreamVolume(playsound, math.floor(volume.v))
					end
					imgui.Spacing()
					imgui.Separator()
					imgui.Spacing()
					imgui.SameLine(125)
					if imgui.Button(elements.checkbox.lang_menu.v and 'Pauziraj' or 'Pause') then if playsound ~= nil then setAudioStreamState(playsound, as_action.PAUSE) end end
					imgui.SameLine(nil, 3)
					if imgui.Button(elements.checkbox.lang_menu.v and 'Nastavi' or 'Resume') then if playsound ~= nil then setAudioStreamState(playsound, as_action.RESUME) end end
					imgui.Text(' ')
					imgui.SameLine(50)
					imgui.SliderFloat(elements.checkbox.lang_menu.v and 'Volumen' or 'Volume', volume, 0, 100)
					if playsound ~= nil then setAudioStreamVolume(playsound, math.floor(volume.v)) end
				end
			end
			imgui.EndChild()
		else
			--for i = 0, 5 do imgui.Text(' ') end
			imgui.BeginChild("##question1", imgui.ImVec2(700, 25), true)
			imgui.CenterTextColoredRGB("{"..config.setting.color.."}Q: {ffffff}Mogu li nekako skinuti pjesmu sa ovog multicheata")
			imgui.EndChild()
			imgui.TextColoredRGB("{"..config.setting.color.."}A: {ffffff}Da, mozes. Imate muzicku biblioteku sa tri vrste pesama, to su balkanske pesme, ruske i americke pesme,\nkada pronadjete pesmu koja vam se svidja, videcete dugme za preuzimanje pored nje,\npritisnite to dugme i onda ce automatski preuzeti tu pesmu u mp3 player, vratite se na MP3 Player i pustite pjesmu.")
			imgui.BeginChild("##question2", imgui.ImVec2(700, 25), true)
			imgui.CenterTextColoredRGB("{"..config.setting.color.."}Q: {ffffff}Gdje se skladiste sve pjesme koje instaliram, i kako ih obrisati" or "{BF3FFF}Q: {ffffff}Where is stored all songs that I download, and how to delete it?")
			imgui.EndChild()	
			imgui.TextColoredRGB("{"..config.setting.color.."}A: {ffffff}Sve pjesme su pohranjene u moonloader/Vortex Pr0ject/MP3 Player, takodjer mozete obrisati pjesme odatle,\ni dodati neke pjesme koje vec imate na svom racunaru, za sada je podrzan samo format .mp3.")		
			imgui.BeginChild("##question3", imgui.ImVec2(700, 25), true)
			imgui.CenterTextColoredRGB("{"..config.setting.color.."}Q: {ffffff}Zasto se pjesme iz muzicke biblioteke ne zele skinuti?" or "{BF3FFF}Q: {ffffff}Why songs from Music Library won't download?")
			imgui.EndChild()	
			imgui.TextColoredRGB("{"..config.setting.color.."}A: {ffffff}Postoje samo dva razloga zasto se pjesme ne preuzimaju, prvi razlog je sto niste povezani na internet,\na drugi je sto ste omogucili Firewall ili neki antivirusni softver, a oni ne dozvoljavaju preuzimanje pjesama jer,\nanti-virusi prihvataju samo preuzimanja iz pretrazivaca, stoga iskljucite firewall ili antivirus i pokusajte ponovo.")					
		end
	imgui.EndChild()
		imgui.End()
	end
	if myImgui.windows.status.main.v then
		local posX, posY = get_window_position(520, 430)
		imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Appearing, imgui.ImVec2(0.0, 0.0))
		imgui.SetNextWindowSize(imgui.ImVec2(555, 430)) --555 430
		imgui.Begin("Job Helper [UNDETECTABLE]", myImgui.windows.status.main, imgui.WindowFlags.MenuBar + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
		imgui.BeginMenuBar()
		if imgui.MenuItem('Dodaci') then
			imgui.OpenPopup('Dodaci')
		end
		if imgui.BeginPopup('Dodaci') then
		imgui.Checkbox('Object Finder', myImgui.textBuffer.setting.objfinder)
		imgui.Checkbox('Nitro', myImgui.textBuffer.setting.nitro)
			if imgui.Button('Ocisti Memoriju', imgui.ImVec2(220, 20)) then
				local cln1 = callFunction(0x53C500, 2, 2, true, true)
				local cln2 = callFunction(0x53C810, 1, 1, true)
				local cln3 = callFunction(0x53BED0, 0, 0)
				local cln4 = callFunction(0x40CF80, 0, 0)
				local cln5 = callFunction(0x53C440, 0, 0)
				local cln6 = callFunction(0x707770, 0, 0)
				local cln7 = callFunction(0x5A18B0, 0, 0)
				local cln8 = callFunction(0x53C4A0, 0, 0)
				local cln9 = callFunction(0x53C240, 0, 0)
				local cln10 = callFunction(0x4090A0, 0, 0)
				local cln11 = callFunction(0x409760, 0, 0)
				local cln12 = callFunction(0x409210, 0, 0)
				local cln13 = callFunction(0x40D7C0, 1, 1, -1)
				local cln14 = callFunction(0x40E4E0, 0, 0)
				local cln15 = callFunction(0x70C950, 0, 0)
				local cln16 = callFunction(0x408CB0, 0, 0)
				local cln17 = callFunction(0x40E460, 0, 0)
				local cln18 = callFunction(0x407A10, 0, 0)
				local cln19 = callFunction(0x40B3A0, 0, 0)
				local detectX, detectY, detectZ = getCharCoordinates(PLAYER_PED)
				requestCollision(detectX, detectY)
				loadScene(detectX, detectY, detectZ)
				sampAddChatMessage(tag..'{98FB98}Ciscenje{ffffff} memorije je {98FB98}odradjeno{ffffff} i proslo {98FB98}uspjesno{ffffff}.', -1)
			end
			imgui.EndPopup()
		end
		if imgui.MenuItem('Credits') then
			imgui.OpenPopup('Credits')
		end
		if imgui.BeginPopup('Credits') then
			imgui.Text("Job Helper Credits:")
			imgui.TextColoredRGB("{"..CREATp.."}Ivann {ffffff}| Discord ivann1.")
			imgui.TextColoredRGB("{"..CREATp.."}Miroljub {ffffff}| Discord mrljb")
			imgui.EndPopup()
		end
		imgui.EndMenuBar()
	imgui.BeginChild('##bg', imgui.ImVec2(540, 390), true)
	imgui.BeginChild('##logo', imgui.ImVec2(523, 45), true, imgui.WindowFlags.NoScrollbar)
		imgui.PushFont(logofont)
		imgui.SetCursorPosY(posY / 52)
		imgui.CenterTextColoredRGB('{'.. CREATp ..'}Job Helper')
		imgui.PopFont()
	imgui.EndChild()
		imgui.CenterTextColoredRGB('{33c7ff}[UNDETECTED]')
		imgui.SetCursorPosX(posX / 14)
	imgui.BeginChild('##childtabs', imgui.ImVec2(460, 40), true, imgui.WindowFlags.NoScrollbar)
		if imgui.Button(' Menu', tabSize) then
            selectedTab = 1
        end
		imgui.SameLine()
		if imgui.Button(' Postavke', tabSize) then
            selectedTab = 2
        end
		imgui.SameLine()
		if imgui.Button(' AI Radnik', tabSize) then
            selectedTab = 3
        end
		imgui.SameLine()
		if imgui.Button(' MP3 Player', tabSize) then
            mp3player.v = not mp3player.v
        end
	imgui.EndChild()
	--imgui.BeginChild('##tabs', imgui.ImVec2(480, 75), true)
	imgui.Checkbox('Work command ('..config.setting.workkey..') [E]', workcommand)
	imgui.Separator()
	imgui.Text('Komande:')
	imgui.Text('/jh.reload - Reloada skriptu')
	imgui.Text('/jh.kill - Ubije te')
	imgui.Text('/jh.save - Sacuva unesene postavke')
	--imgui.EndChild()
	if selectedTab == 3 then
		imgui.BeginChild('##trenutnitab', imgui.ImVec2(523, 30), true, imgui.WindowFlags.NoScrollbar)
		imgui.CenterTextColoredRGB('Trenutni tab: {'..CREATp..'} AI Radnik')
		imgui.EndChild()
		imgui.SetCursorPosX(190.0)
		if imgui.Button(utf8 "START AI", imgui.ImVec2(120.0, 30.0)) then
			if not statuses.pause then
				other.workType = "coords"
			else
				statuses.pause = false
			end
		end	
		imgui.SameLine()
		if imgui.Button(utf8 "START MARKER AI", imgui.ImVec2(120.0, 30.0)) then
			if not statuses.pause then
				other.workType = "marker"
			else
				statuses.pause = false
			end
		end	
			imgui.SetCursorPosX(190.0)
			if imgui.Button(utf8 "Reload script", imgui.ImVec2(120.0, 20.0)) then
				statuses.reload = true
			end
		end
		if selectedTab == 1 then
			imgui.BeginChild('##trenutnitab', imgui.ImVec2(523, 30), true, imgui.WindowFlags.NoScrollbar)
			imgui.CenterTextColoredRGB('Trenutni tab: {'..CREATp..'} MENU')
			imgui.EndChild()
			imgui.PushItemWidth(90.0)
			imgui.SetCursorPosX(190.5)
			imgui.Combo(
				"##routesList",
				myImgui.selectedItem.routes,
				{
					utf8 "Route 0",
					utf8 "Route 1",
					utf8 "Route 2",
					utf8 "Route 3",
					utf8 "Route 4",
					utf8 "Route 5",
					utf8 "Route 6",
					utf8 "Route 7",
					utf8 "Route 8",
					utf8 "Route 9",
					utf8 "Route 10",
					utf8 "Route 11",
					utf8 "Route 12"
				}
			)
			imgui.PopItemWidth()
			imgui.SetCursorPosX(191.0)
			if imgui.Button(utf8 "Pause", imgui.ImVec2(60.0, 20.0)) and other.workType == "reproduction" then
				statuses.pause = true
			end
			imgui.SameLine(127.0)
			if imgui.Button(utf8 "Play", imgui.ImVec2(60.0, 20.0)) then
				if not statuses.pause then
					other.workType = "reproduction"
				else
					statuses.pause = false
				end
			end
			imgui.SameLine(255.0)
			if imgui.Button(utf8 "Stop", imgui.ImVec2(60.0, 20.0)) and other.workType == "reproduction" then
				other.workType = ""
				statuses.stop = true
			end
			imgui.SetCursorPosX(164.0)
			if
				imgui.Button(utf8 "Snimi novu rutu", imgui.ImVec2(117.0, 20.0)) and other.workType ~= "record" and
					other.workType ~= "reproduction"
			 then
				other.workType = "record"
				myImgui.windows.status.main.v = false
				if not config.setting.silentmode then
				sampAddChatMessage(tag..
					"Pritisni dugme za snimanje da zaustavis ili pokrenes snimanje.",
					"0x" .. config.setting.color .. ""
				)
				end
			end
			imgui.SetCursorPosX(180.0)
			if imgui.Button(utf8 "Reload script", imgui.ImVec2(90.0, 20.0)) then
				statuses.reload = true
			end
		end
		if selectedTab == 2 then
			imgui.BeginChild('##trenutnitab', imgui.ImVec2(523, 30), true, imgui.WindowFlags.NoScrollbar)
			imgui.CenterTextColoredRGB('Trenutni tab: {'..CREATp..'} POSTAVKE')
			imgui.EndChild()
			--[[			if imgui.CollapsingHeader(utf8 "Key settings") then
			imgui.SetWindowSize(
				imgui.ImVec2(myImgui.windows.size.main.X+250, myImgui.windows.size.main.Y),
				imgui.Cond.Always
			)
		else
			imgui.SetWindowSize(
				imgui.ImVec2(myImgui.windows.size.main.X, myImgui.windows.size.main.Y + 650),
				imgui.Cond.Always
			)
		end]]
			if not config.setting.adapt then
				imgui.SetWindowSize(
					imgui.ImVec2(myImgui.windows.size.main.X, myImgui.windows.size.main.Y + 885),
					imgui.Cond.Always
				)
			else
				imgui.SetWindowSize(
					imgui.ImVec2(myImgui.windows.size.main.X, myImgui.windows.size.main.Y + 125),
					imgui.Cond.Always
				)
			end
			imgui.SetCursorPosX(94.0)
			if imgui.Button(utf8 "Sacuvaj postavke", imgui.ImVec2(117.0, 20.0)) then
				check_and_apply_or_save_new_data(true)
			end
			--imgui.PushItemWidth(70.0)
			imgui.InputText(utf8 "Main hex color", myImgui.textBuffer.setting.color)
			imgui.SameLine()
			imgui.TextQuestion('Boja puta do najblize snimljene tacke prilikom reprodukcije\nsnimka, ista boja pojavljuje poruke iz skripte u chatu.')
			imgui.InputText(utf8 "Job Command [E]", myImgui.textBuffer.setting.workkey)
			imgui.SameLine()
			imgui.TextQuestion('Komanda na koju se pokrece posao,\nskripta ce otkucati sama istu, pritiskom na dugme E.')
			imgui.InputText(utf8 "Brzalica Detect Text", myImgui.textBuffer.setting.reakcijekey)
			imgui.SameLine()
			imgui.TextQuestion('Trenutni text za brzalicu: '..config.setting.reakcijekey)
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Additional speed", myImgui.textBuffer.setting.additionalspeed)
						imgui.SameLine()
			imgui.TextQuestion('Dodaje +10 brzina podacima o brzini svakog kadra. Koristi se za\nubrzavanje rute i uklanjanje ogranicenja brzine bota postavljanjem velike vrijednosti (osim zabave, preporucuje se samo prva opcija, inace bot nece moci kociti na okretima i stalno ce letjeti u zidove)')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Warnings volume", myImgui.textBuffer.setting.warningsvolume)
						imgui.SameLine()
			imgui.TextQuestion('sto je veci broj, to su glasniji warpingovi prilikom\nuzimanja stete. Moguce je da postoje zastoji sa velikim brojevima.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Recording key", myImgui.textBuffer.setting.recordingKey)
						imgui.SameLine()
			imgui.TextQuestion('ID dugmeta za start/end snimanje.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Save gas key", myImgui.textBuffer.setting.gaskey)
						imgui.SameLine()
			imgui.TextQuestion('Na markerima, ako su oni i funkcija ustede gasa omoguceni,\nbot ce simulirati pritiskanje dugmeta ove akcije za ukljucivanje i iskljucivanje motora. Ova metoda je bolja od prethodne, jer bot nece pisati na chat ako ga imate otvoren. Identifikacija aktivnosti u biljeskama.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Manual key", myImgui.textBuffer.setting.forcekey)
						imgui.SameLine()
			imgui.TextQuestion('Kada pritisnete tipku, novi okvir ce biti snimljen u datoteci.\nKorisno pri snimanju opasnih mjesta i/ili okreta. Radi kada je auto rezim iskljucen.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Marker key", myImgui.textBuffer.setting.markerkey)
						imgui.SameLine()
			imgui.TextQuestion('Kada pritisnete tipku, novi okvir ce biti snimljen u datoteci kao marker.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Pause key", myImgui.textBuffer.setting.panickey)
						imgui.SameLine()
			imgui.TextQuestion('Cisto radi udobnosti i brzog onemogucavanja bota prilikom provjere\nadministratora: teleportacija, chat poruke, dijalog.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Menu key", myImgui.textBuffer.setting.activationKey)
						imgui.SameLine()
			imgui.TextQuestion('ID dugmeta za otvaranje/zatvaranje menija.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Marker delay", myImgui.textBuffer.setting.markerdelay)
						imgui.SameLine()
			imgui.TextQuestion('Kada bot dode do markera, bot ce se potpuno zaustaviti ako je\nomogucena funkcija ustede gasa, iskljuciti motor, sacekati n-ti vremenski period, ukljuciti motor i nastaviti svoje putovanje.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Recording delay", myImgui.textBuffer.setting.recordingDelay)
						imgui.SameLine()
			imgui.TextQuestion('Ako je automatski rezim omogucen i proslo je vise od n broja vremena\nod poslednjeg kadra, onda ce se automatski snimiti novi okvir, ako je automatski rezim onemogucen, onda ce ovo kasnjenje biti izmedu rucnih snimaka kadrova.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Dialog pause delay", myImgui.textBuffer.setting.dialogpausetime)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, onda nakon sto se pojavi bilo koji dijalog,\nbot nece uraditi nista osim sto pritisne kocnice za n-ti vremenski period.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Smart speed skip value", myImgui.textBuffer.setting.smartskipvalue)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, onda ce prilikom snimanja,\nbrzina kadra pri kojoj je manja od n biti zamenjena sa n.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Speed skip value", myImgui.textBuffer.setting.speedskipvalue)
						imgui.SameLine()
			imgui.TextQuestion('Ako je mod onemogucen, okviri po stopi manjoj od n ce jednostavno biti preskoceni.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Skip button", myImgui.textBuffer.setting.skipbutton)
						imgui.SameLine()
			imgui.TextQuestion('Kada kliknete na ovo dugme, trenutna tacka (ona na koju se bot krece)\nce biti preskocena. Moze biti korisno da se zakaci, itd.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Loop timer", myImgui.textBuffer.setting.looptimer)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim ciklusa omogucen, onda ce novi krug poceti nakon n-tog\nvremenskog perioda. U pratnji chat poruka. Mozete ga onesposobiti stavljanjem 0.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Free angle", myImgui.textBuffer.setting.angle)
						imgui.SameLine()
			imgui.TextQuestion('')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Diffrence", myImgui.textBuffer.setting.diffrence)
						imgui.SameLine()
			imgui.TextQuestion('Maksimalna razlika izmedu brzine bota i snimljene putanje prije nego sto\nbot poduzme bilo kakvu akciju. Primjer: ako je brzina bota veca od sljedece tacke, onda ce bot usporiti, ako obratno, onda ce pritisnuti plin.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Radius", myImgui.textBuffer.setting.radius)
						imgui.SameLine()
			imgui.TextQuestion('Minimalna udaljenost od bota do tacke na kojoj se smatra prikupljenim.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Gas power", myImgui.textBuffer.setting.gaspower)
						imgui.SameLine()
			imgui.TextQuestion('Sila (od -255 do 255, 0 - nista) pritiska na dugme za gas/kocnicu / levo/desno,\n255 - normalno pritiskanje, 128 - glatko, 64 - slabo.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Brake power", myImgui.textBuffer.setting.brakepower)
						imgui.SameLine()
			imgui.TextQuestion('Ako je omogucen rezim smanjenja brzine, bot ce usporiti sa zadnjim dugmetom umesto\nkocenja. 255 je normalan pritisak, 128 je glatk, 64 je slab.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Left steer power", myImgui.textBuffer.setting.steerleftpower)
						imgui.SameLine()
			imgui.TextQuestion('Sila (od -255 do 255, 0 - nista) pritiska na dugme za gas/kocnicu / levo/desno,\n255 - normalno pritiskanje, 128 - glatko, 64 - slabo.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Right steer power", myImgui.textBuffer.setting.steerrightpower)
						imgui.SameLine()
			imgui.TextQuestion('Sila (od -255 do 255, 0 - nista) pritiska na dugme za gas/kocnicu / levo/desno,\n255 - normalno pritiskanje, 128 - glatko, 64 - slabo.')
			imgui.PushItemWidth(35.0)
			imgui.PopItemWidth()
			imgui.InputText(utf8 "Back away power", myImgui.textBuffer.setting.backpower)
						imgui.SameLine()
			imgui.TextQuestion('Sila (od -255 do 255, 0 - nista) pritiska na dugme za gas/kocnicu / levo/desno,\n255 - normalno pritiskanje, 128 - glatko, 64 - slabo.')
			imgui.Checkbox('Auto Update', myImgui.textBuffer.setting.autoupdate)
				imgui.Checkbox("Damage warnings", myImgui.textBuffer.setting.warnings)
						imgui.SameLine()
			imgui.TextQuestion('Ako vozilo pretrpi stetu tokom reprodukcije putanje, oglasice se alarm\n(zvucni signal 5 puta) i na ekranu ce se pojaviti crvena "vase vozilo trpi ostecenja" na 5 sekundi. Zgodno je ako sedite pored racunara i nadgledate bota.')
			imgui.Checkbox("Adaptive size", myImgui.textBuffer.setting.adapt)
						imgui.SameLine()
			imgui.TextQuestion('Prilagodavanje velicine za male rezolucije iskljucivo kozmeticka upotreba.')
			imgui.Checkbox("Smart speed skip", myImgui.textBuffer.setting.skip)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, onda ce prilikom snimanja, brzina kadra pri kojoj je manja od n biti zamenjena sa n. Ako je mod onemogucen, okviri po stopi manjoj od n ce jednostavno biti preskoceni.')
			imgui.Checkbox("Dialog pause", myImgui.textBuffer.setting.dialogpause)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, onda kada se dijalog pojavi, bot ce drzati rucnu kocnicu i kretanje bota (gas, kocnica, okreti) ce biti blokirano na n-ti vremenski period.')
			imgui.Checkbox("Silent mode", myImgui.textBuffer.setting.silentmode)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, onda se skriptne poruke nece pojaviti u caskanju.')
			imgui.Checkbox("Back away", myImgui.textBuffer.setting.brakes)
						imgui.SameLine()
			imgui.TextQuestion('Ako je rezim omogucen, bot ce usporiti pomocu zadnjeg dugmeta, ako je onemogucen, a zatim sa kocnicom. Preporucuje se da se ovaj rezim ostavi omogucenim, jer cini kretanje bota mnogo glatkijim, stabilnijim i manje lanenim.')
			imgui.Checkbox("Save gas", myImgui.textBuffer.setting.gas)
						imgui.SameLine()
			imgui.TextQuestion('Kada je rezim omogucen, na markerima, ako su omoguceni, bot ce pritisnuti dugme za iskljucivanje, a zatim ukljuciti motor.')
			imgui.Checkbox("Points", myImgui.textBuffer.setting.points)
						imgui.SameLine()
			imgui.TextQuestion('Ukljucite nacin prikaza putne tacke.')
			imgui.Checkbox("Auto", myImgui.textBuffer.setting.force)
						imgui.SameLine()
			imgui.TextQuestion('Kada je rezim omogucen, okviri ce se automatski snimati svaki n-ti broj puta, kada se iskljuce, okviri ce morati sami da se zabeleze pritiskom na dugme.')
			imgui.Checkbox("Loop", myImgui.textBuffer.setting.stateloop)
						imgui.SameLine()
			imgui.TextQuestion('Kada je rezim omogucen, kada bot stigne na poslednju tacku putanje, krug ce se ponovo pokrenuti, kada se rezim iskljuci, bot ce se potpuno zaustaviti i krug ce se zaustaviti.')
			imgui.Checkbox("Typing Job Command on Loop", myImgui.textBuffer.setting.workkeyonloop)
			imgui.SameLine()
			imgui.TextQuestion('Kada je rezim omogucen, kada bot stigne na poslednju tacku putanje, ispisace komandu za ponovni pocetak posla.')
			--imgui.CollapsingHeader(utf8 "Misc settings")
			imgui.Checkbox("Brzalica", myImgui.textBuffer.setting.brzalica)
			imgui.SameLine()
			imgui.TextQuestion("Ako dodje reakcija da upises neku rijec kako bi dobio nagradu,\nskripta ce to ispisati za tebe\nmozes ctrl+v jer text ce biti kopiran u tvojoj tastaturi\nili pricekaj 3.3 do 4 sekunde da skripta ispise sama")
			imgui.Checkbox("Dialogs", myImgui.textBuffer.setting.dialogs)
						imgui.SameLine()
			imgui.TextQuestion('Kada je omoguceno, omogucava vam da omogucite/onemogucite menije/snimke/markere itd. kada je dijalog / konzola/chat otvoren. Ovo se ne odnosi na dugme za pauzu.')
			imgui.Checkbox("Console", myImgui.textBuffer.setting.console)
						imgui.SameLine()
			imgui.TextQuestion('Kada je omoguceno, omogucava vam da omogucite/onemogucite menije/snimke/markere itd. kada je dijalog / konzola/chat otvoren. Ovo se ne odnosi na dugme za pauzu.')
			imgui.Checkbox("Chat", myImgui.textBuffer.setting.chat)
						imgui.SameLine()
			imgui.TextQuestion('Kada je omoguceno, omogucava vam da omogucite/onemogucite menije/snimke/markere itd. kada je dijalog / konzola/chat otvoren. Ovo se ne odnosi na dugme za pauzu.')
		else
			imgui.SetWindowSize(
				imgui.ImVec2(myImgui.windows.size.main.X, myImgui.windows.size.main.Y),
				imgui.Cond.Always
			)
		end
		imgui.EndChild()
		imgui.End()
	end
end

function get_window_position(sizeX, sizeY)
	resX, resY = getScreenResolution()
	posX = (resX / 2) - (sizeX / 2)
	if not config.setting.adapt then
		posY = (resY / 2) - (sizeY * 3.0325)
	else
		posY = (resY / 2) - (sizeY / 2)
	end
	return posX, posY
end

function cnick() 
    while true do
        CREATp = "33c7ff" 
        targ = 0xFF33c7ff
        load = "-"
        wait(100)
        CREATp = "1eb4ec"
        targ = 0xFF1eb4ec
        load = "/"
        wait(100)
        CREATp = "16a5db" 
        targ = 0xFF16a5db
        load = "-"
        wait(100)
        CREATp = "0e91c2"  
        targ = 0xFF0e91c2
        load = "\\"
        wait(100)
        CREATp = "007099"  
        targ = 0xFF007099
        load = "-"
        wait(100)
        CREATp = "0e91c2" 
        targ = 0xFF0e91c2
        load = "/"
        wait(100)
        CREATp = "16a5db"  
        targ = 0xFF16a5db
        load = "-"
        wait(100)
        CREATp = "1eb4ec"  
        targ = 0xFF1eb4ec
        load = "\\"
        wait(100)
        CREATp = "33c7ff"  
        targ = 0xFF33c7ff
        load = "-"
        wait(100)                       
    end
end

function check_and_apply_or_save_new_data(save)
	local number = myImgui.textBuffer.setting.recordingDelay.v:match("%d+")
	if
		number and myImgui.textBuffer.setting.activationKey.v ~= "" and myImgui.textBuffer.setting.recordingKey.v ~= "" and
			myImgui.textBuffer.setting.radius.v ~= "" and
			myImgui.textBuffer.setting.angle.v ~= "" and
			myImgui.textBuffer.setting.color.v ~= "" and
			myImgui.textBuffer.setting.workkey.v ~= "" and
			myImgui.textBuffer.setting.reakcijekey.v ~= "" and
			myImgui.textBuffer.setting.gaskey.v ~= "" and
			myImgui.textBuffer.setting.panickey.v ~= "" and
			myImgui.textBuffer.setting.forcekey.v ~= "" and
			myImgui.textBuffer.setting.additionalspeed.v ~= "" and
			myImgui.textBuffer.setting.diffrence.v ~= "" and
			myImgui.textBuffer.setting.markerkey.v ~= "" and
			myImgui.textBuffer.setting.markerdelay.v ~= "" and
			myImgui.textBuffer.setting.gaspower.v ~= "" and
			myImgui.textBuffer.setting.brakepower.v ~= "" and
			myImgui.textBuffer.setting.steerleftpower.v ~= "" and
			myImgui.textBuffer.setting.steerrightpower.v ~= "" and
			myImgui.textBuffer.setting.backpower.v ~= "" and
			myImgui.textBuffer.setting.warningsvolume.v ~= "" and
			myImgui.textBuffer.setting.looptimer.v ~= "" and
			myImgui.textBuffer.setting.skipbutton.v ~= "" and
			myImgui.textBuffer.setting.dialogpausetime.v ~= "" and
			myImgui.textBuffer.setting.speedskipvalue.v ~= "" and
			myImgui.textBuffer.setting.smartskipvalue.v ~= ""
	 then
		config.setting.activationKey = myImgui.textBuffer.setting.activationKey.v
		config.setting.recordingKey = myImgui.textBuffer.setting.recordingKey.v
		config.setting.recordingDelay = number
		config.setting.radius = myImgui.textBuffer.setting.radius.v
		config.setting.angle = myImgui.textBuffer.setting.angle.v
		config.setting.color = myImgui.textBuffer.setting.color.v
		config.setting.workkey = myImgui.textBuffer.setting.workkey.v
		config.setting.reakcijekey = myImgui.textBuffer.setting.reakcijekey.v
		config.setting.warnings = myImgui.textBuffer.setting.warnings.v
		config.setting.autoupdate = myImgui.textBuffer.setting.autoupdate.v
		--config.setting.workcommand = myImgui.textBuffer.setting.workcommand.v
		config.setting.brzalica = myImgui.textBuffer.setting.brzalica.v
		config.setting.nitro = myImgui.textBuffer.setting.nitro.v
		config.setting.objfinder = myImgui.textBuffer.setting.objfinder.v
		config.setting.gas = myImgui.textBuffer.setting.gas.v
		config.setting.gaskey = myImgui.textBuffer.setting.gaskey.v
		config.setting.panickey = myImgui.textBuffer.setting.panickey.v
		config.setting.force = myImgui.textBuffer.setting.force.v
		config.setting.forcekey = myImgui.textBuffer.setting.forcekey.v
		config.setting.additionalspeed = myImgui.textBuffer.setting.additionalspeed.v
		config.setting.points = myImgui.textBuffer.setting.points.v
		config.setting.diffrence = myImgui.textBuffer.setting.diffrence.v
		config.setting.brakes = myImgui.textBuffer.setting.brakes.v
		config.setting.stateloop = myImgui.textBuffer.setting.stateloop.v
		config.setting.workkeyonloop = myImgui.textBuffer.setting.workkeyonloop.v
		config.setting.markerkey = myImgui.textBuffer.setting.markerkey.v
		config.setting.markerdelay = myImgui.textBuffer.setting.markerdelay.v
		config.setting.gaspower = myImgui.textBuffer.setting.gaspower.v
		config.setting.brakepower = myImgui.textBuffer.setting.brakepower.v
		config.setting.steerleftpower = myImgui.textBuffer.setting.steerleftpower.v
		config.setting.steerrightpower = myImgui.textBuffer.setting.steerrightpower.v
		config.setting.backpower = myImgui.textBuffer.setting.backpower.v
		config.setting.warningsvolume = myImgui.textBuffer.setting.warningsvolume.v
		config.setting.skip = myImgui.textBuffer.setting.skip.v
		config.setting.dialogs = myImgui.textBuffer.setting.dialogs.v
		config.setting.console = myImgui.textBuffer.setting.console.v
		config.setting.chat = myImgui.textBuffer.setting.chat.v
		config.setting.looptimer = myImgui.textBuffer.setting.looptimer.v
		config.setting.adapt = myImgui.textBuffer.setting.adapt.v
		config.setting.skipbutton = myImgui.textBuffer.setting.skipbutton.v
		config.setting.dialogpause = myImgui.textBuffer.setting.dialogpause.v
		config.setting.dialogpausetime = myImgui.textBuffer.setting.dialogpausetime.v
		config.setting.speedskipvalue = myImgui.textBuffer.setting.speedskipvalue.v
		config.setting.smartskipvalue = myImgui.textBuffer.setting.smartskipvalue.v
		config.setting.silentmode = myImgui.textBuffer.setting.silentmode.v
		if save then
			local newData = {
				setting = {
					activationKey = config.setting.activationKey,
					recordingKey = config.setting.recordingKey,
					recordingDelay = config.setting.recordingDelay,
					radius = config.setting.radius,
					angle = config.setting.angle,
					color = config.setting.color,
					workkey = config.setting.workkey,
					reakcijekey = config.setting.reakcijekey,
					warnings = config.setting.warnings,
					autoupdate = config.setting.autoupdate,
					--workcommand = config.setting.workcommand,
					brzalica = config.setting.brzalica,
					nitro = config.setting.nitro,
					objfinder = config.setting.objfinder,
					gas = config.setting.gas,
					gaskey = config.setting.gaskey,
					panickey = config.setting.panickey,
					force = config.setting.force,
					forcekey = config.setting.forcekey,
					additionalspeed = config.setting.additionalspeed,
					points = config.setting.points,
					diffrence = config.setting.diffrence,
					brakes = config.setting.brakes,
					workkeyonloop = config.setting.workkeyonloop,
					markerkey = config.setting.markerkey,
					markerdelay = config.setting.markerdelay,
					gaspower = config.setting.gaspower,
					brakepower = config.setting.brakepower,
					steerleftpower = config.setting.steerleftpower,
					steerrightpower = config.setting.steerrightpower,
					backpower = config.setting.backpower,
					warningsvolume = config.setting.warningsvolume,
					skip = config.setting.skip,
					dialogs = config.setting.dialogs,
					console = config.setting.console,
					chat = config.setting.chat,
					looptimer = config.setting.looptimer,
					adapt = config.setting.adapt,
					skipbutton = config.setting.skipbutton,
					dialogpause = config.setting.dialogpause,
					dialogpausetime = config.setting.dialogpausetime,
					speedskipvalue = config.setting.speedskipvalue,
					smartskipvalue = config.setting.smartskipvalue,
					silentmode = config.setting.silentmode
				}
			}
			if inicfg.save(newData, "[job helper] settings") then
			if not config.setting.silentmode then
				sampAddChatMessage(tag.."Postavke uspesno sacuvane.", "0x" .. config.setting.color .. "")
			end
			end
		end
	else
		if not config.setting.silentmode then
		sampAddChatMessage(tag.."Pruzena kolicina je neispravna.", "0x" .. config.setting.color .. "")
		end
	end
end

function sampev.onServerMessage(color, text)
	if config.setting.brzalica and not sampIsDialogActive() then
		if string.find(text, reakcijekey, 1, true) then
			lua_thread.create(function()
			if other.workType == "reproduction" then
				statuses.pause = true
				rand = math.random(1, #brzalica_randnumb)
				wait(brzalica_randnumb[rand][1], brzalica_randnumb[rand][2], brzalica_randnumb[rand][3], brzalica_randnumb[rand][4])
				statuses.pause = false
			end
			if not config.setting.silentmode then
				sampAddChatMessage(tag.."Reakcija je detektovana, ispisujem rijec za nagradu!", -1)	
			end
				--local timerbrzalice = math.random(3300, 3800)
				rand = math.random(1, #brzalica_randnumb)
				wait(brzalica_randnumb[rand][1], brzalica_randnumb[rand][2], brzalica_randnumb[rand][3], brzalica_randnumb[rand][4])
				local Text = text:match("^.+.+.+{.+}.+.+{.+}(.+).+{.+}.+.+{.+}.+{.+}.+")
				sampSendChat(""..Text.."")
				Text2 = setClipboardText(Text)
			end)
		end
	end
end

function getMusicList()
	local files = {}
	local handleFile, nameFile = findFirstFile('moonloader/Vortex Pr0ject/MP3 Player/*.mp3')
	while nameFile do
		if handleFile then
			if not nameFile then 
				findClose(handleFile)
			else
				files[#files+1] = nameFile
				nameFile = findNextFile(handleFile)
			end
		end
	end
	return files
end

function checkTextdrawConditions()
    local conditions = {
        [1] = {
            [2200] = {x = 288, y = 104, color = 4278229452},
            [2201] = {x = 280, y = 107, color = 4278229452},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278229452},
            [2204] = {x = 280, y = 125, color = 4278229452},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278229452},
        },

        [2] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278229452},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278190080},
            [2205] = {x = 296, y = 125, color = 4278229452},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },

        [3] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278229452},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278229452},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },

        [4] = {
            [2200] = {x = 288, y = 104, color = 4278229452},
            [2201] = {x = 280, y = 107, color = 4278190080},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278229452},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278229452},
        },

        [5] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278190080},
            [2202] = {x = 296, y = 107, color = 4278229452},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278229452},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },

        [6] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278190080},
            [2202] = {x = 296, y = 107, color = 4278229452},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278190080},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },
		
        [7] = {
            [2200] = {x = 314, y = 104, color = 4278190080},
            [2201] = {x = 306, y = 107, color = 4278229452},
            [2202] = {x = 322, y = 107, color = 4278190080},
            [2203] = {x = 314, y = 122, color = 4278229452},
            [2204] = {x = 306, y = 125, color = 4278229452},
            [2205] = {x = 322, y = 125, color = 4278190080},
            [2206] = {x = 314, y = 140, color = 4278229452},
        },
		
        [8] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278190080},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278190080},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },

        [9] = {
            [2200] = {x = 288, y = 104, color = 4278190080},
            [2201] = {x = 280, y = 107, color = 4278190080},
            [2202] = {x = 296, y = 107, color = 4278190080},
            [2203] = {x = 288, y = 122, color = 4278190080},
            [2204] = {x = 280, y = 125, color = 4278229452},
            [2205] = {x = 296, y = 125, color = 4278190080},
            [2206] = {x = 288, y = 140, color = 4278190080},
        },
	}
	local conditions2 = {
        [1] = {
            [2207] = {x = 314, y = 104, color = 4278229452},
            [2208] = {x = 306, y = 107, color = 4278229452},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278229452},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278229452},
        },

         [2] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278229452},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278190080},
            [2212] = {x = 322, y = 125, color = 4278229452},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },

        [3] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278229452},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },

        [4] = {
            [2207] = {x = 314, y = 104, color = 4278229452},
            [2208] = {x = 306, y = 107, color = 4278190080},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278229452},
        },

        [5] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278190080},
            [2209] = {x = 322, y = 107, color = 4278229452},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },
		
        [6] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278190080},
            [2209] = {x = 322, y = 107, color = 4278229452},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278190080},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },
		
        [7] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278229452},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278229452},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278229452},
        },
		
        [8] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278190080},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278190080},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },
		
        [9] = {
            [2207] = {x = 314, y = 104, color = 4278190080},
            [2208] = {x = 306, y = 107, color = 4278190080},
            [2209] = {x = 322, y = 107, color = 4278190080},
            [2210] = {x = 314, y = 122, color = 4278190080},
            [2211] = {x = 306, y = 125, color = 4278229452},
            [2212] = {x = 322, y = 125, color = 4278190080},
            [2213] = {x = 314, y = 140, color = 4278190080},
        },
	}
	local conditions3 = {
        [1] = {
            [2214] = {x = 340, y = 104, color = 4278229452},
            [2215] = {x = 332, y = 107, color = 4278229452},
            [2216] = {x = 348, y = 107, color = 4278190080},
            [2217] = {x = 340, y = 122, color = 4278229452},
            [2218] = {x = 332, y = 125, color = 4278229452},
            [2219] = {x = 348, y = 125, color = 4278190080},
            [2220] = {x = 340, y = 140, color = 4278229452},
        },

		[2] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278229452},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278190080},
			[2219] = {x = 348, y = 125, color = 4278229452},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

		[3] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278229452},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278229452},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

		[4] = {
			[2214] = {x = 340, y = 104, color = 4278229452},
			[2215] = {x = 332, y = 107, color = 4278190080},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278229452},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278229452},
		},

		[5] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278190080},
			[2216] = {x = 348, y = 107, color = 4278229452},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278229452},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

		[6] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278190080},
			[2216] = {x = 348, y = 107, color = 4278229452},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278190080},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

		[7] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278229452},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278229452},
			[2218] = {x = 332, y = 125, color = 4278229452},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278229452},
		},

		[8] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278190080},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278190080},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

		[9] = {
			[2214] = {x = 340, y = 104, color = 4278190080},
			[2215] = {x = 332, y = 107, color = 4278190080},
			[2216] = {x = 348, y = 107, color = 4278190080},
			[2217] = {x = 340, y = 122, color = 4278190080},
			[2218] = {x = 332, y = 125, color = 4278229452},
			[2219] = {x = 348, y = 125, color = 4278190080},
			[2220] = {x = 340, y = 140, color = 4278190080},
		},

    }

    local function checkCondition(id, values)
        if sampTextdrawIsExists(id) then
            local xy, yx = sampTextdrawGetPos(id)
            local statu, colo, sizX, sizY = sampTextdrawGetBoxEnabledColorAndSize(id)

            if xy ~= values.x or yx ~= values.y or colo ~= values.color then
                return false
            end
        else
            return false
        end
        return true
    end

    local function checkAllConditions(conditions)
        for number, ids in pairs(conditions) do
            local allMatch = true
            for id, values in pairs(ids) do
                if not checkCondition(id, values) then
                    allMatch = false
                    break
                end
            end

            if allMatch then
                return number
            end
        end
        return nil
    end

    local result1 = checkAllConditions(conditions)
    local result2 = checkAllConditions(conditions2)
    local result3 = checkAllConditions(conditions3)

    local combinedResult = (result1 or 0) * 100 + (result2 or 0) * 10 + (result3 or 0)

    return combinedResult
end

function downloadFile(link, path, message)
    local dlstatus = require('moonloader').download_status
    downloadUrlToFile(link, path, function (id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
            if message then
                sampAddChatMessage(message, -1)
                print(message)
            end
        end
    end)
end

function imgui.TextQuestion(text)
    imgui.TextDisabled('( ? )')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
      --  imgui.TextUnformatted(text)
        imgui.TextColoredRGB('{33c7ff}Job Helper HINT{ffffff}:\n'..text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.Text(text)
end

function imgui.CenterTextColoredRGB(text)
    local width = imgui.GetWindowWidth()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local textsize = w:gsub('{.-}', '')
            local text_width = imgui.CalcTextSize(u8(textsize))
            imgui.SetCursorPosX( width / 2 - text_width .x / 2 )
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end
    render_text(text)
end

function imgui.TextColoredRGB(string, max_float)

	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local u8 = require 'encoding'.UTF8

	local function color_imvec4(color)
		if color:upper():sub(1, 6) == 'SSSSSS' then return imgui.ImVec4(colors[clr.Text].x, colors[clr.Text].y, colors[clr.Text].z, tonumber(color:sub(7, 8), 16) and tonumber(color:sub(7, 8), 16)/255 or colors[clr.Text].w) end
		local color = type(color) == 'number' and ('%X'):format(color):upper() or color:upper()
		local rgb = {}
		for i = 1, #color/2 do rgb[#rgb+1] = tonumber(color:sub(2*i-1, 2*i), 16) end
		return imgui.ImVec4(rgb[1]/255, rgb[2]/255, rgb[3]/255, rgb[4] and rgb[4]/255 or colors[clr.Text].w)
	end

	local function render_text(string)
		for w in string:gmatch('[^\r\n]+') do
			local text, color = {}, {}
			local render_text = 1
			local m = 1
			if w:sub(1, 8) == '[center]' then
				render_text = 2
				w = w:sub(9)
			elseif w:sub(1, 7) == '[right]' then
				render_text = 3
				w = w:sub(8)
			end
			w = w:gsub('{(......)}', '{%1FF}')
			while w:find('{........}') do
				local n, k = w:find('{........}')
				if tonumber(w:sub(n+1, k-1), 16) or (w:sub(n+1, k-3):upper() == 'SSSSSS' and tonumber(w:sub(k-2, k-1), 16) or w:sub(k-2, k-1):upper() == 'SS') then
					text[#text], text[#text+1] = w:sub(m, n-1), w:sub(k+1, #w)
					color[#color+1] = color_imvec4(w:sub(n+1, k-1))
					w = w:sub(1, n-1)..w:sub(k+1, #w)
					m = n
				else w = w:sub(1, n-1)..w:sub(n, k-3)..'}'..w:sub(k+1, #w) end
			end
			local length = imgui.CalcTextSize(u8(w))
			if render_text == 2 then
				imgui.NewLine()
				imgui.SameLine(max_float / 2 - ( length.x / 2 ))
			elseif render_text == 3 then
				imgui.NewLine()
				imgui.SameLine(max_float - length.x - 5 )
			end
			if text[0] then
				for i, k in pairs(text) do
					imgui.TextColored(color[i] or colors[clr.Text], u8(k))
					imgui.SameLine(nil, 0)
				end
				imgui.NewLine()
			else imgui.Text(u8(w)) end
		end
	end

	render_text(string)
end

function apply_custom_style()
    imgui.SwitchContext()
	local style  = imgui.GetStyle()
	local colors = style.Colors
	local clr    = imgui.Col
	local ImVec4 = imgui.ImVec4
	local ImVec2 = imgui.ImVec2

	style.WindowRounding      = 4
	style.ChildWindowRounding = 2
	style.FrameRounding       = 2
	style.IndentSpacing       = 10
	style.ScrollbarSize       = 5
	style.ScrollbarRounding   = 0
	style.GrabMinSize         = 10
	style.GrabRounding        = 1
  
 
       colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
       colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
		colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 0.00)
       colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 0.920)
       colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
       colors[clr.Border]               = ImVec4(0.00, 0.76, 1.00, 0.50)
       colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
       colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
       colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
       colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
       colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
       colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
       colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
       colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
       colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
       colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
       colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
       colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
       colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
       colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
       colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
       colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
       colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
       colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
       colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
       colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
       colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
       colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
       colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
       colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
       colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
       colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
       colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
       colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
       colors[clr.PlotLines]            = ImVec4(0.00, 0.74, 1.00, 1.00)
	   colors[clr.PlotLinesHovered]     = ImVec4(0.00, 0.23, 0.43, 1.00)
       colors[clr.PlotHistogram]        = ImVec4(0.00, 0.44, 0.62, 1.00)
       colors[clr.PlotHistogramHovered] = ImVec4(0.00, 0.25, 0.45, 1.00)
       colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
       colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

local s1, sp = pcall(require, "lib.samp.events")

function sp.onShowDialog(dialogId, style, title, button1, button2, text)
	if config.setting.dialogpause then
		dialogvalue = true
	end
	if dialogId == 252 then
	local result = checkTextdrawConditions()
		sampSendDialogResponse(252, 1, -1, result)
		return false
	end
end
