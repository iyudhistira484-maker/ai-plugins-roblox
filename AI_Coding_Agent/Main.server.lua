-- Main.server.lua
-- Entry point AI Coding Agent Plugin

local plugin = _G["Plugin"] or game:GetService("CoreStudioService"):FindFirstChild("Plugins"):FindFirstChildOfClass("LocalPlugin")

if not plugin then
	warn("AI Coding Agent: Plugin reference tidak ditemukan")
	return
end

-- Load Modules
local Constants = require(script.Parent.Modules.Constants)
local ApiClient = require(script.Parent.Modules.ApiClient)
local UI = require(script.Parent.Modules.UI)

-- Initialize components
local apiClient = ApiClient.new()
local ui = UI.new(plugin)

-- Load saved settings
local settings = plugin:GetSetting(Constants.SETTINGS_KEY) or {}
apiClient:updateConfig(settings)

-- Create GUI
ui:createGui()

-- Load settings into UI
if settings.apiKey then
	ui.apiKeyBox.Text = settings.apiKey
end
if settings.baseUrl then
	ui.baseUrlBox.Text = settings.baseUrl
end
if settings.providerId then
	ui.providerIdBox.Text = settings.providerId
end
if settings.modelId then
	ui.modelIdBox.Text = settings.modelId
end

-- Set provider dropdown
if settings.provider then
	local tmpl = Constants.PROVIDER_TEMPLATES[settings.provider]
	if tmpl then
		ui.providerDropdown.Text = tmpl.label
		ui.selectedProvider = settings.provider
	end
end

-- Set model dropdown
if settings.model then
	local found = false
	for i, m in ipairs(Constants.MODELS) do
		if m.value == settings.model then
			ui.modelDropdown.Text = m.label
			found = true
			break
		end
	end
	if not found then
		ui.modelDropdown.Text = settings.model
	end
end

-- Event handlers
ui.onSendMessage = function(message)
	ui.chatHistory = ui.chatHistory or {}
	table.insert(ui.chatHistory, { role = "user", content = message })
	ui:showTyping(true)

	local systemPrompt = "Kamu adalah agen coding Roblox yang ahli Luau. Jawab dalam Bahasa Indonesia. Tulis kode Luwai modern (task.wait bukan wait, game:GetService, tipe opsional). Kerjakan satu langkah rencana per giliran. Serta sebutkan jenis script (Script/LocalScript/ModuleScript) dan lokasi penempatannya."

	apiClient:sendMessage(
		ui.chatHistory,
		systemPrompt,
		function(chunk)
			ui:addAIMessage(chunk, true)
		end,
		function(success, result)
			ui:showTyping(false)
			if not success then
				ui:addAIMessage("Terjadi kesalahan: " .. tostring(result), false)
			end
		end
	)
end

ui.onTemplateSelect = function(template)
	ui.inputBox.Text = template.prompt
end

ui.onSaveSettings = function()
	local config = {
		provider = ui.selectedProvider or "anthropic",
		apiKey = ui.apiKeyBox.Text,
		baseUrl = ui.baseUrlBox.Text,
		providerId = ui.providerIdBox.Text,
		modelId = ui.modelIdBox.Text,
		model = (function()
			for i, m in ipairs(Constants.MODELS) do
				if m.label == ui.modelDropdown.Text then
					return m.value
				end
			end
			return ui.modelIdBox.Text or Constants.DEFAULT_MODEL
		end)()
	}
	plugin:SetSetting(Constants.SETTINGS_KEY, config)
	apiClient:updateConfig(config)
	ui:addSystemMessage("Pengaturan berhasil disimpan!")
end

ui.onProviderChange = function(providerKey)
	ui:addSystemMessage("Provider diganti ke: " .. Constants.PROVIDER_TEMPLATES[providerKey].label)
end

ui.onModelChange = function(modelId)
	ui:addSystemMessage("Model diganti ke: " .. modelId)
end

-- Add save button handler
if ui.tabFrames and #ui.tabFrames >= 5 then
	local settingsFrame = ui.tabFrames[5]
	local saveBtn = ui:_create("SaveBtn", {
		Size = UDim2.new(1, -40, 0, 35),
		Position = UDim2.new(0, 20, 0, 400),
		BackgroundColor3 = Constants.COLORS.SUCCESS,
		Font = Enum.Font.GothamSemiBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "Simpan Pengaturan"
	}, settingsFrame)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = saveBtn

	saveBtn.MouseButton1Click:Connect(function()
		ui.onSaveSettings()
	end)
end

-- Show welcome message
ui:addSystemMessage("Selamat datang di AI Coding Agent!")
ui:addSystemMessage("Pilih provider AI di tab Pengaturan, lalu masukkan API Key Anda.")

return true
