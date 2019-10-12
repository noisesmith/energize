-- shim to load polywell
local fennel_module = "polywell.lib.fennel"
fennel = require(fennel_module)
table.insert(package.loaders, fennel.make_searcher({correlate=true,
                                                    moduleName = fennel_module,
                                                    useMetadata=true,}))
package.loaded.fennel = fennel

fennel.path = love.filesystem.getSource() .. "/?.fnl;" ..
   love.filesystem.getSource() .. "/?/init.fnl;" .. fennel.path
local fennelview = require("polywell.lib.fennelview")
_G.pp = function(x) print(fennelview(x)) end

lume = require("polywell.lib.lume")

local editor = require("polywell")

-- sets up handlers for key, mouse, etc
lume.extend(love, editor.handlers)

love.draw = editor.draw

love.load = function()
   editor['set-wh'](320, 200)
   love.graphics.setFont(love.graphics.newFont("assets/Anonymous Pro.ttf", 10))
   love.keyboard.setTextInput(true)
   love.keyboard.setKeyRepeat(true)
   require("config")
end
