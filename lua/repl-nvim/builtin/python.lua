local _opts = require("repl-nvim")._config.python
local shared = require("repl-nvim.builtin.shared")

local function venvExists()
	return vim.fn.isdirectory(vim.fn.getcwd() .. "/env") == 1 -- the == 1 here is important for lua
end

local function anacondaVenvExists()
	return vim.fn.filereadable(vim.fn.getcwd() .. "/environment.yaml") == 1 -- the == 1 here is important for lua
end

local function getAnacondaVenv()
	local grep = "grep 'name:' environment.yaml"
	local phony_removal = "sed 's/name:[ ]*//'"
	local commands = vim.trim(vim.fn.system(string.format("%s | %s", grep, phony_removal)))
	return commands
end


local function wrapVenvOutput(term, output, opts)
	if opts.source ~= "" then
		local source = vim.trim(opts.source)
		return require("harpoon.term").sendCommand(term, "%s %s && %s && %s\n", "source", source, output, "deactivate")
	elseif venvExists() then
		return require("harpoon.term").sendCommand(term, "%s && %s && %s\n", "source env/bin/activate", output, "deactivate")
	-- else
		-- return require("harpoon.term").sendCommand(term, output .. "\n")

	-- source /root/anaconda3/bin/activate wmanalysis && conda activate wmanalysis && python3 -m automation_scripts.update_all.py && conda deactivate
	elseif anacondaVenvExists() then
		local name = getAnacondaVenv()
		return require("harpoon.term").sendCommand(term, "source /root/anaconda3/bin/activate "..name.." && conda activate "..name.." && " .. output .." && conda deactivate \n")
	else
		return require("harpoon.term").sendCommand(term, output .. "\n")
	end
end

M.sourceVenv = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	local file = vim.fn.expand("%")
	wrapVenvOutput(term, string.format("python3 %s", file), opts)
	require("harpoon.term").gotoTerminal(term)
end

M.sourceInstallModules = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	local prompt = "enter python module for installation: "
	local response = vim.trim(vim.fn.input({prompt = prompt, cancelreturn = ""}))
	local res
	if string.len(response) ~= 0 then
		res = wrapVenvOutput(term, string.format("pip3 install %s", response), opts)
	end
	return res
end

local lineIsIndented = function (line)
	local char = string.sub(line, 1, 1)
	return char == " " or char == '\t'
end

local blacklist = function(line)
	local blacklist = {"except", "else", "elif"}
	for _, items in ipairs(blacklist) do
		local find = string.find(line, items)
		if find == 1 then
			return true
		end
	end
	-- print(type(string.find(line, "except")[1]))
	return false
end

local sendLine = function (line, term)
	if line == "" then
		return
	end

	if lineIsIndented(line) then
		shared.state["python"].previously_indented = true
	elseif shared.state["python"].previously_indented and not blacklist(line) then
		require("harpoon.term").sendCommand(term, "\n")
		shared.state["python"].previously_indented = false
	end

	if not shared.lineStartsWithPattern("#", line) then
		require("harpoon.term").sendCommand(term, (vim.fn.substitute(line, "%", "%%", "g")) .. "\n") -- escaping strings cause % causes problems with harpoon
	end
end

M.replInit = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.replInit(term, opts, wrapVenvOutput, "python")
end

-- code for having a jupyter like experience
M.runReplSelection = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplSelection(term, opts, M.replInit, wrapVenvOutput, sendLine, "python")
end

M.runReplBlock = function(term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplBlock(term, opts, M.replInit, sendLine, "python")
end

M.runReplLineNoIndent = function (term, opts)
	opts = vim.tbl_deep_extend("force", _opts, opts or {})
	return shared.runReplLineNoIndent(term, opts, M.replInit, sendLine, "python")
end

return M
