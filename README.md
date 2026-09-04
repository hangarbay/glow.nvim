# glow.nvim

Neovim integration for [glow](https://github.com/charmbracelet/glow), the terminal markdown renderer.

## Features

- **Vertical preview pane** on the right side (float optional) rendered by glow
- **`q` to close** the preview window
- **Optional file argument** -- preview any markdown file from anywhere
- **Zero dependencies** -- no toggleterm, just glow on your PATH

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "hangarbay/glow.nvim",
  keys = {
    { "<leader>cg", desc = "Preview markdown in glow" },
  },
  opts = {},
}
```

## Configuration

All options with their defaults:

```lua
require("glow").setup({
  cmd = "glow",              -- path to the glow binary
  direction = "vertical",    -- "vertical" right pane, or "float"
  width_ratio = 0.45,        -- pane width (vertical) as a ratio of columns
  height_ratio = 0.85,       -- float height as a ratio of lines
  keymaps = {
    preview = "<leader>cg",  -- open preview for current file
    close = "q",             -- close the preview window
  },
})
```

## Usage

| Mapping     | Mode | Action                          |
| ----------- | ---- | ------------------------------- |
| `<leader>cg` | normal | Preview current markdown file |
| `q`         | in preview | Close the preview          |

Or run `:Glow [path]` to preview a specific file.

## License

[MIT](LICENSE)
