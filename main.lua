
return function(mod)
  local Strings = require("src.core.Strings")

  local SPEEDS = {
    { 5, "SLOW" }, { 3, "MEDIUM" }, { 1, "FAST" },
    { "fastest", "FASTEST" }, { "instant", "INSTANT" },
  }

  local function speedIndex(game)
    local cur = game.save.options.textSpeed or 3
    for i, s in ipairs(SPEEDS) do
      if s[1] == cur then return i end
    end
    return 2 
  end


  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    rows = next(game, rows)
    for _, row in ipairs(rows) do
      if row.id == "textSpeed" then
        row.value = function(g) return Strings(SPEEDS[speedIndex(g)][2]) end
        row.step = function(g)
          local i = speedIndex(g) % #SPEEDS + 1
          g.save.options.textSpeed = SPEEDS[i][1]
          return true
        end
        break
      end
    end
    return rows
  end)

  local ok, TextBox = pcall(require, "src.render.TextBox")

  if ok and TextBox and type(TextBox.update) == "function" then
    local originalUpdate = TextBox.update


    local FASTEST_TICKS_PER_FRAME = 8

    local function mode(self)
      local v = self.game and self.game.save and self.game.save.options
                and self.game.save.options.textSpeed
      if v == "fastest" or v == "instant" then return v end
      return nil
    end

    TextBox.update = function(self, dt)
      local m = mode(self)
      if not m then
        originalUpdate(self, dt)
        return
      end


      if self.waiting or self.done or (self.holdFrames or 0) > 0 then
        originalUpdate(self, dt)
        return
      end

      if m == "instant" then

        local guard = 0
        while not self.done and not self.waiting
              and (self.holdFrames or 0) <= 0 and guard < 4000 do
          originalUpdate(self, dt)
          guard = guard + 1
        end
        return
      end


      local startLine = self.lineIndex
      for _ = 1, FASTEST_TICKS_PER_FRAME do
        originalUpdate(self, dt)
        if self.done or self.waiting or (self.holdFrames or 0) > 0
            or self.lineIndex ~= startLine then
          break
        end
      end
    end

    mod.log:info("instant_text_speed: TextBox.update correctly patched")
  else
    mod.log:warn(
      "instant_text_speed: couldn't src.render.TextBox; " ..
      "TEXT SPEED will get FASTEST/INSTANT but they wont change " ..
      "text speed. It might changed the engine " ..
      "version -- check src/render/TextBox.lua on your game copy."
    )
  end
end
