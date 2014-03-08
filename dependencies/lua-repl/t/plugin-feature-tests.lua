local repl  = require 'repl'
local utils = require 'test-utils'
pcall(require, 'luarocks.loader')
require 'Test.More'

plan(14)

do -- basic tests {{{
  local clone = repl:clone()

  clone:loadplugin(function()
    features = 'foo'
  end)

  ok(clone:hasfeature 'foo')
  ok(not clone:hasfeature 'bar')
  ok(not clone:hasfeature 'baz')

  clone:loadplugin(function()
    features = { 'bar', 'baz' }
  end)

  ok(clone:hasfeature 'foo')
  ok(clone:hasfeature 'bar')
  ok(clone:hasfeature 'baz')
end -- }}}

do -- requirefeature {{{
  local clone = repl:clone()

  clone:loadplugin(function()
    features = 'foo'
  end)

  clone:requirefeature 'foo'

  local line_no
  local _, err = pcall(function()
    line_no = utils.next_line_number()
    clone:requirefeature 'bar'
  end)

  like(err, tostring(line_no) .. ': required feature "bar" not present')
end -- }}}

do -- conflicts {{{
  local clone = repl:clone()
  local line_no

  clone:loadplugin(function()
    features = 'foo'
  end)

  local _, err = pcall(function()
    line_no = utils.next_line_number()
    clone:loadplugin(function()
      features = 'foo'
    end)
  end)
  like(err, tostring(line_no) .. ': feature "foo" already present')

  -- XXX what about methods injected into the object?
end -- }}}

do -- clone:hasfeature {{{
  local child = repl:clone()

  child:loadplugin(function()
    features = 'foo'
  end)

  local grandchild = child:clone()

  ok(not repl:hasfeature 'foo')
  ok(child:hasfeature 'foo')
  ok(grandchild:hasfeature 'foo')

  child:loadplugin(function()
    features = 'bar'
  end)

  ok(not repl:hasfeature 'bar')
  ok(child:hasfeature 'bar')
  ok(not grandchild:hasfeature 'bar')
end -- }}}
