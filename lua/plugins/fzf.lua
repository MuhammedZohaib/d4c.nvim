return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      winopts = {
        height = 0.86,
        width = 0.92,
        preview = {
          layout = "horizontal",
          horizontal = "right:55%",
        },
      },
      files = {
        cwd_prompt = false,
        rg_opts = table.concat({
          "--color=never",
          "--files",
          "--hidden",
          "--follow",
          "--glob '!.git'",
          "--glob '!node_modules'",
          "--glob '!dist'",
          "--glob '!build'",
          "--glob '!.next'",
          "--glob '!coverage'",
          "--glob '!.venv'",
          "--glob '!venv'",
        }, " "),
      },
      grep = {
        rg_opts = table.concat({
          "--column",
          "--line-number",
          "--no-heading",
          "--color=always",
          "--smart-case",
          "--hidden",
          "--glob '!.git'",
          "--glob '!node_modules'",
          "--glob '!dist'",
          "--glob '!build'",
          "--glob '!.next'",
          "--glob '!coverage'",
          "--glob '!.venv'",
          "--glob '!venv'",
        }, " "),
      },
    },
  },
}
