local hdmod_version <const> = "2.0.1"

---@diagnostic disable: lowercase-global
bankmanagerlib = require("fmod_bank_manager")
hdmod = import("tilecode/hdmod", hdmod_version)
hdmusic = require("hdmusic")

meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local function init_music_pack()
	if hdmod then
		hdmusic.load_func(function()
			hdmod.register_hdmod_music_pack(hdmusic)
		end)
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