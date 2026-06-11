return {
  -- Pywal (configuración de arriba)

  -- Catppuccin con su propia configuración
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    opts = {
      flavour = "mocha", -- o "latte", "frappe", "macchiato"
      transparent_background = false, -- IMPORTANTE: desactiva transparencia por defecto
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        mason = true,
        lsp_trouble = true,
        which_key = true,
      },
      custom_highlights = function(colors)
        return {
          -- Puedes personalizar colores específicos para catppuccin aquí
          NormalFloat = { bg = colors.mantle },
          FloatBorder = { bg = colors.mantle, fg = colors.blue },
        }
      end,
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)

      -- Función para restaurar colores sólidos al cambiar a catppuccin
      local function restore_solid_colors()
        if vim.g.colors_name ~= "catppuccin" then
          return
        end

        -- Grupos que quieres mantener sólidos en catppuccin
        local solid_groups = {
          "Normal",
          "NormalFloat",
          "Pmenu",
          "StatusLine",
        }

        for _, group in ipairs(solid_groups) do
          vim.api.nvim_set_hl(0, group, {})
        end

        print("Colores sólidos restaurados para catppuccin")
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "catppuccin",
        callback = restore_solid_colors,
      })
    end,
  },
}
