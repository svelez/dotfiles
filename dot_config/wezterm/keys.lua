local wezterm = require 'wezterm'

-- export module
local module = {}

function assign_dirs(config, actFn, kt_name, mod)
	local kt = {}
	local top_mod = ''
	if mod ~= nil then
		top_mod = ('|'..mod)
	end

	-- For every direction 
	for i, dir in ipairs({'Up', 'Down', 'Left', 'Right'}) do
		-- Compute the activation action
		local act = actFn(dir)
		-- ... and the key that triggers it
		local actKey = (dir .. 'Arrow')

		-- Now add a callback for that key that performs the action
		-- AND activates a temporary key table to allow repeated operations
		table.insert(
			config.keys,
			{
				key = actKey,
				mods = ('LEADER'..top_mod),
				action = wezterm.action_callback(function(win, pane)
					win:perform_action( act, pane )
					win:perform_action(
						wezterm.action.ActivateKeyTable {
							name = kt_name,
							timeout_milliseconds = 1000,
							one_shot = false,
						},
						pane
					)
				end)	
			}
		)

		-- Also include that key and action in the key table
		table.insert( kt, { key = actKey, mods = mod, action = act, } )
	end

	config.key_tables[kt_name] = kt
end

function do_nav(config)
	assign_dirs(config, wezterm.action.ActivatePaneDirection, 'activate_pane')
end

function do_resize(config)
	do_resize = function(dir)
		return wezterm.action.AdjustPaneSize({ dir, 5 })
	end
	assign_dirs(config, do_resize, 'resize_pane', 'META')
end

-- keys mapping
function module.apply_to_config(config)
	config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }
	config.keys = {
		-- forward leader key
		{
			key = 'a',
			mods = 'LEADER|CTRL',
			action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
		},
		-- emulate default tmux pane splitting
		{
			key = '%',
			mods = 'LEADER|SHIFT',
			action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
		},
		{
			key = '"',
			mods = 'LEADER|SHIFT',
			action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
		},
	}

	-- emulate default tmux pane nav
	do_nav(config)
	do_resize(config)
end

return module
