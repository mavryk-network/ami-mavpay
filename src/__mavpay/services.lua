local app_id = am.app.get("id")
local continual_service_id = "continual"

local possible_residues = {
	[app_id .. "-mavpay"] = am.app.get_model("MAVPAY_SERVICE_FILE", "__mavpay/assets/mavpay.service")
}

local available_services = {
	[app_id .. "-" .. continual_service_id] = am.app.get_model("MAVPAY_SERVICE_FILE", "__mavpay/assets/continual")
}

local function get_active_services()
	local service_manager = require "__mvrk.service-manager"
	local installed_services = service_manager.get_installed_services(table.keys(available_services))
	local active_services = {}
	for _, id in ipairs(installed_services) do
		active_services[id] = available_services[id]
	end
	return active_services
end

local function get_active_names()
	return table.keys(get_active_services())
end

--- cleanup names include everything including residues
---@type string[]
local cleanup_names = {}
cleanup_names = util.merge_arrays(cleanup_names, table.values(available_services))
cleanup_names = util.merge_arrays(cleanup_names, table.values(possible_residues))

return {
	get_active = get_active_services,
	get_active_names = get_active_names,
	available_services = available_services,
	cleanup_names = cleanup_names
}
