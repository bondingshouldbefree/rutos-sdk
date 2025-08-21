local FunctionService = require("api/FunctionService")

local Example = FunctionService:new()

-- GET /api/example_f/test
function Example:GET_TYPE_test()
	os.execute("sleep 2")
	return self:ResponseOK({
		result = "API result example"
	})
end

function Example:TestAction()
	-- For error handling use error functions:
	--      self:add_critical_error(100, "Example error message", "Source")
	--      self:add_error(100, "Example error message", "Source")

	return self:ResponseOK({
		result = "API action example",
		data = self.arguments.data
	})
end

-- POST /api/example_f/actions/test
local test_action = Example:action("test", Example.TestAction)

	local name = test_action:option("name")
		name.require = true
		name.maxlength = 256

	local custom = test_action:option("custom")
		function custom:validate(value)
			-- Here you can write a custom validation for this field
			if value == "value error" then
				return false, "Example error message"
			end
			return true
		end

function Example:UPLOAD_init()
	local location = "/tmp/%s"

	local function handle_request(upload_request)
		if #upload_request.files > 1 then
			return false, { code = 5, error = "Only uploading a single file is allowed", source = "filename" }
		end

		local file = upload_request.files[1]
		file.location = string.format(location, file.filename)
		return true
	end

	return { handle_request = handle_request }
end

function Example:UPLOAD_after_upload_hook(upload_request)
	local path = upload_request.files[1].location
	-- Do something after upload, must return file path
	return { path = path }
end

return Example
