local M = {}
local shared = require("repl-nvim.builtin.shared")

M.setup = function(config)
	config = config or {}
	M._config = M._config or {
		python = {
			getSource = function() return "" end,
			repl = "python3",
			tox_environment = "test_service"
		},
		cpp = {
			getSource = function() return "" end,
			repl = "cling"
		},
		matlab = {
			getSource = function() return "" end,
			repl = "matlab -nodesktop"
		}
	}
	M._config = vim.tbl_deep_extend("force", M._config, config)
	shared.setup()
end


return M

