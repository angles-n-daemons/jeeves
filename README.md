# jeeves

jeeves is a small library for managing context with [CopilotChat](https://github.com/CopilotC-Nvim/CopilotChat.nvim).


[![asciicast](https://asciinema.org/a/9VQ8OdALcuyfXKqBohqXswsKk.svg)](https://asciinema.org/a/9VQ8OdALcuyfXKqBohqXswsKk)

# installation

to install jeeves, use lazy or an equivalent package manager to install the package.

```lua
return {
  'angles-n-daemons/jeeves',
  keys = {
    {
      mode = { 'v' },
      'M',
      function()
        require('jeeves').add_selection()
      end,
    },
    {
      mode = { 'n' },
      'M',
      function()
        require('jeeves').remove_selections_under_cursor()
      end,
    },
    {
      '<leader>jc',
      function()
        require('jeeves').clear()
      end,
    },
  },
}
```

separately, modify your CopilotChat configuration with the new context:

```lua
return {
  'CopilotC-Nvim/CopilotChat.nvim',
  ...
  opts = {
    contexts = {
      jeeves = {
        resolve = function()
          require('jeeves').collect_context()
        end,
      },
    },
  ...
}
```

## usage

to add visual selections to the context, utilize the designated keybinding for `add_selection`, for example, `M`.

to remove individual selections, employ the `remove_selections_under_cursor` command while positioned over a selection. Alternatively, you can clear the entire context using the `clear` command.
