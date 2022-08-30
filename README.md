# Introduction

The LSP specification [3.17](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#version_3_17_0) adds support for the [type hierarchy](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareTypeHierarchy) protocol.
  
As this protocol is fairly recent, adoption in the native neovim client (see `:h lsp-methods` for the list of methods supported by the client) and, most importantly, in LSP servers, will take some time.

# Hierarchy.nvim

This plugin provides an hacked around solution (relying on `textDocument/references`, `textDocument/definition` and treesitter) to get this functionality early.

## Goals

- Provide an experience as close as possible to the LSP specification, even though the logic is executed by the lua plugin. Once your server supports the methods, you should be able to switch seamlessly without loosing the config you're used to.
- Support the methods `textDocument/prepareTypeHierarchy`, `typeHierarchy/supertypes`, `typeHierarchy/subtypes`
- Provide some handlers suited to type hierarchy navigation
- Support as many languages/edge cases as reasonably possible

## Non Goals

- **This plugin is not a replacement for an LSP server supporting the `type hierarchy` protocol.**

## Low Level Interface

The plugin provides a low level interface mimicking `:h vim.lsp.buf_request` that only accepts `textDocument/prepareTypeHierarchy`, `typeHierarchy/supertypes` and `typeHierarchy/subtypes`.
This interface should act as `vim.lsp.buf_request` except that it will run the plugin's implementation if none of the current LSP servers support the methods. If the methods are supported, it will delegate the call to `vim.lsp.buf_request` (i.e. your LSP server).

See `:h hierarchy.request` for the signature and options.

## High(er) level interface

You rarely need to make. The plugin provides 2 slightly 
