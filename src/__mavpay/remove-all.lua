local service_manager = require"__mvrk.service-manager"
local services = require"__mavpay.services"

service_manager.remove_services(services.cleanup_names) -- cleanup past install

log_success("mavpay services succesfully removed")
