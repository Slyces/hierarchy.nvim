# Hierarchy.nvim

> This plugin provides methods to navigate the type hierarchy of your code (methods & classes)


The specification [3.17.0](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#version_3_17_0) of the Language Server Protocol introduced a new set of methods, the [type hierarchy protocol](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareTypeHierarchy). Those methods introduce the ability to navigate the type hierarchy of your program, through 3 new methods:
- `textDocument/prepareTypeHierarchy` identify the type symbol at a given location
- `typeHierarchy/supertypes` find supertypes of a prepared symbol
- `typeHierarchy/subtypes` find subtypes of a prepared symbol

Those methods being somewhat new, they are not yet supported by either the native neovim LSP client nor any of the language server that I use.

This plugin is a « hack » providing those functionalities by combining existing, well supported LSP methods, `textDocument/references` and `textDocument/definition` with [treesitter](https://github.com/nvim-treesitter/nvim-treesitter). Requests to your LSP server allows discovering symbols in different files, and treesitter allows contextual awareness to manipulate the matched symbols and find related symbols to query for.

## Preview

**Jump to first parent method**

![](https://github.com/Slyces/hierarchy.nvim/blob/master/videos/supertype_jump.mov)

**Quickfix all child implementations**

![](https://github.com/Slyces/hierarchy.nvim/blob/master/videos/subtype_quickfix.mov)

## Languages

In theory, the algorithm used should work for any language. However, as the implementation uses `treesitter`, some small tweaks might be required from language to language.

Please note that you will need at least 1 LSP server for your language providing `textDocument/references` (subtypes) and `textDocument/definition` (supertypes) along with the `treesitter` syntax for your language.

**Tested Languages**
- python

# Installation
Just like any other plugin.

Example using [vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'slyces/hierarchy.nvim'
```
Example using [packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use { 'slyces/hierarchy.nvim', requires = 'nvim-treesitter/nvim-treesitter' }
```

# Usage

## High Level

The main interface of this plugin is provided through 2 functions:
```lua
-- Queries super type items for the symbol under the cursor.
require('hiearchy').supertypes(handler)
require('hiearchy').subtypes(handler)
```

Where `handler` is a regular `lsp-handler` (see `:h lsp-handler`). Those two functions will find:
- implementations of the current method in all (super/sub)classes
- definition of all (super/sub)classes for the current

If you're not currently in a class or method, nothing happens.

The plugin does not provide any mapping, you'll need to make those mappings yourself in your config. See some examples in the next section.

## Handlers

The plugin provides some handlers if you don't want to code them yourself:

### Jump First

> `require('hierarchy.handlers').jump_first` 

Jumps to the first element of the hierarchy.

<details><summary>Why this handler</summary>

> I find this very useful when going to superclasses (as my codebases rarely have multiple parents). Chaining those calls and using `C-o` and `C-i` to jump back and forth cover most of my usages when going up the hierarchy tree.

</details>


**Example mapping in vimscript**
```vim
" <space>p for `parent` for instance
nnoremap <space>p <cmd>lua require'hierarchy'.supertypes(require'hierarchy.handlers'.jump_first)
```
**Example mapping using lua**
```lua
local hierarchy = require('hierarchy')
local jump_first = hierarchy.handlers.jump_first
-- <space>p for `parent` for instance
vim.keymap.set('n', '<space>p', function() hierarchy.supertypes(jump_first) end)
```

### Quickfix

> `require('hierarchy.handlers').load_quickfix`

Loads the matches in the quickfix list, prefixing methods with the class they're defined in. Includes the item that triggered the method. You should probably not use this directly.

> `require('hierarchy.handlers').quickfix`

Loads the matches in the quickfix list, prefixing methods with the class they're defined in, then **opens the quickfix window**. Includes the item that triggered the method.

<details><summary>Why this handler</summary>

> I find showing all matches very useful when going down the hierarchy (to *subtypes*), specifically when working with abstract classes.

</details>

**Example mapping in vimscript**
```vim
" <space>c for `children` for instance
nnoremap <space>c <cmd>lua require'hierarchy'.supertypes(require'hierarchy.handlers'.quickfix)
```
**Example mapping using lua**
```lua
local hierarchy = require('hierarchy')
local quickfix = hierarchy.handlers.quickfix
-- <space>c for `children` for instance
vim.keymap.set('n', '<space>c', function() hierarchy.supertypes(quickfix) end)
```

## Low Level

At a lower level, this plugin is trying to stay as closely compatible with the LSP protocol definition as possible.

Lacking real world examples of server implementation, my implementation/behaviour might be somewhat off from what servers will provide.

The main low level interface of this server is the following method:
```lua
---Low level interface of `hierarchy.nvim`. Sends an LSP request with the same
---interface as `vim.lsp.buf_request`.
---  
---Supports only the methods:
--- - `textDocument/prepareTypeHierarchy`
--- - `typeHierarchy/supertypes`
--- - `typeHierarchy/subtypes`
---  
---If the method requested is supported by one of your current LSP clients,
---delegates the call to `vim.lsp.buf_request`. If it's not supported, use the
---plugin's implementation for this request.
---Returns a client id of -1 if the plugin is providing the request.
---  
---@see |vim.lsp.buf_request|
require('hierarchy').request(bufnr, method, params, handler)
```

Hopefully, this method could be used as a temporary replacement for `vim.lsp.buf_request` while the coverage for this set of method is lacking in servers. I hope to make the transition to native LSP request as seemless as possible, so you can keep your configs.

## Example Customization

Let's say you want an integration with [telescope](https://github.com/nvim-telescope/telescope.nvim). Here's an example of code snippet creating a handler using telescope's quickfix picker with a cursor theme.

```lua
---Loads all matches to the quickfix list then opens a telescope picker
---
---@param err any
---@param result lsp_hierarchy_item[]|nil
---@param ctx {params: {item: lsp_hierarchy_item}}
---@param config any
function M.telescope_quickfix(err, result, ctx, config)
  M.load_quickfix(err, result, ctx, config)
  local theme = require('telescope.themes').get_cursor({
    layout_config = {
      width = function(_, max_columns, _)
        return math.floor(0.7 * max_columns)
      end
    }
  })
  require('telescope.builtin').quickfix(theme)
end
```

For more information about the signature of those handlers, see `:h hierarchy` or `:h hierarchy-types-handler`. The documentation provides lua docs entries for all elements of the LSP protocol (relevant to the plugin).

# Possible Features

- [ ] Create proper tests
- [ ] Add options to `supertypes` and `subtypes` (maybe through module config?)
  - [ ] skip some classes in the hierarchy (e.g. [ABC](https://docs.python.org/3.8/library/abc.html#abc.ABC) in python)
- [ ] New handlers
  - [ ] handler wrapping other handlers - when a method has no matches, re-run LSP requests on the class instead
    Note: requires caching of recent requests for performance optimisation
# FAQ

### Does this plugin replace an LSP server supporting type hierarchy?

No. It absolutely does not. Hopefully, the interface should make it easy to switch once your server supports it.

### What if one of my server supports the method, but not the others?

The plugin's low level interface should redirect request to your LSP server if it supports the method.
This is not tested yet, as I don't use any server that does support.
Please also note that the internal implementation of neovim's LSP client makes this tricky as long as neovim itself doesn't know about the method.

### It doesn't work for my language

Please open an issue, I'll do what I can to extend the support as long as I can setup some kind of working environment.

# Contributing

Please do not hesitate to open an issue or PR to provide feedback on the plugin, give update on the current support of this specification in clients & servers, or ask for features.
