return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      cpp = { "clang-format" }, -- Formateador por defecto para cpp
    },
    -- Configuración de mapeos
    keys = {
      {
        "<leader>cFB",
        function()
          require("conform").format({ formatters = { "clang-format" }, timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Formatear C++",
      },
    },
  },
}
