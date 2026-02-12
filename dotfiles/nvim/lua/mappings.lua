require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<leader>n", "<cmd>set rnu!<CR>", { desc = "Toggle relative number" })

-- DAP
map("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "DAP toogle breakpoint" })
map("n", "<leader>dr", "<cmd>DapContinue<CR>", { desc = "DAP continue/start" })
map("n", "<leader>di", "<cmd>DapStepInto<CR>", { desc = "DAP step into" })
map("n", "<leader>do", "<cmd>DapStepOver<CR>", { desc = "DAP step over" })
map("n", "<leader>dt", "<cmd>DapTerminate<CR>", { desc = "DAP terminate" })
map("n", "<leader>du", function() require("dapui").toggle() end, { desc = "DAP toggle UI" })

-- Custom mappings for developer experience
map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "LSP code action" })
map("n", "<leader>ra", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "LSP rename" })
map("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", { desc = "LSP references" })
map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "LSP definition" })
