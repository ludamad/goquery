#!/usr/bin/env lua

-- Copyright (c) 2011-2012 Rob Hoelz <rob@hoelz.ro>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of
-- this software and associated documentation files (the "Software"), to deal in
-- the Software without restriction, including without limitation the rights to
-- use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
-- the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
-- FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
-- COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
-- IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

-- Not as cool a name as re.pl, but I tried.

local repl          = require 'repl.console'
local has_linenoise = pcall(require, 'linenoise')

if has_linenoise then
  repl:loadplugin 'linenoise'
else
  -- XXX check that we're not receiving input from a non-tty
  local has_rlwrap = os.execute('which rlwrap >/dev/null 2>/dev/null') == 0

  if has_rlwrap and not os.getenv 'LUA_REPL_RLWRAP' then
    local lowest_index = -1

    while arg[lowest_index] ~= nil do
      lowest_index = lowest_index - 1
    end
    lowest_index = lowest_index + 1
    os.execute(string.format('LUA_REPL_RLWRAP=1 rlwrap %q %q', arg[lowest_index], arg[0]))
    return
  end
end

repl:loadplugin 'history'
repl:loadplugin 'completion'
repl:loadplugin 'autoreturn'
repl:loadplugin 'rcfile'

print('Lua REPL ' .. tostring(repl.VERSION))
repl:run()
