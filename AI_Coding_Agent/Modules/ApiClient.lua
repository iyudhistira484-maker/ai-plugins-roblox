-- ApiClient.lua
-- Mengelola komunikasi HTTP ke berbagai provider AI

local HttpService = game:GetService("HttpService")
local Constants = require(script.Parent.Constants)
local Utils = require(script.Parent.Utils)

local ApiClient = {}
ApiClient.__index = ApiClient

function ApiClient.new()
	local self = setmetatable({}, ApiClient)
	self.config = {}
	self.timeout = Constants.DEFAULT_TIMEOUT
	self.maxTokens = Constants.MAX_TOKENS
	return self
end

function ApiClient:updateConfig(config)
	self.config = config
end

function ApiClient:_buildHeaders()
	local headers = {}
	local template = Constants.PROVIDER_TEMPLATES[self.config.provider or "anthropic"]

	-- Default headers untuk semua provider
	headers["Content-Type"] = "application/json"

	if template and template.headerFormat then
		for headerName, pattern in pairs(template.headerFormat) do
			local value = pattern
			if self.config.apiKey then
				value = string.gsub(value, "{apiKey}", self.config.apiKey)
			end
			if self.config.providerId then
				value = string.gsub(value, "{providerId}", self.config.providerId)
			end
			if self.config.modelId then
				value = string.gsub(value, "{modelId}", self.config.modelId)
			end
			if self.config.apiVersion then
				value = string.gsub(value, "{apiVersion}", self.config.apiVersion)
			end
			headers[headerName] = value
		end
	end

	return headers
end

function ApiClient:_buildRequestBody(messages, systemPrompt)
	if self.config.provider == "openai" then
		-- Format OpenAI
		local formattedMessages = {}
		if systemPrompt and #systemPrompt > 0 then
			table.insert(formattedMessages, { role = "system", content = systemPrompt })
		end
		for _, msg in ipairs(messages) do
			table.insert(formattedMessages, { role = msg.role, content = msg.content })
		end
		return {
			model = self.config.model,
			max_tokens = self.maxTokens,
			messages = formattedMessages,
			stream = true,
		}
	else
		-- Format Anthropic atau custom (seperti 9router)
		return {
			model = self.config.model,
			max_tokens = self.maxTokens,
			system = systemPrompt or "",
			messages = messages,
			stream = true,
		}
	end
end

function ApiClient:_parseStreamResponse(chunk, buffer, onChunk)
	local success, json = Utils.validateJSON(chunk)
	if success and json then
		-- Format Anthropic
		if json.delta and json.delta.text then
			if onChunk then onChunk(json.delta.text) end
		-- Format OpenAI
		elseif json.choices and json.choices[1] and json.choices[1].delta then
			local delta = json.choices[1].delta
			if delta.content then
				if onChunk then onChunk(delta.content) end
			elseif delta.role == "assistant" then
				if onChunk then onChunk("") end
			end
		-- Format custom/9router
		elseif json.delta and json.delta.content then
			if onChunk then onChunk(json.delta.content) end
		end
	end
	return buffer
end

function ApiClient:sendMessage(messages, systemPrompt, onChunk, onComplete)
	if not self.config.apiKey or #self.config.apiKey == 0 then
		warn("[ApiClient] API Key belum diatur!")
		if onComplete then onComplete(false, "API Key belum diatur") end
		return false, "API Key belum diatur"
	end

	if not self.config.baseUrl or #self.config.baseUrl == 0 then
		warn("[ApiClient] baseUrl belum diatur!")
		if onComplete then onComplete(false, "Base URL belum diatur") end
		return false, "Base URL belum diatur"
	end

	local headers = self:_buildHeaders()
	local body = HttpService:JSONEncode(self:_buildRequestBody(messages, systemPrompt))
	local attempt = 0
	local lastError = ""

	repeat
		attempt += 1
		local request = {
			Url = self.config.baseUrl,
			Method = "POST",
			Headers = headers,
			Body = body,
			Timeout = self.timeout,
		}

		local success, result = pcall(function()
			return HttpService:RequestAsync(request)
		end)

		if success and result then
			local content = result.ResponseBody or ""
			-- Parse streaming response
			for line in string.gmatch(content, "[^\r\n]+") do
				if string.sub(line, 1, 5) == "data:" then
					local dataStr = string.sub(line, 7)
					if dataStr ~= "[DONE]" then
						self:_parseStreamResponse(dataStr, "", onChunk)
					end
				end
			end
			if onComplete then onComplete(true, result) end
			return true, result
		else
			lastError = tostring(result)
			warn(string.format("[ApiClient] Error (attempt %d/%d): %s",
				attempt, Constants.MAX_RETRIES, lastError))

			if (lastError:find("401") or lastError:find("403")) then
				lastError = "API Key tidak valid. Pastikan key Anda benar."
				break
			elseif lastError:find("429") then
				lastError = "Rate limit tercapai. Tunggu sebentar sebelum mencoba lagi."
			elseif lastError:find("404") then
				lastError = "Endpoint tidak ditemukan. Periksa Base URL Anda."
				break
			end

			if attempt < Constants.MAX_RETRIES then
				task.wait(Constants.BACKOFF_BASE * math.pow(2, attempt - 1))
			end
		end
	until attempt >= Constants.MAX_RETRIES

	if onComplete then onComplete(false, lastError) end
	return false, lastError
end

return ApiClient
