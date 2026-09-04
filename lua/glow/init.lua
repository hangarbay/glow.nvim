local M = {}

local defaults = {
  cmd = vim.fn.exepath("glow") ~= "" and vim.fn.exepath("glow") or "glow",
  direction = "vertical",
  width_ratio = 0.45,
  height_ratio = 0.85,
  auto_open = false,
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

local function open_window()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.keymap.set("n", M.config.keymaps.close, close_preview, { buffer = buf, silent = true })

  if M.config.direction == "vertical" then
    local width = math.floor(vim.o.columns * M.config.width_ratio)
    vim.cmd("botright vsplit")
    vim.cmd("vertical resize " .. width)
    vim.api.nvim_win_set_buf(0, buf)
  else
    local width = math.floor(vim.o.columns * M.config.width_ratio * 2)
    local height = math.floor(vim.o.lines * M.config.height_ratio)
    vim.api.nvim_open_win(0, buf, true, {
      relative = "editor",
      width = width,
      height = height,
      col = math.floor((vim.o.columns - width) / 2),
      row = math.floor((vim.o.lines - height) / 2),
      border = "rounded",
      style = "minimal",
    })
  end

  return buf
end

function M.preview(path, o)
  local popts = o or {}
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

  local prev_win = vim.api.nvim_get_current_win()
  local buf = open_window()
  preview_win = vim.api.nvim_get_current_win()
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(preview_win),
    once = true,
    callback = function() preview_win = nil end,
  })
  run_glow(buf, file)

  if popts.keep_focus and vim.api.nvim_win_is_valid(prev_win) then
    vim.api.nvim_set_current_win(prev_win)
  end
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

  if config.auto_open then
    local group = vim.api.nvim_create_augroup("glow_nvim_auto", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "markdown",
      callback = function()
        M.preview(nil, { keep_focus = true })
      end,
    })
    if vim.bo.filetype == "markdown" and vim.fn.expand("%:p") ~= "" then
      vim.schedule(function() M.preview(nil, { keep_focus = true }) end)
    end
  end
end

return M
