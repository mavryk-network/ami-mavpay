local user = am.app.get("user", "root")
ami_assert(type(user) == "string", "User not specified...", EXIT_INVALID_CONFIGURATION)

local ok, err = fs.mkdirp("reports")
ami_assert(ok, "failed to create reports directory - error: " .. tostring(err))
local uid, err = fs.getuid(user)
ami_assert(uid, "failed to get " .. user .. "uid - error: " .. tostring(err))

--- enable linger if not root
--- for now we run mavpay continual under root systemd
-- if user ~= "root" then
-- 	local result, err = proc.exec("loginctl show-user ".. user .. " --property=Linger=yes", { stdout = "pipe" })
-- 	ami_assert(result, "failed to set linger for " .. user .. " - error: " .. tostring(err))
-- 	local stdout = result.stdout_stream:read("a") or ""
-- 	if not ok or result.exit_code ~= 0 or stdout == ""  then
-- 		log_info("enabling linger for " .. user .. "...")
-- 		local ok, _, exit_code = os.execute("loginctl enable-linger ".. user)
-- 		assert(ok and exit_code == 0, "failed to enable linger for " .. user .. " - " .. tostring(exit_code))
-- 	end
-- end

local service_manager = require"__mvrk.service-manager"
local services = require "__mavpay.services"

service_manager.remove_services(services.cleanup_names) -- cleanup past install
service_manager.install_services(services.get_active())

log_success(am.app.get("id") .. " services configured")

local ok, err = fs.mkdirp("samples")
ami_assert(ok, "failed to create samples directory - error: " .. tostring(err))

local constants = require"__mavpay/constants"
local configurations = constants.configurations
-- download sample config
local ok, err = net.download_file(configurations.config, "samples/config.hjson",
	{ follow_redirects = true })
if not ok then log_warn("Failed to download sample config.hjson - " .. (err or "")) end

-- download sample remote_signer config
local ok, err = net.download_file(configurations.remote_signer, "samples/remote_signer.hjson",
	{ follow_redirects = true })
if not ok then log_warn("Failed to download sample remote_signer.hjson - " .. (err or "")) end

-- download sample payout_wallet_private.key
local ok, err = net.download_file(configurations.payout_wallet_private_key, "samples/payout_wallet_private.key",
        { follow_redirects = true })
if not ok then log_warn("Failed to download sample payout_wallet_private.key - " .. (err or "")) end

require"__mvrk.base_utils".setup_file_ownership()