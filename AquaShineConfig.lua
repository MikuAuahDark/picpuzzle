-- AquaShine configuration file

return {
	Entries = {
		-- List of entry points in form
		-- name = {minarg, "scriptfile.lua"}
		-- if minarg is -1, it can't be invoked from command-line
		puzzle_main = {1, "puzzle_main.lua"},
		menu = {0, "prog.lua"}
	},
	-- Default entry point to be used if there's none specificed in command-line
	DefaultEntry = "menu",
	-- Allow entry points to be preloaded?
	-- Disabling entry preloading allows code that changed to be reflected without restarting
	EntryPointPreload = false,
	
	-- If this table present, letterboxing is enabled.
	-- Otherwise, if it's not present, letterboxing is disabled.
	Letterboxing = {
		-- Logical screen width. Letterboxed if necessary.
		LogicalWidth = 864,
		-- Logical screen height. Letterboxed if necessary.
		LogicalHeight = 486
	},
	
	-- LOVE-specific configuration
	LOVE = {
		-- The name of the save directory
		Identity = "picpuzzle",
		-- The LÖVE version this game was made for
		Version = "0.10.0",
		-- Enable external storage for Android
		AndroidExternalStorage = true,
		-- Window title name
		WindowTitle = "Picture Puzzle",
		-- Window icon path
		WindowIcon = "icon32.png",
		-- Default window width
		Width = 864,
		-- Default window height
		Height = 486,
		-- Let the window be user-resizable
		Resizable = true,
		-- Minimum window width if the window is resizable
		MinWidth = 256,
		-- Minimum window height if the window is resizable
		MinHeight = 144
	},
	
	-- AquaShine extensions/modules
	Extensions = {
		-- Disable multitouch support?
		NoMultiTouch = true,
		-- Disable audio?
		DisableAudio = true,
		-- Disable threads? This also disable screenshot and Download feature as it depends on it
		DisableThread = false,
		-- Disable video? This also disables FFX and extensions which depends on it.
		DisableVideo = true,
		-- Disable FFX? This also disable TempDirectory as it depends on it
		DisableFFX = true,
		-- Disable download?
		DisableDownload = true,
		-- Disable TempDirectory?
		DisableTempDirectory = true
	}
}
