local module = {}

module.debug_print = false

-- The type of loading state, used in loading_state_callback()
module.LOADING_STATE_TYPE = {
	-- Metadata about events
	METADATA = 1,
	-- Audio sample data for events
	SAMPLEDATA = 2,
}

-- Stores CustomBank objects. Each entry is any fmod_bank_path that maps to a CustomBank.
local FMOD_BANKS = {}

-- Stores the callbacks that are executed when a bank is unloaded. Each entry is any fmod_bank_path that maps to a user-defined function. All unload callbacks are executed on script disable.
local UNLOAD_CALLBACKS = {}

---@param fmod_bank_path string @ Path of the bank to load sample data for
---@param load_bank_flags FMOD_LOAD_BANK_FLAGS @ Bank load flags used for load_bank(). FMOD_LOAD_BANK_FLAGS.NORMAL will cause the game to hang until loading finishes; FMOD_LOAD_BANK_FLAGS.NONBLOCKING will load more slowly in the background
---@param sampledata_load_callback function @ Function called when when sample data finishes loading
---@param unload_callback function @ Function called when when the bank is unloaded, useful for clearing any callbacks and clearing music
---@param loading_state_callback function? @ Optional. Function that is called during each part of bank loading. The callback signature is nil loading_state_callback(fmod_bank_manager.LOADING_STATE_TYPE statetype, FMOD_LOADING_STATE loadstate)
function module.load_bank(
	fmod_bank_path,
	load_bank_flags,
	sampledata_load_callback,
	unload_callback,
	loading_state_callback
)
	if
		not (
			type(fmod_bank_path) == "string"
			and type(load_bank_flags) == "number"
			and type(sampledata_load_callback) == "function"
			and type(unload_callback) == "function"
			and (not loading_state_callback or type(loading_state_callback) == "function")
		)
	then
		if module.debug_print then
			print("[load_bank] Invalid parameters passed to function.")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	if FMOD_BANKS[fmod_bank_path] then
		if module.debug_print then
			print("[load_bank] Bank already exists in bank array.")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	if module.debug_print then
		print("[load_bank] Loading FMOD bank " .. fmod_bank_path)
	end

	local bank = load_bank(fmod_bank_path, load_bank_flags)

	if bank == nil or not bank:is_valid() then
		if module.debug_print then
			print("[load_bank] Bank load failed, does the bank file exist?")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	FMOD_BANKS[fmod_bank_path] = bank

	if FMOD_BANKS[fmod_bank_path] == nil then
		if module.debug_print then
			print("[load_bank] Bank load failed, does the bank file exist?")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	local bank_metadata_loaded = false

	set_callback(function()
		if FMOD_BANKS[fmod_bank_path]:is_valid() then
			if not bank_metadata_loaded then
				local metadata_loading_state = FMOD_BANKS[fmod_bank_path]:get_loading_state()

				if not metadata_loading_state or metadata_loading_state == FMOD_LOADING_STATE.ERROR then
					FMOD_BANKS[fmod_bank_path] = nil
					clear_callback()

					if module.debug_print then
						print("[load_bank] Warning: Failed to load FMOD bank file.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADING then
					if module.debug_print then
						print("[load_bank] Bank metadata loading...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADING)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADED then
					if module.debug_print then
						print("[load_bank] Bank metadata loaded, loading sample data...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADED)
					end

					bank_metadata_loaded = true
					FMOD_BANKS[fmod_bank_path]:load_sample_data()
				end
			else
				local sample_data_loading_state = FMOD_BANKS[fmod_bank_path]:get_sample_loading_state()

				if not sample_data_loading_state or sample_data_loading_state == FMOD_LOADING_STATE.ERROR then
					FMOD_BANKS[fmod_bank_path] = nil
					clear_callback()

					if module.debug_print then
						print("[load_bank] Warning: Failed to load sample data for bank.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.ERROR)
					end
				end

				if sample_data_loading_state == FMOD_LOADING_STATE.LOADING then
					if module.debug_print then
						print("[load_bank] Bank sample data loading...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.LOADING)
					end
				end

				if sample_data_loading_state == FMOD_LOADING_STATE.LOADED then
					clear_callback()
					if module.debug_print then
						print("[load_bank] Bank sample data loaded succesfully. Executing sample data load callback...")
					end

					-- Execute the sample data load callback.
					local success, result = pcall(function()
						sampledata_load_callback()
					end)
					if not success then
						if module.debug_print then
							print("[load_bank] Caught error in sample data load callback: " .. result)
						end
						error(result)
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.LOADED)
					end

					UNLOAD_CALLBACKS[fmod_bank_path] = unload_callback
				end
			end
		else
			FMOD_BANKS[fmod_bank_path] = nil
			clear_callback()

			if module.debug_print then
				print("[load_bank] Bank failed to load. Invalid FMOD handle.")
			end

			if loading_state_callback ~= nil then
				loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
			end
		end
	end, ON.POST_UPDATE)
end

---@param fmod_bank_path string @ Path of the bank to load sample data for
---@param load_bank_flags FMOD_LOAD_BANK_FLAGS @ Bank load flags used for load_bank(). Use FMOD_LOAD_BANK_FLAGS.NORMAL, or FMOD_LOAD_BANK_FLAGS.NONBLOCKING
---@param metadata_load_callback function @ Function called when when sample data finishes loading
---@param unload_callback function @ Function called when when the bank is unloaded, useful for clearing any callbacks and clearing music
---@param loading_state_callback function? @ Optional. Function that is called during each part of bank loading. The callback signature is nil loading_state_callback(fmod_bank_manager.LOADING_STATE_TYPE statetype, FMOD_LOADING_STATE loadstate)
function module.load_bank_metadata(
	fmod_bank_path,
	load_bank_flags,
	metadata_load_callback,
	unload_callback,
	loading_state_callback
)
	if
		not (
			type(fmod_bank_path) == "string"
			and type(load_bank_flags) == "number"
			and type(metadata_load_callback) == "function"
			and type(unload_callback) == "function"
			and (not loading_state_callback or type(loading_state_callback) == "function")
		)
	then
		if module.debug_print then
			print("[load_bank_metadata] Invalid parameters passed to function.")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	if FMOD_BANKS[fmod_bank_path] then
		if module.debug_print then
			print("[load_bank_metadata] Bank already exists in bank array.")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	if module.debug_print then
		print("[load_bank_metadata] Loading FMOD bank " .. fmod_bank_path)
	end

	local bank = load_bank(fmod_bank_path, load_bank_flags)

	if bank == nil or not bank:is_valid() then
		if module.debug_print then
			print("[load_bank_metadata] Bank load failed, does the bank file exist?")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	FMOD_BANKS[fmod_bank_path] = bank

	if FMOD_BANKS[fmod_bank_path] == nil then
		if module.debug_print then
			print("[load_bank_metadata] Bank load failed, does the bank file exist?")
		end

		return
	end

	local bank_metadata_loaded = false

	set_callback(function()
		if FMOD_BANKS[fmod_bank_path]:is_valid() then
			if not bank_metadata_loaded then
				local metadata_loading_state = FMOD_BANKS[fmod_bank_path]:get_loading_state()

				if not metadata_loading_state or metadata_loading_state == FMOD_LOADING_STATE.ERROR then
					FMOD_BANKS[fmod_bank_path] = nil
					clear_callback()

					if module.debug_print then
						print("[load_bank_metadata] Warning: Failed to load FMOD bank file.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADING then
					if module.debug_print then
						print("[load_bank_metadata] Bank metadata loading...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADING)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADED then
					if module.debug_print then
						print("[load_bank_metadata] Bank metadata loaded, running metadata load callbacks...")
					end

					clear_callback()

					bank_metadata_loaded = true

					-- Execute the metdata load callback.
					local success, result = pcall(function()
						metadata_load_callback()
					end)
					if not success then
						if module.debug_print then
							print("[load_bank_metadata] Caught error in bank metadata load callback: " .. result)
						end
						error(result)
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADED)
					end

					UNLOAD_CALLBACKS[fmod_bank_path] = unload_callback
				end
			end
		else
			FMOD_BANKS[fmod_bank_path] = nil
			clear_callback()

			if module.debug_print then
				print("[load_bank_metadata] Bank failed to load. Invalid FMOD handle.")
			end

			if loading_state_callback ~= nil then
				loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
			end
		end
	end, ON.POST_UPDATE)
end

---@param fmod_bank_path string @ Path of the bank to load sample data for
---@param sampledata_load_callback function @ Function called when when sample data finishes loading
---@param unload_callback function @ Function called when when the bank is unloaded, useful for clearing any callbacks and clearing music
---@param loading_state_callback function? @ Optional. Function that is called during each part of bank loading. The callback signature is nil loading_state_callback(fmod_bank_manager.LOADING_STATE_TYPE statetype, FMOD_LOADING_STATE loadstate)
function module.load_bank_sample_data(fmod_bank_path, sampledata_load_callback, loading_state_callback)
	if
		not (
			type(fmod_bank_path) == "string"
			and type(sampledata_load_callback) == "function"
			and (not loading_state_callback or type(loading_state_callback) == "function")
		)
	then
		if module.debug_print then
			print("[load_bank_sample_data] Invalid parameters passed to function.")
		end

		if loading_state_callback ~= nil then
			loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.ERROR)
		end

		return
	end

	local bank_metadata_loaded = false

	set_callback(function()
		if FMOD_BANKS[fmod_bank_path]:is_valid() then
			if not bank_metadata_loaded then
				local metadata_loading_state = FMOD_BANKS[fmod_bank_path]:get_loading_state()

				if not metadata_loading_state or metadata_loading_state == FMOD_LOADING_STATE.ERROR then
					FMOD_BANKS[fmod_bank_path] = nil
					clear_callback()

					if module.debug_print then
						print("[load_bank_sample_data] Warning: Failed to load FMOD bank file.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.ERROR)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.UNLOADED then
					clear_callback()

					if module.debug_print then
						print("[load_bank_sample_data] Warning: Unable to load bank sample data, bank was not loaded.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.UNLOADED)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADING then
					if module.debug_print then
						print("[load_bank_sample_data] Bank metadata loading...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADING)
					end
				end

				if metadata_loading_state == FMOD_LOADING_STATE.LOADED then
					if module.debug_print then
						print("[load_bank_sample_data] Bank metadata loaded, loading sample data...")
					end

					bank_metadata_loaded = true
					FMOD_BANKS[fmod_bank_path]:load_sample_data()

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.METADATA, FMOD_LOADING_STATE.LOADED)
					end

					UNLOAD_CALLBACKS[fmod_bank_path] = unload_callback
				end
			else
				local sample_data_loading_state = FMOD_BANKS[fmod_bank_path]:get_sample_loading_state()

				if not sample_data_loading_state or sample_data_loading_state == FMOD_LOADING_STATE.ERROR then
					FMOD_BANKS[fmod_bank_path] = nil
					clear_callback()

					if module.debug_print then
						print("[load_bank_sample_data] Warning: Failed to load sample data for bank.")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.ERROR)
					end
				end

				if sample_data_loading_state == FMOD_LOADING_STATE.LOADING then
					if module.debug_print then
						print("[load_bank_sample_data] Bank sample data loading...")
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.LOADING)
					end
				end

				if sample_data_loading_state == FMOD_LOADING_STATE.LOADED then
					clear_callback()
					if module.debug_print then
						print(
							"[load_bank_sample_data] Bank sample data loaded succesfully. Running sample data load callback..."
						)
					end

					-- Execute the sample data load callback.
					local success, result = pcall(function()
						sampledata_load_callback()
					end)
					if not success then
						if module.debug_print then
							print("[load_bank_sample_data] Caught error in sample data load callback: " .. result)
						end
						error(result)
					end

					if loading_state_callback ~= nil then
						loading_state_callback(module.LOADING_STATE_TYPE.SAMPLEDATA, FMOD_LOADING_STATE.LOADED)
					end
				end
			end
		else
			FMOD_BANKS[fmod_bank_path] = nil

			clear_callback()

			if module.debug_print then
				print("[load_bank_sample_data] Bank failed to load. Invalid FMOD handle.")
			end
		end
	end, ON.POST_UPDATE)
end

---@param fmod_bank_path string @ Path of the bank to unload
---@return boolean @ true if the bank was succesfully unloaded, false otherwise
function module.unload_bank(fmod_bank_path)
	if not type(fmod_bank_path) == "string" then
		if module.debug_print then
			print("[unload_bank] Invalid parameters passed to function.")
		end

		return false
	end

	if not FMOD_BANKS[fmod_bank_path] then
		if module.debug_print then
			print("[unload_bank] Bank does not exist in bank array, was it loaded?")
		end

		return false
	end

	if not FMOD_BANKS[fmod_bank_path]:is_valid() then
		FMOD_BANKS[fmod_bank_path] = nil

		if module.debug_print then
			print("[unload_bank] Error unloading bank, invalid handle. Removing invalid handle: " .. fmod_bank_path)
		end

		return false
	end

	if UNLOAD_CALLBACKS[fmod_bank_path] then
		local success, result = pcall(function()
			UNLOAD_CALLBACKS[fmod_bank_path]()
		end)
		if not success then
			if module.debug_print then
				print("Caught error in bank unload callback: " .. result)
			end
			error(result)
		end
	end

	if module.debug_print then
		print("[unload_bank] Bank unloading: " .. fmod_bank_path)
	end

	if FMOD_BANKS[fmod_bank_path]:unload() then
		FMOD_BANKS[fmod_bank_path] = nil
		if module.debug_print then
			print("[unload_bank] Bank successfully unloaded.")
		end

		return true
	else
		if module.debug_print then
			print("[unload_bank] Error unload failed. Invalid FMOD handle.")
		end

		return false
	end
end

---@param fmod_bank_path string @ Path of the bank to unload sample data for
function module.unload_bank_sample_data(fmod_bank_path)
	if not type(fmod_bank_path) == "string" then
		if module.debug_print then
			print("[unload_bank_sample_data] Invalid parameters passed to function.")
		end

		return false
	end

	if not FMOD_BANKS[fmod_bank_path] then
		if module.debug_print then
			print("[unload_bank_sample_data] Bank does not exist in bank array, was it loaded?")
		end

		return false
	end

	if not FMOD_BANKS[fmod_bank_path]:is_valid() then
		FMOD_BANKS[fmod_bank_path] = nil

		if module.debug_print then
			print(
				"[unload_bank_sample_data] Error unloading bank, invalid handle. Removing invalid handle: "
					.. fmod_bank_path
			)
		end

		return false
	end

	if module.debug_print then
		print("[unload_bank_sample_data] Bank sample data unloading: " .. fmod_bank_path)
	end

	if FMOD_BANKS[fmod_bank_path]:unload_sample_data() then
		if module.debug_print then
			print("[unload_bank_sample_data] Bank sample data successfully unloaded.")
		end
	else
		if module.debug_print then
			print("[unload_bank_sample_data] Error sample data unload failed. Invalid FMOD handle.")
		end
	end
end

---@param fmod_bank_path string @ Path of the bank to check metadata loading state of
---@return FMOD_LOADING_STATE? @ The sample data loading state of the bank, or nil if it doesn't exist
function module.get_bank_loading_state(fmod_bank_path)
	if not type(fmod_bank_path) == "string" then
		if module.debug_print then
			print("[get_bank_loading_state] Invalid parameters passed to function.")
		end

		return nil
	end

	if FMOD_BANKS[fmod_bank_path] then
		return FMOD_BANKS[fmod_bank_path]:get_loading_state()
	else
		if module.debug_print then
			print("[get_bank_loading_state] Bank does not exist in bank array, was it loaded?")
		end

		return nil
	end
end

---@param fmod_bank_path string @ Path of the bank to check sample data loading state of
---@return FMOD_LOADING_STATE? @ The sample data loading state of the bank, or nil if it doesn't exist
function module.get_bank_sample_loading_state(fmod_bank_path)
	if not type(fmod_bank_path) == "string" then
		if module.debug_print then
			print("[get_bank_sample_loading_state] Invalid parameters passed to function.")
		end

		return nil
	end

	if FMOD_BANKS[fmod_bank_path] then
		return FMOD_BANKS[fmod_bank_path]:get_sample_loading_state()
	else
		if module.debug_print then
			print("[get_bank_sample_loading_state] Bank does not exist in bank array, was it loaded?")
		end

		return nil
	end
end

---@param fmod_bank_path string @ Path of the bank to check
---@return boolean @ Whether the bank exists in fmod_bank_manager
function module.bank_exists(fmod_bank_path)
	if not type(fmod_bank_path) == "string" then
		if module.debug_print then
			print("[bank_exists] Invalid parameters passed to function.")
		end

		return false
	end

	if FMOD_BANKS[fmod_bank_path] then
		return true
	else
		return false
	end
end

set_callback(function()
	if module.debug_print then
		print("Disabling FMOD bank manager and running all unload callbacks...")
	end
	-- Execute all music unload callbacks.
	for _, unload_callback in pairs(UNLOAD_CALLBACKS) do
		local success, result = pcall(function()
			unload_callback()
		end)
		if not success then
			if module.debug_print then
				print("Caught error in bank unload callback: " .. result)
			end
			error(result)
		end
	end

	UNLOAD_CALLBACKS = {}

	for path, bank in pairs(FMOD_BANKS) do
		if module.debug_print then
			print("Unloading bank " .. path)
		end
		if bank:is_valid() then
			if bank:unload() then
				bank = nil
				if module.debug_print then
					print("Unloaded bank " .. path .. " succesfully.")
				end
			else
				if module.debug_print then
					print("Failed to unload bank " .. path .. ". Invalid FMOD handle.")
				end
			end
		else
			if module.debug_print then
				print("Failed to unload bank " .. tostring(path) .. ". Invalid FMOD handle.")
			end
		end
	end

	FMOD_BANKS = {}
end, ON.SCRIPT_DISABLE)

return module
