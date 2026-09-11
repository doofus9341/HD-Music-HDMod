local module = {}

module.pack_name = "HDMusic"

module.level_musics = {}

module.title_music = nil
module.credits_music = nil

module.MUSIC_FEELING_STORAGE = {}
module.MUSIC_PARAMETER_STORAGE = {}

module.adventure_played = false

-- Stores the track we selected a/b/c
module.level_track = 0.0

-- Stores the current levels shop type
module.shop_type = 0.0

module.debug_cb_id = nil
module.on_reset_cb_id = nil
module.on_menu_cb_id = nil

module.banks = {
	hdmusic = {
		bank_path = "banks/Desktop/HDMod_HD_Music.bank",
		load_bank_flags = FMOD_LOAD_BANK_FLAGS.NONBLOCKING,
		sampledata_load_func = function()
			module.title_music = {
				base_volume = 1.0,
				event_name = "hd_title_custom_music",
				event_description = get_event_by_id("{4dc3da1b-2232-4001-8be6-51d6db577477}"),
			}

			module.credits_music = {
				base_volume = 1.0,
				event_name = "hd_credits_custom_music",
				event_description = get_event_by_id("{629b9133-ec61-461d-be90-ca91b9efcd84}"),
				init_function = function(ctx)
					local winstate = state.win_state
					if winstate >= 0 and winstate < 4 then
						ctx.event_instance:set_parameter_by_name("win_state", winstate)
					end
				end,
			}

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_tutorial_custom_music",
					event_description = get_event_by_id("{95fcd4bd-5ef8-4637-a0b4-9b555e43e9dc}"),
					init_function = function(ctx)
						if module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"] == nil then
							module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"] = 1.0
						end

						ctx.event_instance:set_parameter_by_name(
							"hd_tutorial_journal",
							module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"]
						)
						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL
						and hdmod.worldlib.HD_WORLDSTATE_STATE == hdmod.worldlib.HD_WORLDSTATE_STATUS.TUTORIAL

					if should_play then
						module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
					elseif module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"] ~= nil then
						module.MUSIC_PARAMETER_STORAGE = {}
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_mines_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 1.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)

						ctx.event_instance:set_parameter_by_name("level_track", module.level_track)
						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end

						if module.MUSIC_PARAMETER_STORAGE["current_shop_type"] ~= module.shop_type then
							module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
							ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
						end
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL and state.theme == THEME.DWELLING

					if should_play then
						if test_flag(get_level_flags(), 18) then
							hdmod.custommusiclib.clear_level_music()
						end

						if not module.adventure_played then
							module.adventure_played = true
							module.level_track = 0.0
						elseif prng:random_index(100, PRNG_CLASS.FX) == 1 then
							module.level_track = 4.0
						elseif module.level_track < 1 or module.level_track > 3 then
							local new_level_track = prng:random_index(3, PRNG_CLASS.FX)

							if new_level_track ~= module.level_track then
								module.level_track = new_level_track
								hdmod.custommusiclib.clear_level_music()
							end
						end

						local shop_type = state.level_gen.shop_type
						if shop_type == SHOP_TYPE.HIRED_HAND_SHOP then
							module.shop_type = 4.0
						elseif shop_type == SHOP_TYPE.PET_SHOP then
							module.shop_type = 5.0
						elseif shop_type == SHOP_TYPE.DICE_SHOP then
							module.shop_type = 6.0
						else
							module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
						end
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_black_market_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("hdmod_level_feeling", 9.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL
						and hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.BLACKMARKET)
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_castle_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("hdmod_level_feeling", 10.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL
						and hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.HAUNTEDCASTLE)
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_restless_dead_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
						module.MUSIC_PARAMETER_STORAGE["rushing_water"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["player_depth"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)
						local player_depth = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.PLAYER_DEPTH)

						ctx.event_instance:set_parameter_by_name("hdmod_level_feeling", 5.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)

						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)

						module.MUSIC_PARAMETER_STORAGE["rushing_water"] = module.MUSIC_FEELING_STORAGE["rushing_water"]
						ctx.event_instance:set_parameter_by_name(
							"rushing_water",
							module.MUSIC_FEELING_STORAGE["rushing_water"]
						)
						module.MUSIC_PARAMETER_STORAGE["player_depth"] = player_depth
						ctx.event_instance:set_parameter_by_name("player_depth", player_depth)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end

						if module.MUSIC_PARAMETER_STORAGE["current_shop_type"] ~= module.shop_type then
							module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
							ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
						end

						if
							module.MUSIC_PARAMETER_STORAGE["rushing_water"]
							~= module.MUSIC_FEELING_STORAGE["rushing_water"]
						then
							module.MUSIC_PARAMETER_STORAGE["rushing_water"] =
								module.MUSIC_FEELING_STORAGE["rushing_water"]
							ctx.event_instance:set_parameter_by_name(
								"rushing_water",
								module.MUSIC_FEELING_STORAGE["rushing_water"]
							)
						end

						if module.MUSIC_FEELING_STORAGE["rushing_water"] == 1.0 then
							local player_depth = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.PLAYER_DEPTH)

							if module.MUSIC_PARAMETER_STORAGE["player_depth"] ~= player_depth then
								module.MUSIC_PARAMETER_STORAGE["player_depth"] = player_depth
								ctx.event_instance:set_parameter_by_name("player_depth", player_depth)
							end
						end
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL
						and hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.RESTLESS)
						and not test_flag(get_level_flags(), 18)

					if should_play then
						local shop_type = state.level_gen.shop_type
						if shop_type == SHOP_TYPE.HIRED_HAND_SHOP then
							module.shop_type = 4.0
						elseif shop_type == SHOP_TYPE.PET_SHOP then
							module.shop_type = 5.0
						elseif shop_type == SHOP_TYPE.DICE_SHOP then
							module.shop_type = 6.0
						else
							module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
						end

						module.MUSIC_FEELING_STORAGE = {}

						if hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.RUSHING_WATER) then
							module.MUSIC_FEELING_STORAGE["rushing_water"] = 1.0
						else
							module.MUSIC_FEELING_STORAGE["rushing_water"] = 0.0
						end
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_jungle_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
						module.MUSIC_PARAMETER_STORAGE["rushing_water"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["player_depth"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)
						local player_depth = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.PLAYER_DEPTH)

						ctx.event_instance:set_parameter_by_name("current_theme", 2.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)

						ctx.event_instance:set_parameter_by_name("level_track", module.level_track)
						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)

						module.MUSIC_PARAMETER_STORAGE["rushing_water"] = module.MUSIC_FEELING_STORAGE["rushing_water"]
						ctx.event_instance:set_parameter_by_name(
							"rushing_water",
							module.MUSIC_FEELING_STORAGE["rushing_water"]
						)
						module.MUSIC_PARAMETER_STORAGE["player_depth"] = player_depth
						ctx.event_instance:set_parameter_by_name("player_depth", player_depth)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end

						if module.MUSIC_PARAMETER_STORAGE["current_shop_type"] ~= module.shop_type then
							module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
							ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
						end

						if
							module.MUSIC_PARAMETER_STORAGE["rushing_water"]
							~= module.MUSIC_FEELING_STORAGE["rushing_water"]
						then
							module.MUSIC_PARAMETER_STORAGE["rushing_water"] =
								module.MUSIC_FEELING_STORAGE["rushing_water"]
							ctx.event_instance:set_parameter_by_name(
								"rushing_water",
								module.MUSIC_FEELING_STORAGE["rushing_water"]
							)
						end

						if module.MUSIC_FEELING_STORAGE["rushing_water"] == 1.0 then
							local player_depth = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.PLAYER_DEPTH)

							if module.MUSIC_PARAMETER_STORAGE["player_depth"] ~= player_depth then
								module.MUSIC_PARAMETER_STORAGE["player_depth"] = player_depth
								ctx.event_instance:set_parameter_by_name("player_depth", player_depth)
							end
						end
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL and state.theme == THEME.JUNGLE

					if should_play then
						if test_flag(get_level_flags(), 18) then
							hdmod.custommusiclib.clear_level_music()
						end

						if prng:random_index(100, PRNG_CLASS.FX) == 1 then
							module.level_track = 4.0
						elseif module.level_track < 1 or module.level_track > 3 then
							local new_level_track = prng:random_index(3, PRNG_CLASS.FX)

							if new_level_track ~= module.level_track then
								module.level_track = new_level_track
								hdmod.custommusiclib.clear_level_music()
							end
						end

						local shop_type = state.level_gen.shop_type
						if shop_type == SHOP_TYPE.HIRED_HAND_SHOP then
							module.shop_type = 4.0
						elseif shop_type == SHOP_TYPE.PET_SHOP then
							module.shop_type = 5.0
						elseif shop_type == SHOP_TYPE.DICE_SHOP then
							module.shop_type = 6.0
						else
							module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
						end

						module.MUSIC_FEELING_STORAGE = {}

						if hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.RUSHING_WATER) then
							module.MUSIC_FEELING_STORAGE["rushing_water"] = 1.0
						else
							module.MUSIC_FEELING_STORAGE["rushing_water"] = 0.0
						end
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_worm_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 15.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL and state.theme == THEME.EGGPLANT_WORLD
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_yeti_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("hdmod_level_feeling", 11.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL
						and hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.YETIKINGDOM)
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_mothership_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 8.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL and state.theme == THEME.NEO_BABYLON
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_ice_caves_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 7.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)

						ctx.event_instance:set_parameter_by_name("level_track", module.level_track)
						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end

						if module.MUSIC_PARAMETER_STORAGE["current_shop_type"] ~= module.shop_type then
							module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
							ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
						end
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL and state.theme == THEME.ICE_CAVES

					if should_play then
						if prng:random_index(100, PRNG_CLASS.FX) == 1 then
							module.level_track = 4.0
						elseif module.level_track < 1 or module.level_track > 3 then
							local new_level_track = prng:random_index(3, PRNG_CLASS.FX)

							if new_level_track ~= module.level_track then
								module.level_track = new_level_track
								hdmod.custommusiclib.clear_level_music()
							end
						end

						local shop_type = state.level_gen.shop_type
						if shop_type == SHOP_TYPE.HIRED_HAND_SHOP then
							module.shop_type = 4.0
						elseif shop_type == SHOP_TYPE.PET_SHOP then
							module.shop_type = 5.0
						elseif shop_type == SHOP_TYPE.DICE_SHOP then
							module.shop_type = 6.0
						else
							module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
						end
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_city_of_gold_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 11.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL and state.theme == THEME.CITY_OF_GOLD
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_temple_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0
						module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 6.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)

						ctx.event_instance:set_parameter_by_name("level_track", module.level_track)
						ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end

						if module.MUSIC_PARAMETER_STORAGE["current_shop_type"] ~= module.shop_type then
							module.MUSIC_PARAMETER_STORAGE["current_shop_type"] = module.shop_type
							ctx.event_instance:set_parameter_by_name("current_shop_type", module.shop_type)
						end
					end,
				},
				should_play = function()
					local should_play = state.screen == SCREEN.LEVEL and state.theme == THEME.TEMPLE

					if should_play then
						if test_flag(get_level_flags(), 18) then
							hdmod.custommusiclib.clear_level_music()
						end

						if prng:random_index(100, PRNG_CLASS.FX) == 1 then
							module.level_track = 4.0
						elseif module.level_track < 1 or module.level_track > 3 then
							local new_level_track = prng:random_index(3, PRNG_CLASS.FX)

							if new_level_track ~= module.level_track then
								module.level_track = new_level_track
								hdmod.custommusiclib.clear_level_music()
							end
						end

						local shop_type = state.level_gen.shop_type
						if shop_type == SHOP_TYPE.HIRED_HAND_SHOP then
							module.shop_type = 4.0
						elseif shop_type == SHOP_TYPE.PET_SHOP then
							module.shop_type = 5.0
						elseif shop_type == SHOP_TYPE.DICE_SHOP then
							module.shop_type = 6.0
						else
							module.shop_type = prng:random_int(0, 3, PRNG_CLASS.FX)
						end
					end

					return should_play
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_hell_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					parameter_update_time = 1000,
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						module.MUSIC_PARAMETER_STORAGE["ghost"] = 0.0

						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						ctx.event_instance:set_parameter_by_name("current_theme", 3.0)

						module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
						ctx.event_instance:set_parameter_by_name("ghost", ghost)
					end,
					update_function = function(ctx)
						local ghost = ctx.bgm_master:get_parameter(VANILLA_SOUND_PARAM.GHOST)

						if module.MUSIC_PARAMETER_STORAGE["ghost"] ~= ghost then
							module.MUSIC_PARAMETER_STORAGE["ghost"] = ghost
							ctx.event_instance:set_parameter_by_name("ghost", ghost)
						end
					end,
				},
				should_play = function()
					return (
						state.screen == SCREEN.LEVEL
						and state.theme == THEME.VOLCANA
						and not hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.YAMA)
					)
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_olmec_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}

						ctx.event_instance:set_parameter_by_name("current_theme", 4.0)
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL and state.theme == THEME.OLMEC
				end,
			})

			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "hd_yama_custom_music",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}

						ctx.event_instance:set_parameter_by_name("hdmod_level_feeling", 23.0)
					end,
				},
				should_play = function()
					return state.screen == SCREEN.LEVEL
						and hdmod.feelingslib.feeling_check(hdmod.feelingslib.FEELING_ID.YAMA)
				end,
			})

			-- Hack to keep music muted during level transitions
			table.insert(module.level_musics, {
				settings = {
					base_volume = 1.0,
					mute_shop_music = true,
					event_name = "transition_silent",
					event_description = get_event_by_id("{074918db-c60d-4921-8f15-287d9772460a}"),
					init_function = function(ctx)
						module.MUSIC_PARAMETER_STORAGE = {}
						ctx.event_instance:set_parameter_by_name("current_theme", 0.0)
					end,
				},
				should_play = function()
					return state.screen == SCREEN.TRANSITION
				end,
			})
		end,
		unload_func = function()
			if module.on_reset_cb_id then
				clear_callback(module.on_reset_cb_id)
				module.on_reset_cb_id = nil
			end

			if module.on_menu_cb_id then
				clear_callback(module.on_menu_cb_id)
				module.on_menu_cb_id = nil
			end

			module.title_music = nil

			module.credits_music = nil

			module.level_musics = {}

			collectgarbage("collect")

			if module.debug_cb_id then
				clear_callback(module.debug_cb_id)
			end
		end,
	},
}

function module.enable_tutorial_journal_music_layer()
	local current_custom_level_music = hdmod.custommusiclib.get_current_custom_level_music()
	if current_custom_level_music and current_custom_level_music.settings.event_name == "hd_tutorial_custom_music" then
		module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"] = 1.0
		hdmod.custommusiclib.set_custom_music_level_parameter_by_name("hd_tutorial_journal", 1.0)
	end
end

function module.disable_tutorial_journal_music_layer()
	local current_custom_level_music = hdmod.custommusiclib.get_current_custom_level_music()
	if current_custom_level_music and current_custom_level_music.settings.event_name == "hd_tutorial_custom_music" then
		module.MUSIC_PARAMETER_STORAGE["hd_tutorial_journal"] = 0.0
		hdmod.custommusiclib.set_custom_music_level_parameter_by_name("hd_tutorial_journal", 0.0)
	end
end

function module.eggplant_music()
	local current_custom_level_music = hdmod.custommusiclib.get_current_custom_level_music()
	if current_custom_level_music and current_custom_level_music.settings.event_name ~= "hd_tutorial_custom_music" then
		hdmod.custommusiclib.set_custom_music_level_parameter_by_name("eggplant", 1.0)
	end
end

function module.haunted_castle_door_jumpscare()
	return
end

function module.boss_music()
	local current_custom_level_music = hdmod.custommusiclib.get_current_custom_level_music()
	if current_custom_level_music and current_custom_level_music.settings.event_name == "hd_olmec_custom_music" then
		hdmod.custommusiclib.set_custom_music_level_parameter_by_name("trigger", 1.0)
	elseif current_custom_level_music and current_custom_level_music.settings.event_name == "hd_yama_custom_music" then
		hdmod.custommusiclib.set_custom_music_level_parameter_by_name("trigger", 1.0)
	end
end

function module.post_boss_music()
	return
end

function module.toggle_debug()
	if module.debug_cb_id == nil then
		module.debug_cb_id = set_callback(function(ctx)
			local window_open = ctx:window("Music debug viewer", 0, 0, 0, 0, true, function(ctx, pos, size)
				ctx:win_text("Current Level Track: " .. tostring(module.level_track))
				ctx:win_separator()
				for p_name, p_value in pairs(module.MUSIC_PARAMETER_STORAGE) do
					ctx:win_text(p_name .. ": " .. tostring(p_value))
					ctx:win_separator()
				end
			end)
			if not window_open then
				clear_callback(module.debug_cb_id)
				module.debug_cb_id = nil
			end
		end, ON.GUIFRAME)
	else
		clear_callback(module.debug_cb_id)
		module.debug_cb_id = nil
	end
end

function module.load_func(metadata_load_cb)
	for _, bank in pairs(module.banks) do
		if not bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.load_bank_metadata(bank.bank_path, bank.load_bank_flags, metadata_load_cb, bank.unload_func)
		end
	end
end

function module.unload_func()
	for _, bank in pairs(module.banks) do
		if bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.unload_bank(bank.bank_path)
		end
	end
end

function module.load_sample_data_func(notify_cb)
	for _, bank in pairs(module.banks) do
		if bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.load_bank_sample_data(bank.bank_path, bank.sampledata_load_func, function(statetype, loadstate)
				if statetype == bankmanagerlib.LOADING_STATE_TYPE.METADATA then
					if loadstate == FMOD_LOADING_STATE.ERROR then
						notify_cb(module, statetype, loadstate)
					end
				end
				if statetype == bankmanagerlib.LOADING_STATE_TYPE.SAMPLEDATA then
					notify_cb(module, statetype, loadstate)
					if loadstate == FMOD_LOADING_STATE.LOADED then
						if module.on_reset_cb_id == nil then
							module.on_reset_cb_id = set_callback(function()
								module.level_track = 0.0
								hdmod.custommusiclib.clear_level_music()
							end, ON.RESET)
						end

						if module.on_menu_cb_id == nil then
							module.on_menu_cb_id = set_callback(function()
								if module.adventure_played then
									module.adventure_played = false
								end
							end, ON.MENU)
						end
					end
				end
			end)
		end
	end
end

function module.unload_sample_data_func()
	for _, bank in pairs(module.banks) do
		if not bankmanagerlib.bank_exists(bank.bank_path) then
			bankmanagerlib.unload_bank_sample_data(bank.bank_path)
		end
	end

	if module.on_reset_cb_id then
		clear_callback(module.on_reset_cb_id)
		module.on_reset_cb_id = nil
	end

	if module.on_menu_cb_id then
		clear_callback(module.on_menu_cb_id)
		module.on_menu_cb_id = nil
	end
end

return module
