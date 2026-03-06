local startup_args = am.app.get_configuration("STARTUP_ARGS", {})

local continual_configuration = am.app.get_configuration("CONTINUAL", nil)
if type(continual_configuration) == "table" then
	local payout_interval = continual_configuration.interval or 1
	if type(payout_interval) == "number" and payout_interval > 1 then
		table.insert(startup_args, "--interval=" .. tostring(payout_interval))
	end
	local payout_interval_trigger_offset = continual_configuration.interval_trigger_offset or 0
	if type(payout_interval_trigger_offset) == "number" and payout_interval_trigger_offset > 0 then
		table.insert(startup_args, "--interval-trigger-offset=" .. tostring(payout_interval_trigger_offset))
	end
	local payout_include_previous_cycles = continual_configuration.include_previous_cycles or 0
	if type(payout_include_previous_cycles) == "number" and payout_include_previous_cycles > 0 then
		table.insert(startup_args, "--include-previous-cycles=" .. tostring(payout_include_previous_cycles))
	end
end

am.app.set_model(
	{
		WANTED_BINARIES = { "mavpay" },
		SERVICE_CONFIGURATION = util.merge_tables(
			{
				TimeoutStopSec = 600,
			},
			type(am.app.get_configuration("SERVICE_CONFIGURATION")) == "table" and
			am.app.get_configuration("SERVICE_CONFIGURATION") or {},
			true
		),
		STARTUP_ARGS = startup_args,
	},
	{ merge = true, overwrite = true }
)
