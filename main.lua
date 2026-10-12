local hdmod_version <const> = "2.0.1"

---@diagnostic disable: lowercase-global
bankmanagerlib = require("fmod_bank_manager")
hdmod = import("tilecode/hdmod", hdmod_version)
hdmusic = require("hdmusic")

meta.name = "HD-Music-HDMod"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local mod_script_id <const> = get_id()

local on_menu_cb_id = nil

local music_pack_meta = {
	pack_name = "HDMusic",
	music_pack_format_version = 1.0,
	load_sample_data_func = function(notify_cb)
		if bankmanagerlib.bank_exists(hdmusic.banks.hdmusic.bank_path) then
			bankmanagerlib.load_bank_sample_data(
				hdmusic.banks.hdmusic.bank_path,
				hdmusic.banks.hdmusic.sampledata_load_func,
				function(statetype, loadstate)
					notify_cb(mod_script_id, statetype, loadstate)
					if statetype == bankmanagerlib.LOADING_STATE_TYPE.SAMPLEDATA then
						if loadstate == FMOD_LOADING_STATE.LOADED then
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
		else
			notify_cb(mod_script_id, bankmanagerlib.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end
	end,
	unload_sample_data_func = function()
		if not bankmanagerlib.bank_exists(hdmusic.banks.hdmusic.bank_path) then
			bankmanagerlib.unload_bank_sample_data(hdmusic.banks.hdmusic.bank_path)
		end

		if on_menu_cb_id then
			clear_callback(on_menu_cb_id)
			on_menu_cb_id = nil
		end
	end,
}

local function init_music_pack()
	if hdmod then
		if not bankmanagerlib.bank_exists(hdmusic.banks.hdmusic.bank_path) then
			bankmanagerlib.load_bank_metadata(hdmusic.banks.hdmusic.bank_path, hdmusic.banks.hdmusic.load_bank_flags, function()
				hdmod.register_hdmod_music_pack(mod_script_id, music_pack_meta, hdmusic)
			end, hdmusic.banks.hdmusic.unload_func)
		end
	end
end

set_callback(function()
	init_music_pack()
end, ON.SCRIPT_ENABLE)

set_callback(function()
	if hdmod then
		hdmod.unregister_hdmod_music_pack(mod_script_id)
	end
end, ON.SCRIPT_DISABLE)

init_music_pack()
