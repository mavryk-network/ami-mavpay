local service_manager = require"__mvrk.service-manager"
local services = require"__mavpay.services"

log_info("stopping mavpay services... this may take few minutes.")

service_manager.stop_services(services.get_active_names())

log_success("mavpay services succesfully stopped.")