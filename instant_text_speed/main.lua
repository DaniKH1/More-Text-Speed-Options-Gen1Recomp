-- mods/instant_text_speed/main.lua

return function(mod)


  mod.options:define({
    {
      key = "language",
      type = "choice",
      label = "IDIOMA / LANGUAGE",
      choices = { { "ESP", "es" }, { "ENG", "en" } },
      default = "es",
    },
  })

  local STRINGS = {
    es = { row_label = "TEXTO INSTANTANEO", on = "ON", off = "OFF" },
    en = { row_label = "INSTANT TEXT",       on = "ON", off = "OFF" },
  }

  local function currentLang()
    local lang = mod.options:get("language")
    if STRINGS[lang] then return lang end
    return "es"
  end

  local function t(key)
    local table_ = STRINGS[currentLang()] or STRINGS.es
    return table_[key] or STRINGS.es[key]
  end


  local SAVE_KEY = "instant_enabled"

  local function isInstant()
    return mod.save:get(SAVE_KEY, false) == true
  end

  local function toggleInstant()
    mod.save:set(SAVE_KEY, not isInstant())
  end


  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    rows = next(game, rows)

    mod.ui.insertAfter(rows, "TEXT SPEED", {
      id = "instant_text_speed_toggle",
      label = t("row_label"),
      value = function(g) return isInstant() and t("on") or t("off") end,
      step = function(g, dir)

        local ok, err = pcall(toggleInstant)
        if not ok then
          mod.log:warn("instant_text_speed: fallo al cambiar el toggle: %s",
            tostring(err))
          return false
        end
        return true
      end,
    })

    return rows
  end)


  local ok, TextBox = pcall(require, "src.render.TextBox")

  if ok and TextBox and type(TextBox.update) == "function" then
    local originalUpdate = TextBox.update

    TextBox.update = function(self, dt)
      originalUpdate(self, dt)

      if not isInstant() then return end


      local guard = 0
      while not self.done and not self.waiting
            and (self.holdFrames or 0) <= 0
            and guard < 4000 do
        originalUpdate(self, dt)
        guard = guard + 1
      end
    end

    mod.log:info("instant_text_speed: TextBox.update parcheado correctamente")
  else
    mod.log:warn(
      "instant_text_speed: no se pudo cargar src.render.TextBox; " ..
      "la fila del menu funciona pero el texto no se volvera instantaneo. " ..
      "Puede que el motor haya cambiado de version -- revisa " ..
      "src/render/TextBox.lua en tu copia del juego."
    )
  end

end
