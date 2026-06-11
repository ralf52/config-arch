return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            -- ESTA ES LA LÍNEA CLAVE:
            "--query-driver=/usr/bin/g++,/usr/bin/clang++",
          },
        },
      },
    },
  },
}
