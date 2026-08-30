local module = {}

module.debug_print = true

local FMOD_BANKS = {}

local BANK_METADATA_LOAD_CALLBACKS = {}

local BANK_SAMPLE_DATA_LOAD_CALLBACKS = {}

local CLEANUP_CALLBACKS = {}

function module.set_bank_metadata_load_callback(callback_name, metadata_load_callback)
	if
		type(callback_name) == "string"
		and type(metadata_load_callback) == "function"
	then
		BANK_METADATA_LOAD_CALLBACKS[callback_name] = metadata_load_callback
	end
end

function module.clear_bank_metadata_load_callback(callback_name)
	if
		type(callback_name) == "string"
	then
		BANK_METADATA_LOAD_CALLBACKS[callback_name] = nil
	end
end

function module.set_bank_sample_data_load_callback(callback_name, sample_data_load_callback)
	if
		type(callback_name) == "string"
		and type(sample_data_load_callback) == "function"
	then
		BANK_SAMPLE_DATA_LOAD_CALLBACKS[callback_name] = sample_data_load_callback
	end
end

function module.clear_bank_sample_data_load_callback(callback_name)
	if
		type(callback_name) == "string"
	then
		BANK_METADATA_LOAD_CALLBACKS[callback_name] = nil
	end
end

function module.load_fmod_bank(fmod_bank_path, load_bank_flags, init_callback, cleanup_callback)
	if
		type(fmod_bank_path) == "string"
		and type(load_bank_flags) == "number"
		and type(init_callback) == "function"
		and type(cleanup_callback) == "function"
	then
		if not FMOD_BANKS[fmod_bank_path] then
			if module.debug_print then
				print("[load_fmod_bank] Loading FMOD bank " .. fmod_bank_path)
			end

			local bank = load_bank(fmod_bank_path, load_bank_flags)

			if bank ~= nil and bank:is_valid() then
				FMOD_BANKS[fmod_bank_path] = bank

				if FMOD_BANKS[fmod_bank_path] ~= nil then
					local bank_metadata_loaded = false

					set_callback(function()
						if FMOD_BANKS[fmod_bank_path]:is_valid() then
							if not bank_metadata_loaded then
								local metadata_loading_state = FMOD_BANKS[fmod_bank_path]:get_loading_state()

								if metadata_loading_state == FMOD_LOADING_STATE.LOADING then
									if module.debug_print then
										print("[load_fmod_bank] Bank metadata loading...")
									end
								end

								if metadata_loading_state == FMOD_LOADING_STATE.LOADED then
									if module.debug_print then
										print("[load_fmod_bank] Bank metadata loaded, loading sample data...")
									end

									-- Execute all (if any) music metadata load callbacks.
									for _, metadata_callback in pairs(BANK_METADATA_LOAD_CALLBACKS) do
										local success, result = pcall(function()
											metadata_callback()
										end)
										if not success then
											if module.debug_print then
												print("[load_fmod_bank] Caught error in bank metadata load callback: " .. result)
											end
											error(result)
										end
									end

									bank_metadata_loaded = true
									FMOD_BANKS[fmod_bank_path]:load_sample_data()
								end

								if not metadata_loading_state or metadata_loading_state == FMOD_LOADING_STATE.ERROR then
									FMOD_BANKS[fmod_bank_path] = nil
									clear_callback()
									if module.debug_print then
										print("[load_fmod_bank] Warning: Failed to load FMOD bank file.")
									end
								end
							else
								local sample_data_loading_state = FMOD_BANKS[fmod_bank_path]:get_sample_loading_state()

								if
									not sample_data_loading_state
									or sample_data_loading_state == FMOD_LOADING_STATE.ERROR
								then
									FMOD_BANKS[fmod_bank_path] = nil
									clear_callback()
									if module.debug_print then
										print("[load_fmod_bank] Warning: Failed to load sample data for bank.")
									end
								end

								if sample_data_loading_state == FMOD_LOADING_STATE.LOADING then
									if module.debug_print then
										print("[load_fmod_bank] Bank sample data loading...")
									end
								end

								if sample_data_loading_state == FMOD_LOADING_STATE.LOADED then
									clear_callback()
									if module.debug_print then
										print(
											"[load_fmod_bank] Bank sample data loaded succesfully. Running init callback..."
										)
									end

									-- Execute the music init callback.
									local success, result = pcall(function()
										init_callback()
									end)
									if not success then
										if module.debug_print then
											print("[load_fmod_bank] Caught error in bank init callback: " .. result)
										end
										error(result)
									end

									-- Execute all (if any) music sample data load callbacks.
									for _, sample_data_callback in pairs(BANK_SAMPLE_DATA_LOAD_CALLBACKS) do
										local success, result = pcall(function()
											sample_data_callback()
										end)
										if not success then
											if module.debug_print then
												print("[load_fmod_bank] Caught error in bank sample data load callback: " .. result)
											end
											error(result)
										end
									end

									CLEANUP_CALLBACKS[fmod_bank_path] = cleanup_callback
								end
							end
						else
							FMOD_BANKS[fmod_bank_path] = nil
							clear_callback()
							if module.debug_print then
								print("[load_fmod_bank] Bank failed to load. Invalid FMOD handle.")
							end
						end
					end, ON.POST_UPDATE)
				else
					if module.debug_print then
						print("[load_fmod_bank] Bank load failed, does the bank file exist?")
					end
				end
			else
				if module.debug_print then
					print("[load_fmod_bank] Bank load failed, does the bank file exist?")
				end
			end
		else
			if module.debug_print then
				print("[load_fmod_bank] Bank already exists in bank array.")
			end
		end
	else
		if module.debug_print then
			print("[load_fmod_bank] Invalid parameters passed to function.")
		end
	end
end

function module.unload_fmod_bank(fmod_bank_path)
	if type(fmod_bank_path) == "string" then
		if FMOD_BANKS[fmod_bank_path] then
			if FMOD_BANKS[fmod_bank_path]:is_valid() then
				if module.debug_print then
					print("[unload_fmod_bank] Bank unloading: " .. fmod_bank_path)
				end
				if FMOD_BANKS[fmod_bank_path]:unload() then
					FMOD_BANKS[fmod_bank_path] = nil
					if module.debug_print then
						print("[unload_fmod_bank] Bank successfully unloaded.")
					end
				else
					if module.debug_print then
						print("[unload_fmod_bank] Error unload failed. Invalid FMOD handle.")
					end
				end
			else
				FMOD_BANKS[fmod_bank_path] = nil
				if module.debug_print then
					print("[unload_fmod_bank] Error unloading bank, removing invalid handle: " .. fmod_bank_path)
					print("[unload_fmod_bank] Invalid FMOD handle.")
				end
			end
		else
			if module.debug_print then
				print("[unload_fmod_bank] Bank does not exist in bank array, was it loaded?")
			end
		end
	else
		if module.debug_print then
			print("[unload_fmod_bank] Invalid parameters passed to function.")
		end
	end
end

function module.bank_metadata_loaded(fmod_bank_path)
	if type(fmod_bank_path) == "string" then
		if FMOD_BANKS[fmod_bank_path] then
			local metadata_loading_state = FMOD_BANKS[fmod_bank_path]:get_loading_state()

			if metadata_loading_state == FMOD_LOADING_STATE.LOADING then
				return false
			end

			if metadata_loading_state == FMOD_LOADING_STATE.LOADED then
				return true
			end

			if metadata_loading_state == FMOD_LOADING_STATE.ERROR then
				if module.debug_print then
					print("[bank_metadata_loaded] Warning: Error getting metadata loading state from bank.")
				end
				return false
			end
		else
			if module.debug_print then
				print("[bank_metadata_loaded] Bank does not exist in bank array, was it loaded?")
			end
		end
	else
		if module.debug_print then
			print("[bank_metadata_loaded] Invalid parameters passed to function.")
		end
	end
end

function module.bank_sample_data_loaded(fmod_bank_path)
	if type(fmod_bank_path) == "string" then
		if FMOD_BANKS[fmod_bank_path] then
			local sample_data_loading_state = FMOD_BANKS[fmod_bank_path]:get_sample_loading_state()

			if sample_data_loading_state == FMOD_LOADING_STATE.LOADING then
				return false
			end

			if sample_data_loading_state == FMOD_LOADING_STATE.LOADED then
				return true
			end

			if sample_data_loading_state == FMOD_LOADING_STATE.ERROR then
				if module.debug_print then
					print("[bank_sample_data_loaded] Warning: Error getting metadata loading state from bank.")
				end
				return false
			end
		else
			if module.debug_print then
				print("[bank_sample_data_loaded] Bank does not exist in bank array, was it loaded?")
			end
		end
	else
		if module.debug_print then
			print("[bank_sample_data_loaded] Invalid parameters passed to function.")
		end
	end
end

function module.bank_exists(fmod_bank_path)
	if type(fmod_bank_path) == "string" then
		if FMOD_BANKS[fmod_bank_path] then
			return true
		else
			return false
		end
	else
		if module.debug_print then
			print("[bank_exists] Invalid parameters passed to function.")
		end
	end
end

set_callback(function()
	if module.debug_print then
		print("Disabling FMOD bank manager and running all cleanup callbacks...")
	end
	-- Execute all music cleanup callbacks.
	for _, cleanup_callback in pairs(CLEANUP_CALLBACKS) do
		local success, result = pcall(function()
			cleanup_callback()
		end)
		if not success then
			if module.debug_print then
				print("Caught error in bank cleanup callback: " .. result)
			end
			error(result)
		end
	end

	CLEANUP_CALLBACKS = {}

	for _, bank in ipairs(FMOD_BANKS) do
		if bank:is_valid() then
			if module.debug_print then
				print("Unloading bank...")
			end
			if bank:unload() then
				bank = nil
				if module.debug_print then
					print("Bank successfully unloaded.")
				end
			else
				if module.debug_print then
					print("Error unloading bank!")
				end
			end
		end
	end

	FMOD_BANKS = {}
end, ON.SCRIPT_DISABLE)

return module
