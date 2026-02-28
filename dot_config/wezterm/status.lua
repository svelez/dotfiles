local wezterm = require 'wezterm'

-- export module
local module = {}

function module.set(config)
	wezterm.on('update-status', function(window, pane)
		local config = window:effective_config() or {}
		local scheme_name = config.color_scheme or nil
		local scheme = wezterm.color.get_default_colors()
		local all_schemes = wezterm.color.get_builtin_schemes()


		if scheme_name ~= nil and all_schemes[scheme_name] ~= nil then
			scheme = all_schemes[scheme_name]
		end
		local bg = wezterm.color.parse(scheme.background):lighten(0.1)

		local SOLID_ARROW = wezterm.nerdfonts.pl_right_hard_divider
		local host = pane:get_user_vars().WEZTERM_HOST or "unknown"
		local pad = '   '
		window:set_right_status(wezterm.format {
			{ Background = { Color = 'none' } },
			{ Foreground = { Color = bg } },
			{ Text = SOLID_ARROW },
			{ Background = { Color = bg } },
			{ Foreground = { Color = scheme.foreground } },
			{ Text = pad },
			{ Text = wezterm.nerdfonts.cod_terminal },
			{ Text = pad },
			{ Text = window:active_workspace() },
			{ Text = pad },
			{ Text = wezterm.nerdfonts.md_monitor },
			{ Text = pad },
			{ Text = host },
			{ Text = pad },
		})
	end)
end

return module
