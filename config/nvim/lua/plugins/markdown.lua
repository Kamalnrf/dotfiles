local markdownlint_config = vim.fn.stdpath("config") .. "/.markdownlint-cli2.jsonc"

return {
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
