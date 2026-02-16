-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- and local helper modules
local keys = require 'keys'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font = wezterm.font('Hack Nerd Font Mono')
config.font_size = 14
config.color_scheme = 'Solarized (dark) (terminal.sexy)'
config.window_background_opacity = 0.95

-- around the terminal
config.window_padding = {
	left = '1cell',
	right = '1cell',
	top = '1cell',
	bottom = '1cell',
}
config.window_decorations = 'RESIZE'
-- config.hide_tab_bar_if_only_one_tab = true

--- External config
config.key_tables = {}
keys.apply_to_config(config)

-- Finally, return the configuration to wezterm:
return config
