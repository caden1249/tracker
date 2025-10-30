local HttpService = game:GetService("HttpService")

local Logger = {}
Logger.__index = Logger

function Logger.new(url, label)
	local self = setmetatable({}, Logger)
	self.URL = url
	self.Label = label or "tracker"
	return self
end

function Logger:_send(msg)
	if not self.URL then
		return
	end

	task.spawn(function()
		pcall(function()
			request({
				Url = self.URL,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({
					content = msg
				})
			})
		end)
	end)
end

function Logger:log(msg, type)
	local label = self.Label
	local source = type or "general"
	local formatted = string.format("[%s - %s]: %s", label, source, tostring(msg))
	self:_send(formatted)
end

return Logger
