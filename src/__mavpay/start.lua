local service_manager = require"__mvrk.service-manager"
local services = require"__mavpay.services"

service_manager.start_services(services.get_active_names())

log_success("mavpay services succesfully started.")