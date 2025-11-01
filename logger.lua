local HttpService = game:GetService("HttpService")

-- constants
local PREFIX_WIDTH = 20
local TIME_WIDTH = 8
local WEBHOOK = "https://discord.com/api/webhooks/1433575446506770524/naFId4iZeusdTCjLz_eoVxkkkDeaQUZVHPTsIi_r427MK3lkAE_UuQaY8_2Uhfmh6zma"
local FLUSH_INTERVAL = 5
local BATCH_SIZE = 3
local LINE_WIDTH = 112

-- states
local log_buffer = {}
local last_flush = tick()

local function format_line(section, msg)
	local time = os.date("%H:%M:%S")
	local prefix = ("[monitor - %s]"):format(section)

	local adjusted_msg = msg:gsub("?", "D") 

	if #prefix > PREFIX_WIDTH then
		prefix = prefix:sub(1, PREFIX_WIDTH - 3) .. "..."
	else
		prefix = string.format("%-" .. PREFIX_WIDTH .. "s", prefix)
	end

	local available_for_msg = LINE_WIDTH - PREFIX_WIDTH - TIME_WIDTH - 2

	if #adjusted_msg > available_for_msg then
		msg = msg:sub(1, available_for_msg - 3) .. "..."
		adjusted_msg = msg:gsub("?", "D")
	end

	local current_length = PREFIX_WIDTH + 1 + #adjusted_msg + 1
	local padding_needed = LINE_WIDTH - current_length - TIME_WIDTH
	local padding = string.rep(" ", padding_needed)

	return string.format("%s %s%s%s", prefix, msg, padding, time)
end
local function sendToWebhook(lines)
	task.spawn(function()
		local combined = table.concat(lines, "\n")
		local content = ("```ini\n%s\n```"):format(combined)
		local success, err = pcall(function()
			request({
				Url = WEBHOOK,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({ content = content })
			})
		end)
		if not success then
			warn("[monitor] failed to send log to webhook:", err)
		end
	end)
end

local function flush_logs(force)
	if #log_buffer == 0 then return end

	while #log_buffer > 0 do
		local chunk = {}
		for i = 1, math.min(BATCH_SIZE, #log_buffer) do
			table.insert(chunk, table.remove(log_buffer, 1))
		end
		sendToWebhook(chunk)

		if not force or #log_buffer == 0 then
			break
		end
	end

	last_flush = tick()
end

local function log(section, msg)
	local line = format_line(section, msg)
	table.insert(log_buffer, line)

	if #log_buffer >= BATCH_SIZE then
		flush_logs()
	end

	if tick() - last_flush > FLUSH_INTERVAL then
		flush_logs(true)
	end
end

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		if #log_buffer > 0 then
			flush_logs(true)
		end
	end
end)

return {
	log = log
}
