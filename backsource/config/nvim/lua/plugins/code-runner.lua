return {
  "CRAG666/code_runner.nvim",
  keys = {
    { "<leader>r", ":RunCode<CR>", desc = "Run Code" },
  },
  opts = {
    filetype = {
      cpp = {
        "sh -c 'ROOT=\"$dir\"; FOUND=0; while [ \"$ROOT\" != \"/\" ]; do if find \"$ROOT\" -maxdepth 1 -name \"*.cbp\" | grep -q .; then FOUND=1; break; fi; ROOT=$(dirname \"$ROOT\"); done; if [ \"$FOUND\" -eq 1 ]; then OUT_DIR=\"$ROOT/temp\"; mkdir -p \"$OUT_DIR\"; find \"$ROOT\" -type f -name \"*.cpp\" ! -path \"*/bin/*\" ! -path \"*/obj/*\" ! -path \"*/temp/*\" -print0 | xargs -0 g++ -std=c++17 -Wall -Wextra -I\"$ROOT/include\" -o \"$OUT_DIR/$fileNameWithoutExt\" && \"$OUT_DIR/$fileNameWithoutExt\"; else mkdir -p \"$dir/temp\" && g++ \"$dir/$fileName\" -std=c++17 -Wall -Wextra -o \"$dir/temp/$fileNameWithoutExt\" && \"$dir/temp/$fileNameWithoutExt\"; fi'",
      },
    },
  },
}
