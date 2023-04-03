local _opts = require("repl-nvim")._config.cpp
local shared = require("repl-nvim.builtin.shared")


local function wrapVenvOutput(term, output, opts)
	if opts.source ~= "" then
		print("have not implemented sources yet")
	else
		return require("harpoon.term").sendCommand(term, output .. "\n")
	end
end

local sendLine = function (line, term)
	if line == "" then
		return
	end
	-- if shared.lineStartsWithPattern("///", line, 1) then
	-- 	line = line:match("///(.*)$")
	-- 	require("harpoon.term").sendCommand(term, (vim.fn.substitute(line, "%", "%%", "g")) .. "\n") -- escaping strings cause % causes problems with harpoon
	-- 	return
	-- end
	if shared.lineStartsWithPattern("/*", line, 1) then
		shared.state["cpp"].in_comment_block = true;
	end
	if shared.lineEndsWithPattern("*/", line, 2) then
		shared.state["cpp"].in_comment_block = false;
		return
	end
	if not shared.lineStartsWithPattern("//", line, 1) and not shared.state["cpp"].in_comment_block then
		require("harpoon.term").sendCommand(term, (vim.fn.substitute(line, "%", "%%", "g")) .. "\n") -- escaping strings cause % causes problems with harpoon
	end
end

M.replInit = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.replInit(term, opts, wrapVenvOutput, "cpp")
end

M.runReplSelection = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplSelection(term, opts, M.replInit, wrapVenvOutput, sendLine, "cpp")
end

M.runReplBlock = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplBlock(term, opts, M.replInit, sendLine, "cpp", "////")
end

M.runReplLineNoIndent = function (term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplLineNoIndent(term, opts, M.replInit, sendLine, "cpp")
end

return M
