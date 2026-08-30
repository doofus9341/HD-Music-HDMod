meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local bankmanagerlib = require("fmod_bank_manager")
local hdmusic = require("hdmusic")

local hdmod = import("tilecode/hdmod", "2.0.1")

local pack_load = function()
	bankmanagerlib.set_bank_sample_data_load_callback(hdmusic.pack_name, function()
		if hdmod then
			hdmod.on_hdmod_music_pack_loaded()
			bankmanagerlib.clear_bank_sample_data_load_callback(hdmusic.pack_name)
		end
	end)

    for _, bank in pairs(hdmusic.banks) do
		if not bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.load_fmod_bank(bank.bank_path, bank.load_bank_flags, bank.init_func, bank.cleanup_func)
		end
    end
end

local pack_unload = function()
	for _, bank in pairs(hdmod.banks) do
		bank.cleanup_func()
	end
	for _, bank in pairs(hdmod.banks) do
		bankmanagerlib.unload_fmod_bank(bank.bank_path)
	end
end

if hdmod then
	hdmod.register_hdmod_music_pack(hdmusic)
end

set_callback(function()
	if hdmod then
    	hdmod.unregister_music_pack(get_id())
	end
end, ON.SCRIPT_DISABLE)
