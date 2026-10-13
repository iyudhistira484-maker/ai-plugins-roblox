-- UI.lua
local Constants = require(script.Parent.Constants)

local UI = {}
UI.__index = UI

function UI.new(plugin)
	local self = setmetatable({}, UI)
	self.plugin = plugin
	self.dockWidget = nil
	self.gui = nil
	self.tabHistory = {}
	self.currentAIMessage = nil
	self.onSendMessage = nil
	self.onTemplateSelect = nil
	self.onSaveSettings = nil
	self.onProviderChange = nil
	return self
end

function UI:_create(name, props, parent)
	local obj = Instance.new(name)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	obj.Parent = parent or self.gui
	return obj
end

function UI:createGui()
	self.dockWidget = self.plugin:CreateDockWidgetPluginGui("AIAgentDockId", Instance.new("PluginGui"))
	self.dockWidget.Name = "AIAgentDock"
	self.dockWidget.Title = "AI Coding Agent"
	self.dockWidget.InitialDockState = Enum.DockState.Right
	self.dockWidget.PluginTag = "AIAgent_v2"

	self.gui = self:_create("ScreenGui", {
		Name = "MainUI",
		ResetOnSpawn = false
	})
	local main = self:_create("MainFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Constants.COLORS.BACKGROUND,
		BorderSizePixel = 0
	})
	self:_create("Title", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(35, 35, 40),
		Text = "AI Coding Agent",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Constants.COLORS.TEXT
	}, main)
	self:_createTabs(main)
	self:_createChatArea(main)
	self:_createInputArea(main)
	self:_createTemplates(main)
end

function UI:_createTabs(main)
	local tc = self:_create("Tabs", {
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	}, main)
	local ul = Instance.new("UIListLayout")
	ul.FillDirection = Enum.FillDirection.Horizontal
	ul.Padding = UDim.new(0, 2)
	ul.Parent = tc

	local tabs = {"Chat", "Rencana", "Hasil Tes", "Riwayat", "Pengaturan"}
	self.tabButtons = {}
	self.tabFrames = {}

	for i, name in ipairs(tabs) do
		local btn = self:_create("Btn_" .. name, {
			Size = UDim2.new(0, 140, 1, 0),
			BackgroundColor3 = (i == 1 and Constants.COLORS.ACCENT or Color3.fromRGB(60, 60, 65)),
			Font = Enum.Font.GothamSemiBold,
			Text = name,
			TextSize = 13,
			TextColor3 = Constants.COLORS.TEXT
		}, tc)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
		btn.MouseButton1Click:Connect(function() self:activateTab(i) end)
		table.insert(self.tabButtons, btn)

		local frame = self:_create("Frame_" .. name, {
			Size = UDim2.new(1, 0, 1, -80),
			Position = UDim2.new(0, 0, 0, 80),
			Visible = (i == 1)
		}, main)
		table.insert(self.tabFrames, frame)
	end
end

function UI:_createChatArea(main)
	local chatFrame = self.tabFrames[1]
	self.chatTab = self:_create("ChatArea", {
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 1, 0),
		ScrollBarThickness = 6
	}, chatFrame)
	local cl = Instance.new("UIListLayout")
	cl.Padding = UDim.new(0, 5)
	cl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	cl.Parent = self.chatTab
	self.chatContainer = self.chatTab

	self.typingIndicator = self:_create("Typing", {
		Size = UDim2.new(0.8, 0, 0, 30),
		Visible = false,
		BackgroundTransparency = 1
	}, self.chatTab)
end

function UI:_createSettingsTab(parent)
	local offset = 20
	self:_create("ProviderLbl", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, offset),
		Text = "Provider AI:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.providerDropdown = self:_create("ProviderDropdown", {
		Size = UDim2.new(1, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, offset + 25),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = "Pilih Provider"
	}, parent)
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 4)
	pc.Parent = self.providerDropdown

	self.providerOptions = self:_create("Options", {
		Size = UDim2.new(1, 0, 0, 150),
		Position = UDim2.new(0, 0, 0, offset + 60),
		Visible = false
	}, parent)
	local oc = Instance.new("UICorner")
	oc.CornerRadius = UDim.new(0, 4)
	oc.Parent = self.providerOptions

	self.selectedProvider = "anthropic"
	for key, tmpl in pairs(Constants.PROVIDER_TEMPLATES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 35)
		btn.BackgroundTransparency = 1
		btn.Text = "  " .. tmpl.label
		btn.Parent = self.providerOptions
		btn.MouseButton1Click:Connect(function()
			self.providerDropdown.Text = tmpl.label
			self.selectedProvider = key
			if self.onProviderChange then self.onProviderChange(key) end
			self.providerOptions.Visible = false
		end)
	end
	self.providerDropdown.MouseButton1Click:Connect(function()
		self.providerOptions.Visible = not self.providerOptions.Visible
	end)
end

function UI:_createSettingsTabFull(parent)
	self:_createSettingsTab(parent)
end

function UI:_createInputArea(main)
	local ib = self:_create("InputArea", {
		Size = UDim2.new(1, 0, 0, 70),
		Position = UDim2.new(0, 0, 1, -70),
		BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	}, main)
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(0, 8)
	ic.Parent = ib

	self.inputBox = self:_create("Input", {
		Size = UDim2.new(1, -130, 1, -12),
		Position = UDim2.new(0, 10, 0, 6),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Font = Enum.Font.Gotham,
		Text = "",
		TextSize = 13,
		TextColor3 = Constants.COLORS.TEXT,
		PlaceholderText = "Ketik pesan...",
		MultiLine = true
	}, ib)
	local ibc = Instance.new("UICorner")
	ibc.CornerRadius = UDim.new(0, 6)
	ibc.Parent = self.inputBox

	self.sendButton = self:_create("Send", {
		Size = UDim2.new(0, 100, 1, -12),
		Position = UDim2.new(1, -110, 0, 6),
		BackgroundColor3 = Constants.COLORS.ACCENT,
		Text = "Kirim",
		Font = Enum.Font.GothamSemiBold,
		TextSize = 13,
		TextColor3 = Color3.fromRGB(255, 255, 255)
	}, ib)
	local sbc = Instance.new("UICorner")
	sbc.CornerRadius = UDim.new(0, 6)
	sbc.Parent = self.sendButton

	self.sendButton.MouseButton1Click:Connect(function() self:sendMessage() end)
	self.inputBox.FocusLost:Connect(function(e) if e then self:sendMessage() end end)
end

function UI:_createTemplates(main)
	local tc = self:_create("Templates", {
		Size = UDim2.new(1, 0, 0, 40),
		Position = UDim2.new(0, 0, 1, -110),
		BackgroundTransparency = 1
	}, main)
	local t = Instance.new("UIListLayout")
	t.FillDirection = Enum.FillDirection.Horizontal
	t.HorizontalAlignment = Enum.HorizontalAlignment.Center
	t.Padding = UDim.new(0, 6)
	t.Parent = tc

	self.templateButtons = {}
	for i, tmpl in ipairs(Constants.TEMPLATES) do
		local btn = self:_create("Tmpl_" .. i, {
			Size = UDim2.new(0, 140, 1, 0),
			BackgroundColor3 = Color3.fromRGB(60, 60, 65),
			Text = tmpl.label,
			Font = Enum.Font.GothamSemiBold,
			TextSize = 11,
			TextColor3 = Constants.COLORS.TEXT
		}, tc)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
		btn.MouseButton1Click:Connect(function()
			if self.onTemplateSelect then self.onTemplateSelect(tmpl) end
		end)
		table.insert(self.templateButtons, btn)
	end
end

function UI:_createSettingsTabComplete(parent)
	self:_createSettingsTab(parent)
	local offset = 180
	self:_create("APIKeyLbl", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, offset),
		Text = "API Key:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.apiKeyBox = self:_create("ApiKey", {
		Size = UDim2.new(1, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, offset + 25),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = ""
	}, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = self.apiKeyBox

	self:_create("BaseURLLbl", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, offset + 70),
		Text = "Base URL:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.baseUrlBox = self:_create("BaseUrl", {
		Size = UDim2.new(1, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, offset + 95),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = ""
	}, parent)
	local c2 = Instance.new("UICorner")
	c2.CornerRadius = UDim.new(0, 4)
	c2.Parent = self.baseUrlBox

	-- Provider ID and Model ID for custom providers
	self:_create("ProviderIdLbl", {
		Size = UDim2.new(0.45, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, offset + 140),
		Text = "Provider ID:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.providerIdBox = self:_create("ProviderId", {
		Size = UDim2.new(0.45, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, offset + 165),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = ""
	}, parent)
	local c3 = Instance.new("UICorner")
	c3.CornerRadius = UDim.new(0, 4)
	c3.Parent = self.providerIdBox

	self:_create("ModelIdLbl", {
		Size = UDim2.new(0.45, 0, 0, 25),
		Position = UDim2.new(0.55, 0, 0, offset + 140),
		Text = "Model ID:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.modelIdBox = self:_create("ModelId", {
		Size = UDim2.new(0.45, 0, 0, 35),
		Position = UDim2.new(0.55, 0, 0, offset + 165),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = ""
	}, parent)
	local c4 = Instance.new("UICorner")
	c4.CornerRadius = UDim.new(0, 4)
	c4.Parent = self.modelIdBox

	-- Model selection dropdown
	self:_create("ModelLbl", {
		Size = UDim2.new(1, 0, 0, 25),
		Position = UDim2.new(0, 0, 0, offset + 210),
		Text = "Model:",
		Font = Enum.Font.GothamSemiBold,
		TextColor3 = Constants.COLORS.TEXT
	}, parent)

	self.modelDropdown = self:_create("ModelDropdown", {
		Size = UDim2.new(1, 0, 0, 35),
		Position = UDim2.new(0, 0, 0, offset + 235),
		BackgroundColor3 = Color3.fromRGB(55, 55, 60),
		Text = "Claude 3.5 Sonnet"
	}, parent)
	local c5 = Instance.new("UICorner")
	c5.CornerRadius = UDim.new(0, 4)
	c5.Parent = self.modelDropdown

	self.modelOptions = self:_create("ModelOptions", {
		Size = UDim2.new(1, 0, 0, 150),
		Position = UDim2.new(0, 0, 0, offset + 270),
		Visible = false
	}, parent)
	local c6 = Instance.new("UICorner")
	c6.CornerRadius = UDim.new(0, 4)
	c6.Parent = self.modelOptions

	local ml = Instance.new("UIListLayout")
	ml.Parent = self.modelOptions

	for i, m in ipairs(Constants.MODELS) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundTransparency = 1
		btn.Text = m.label
		btn.Parent = self.modelOptions
		btn.MouseButton1Click:Connect(function()
			self.modelDropdown.Text = m.label
			if self.onModelChange then self.onModelChange(m.value) end
			self.modelOptions.Visible = false
		end)
	end

	self.modelDropdown.MouseButton1Click:Connect(function()
		self.modelOptions.Visible = not self.modelOptions.Visible
	end)
end

function UI:_createContentArea(main)
	self:_createChatAreaContent(self.tabFrames[1])
	self:_createSettingsTabComplete(self.tabFrames[5])
end

function UI:_createChatAreaContent(parent)
	-- Chat area is already created in _createChatArea
end

function UI:activateTab(index)
	for i, frame in ipairs(self.tabFrames) do
		frame.Visible = (i == index)
	end
	for i, btn in ipairs(self.tabButtons) do
		btn.BackgroundTransparency = (i == index) and 0 or 0.7
		btn.BackgroundColor3 = (i == index) and Constants.COLORS.ACCENT or Color3.fromRGB(60, 60, 65)
	end
	self.tabIndex = index
end

function UI:showTyping(show)
	if self.typingIndicator then
		self.typingIndicator.Visible = show
	end
end

function UI:addAIMessage(text, isStreaming)
	if isStreaming and self.currentAIMessage then
		self.currentAIMessage.Text = self.currentAIMessage.Text .. text
		return
	end
	local bubble = self:_create("AIBubble", {
		Size = UDim2.new(0.8, 0, 0, 30),
		BackgroundColor3 = Constants.COLORS.AI_BUBBLE,
		AutomaticSize = Enum.AutomaticSize.Y
	}, self.chatContainer)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.2, 0)
	c.Parent = bubble

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, -20)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = Constants.COLORS.TEXT
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = bubble
	self.currentAIMessage = label
	self.chatTab.CanvasSize = UDim2.new(0, 0, 0, self.chatTab.AbsoluteContentSize.Y + 20)
end

function UI:addSystemMessage(text)
	local label = self:_create("System", {
		Size = UDim2.new(0.8, 0, 0, 25),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = Color3.fromRGB(150, 150, 160),
		TextWrapped = true
	}, self.chatContainer)
	self.chatTab.CanvasSize = UDim2.new(0, 0, 0, self.chatTab.AbsoluteContentSize.Y + 10)
end

function UI:sendMessage()
	local text = self.inputBox.Text
	if text and #string.gsub(text, "%s", "") > 0 then
		local bubble = self:_create("UserBubble", {
			Size = UDim2.new(0.8, 0, 0, 30),
			BackgroundColor3 = Constants.COLORS.USER_BUBBLE,
			AutomaticSize = Enum.AutomaticSize.Y
		}, self.chatContainer)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.2, 0)
		c.Parent = bubble
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -20, 1, -20)
		label.Position = UDim2.new(0, 10, 0, 10)
		label.BackgroundTransparency = 1
		label.Text = text
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextColor3 = Constants.COLORS.TEXT
		label.TextWrapped = true
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Parent = bubble
		self.inputBox.Text = ""
		if self.onSendMessage then
			self.onSendMessage(text)
		end
	end
end

function UI:hide()
	if self.dockWidget then
		self.dockWidget.Visible = false
	end
end

return UI
