return {
  {
    "AlphaTechnolog/pywal.nvim",
    name = "pywal",
    lazy = false,
    priority = 1000,
    config = function()
      require("pywal").setup()
      vim.cmd.colorscheme("pywal")
      local wal_cache_dir = vim.fn.expand("~/.cache/wal")
      local wal_colors_file = wal_cache_dir .. "/colors-wal.vim"
      local last_wal_mtime = nil

      local function get_wal_mtime()
        local stat = vim.loop.fs_stat(wal_colors_file)
        if not stat or not stat.mtime then
          return nil
        end

        return string.format("%d:%d", stat.mtime.sec or 0, stat.mtime.nsec or 0)
      end

      -- Función para aplicar transparencia (tu código original)
      local function apply_transparency()
        -- Verificar si pywal es el tema actual
        if vim.g.colors_name ~= "pywal" then
          return
        end

        -- Grupos básicos de nvim
        local basic_groups = {
          "Normal",
          "NormalFloat",
          "NormalNC",
          "NonText",
          "LineNr",
          "FoldColumn",
          "EndOfBuffer",
          "SignColumn",
          "CursorLine",
          "ColorColumn",
          "Folded",
          "MatchParen",
          "Pmenu",
          "PmenuSel",
          "PmenuSbar",
          "PmenuThumb",
          "CursorLineNr",
          "ModeMsg",
          "MsgArea",
          "MsgSeparator",
          "MoreMsg",
          "Question",
          "TabLine",
          "TabLineFill",
          "TabLineSel",
          "Title",
          "VertSplit",
          "WinSeparator",
          "Whitespace",
          "SpecialKey",
          "Conceal",
          "SpellBad",
          "SpellCap",
          "SpellRare",
          "SpellLocal",
          "QuickFixLine",
          "StatusLine",
          "StatusLineNC",
          "StatusLineTerm",
          "StatusLineTermNC",
        }

        for _, group in ipairs(basic_groups) do
          vim.api.nvim_set_hl(0, group, { bg = "NONE" })
        end

        -- Lualine específico
        if package.loaded["lualine"] then
          local colors = {
            bg = "NONE",
            fg = vim.g.foreground or "#bbbbbb",
            yellow = vim.g.color11 or "#ECBE7B",
            cyan = vim.g.color6 or "#008080",
            darkblue = vim.g.color0 or "#081633",
            green = vim.g.color2 or "#98be65",
            orange = vim.g.color3 or "#FF8800",
            violet = vim.g.color13 or "#a9a1e1",
            magenta = vim.g.color5 or "#c678dd",
            blue = vim.g.color4 or "#51afef",
            red = vim.g.color1 or "#ec5f67",
          }

          local theme = {
            normal = {
              a = { bg = colors.bg, fg = colors.blue, gui = "bold" },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
            insert = {
              a = { bg = colors.bg, fg = colors.green, gui = "bold" },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
            visual = {
              a = { bg = colors.bg, fg = colors.magenta, gui = "bold" },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
            replace = {
              a = { bg = colors.bg, fg = colors.red, gui = "bold" },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
            command = {
              a = { bg = colors.bg, fg = colors.yellow, gui = "bold" },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
            inactive = {
              a = { bg = colors.bg, fg = colors.fg },
              b = { bg = colors.bg, fg = colors.fg },
              c = { bg = colors.bg, fg = colors.fg },
            },
          }

          require("lualine").setup({
            options = {
              theme = theme,
              component_separators = { left = "│", right = "│" },
              section_separators = { left = "", right = "" },
              globalstatus = true,
            },
            sections = {
              lualine_a = { "mode" },
              lualine_b = { "branch", "diff", "diagnostics" },
              lualine_c = { "filename" },
              lualine_x = { "encoding", "fileformat", "filetype" },
              lualine_y = { "progress" },
              lualine_z = { "location" },
            },
            inactive_sections = {
              lualine_a = {},
              lualine_b = {},
              lualine_c = { "filename" },
              lualine_x = { "location" },
              lualine_y = {},
              lualine_z = {},
            },
            tabline = {},
            extensions = {},
          })
        end

        -- Plugins específicos
        local bufferline_selected_bg = vim.g.color8 or vim.g.color0 or "#333333"
        local bufferline_separator_fg = vim.g.color8 or vim.g.color7 or "#666666"
        vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BufferLineBackground", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { bg = bufferline_selected_bg })
        vim.api.nvim_set_hl(0, "BufferLineSeparator", { bg = "NONE", fg = bufferline_separator_fg })
        vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { bg = "NONE", fg = bufferline_separator_fg })
        vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { bg = "NONE", fg = bufferline_separator_fg })
        vim.api.nvim_set_hl(0, "BufferLineCloseButton", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BufferLineCloseButtonVisible", { bg = "NONE" })
        vim.api.nvim_set_hl(0, "BufferLineCloseButtonSelected", { bg = "NONE" })
      end

      -- Función principal para recargar pywal
      local function reload_pywal()
        -- Recargar colores crudos de pywal antes del colorscheme.
        if vim.fn.filereadable(wal_colors_file) == 1 then
          vim.cmd("silent source " .. vim.fn.fnameescape(wal_colors_file))
        end

        -- Recargar el tema pywal
        vim.cmd("silent! colorscheme pywal")
        -- Reaplicar transparencia
        apply_transparency()
        vim.cmd("silent! redraw!")
        last_wal_mtime = get_wal_mtime()
        -- Notificación opcional
        vim.notify("Pywal recargado ✓", vim.log.levels.INFO, { title = "Tema Actualizado" })
      end

      local function reload_pywal_if_changed()
        local current_mtime = get_wal_mtime()
        if not current_mtime or current_mtime == last_wal_mtime then
          return
        end

        if vim.g.colors_name == "pywal" then
          reload_pywal()
        else
          last_wal_mtime = current_mtime
        end
      end

      -- Crear autocmd para detectar cuando Neovim gana foco
      vim.api.nvim_create_augroup("PywalAutoReload", { clear = true })

      vim.api.nvim_create_autocmd("FocusGained", {
        group = "PywalAutoReload",
        pattern = "*",
        callback = function()
          if vim.g.colors_name == "pywal" then
            reload_pywal()
          end
        end,
        desc = "Recargar pywal al recuperar foco después de cambios externos",
      })

      -- También recargar al cambiar de buffer (opcional, más frecuente)
      vim.api.nvim_create_autocmd("BufEnter", {
        group = "PywalAutoReload",
        pattern = "*",
        callback = function()
          if vim.g.colors_name == "pywal" then
            reload_pywal()
          end
        end,
        desc = "Recargar pywal al cambiar de buffer",
      })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = "PywalAutoReload",
        pattern = "*",
        callback = function()
          reload_pywal_if_changed()
        end,
        desc = "Recargar pywal si cambian archivos de wal mientras nvim sigue enfocado",
      })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = "PywalAutoReload",
        pattern = "pywal",
        callback = function()
          -- Ensure transparency and plugin highlights are reapplied on external :colorscheme calls.
          apply_transparency()
        end,
        desc = "Reaplicar transparencia al activar pywal",
      })

      -- Aplicar al iniciar por primera vez
      apply_transparency()
      last_wal_mtime = get_wal_mtime()

      -- Watcher en tiempo real para cambios de pywal.
      local wal_file_watcher = vim.loop.new_fs_event()
      if wal_file_watcher then
        wal_file_watcher:start(wal_cache_dir, {}, function(err, filename)
          if err then
            return
          end

          if filename and filename ~= "colors-wal.vim" and filename ~= "colors" and filename ~= "colors.sh" then
            return
          end

          vim.schedule(function()
            reload_pywal_if_changed()
          end)
        end)

        vim.api.nvim_create_autocmd("VimLeavePre", {
          group = "PywalAutoReload",
          callback = function()
            pcall(function()
              wal_file_watcher:stop()
              wal_file_watcher:close()
            end)
          end,
          desc = "Cerrar watcher de pywal al salir",
        })
      end

      -- Crear comando manual para recargar
      vim.api.nvim_create_user_command("PywalReload", reload_pywal, {
        desc = "Forzar recarga del tema pywal y transparencia",
      })

      -- Mapear tecla rápida para recarga manual (opcional)
      vim.keymap.set("n", "<leader>wr", "<cmd>PywalReload<CR>", { desc = "Recargar Pywal" })
    end,
  },
}
