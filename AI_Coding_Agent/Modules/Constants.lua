-- Constants.lua
-- Berisi konstanta yang digunakan di seluruh plugin

return {
	API_URL = "https://api.anthropic.com/v1/messages",
	DEFAULT_MODEL = "claude-3-5-sonnet-20240620",

	COLORS = {
		BACKGROUND = Color3.fromRGB(25, 25, 30),
		USER_BUBBLE = Color3.fromRGB(40, 140, 255),
		AI_BUBBLE = Color3.fromRGB(45, 45, 50),
		ACCENT = Color3.fromRGB(40, 140, 255),
		TEXT = Color3.fromRGB(240, 240, 240),
		SUCCESS = Color3.fromRGB(76, 175, 80),
		WARNING = Color3.fromRGB(255, 193, 7),
		ERROR = Color3.fromRGB(244, 67, 54),
	},

	PROVIDER_TEMPLATES = {
		anthropic = {
			label = "Anthropic (Claude)",
			baseUrl = "https://api.anthropic.com/v1/messages",
			headerFormat = {
				["x-api-key"] = "{apiKey}",
				["anthropic-version"] = "2023-06-01",
			},
		},
		openai = {
			label = "OpenAI (GPT)",
			baseUrl = "https://api.openai.com/v1/chat/completions",
			headerFormat = {
				["Authorization"] = "Bearer {apiKey}",
			},
		},
		["9router"] = {
			label = "9router",
			baseUrl = "https://api.9router.com/v1/chat",
			headerFormat = {
				["X-Provider-ID"] = "{providerId}",
				["X-API-Key"] = "{apiKey}",
				["X-Model-ID"] = "{modelId}",
			},
		},
	},

	MODELS = {
		{ label = "Claude 3.5 Sonnet", value = "claude-3-5-sonnet-20240620" },
		{ label = "Claude 3 Haiku", value = "claude-3-haiku-20240307" },
		{ label = "Claude 3 Opus", value = "claude-3-opus-20240229" },
		{ label = "GPT-4o", value = "gpt-4o" },
		{ label = "GPT-3.5 Turbo", value = "gpt-3.5-turbo" },
	},

	TEMPLATES = {
		{ label = "Jelaskan script ini", prompt = "Tolong jelaskan fungsi dari script yang sedang dipilih di Roblox Studio. Saya inginkan pemahaman yang jelas dan rinci." },
		{ label = "Cari bug", prompt = "Tolong tinjau kode berikut dan cari potensi bug atau masalah. Sertakan saran perbaikan jika ada." },
		{ label = "Optimalkan", prompt = "Tolong optimalkan kode Luau berikut untuk performa yang lebih baik. Saya menginginkan solusi yang scalable." },
		{ label = "Tambah komentar", prompt = "Tolong tambahkan komentar yang informatif ke kode Luau berikut. Fokus pada kejelasan dan dokumentasi." },
		{ label = "Ubah ke Luau bertipe", prompt = "Ubah kode Luau berikut menjadi versi bertipe (typed) dengan menggunakan type annotations. Sertakan interface dan type definitions yang sesuai." },
		{ label = "Review keamanan", prompt = "Lakukan review keamanan terhadap kode Luau berikut. Cari celah seperti RemoteEvent tanpa validasi, client yang dipercaya untuk data sensitif, atau isu keamanan lainnya." },
	},

	MAX_RETRIES = 3,
	BACKOFF_BASE = 1,
	DEFAULT_TIMEOUT = 120,
	MAX_TOKENS = 4096,
	SETTINGS_KEY = "AI_Agent_v1",
}
