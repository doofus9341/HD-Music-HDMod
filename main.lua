meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local hdmod_script_id = "tilecode/hdmod"
local hdmod_version = "2.0.1"

bankmanagerlib = require("fmod_bank_manager")
libhdmod = import(hdmod_script_id, hdmod_version)
hdmusic = require("hdmusic")

local function init_music_pack()
	if libhdmod then
		print("loading music pack")
		hdmusic.load_func(function()
			print("registering music pack")
			libhdmod.register_hdmod_music_pack(hdmusic)
		end)
	end
end

set_callback(function()
	init_music_pack()
end, ON.SCRIPT_ENABLE)

set_callback(function()
	if libhdmod then
		print("unregistering and unloading music pack")
		libhdmod.unregister_hdmod_music_pack(hdmusic)

		hdmusic.unload_func()
	end
end, ON.SCRIPT_DISABLE)

init_music_pack()