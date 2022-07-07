.PHONY: docs test

docs: README.org
	pandoc -s README.org -o README.md -t gfm

test: lua/repl-nvim/tests/test.py
	nvim $^ -c "lua require('repl-nvim/tests')"
		
