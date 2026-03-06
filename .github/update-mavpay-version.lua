local version = os.getenv("VERSION")
if not version then
	os.exit(222)
end

os.execute("eli src/__mvrk/update-sources.lua " .. version)
