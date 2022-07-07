local M = {}

local function trimWhitespace(line, trim_whitespace)
  	-- removes indentation and other unnecessary whitespace
  	if trim_whitespace == nil then
  		trim_whitespace = true
  	end
  	if trim_whitespace then
  		line = vim.trim(line)
  	end
		return line
end


M.lineStartsWithPattern = function(pattern, line, trim_whitespace)
	local pattern_len = string.len(pattern)
	assert(pattern_len >= 1)
	line = trimWhitespace(line, trim_whitespace)
	-- print(string.sub(line, 1, pattern_len) == pattern)
	return string.len(line) >= pattern_len and string.sub(line, 1, pattern_len) == pattern
end

M.lineEndsWithPattern = function(pattern, line, trim_whitespace)
	local pattern_len = string.len(pattern)
	assert(pattern_len >= 1)
	line = trimWhitespace(line, trim_whitespace)
	-- print(string.sub(line, 1, pattern_len) == pattern)
	return string.len(line) >= pattern_len and string.sub(line, -string.len(pattern), -1) == pattern
end


M.setup = function ()
	M.state = {
		["python"] = {
			was_init = false,
			previously_indented = false
		},
		["cpp"] = {
			was_init = false,
			in_comment_block = false
		}
	}
end

M.replInit = function(term, opts, wrapVenvOutput, lang)
	-- print(term)
	-- print(opts)
	-- print(lang)
	wrapVenvOutput(term, opts.repl, opts)
	-- print(vim.inspect(M))
	-- print(vim.inspect(M.state))
	-- print(lang)
	M.state[lang].was_init = true
end

-- code for having a jupyter like experience
M.runReplSelection = function(term, opts, replInit, wrapVenvOutput, sendLine, lang)
	local lower = vim.fn.getpos("v")[2]
	local upper = vim.fn.getpos(".")[2]
	if M.state[lang].was_init == false then
		replInit(term, opts, wrapVenvOutput)
	end
	if lower > upper then
		lower, upper = upper, lower
	end
	while lower <= upper do
		sendLine(vim.fn.getline(lower), term, lang)
		lower = lower + 1
	end
	require("harpoon.term").sendCommand(term, "\n")
end

M.runReplBlock = function(term, opts, replInit, sendLine, lang)
	if M.state[lang].was_init == false then
		replInit(term, opts)
	end
	local line_num = vim.fn.getpos(".")[2]
	while line_num > 1 do
		if M.lineStartsWithPattern("##", vim.fn.getline(line_num)) then
			line_num = line_num + 1
			break
		end
		line_num = line_num - 1
	end
	-- P(line_num)
	-- P(vim.fn.getpos("$")[2])
	while line_num <= vim.fn.getpos("$")[2] do
		local line = vim.fn.getline(line_num)
		if M.lineStartsWithPattern("##", line) then
			break
		else
			sendLine(line, term)
		end
		line_num = line_num + 1;
	end
	require("harpoon.term").sendCommand(term, "\n")
end

M.runReplLineNoIndent = function (term, opts, replInit, sendLine, lang)
	if M[lang].was_init == false then
		replInit(term, opts)
	end
	local line = vim.fn.getline(".")
	line = vim.trim(line)
	sendLine(line, term)
end


return M
