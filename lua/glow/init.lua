local M = {}

local defaults = {
  cmd = vim.fn.exepath("glow") ~= "" and vim.fn.exepath("glow") or "glow",
  width_ratio = 0.8,
  height_ratio = 0.85,
  keymaps = {
    preview = "<leader>cg",
    close = "q",
  },
}

M.config = {}
local preview_win = nil

local function is_markdown(file)
  return vim.bo.filetype == "markdown" or file:match("%.md$") or file:match("%.markdown$")
end

local function close_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win = nil
end

local function run_glow(buf, file)
  local args = { M.config.cmd, file }
  if vim.fn.has("nvim-0.11") == 1 then
    vim.fn.jobstart(args, { term = true })
  else
    vim.fn.termopen(args)
  end
end

function M.preview(path)
  local file = path and vim.fn.expand(path) or vim.fn.expand("%:p")
  if file == "" then
    vim.notify("glow.nvim: no file to preview", vim.log.levels.WARN)
    return
  end
  if not is_markdown(file) then
    vim.notify("glow.nvim: not a markdown file: " .. file, vim.log.levels.WARN)
    return
  end

  close_preview()

  local width = math.floor(vim.o.columns * M.config.width_ratio)
  local height = math.floor(vim.o.lines * M.config.height_ratio)
  local buf = vim.api.nvim_create_buf(false, true)
  preview_win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    border = "rounded",
    style = "minimal",
  })
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(preview_win),
    once = true,
    callback = function() preview_win = nil end,
  })
  vim.keymap.set("n", M.config.keymaps.close, close_preview, { buffer = buf, silent = true })

  run_glow(buf, file)
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", defaults, opts or {})
  local config = M.config

  vim.keymap.set("n", config.keymaps.preview, function() M.preview() end, {
    desc = "Preview markdown in glow",
    silent = true,
  })
  vim.api.nvim_create_user_command("Glow", function(o)
    M.preview(o.args ~= "" and o.args or nil)
  end, { nargs = "?", desc = "Preview markdown in glow" })
end

return M
