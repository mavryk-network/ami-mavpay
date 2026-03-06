-- mavpay SOURCE: https://github.com/mavryk-network/mavpay/releases
-- usage:
-- eli src/__mvrk/update-sources.lua [version]

local hjson = require "hjson"

local static_version = arg[1]
local http_options = nil

--------------------------------------------------------------------------------
-- GitHub Fetching Helper
--------------------------------------------------------------------------------

local function fetch_github_release(repo, tag)
	local url
	if tag and tag ~= "" then
		print("Fetching release " .. tag .. " from " .. repo .. "...")
		url = "https://api.github.com/repos/" .. repo .. "/releases/tags/" .. tag
	else
		print("Fetching releases from " .. repo .. "...")
		url = "https://api.github.com/repos/" .. repo .. "/releases"
	end

	local response = net.download_string(url, http_options)

	if #response == 0 then
		print("Empty response from " .. repo)
		return nil
	end

	local data = hjson.parse(response)
	if not data then
		print("Failed to parse response from " .. repo)
		return nil
	end

	if tag and tag ~= "" then
		if data.message == "Not Found" then
			print("Release " .. tag .. " not found in " .. repo)
			return nil
		end
		return data
	else
		if #data == 0 then
			return nil
		end
		return data[1]
	end
end

local function extract_asset(release, name_pattern)
	if not release or not release.assets then return nil end
	for _, asset in ipairs(release.assets) do
		if asset.name:match(name_pattern) then
			local hash = nil
			if asset.digest then
				hash = asset.digest:match("sha256:(%x+)")
			end
			return {
				url = asset.browser_download_url,
				sha256 = hash,
				version = release.tag_name
			}
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- Fetch Releases
--------------------------------------------------------------------------------

local mavpay_release = fetch_github_release("mavryk-network/mavpay", static_version)
if mavpay_release then
	print("Found Mavpay release: " .. mavpay_release.tag_name)
else
	print("Warning: Failed to fetch Mavpay release")
end

--------------------------------------------------------------------------------
-- Update Sources
--------------------------------------------------------------------------------

local current_sources = hjson.parse(fs.read_file("src/__mvrk/sources.hjson"))
local new_sources_map = {}

local platforms = {
	["linux-x86_64"] = {
		mavpay_pattern = "mavpay%-linux%-amd64"
	},
	["linux-arm64"] = {
		mavpay_pattern = "mavpay%-linux%-arm64"
	},
	["darwin-arm64"] = {
		mavpay_pattern = "mavpay%-macos%-arm64"
	}
}

for platform, config in pairs(platforms) do
	print("Updating " .. platform .. "...")
	local new_platform_sources = {}

	if mavpay_release then
		local mavpay_data = extract_asset(mavpay_release, config.mavpay_pattern)
		if mavpay_data then
			new_platform_sources.mavpay = mavpay_data
		else
			print("  Warning: Mavpay asset matching " .. config.mavpay_pattern .. " not found")
			if current_sources[platform] and current_sources[platform].mavpay then
				new_platform_sources.mavpay = current_sources[platform].mavpay
			end
		end
	else
		if current_sources[platform] and current_sources[platform].mavpay then
			new_platform_sources.mavpay = current_sources[platform].mavpay
		end
	end

	new_sources_map[platform] = new_platform_sources
end

-- Preserve any platforms not in our list
for k, v in pairs(current_sources) do
	if not new_sources_map[k] then
		new_sources_map[k] = v
	end
end

local new_content = "// mavpay SOURCE: https://github.com/mavryk-network/mavpay/releases \n"
new_content = new_content .. hjson.stringify(new_sources_map, { separator = true, sort_keys = true })

fs.write_file("src/__mvrk/sources.hjson", new_content)
print("Updated src/__mvrk/sources.hjson")

--------------------------------------------------------------------------------
-- Update specs.json version
--------------------------------------------------------------------------------

if mavpay_release then
	local mavpay_version = mavpay_release.tag_name
	local specs_raw = fs.read_file("src/specs.json")
	local specs = hjson.parse(specs_raw)
	local package_version = string.split(specs.version, "+", true)[1]
	local current_mavpay_version = string.split(specs.version, "+", true)[2]

	-- Only update if mavpay version changed
	if current_mavpay_version ~= mavpay_version then
		local package_version_parts = string.split(package_version, ".", true)
		local package_version_patch = tonumber(package_version_parts[3]) + 1
		package_version = package_version_parts[1] .. "." .. package_version_parts[2] .. "." .. package_version_patch
		specs.version = package_version .. "+" .. mavpay_version
		fs.write_file("src/specs.json", hjson.stringify_to_json(specs, { indent = "    " }))
		print("Updated src/specs.json to " .. specs.version)
	else
		print("specs.json already up to date (" .. specs.version .. ")")
	end
end
