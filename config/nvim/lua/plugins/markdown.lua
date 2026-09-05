local markdownlint_config = vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc"

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      enabled = false,
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          args = { "-", "--config", markdownlint_config, "--" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        ["markdownlint-cli2"] = {
          args = { "--config", markdownlint_config, "--fix", "$FILENAME" },
        },
      },
    },
  },
}
