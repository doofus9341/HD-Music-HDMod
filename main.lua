meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local hdmod_script_id = "tilecode/hdmod"
local hdmod_version = "2.0.1"

bankmanagerlib = require("fmod_bank_manager")
libhdmod = import(hdmod_script_id, hdmod_version)

local hdmusic = require("hdmusic")

if libhdmod then
	hdmusic.load_func(function()
		libhdmod.register_hdmod_music_pack(hdmusic)
	end)
end

set_callback(function()
	bankmanagerlib = require("fmod_bank_manager")

	hdmusic = require("hdmusic")

	libhdmod = import(hdmod_script_id, hdmod_version)

	if libhdmod then
		hdmusic.load_func(function()
			libhdmod.register_hdmod_music_pack(hdmusic)
		end)
	end
end, ON.SCRIPT_ENABLE)

set_callback(function()
	if libhdmod then
    	libhdmod.unregister_hdmod_music_pack(hdmusic)

		hdmusic.unload_func()
	end
end, ON.SCRIPT_DISABLE)
