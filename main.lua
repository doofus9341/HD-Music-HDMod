meta.name = "HDMod-HD-Music"
meta.version = "1.0.0"
meta.description = "Spelunky HD's music for HDMod"
meta.author = "Taffer"

local hdmusic = require("hdmusic")

local hdmod = import("tilecode/hdmod", "2.0.1")

if hdmod then
	hdmod.register_hdmod_music_pack(hdmusic)
end

set_callback(function()
	if hdmod then
    	hdmod.unregister_hdmod_music_pack(hdmusic)
	end
end, ON.SCRIPT_DISABLE)
