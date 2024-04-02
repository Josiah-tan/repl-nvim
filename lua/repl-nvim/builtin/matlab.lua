local _opts = require("repl-nvim")._config.matlab
local shared = require("repl-nvim.builtin.shared")
local M = {}

local function wrapVenvOutput(term, output, opts)
	if opts.source ~= "" then
		print("have not implemented sources yet")
	else
		return require("harpoon.term").sendCommand(term, output .. "\r")
	end
end

local sendLine = function (line, term)
	if line == "" then
		return
	end
	-- if shared.lineStartsWithPattern("///", line, 1) then
	-- 	line = line:match("///(.*)$")
	-- 	require("harpoon.term").sendCommand(term, (vim.fn.substitute(line, "%", "%%", "g")) .. "\r") -- escaping strings cause % causes problems with harpoon
	-- 	return
	-- end
	if shared.lineStartsWithPattern("%{", line, 1) then
		shared.state["matlab"].in_comment_block = true;
	end
	if shared.lineEndsWithPattern("%}", line, 2) then
		shared.state["matlab"].in_comment_block = false;
		return
	end
	if not shared.lineStartsWithPattern("%", line, 1) and not shared.state["matlab"].in_comment_block then
		require("harpoon.term").sendCommand(term, (vim.fn.substitute(line, "%", "%%", "g")) .. "\r") -- escaping strings cause % causes problems with harpoon
	end
end

M.sourceVenv = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	local file = vim.fn.expand("%")
	vim.cmd[[:wa]]
	wrapVenvOutput(term, string.format([[matlab -nodesktop -nosplash -r "run('%s');exit;"]], file), opts)
	-- wrapVenvOutput(term, string.format("python3 %s", file), opts)
	require("harpoon.term").gotoTerminal(term)
end

M.replInit = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.replInit(term, opts, wrapVenvOutput, "matlab")
end

M.runReplSelection = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplSelection(term, opts, M.replInit, wrapVenvOutput, sendLine, "matlab")
end

M.runReplBlock = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplBlock(term, opts, M.replInit, sendLine, "matlab", "%%")
end

M.runReplLineNoIndent = function (term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplLineNoIndent(term, opts, M.replInit, sendLine, "matlab")
end

return M

