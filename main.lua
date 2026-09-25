local hdmod_version <const> = "2.0.1"

---@diagnostic disable: lowercase-global
bankmanagerlib = require("fmod_bank_manager")
hdmod = import("tilecode/hdmod", hdmod_version)
hdmusic = require("hdmusic")

meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local on_reset_cb_id = nil
local on_menu_cb_id = nil

function load_sample_data_func(notify_cb)
	for _, bank in pairs(hdmusic.banks) do
		if bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.load_bank_sample_data(
				bank.bank_path,
				bank.sampledata_load_func,
				function(statetype, loadstate)
					notify_cb(hdmusic, statetype, loadstate)
					if statetype == bankmanagerlib.LOADING_STATE_TYPE.SAMPLEDATA then
						if loadstate == FMOD_LOADING_STATE.LOADED then
							if on_reset_cb_id == nil then
								on_reset_cb_id = set_callback(function()
									hdmusic.level_track = 0.0
									hdmod.custommusiclib.clear_level_music()
								end, ON.RESET)
							end

							if on_menu_cb_id == nil then
								on_menu_cb_id = set_callback(function()
									if hdmusic.adventure_played then
										hdmusic.adventure_played = false
									end
								end, ON.MENU)
							end
						end
					end
				end
			)
		end
	end
end

function unload_sample_data_func()
	for _, bank in pairs(hdmusic.banks) do
		if not bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.unload_bank_sample_data(bank.bank_path)
		end
	end

	if on_reset_cb_id then
		clear_callback(on_reset_cb_id)
		on_reset_cb_id = nil
	end

	if on_menu_cb_id then
		clear_callback(on_menu_cb_id)
		on_menu_cb_id = nil
	end
end

local function init_music_pack()
	if hdmod then
		for _, bank in pairs(hdmusic.banks) do
			if not bankmanagerlib.bank_exists(bank.bank_path) then
				bankmanagerlib.load_bank_metadata(bank.bank_path, bank.load_bank_flags, function()
					hdmod.register_hdmod_music_pack(hdmusic, load_sample_data_func, unload_sample_data_func)
				end, bank.unload_func)
			end
		end
	end
end

set_callback(function()
	init_music_pack()
end, ON.SCRIPT_ENABLE)

set_callback(function()
	if hdmod then
		hdmod.unregister_hdmod_music_pack(hdmusic)
	end
end, ON.SCRIPT_DISABLE)

init_music_pack()
