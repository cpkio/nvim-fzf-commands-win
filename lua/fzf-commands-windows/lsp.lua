local vim, fn, api = vim, vim.fn, vim.api

local term = require'fzf-commands-windows.term'

local strings = require("plenary.strings")

local delim = ' '

local fzfwinopts = {
  border = false,
  relative = "editor",
  width = 280,
  noautocmd = true
}

local kind_to_color = {
  ["Class"] = "blue",
  ["Constant"] = "cyan",
  ["Field"] = "yellow",
  ["Interface"] = "yellow",
  ["Function"] = "green",
  ["Method"] ="green",
  ["Module"] = "magenta",
  ["Property"] = "yellow",
  ["Struct"] = "red",
  ["Variable"] = "cyan",
}

local diag_to_color = {
  ["Error"] = term.brightmagenta,
  ["Warning"] = term.yellow,
  ["Info"] = term.brightred,
  ["Hint"] = term.brightcyan
}

local M = {}

-- local __file = debug.getinfo(1, "S").source:match("@(.*)$")
-- assert(__file ~= nil)
-- local bin_dir = fn.fnamemodify(__file, ":p:h:h") .. "/bin"
-- local bin = { preview = (bin_dir .. "/preview.sh") }

-- utility functions {{{
local function partial(func, arg)
  return (function(...)
    return func(arg, ...)
  end)
end

local function perror(err)
  vim.notify("ERROR: " .. tostring(err), vim.log.levels.WARN)
end

local function mk_handler(fun)
  return function(...)
    local config_or_client_id = select(4, ...)
    local is_new = type(config_or_client_id) ~= 'number'
    if is_new then
      fun(...)
    else
      local err = select(1, ...)
      local method = select(2, ...)
      local result = select(3, ...)
      local client_id = select(4, ...)
      local bufnr = select(5, ...)
      local config = select(6, ...)
      fun(err, result, { method = method, client_id = client_id, bufnr = bufnr }, config)
    end
  end
end

local function fnamemodify(filename, include_filename)
  if include_filename and filename ~= nil then
    return fn.fnamemodify(filename, ":~:.") .. ":"
  else
    return ""
  end
end

local function colored_kind(kind)
  local width = 10 -- max lenght of listed kinds
  local color = kind_to_color[kind] or "white"
  -- return ansi.noReset("%{bright}%{" .. color .. "}")
  --   .. strings.align_str(strings.truncate(kind or "", width), width)
  --   .. ansi.noReset("%{reset}")
  return strings.align_str(strings.truncate(kind or "", width), width)
end
-- }}}

-- LSP utility {{{
local function extract_result(results_lsp)
  if results_lsp then
    local results = {}
    for client_id, response in pairs(results_lsp) do
      if response.result then
        for _, result in pairs(response.result) do
          result.client_id = client_id
          table.insert(results, result)
        end
      end
    end

    return results
  end
end

local function call_sync(method, params, opts, handler)
  params = params or {}
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local results_lsp, err = vim.lsp.buf_request_sync(
    bufnr, method, params, opts.timeout
  )

  local ctx = {
    method = method,
    bufnr = bufnr,
    client_id = results_lsp and next(results_lsp) or nil,
  }
  handler(err, extract_result(results_lsp), ctx, nil)
end

local function check_capabilities(provider, client_id)
  local clients = vim.lsp.buf_get_clients(client_id or 0)

  local supported_client = false
  for _, client in pairs(clients) do
    supported_client = client.server_capabilities[provider]
    if supported_client then
      return true
    else
      if #clients == 0 then
        vim.notify("LSP: no client attached", vim.log.levels.INFO)
      else
        vim.notify("LSP: server does not support " .. provider, vim.log.levels.INFO)
      end
      return false
    end
  end
end

local function code_action_execute(action, offset_encoding)
  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit, offset_encoding)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
  else
    vim.lsp.buf.execute_command(action)
  end
end

local function joinloc_raw(loc, include_filename)
  return fnamemodify(loc['filename'], include_filename)
    .. loc["lnum"]
    .. ":"
    .. loc["col"]
    .. ": "
    .. vim.trim(loc["text"])
end

local function joinloc_pretty(loc, include_filename)
  local width = 48
  local text = vim.trim(loc["text"]:gsub("%b[]", ""))
  return strings.align_str(strings.truncate(text, width), width)
    .. " "
    .. colored_kind(loc["kind"])
    .. string.rep(" ", 50)
    .. delim
    .. fnamemodify(loc["filename"], include_filename)
    .. loc["lnum"]
    .. ":"
    .. loc["col"]
end

local function extloc_raw(line, include_filename)
  local path, lnum, col, text, bufnr

  if include_filename then
    path, lnum, col, text = line:match("([^:]*):([^:]*):([^:]*):(.*)")
  else
    bufnr = api.nvim_get_current_buf()
    path = fn.expand("%")
    lnum, col, text = line:match("([^:]*):([^:]*):(.*)")
  end

  return {
    bufnr = bufnr,
    filename = path,
    lnum = lnum,
    col = col,
    text = text or "",
  }
end

local function extloc_pretty(line, include_filename)
  local split = vim.split(line, delim)
  local text = split[1]
  local file = split[2]

  local path, lnum, col, bufnr
  if include_filename then
    path, lnum, col = file:match("([^:]*):([^:]*):([^:]*):")
  else
    bufnr = api.nvim_get_current_buf()
    path = fn.expand("%")
    lnum, col = file:match("([^:]*):([^:]*):")
  end

  return {
    bufnr = bufnr,
    filename = path,
    lnum = lnum,
    col = col,
    text = text or "",
  }
end

-- Эта функция вызывается только в M.diagnostic, точнее я вызываю там
-- следующую, а эта не задействована, но может быть полезна
local function joindiag_raw(e, include_filename)
  return fnamemodify(e["filename"], include_filename)
    .. e["lnum"]
    .. ':'
    .. e["col"]
    .. ': '
    .. e["type"]
    .. ': '
    .. e["text"]:gsub("%s", " ")
end

-- Эта функция вызывается только в M.diagnostic
local function joindiag_pretty(e, include_filename)
  return diag_to_color[e["type"]]
    .. e["lnum"]
    .. ": "
    .. '(' .. e["type"] .. ') '
    .. e["text"]:gsub("%s", " ")
    .. delim
    .. fnamemodify(e["filename"], include_filename)
    .. term.reset
end

local function lines_from_locations(locations, include_filename)
  local joinfn = joinloc_pretty or joinloc_raw

  local lines = {}
  for _, loc in ipairs(locations) do
    table.insert(lines, joinfn(loc, include_filename))
  end

  return lines
end

local function locations_from_lines(lines, include_filename)
  local extractfn = extloc_pretty or extloc_raw

  local locations = {}
  for _, l in ipairs(lines) do
    table.insert(locations, extractfn(l, include_filename))
  end

  return locations
end

local function location_handler(err, locations, ctx, _, error_message)
  if err ~= nil then
    perror(err)
    return
  end

  if not locations or vim.tbl_isempty(locations) then
    vim.notify(error_message, vim.log.levels.INFO)
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)

  if vim.tbl_islist(locations) then
    if #locations == 1 then
      vim.lsp.util.jump_to_location(locations[1], client.offset_encoding)

      return
    end
  else
    vim.lsp.util.jump_to_location(locations, client.offset_encoding)
  end

  return lines_from_locations(
    vim.lsp.util.locations_to_items(locations, client.offset_encoding), true
  )
end

local function call_hierarchy_handler(direction, err, result, _, _, error_message)
  if err ~= nil then
    perror(err)
    return
  end

  if not result or vim.tbl_isempty(result) then
    vim.notify(error_message, vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, call_hierarchy_call in pairs(result) do
    local call_hierarchy_item = call_hierarchy_call[direction]
    for _, range in pairs(call_hierarchy_call.fromRanges) do
      table.insert(items, {
        filename = assert(vim.uri_to_fname(call_hierarchy_item.uri)),
        text = call_hierarchy_item.name,
        lnum = range.start.line + 1,
        col = range.start.character + 1,
      })
    end
  end

  return lines_from_locations(items, true)
end

local call_hierarchy_handler_from = partial(call_hierarchy_handler, "from")
local call_hierarchy_handler_to = partial(call_hierarchy_handler, "to")
-- }}}

-- FZF functions {{{

-- Обработчик выбранной строки или строк
local function common_sink(infile, lines)

  -- Создаём массив строк для QuickFixList из lines
  local locations = locations_from_lines(lines, not infile)
  if #lines > 1 then
    vim.fn.setqflist({}, ' ', {
        title = 'Language Server';
        items = locations;
      })
    api.nvim_command("copen")
    api.nvim_command("wincmd p")
    return
  end

  -- Если выбран только один вариант, переходим к нему
  for _, loc in ipairs(locations) do
    fn.cursor(loc["lnum"], loc["col"])
    api.nvim_command("normal! zvzz")
  end
end

-- Эта функция не используется!
local function fzf_ui_select(items, opts, on_choice)
  local prompt = opts.prompt or "Select one of:"
  local format_item = opts.format_item or tostring

  local source = {}
  for i, item in pairs(items) do
    table.insert(source, string.format('%d: %s', i, format_item(item)))
  end

  local function sink_fn(lines)
    local _, line = next(lines)
    local choice = -1
    for i, s in pairs(source) do
      if s == line then
        choice = i
        goto continue
      end
    end

    ::continue::
    if choice < 1 then
      on_choice(nil, nil)
    else
      on_choice(items[choice], choice)
    end
  end

  -- fzf_run(fzf_wrap("fzf_lsp", {
  --     source = source,
  --     sink = sink_fn,
  --     options = {
  --       "--prompt", prompt .. " ",
  --       "--ansi",
  --     }
  -- }, 0))
end

local function fzf_locations(header, prompt, source, infile)

  local options = {
    "--ansi",
    "--multi",
    "--reverse"
  }
  if string.len(prompt) > 0 then
    table.insert(options, '--prompt="' .. prompt .. '> "')
  end
  if string.len(header) > 0 then
    table.insert(options, '--header="' .. header .. '"')
  end
  local opts = table.concat(options, ' ')

  coroutine.wrap(function()
    local lines = require("fzf").fzf(source, opts, fzfwinopts)
    if not lines then
      return
    end
    if #lines == 1 then
      local linenum, _ = string.match(lines[1], '^%s*(%d+)')
      api.nvim_command(linenum)
    else
      local bufnum = api.nvim_get_current_buf()
      local itemsqf = {}
      for j = 1, #lines do
        local linenum, line = string.match(lines[j], '^%s*(%d+):%s*(%S.+)')
        table.insert(itemsqf, { bufnr = bufnum, lnum = tonumber(linenum), text = line })
      end
      fn.setqflist({},' ',{ id = 'FzfDiag', items = itemsqf, title = 'FzfDiag'})
      api.nvim_command('botright copen')
    end
  end)()

  -- fzf_run(fzf_wrap("fzf_lsp", {
  --   source = source,
  --   sink = partial(common_sink, infile),
  --   options = options,
  -- }, bang))
end

local function fzf_code_actions(header, prompt, actions)
  local lines = {}
  for i, a in ipairs(actions) do
    lines[i] = a["idx"] .. ". " .. a["title"]
  end

  local sink_fn = (function(source)
    local _, line = next(source)
    local idx = tonumber(line:match("(%d+)[.]"))
    local action = actions[idx]
    local client = vim.lsp.get_client_by_id(action.client_id)
    if
      not action.edit
      and client
      and type(client.server_capabilities.codeActionProvider) == "table"
      and client.server_capabilities.codeActionProvider.resolveProvider
      then
      client.request("codeAction/resolve", action, function(resolved_err, resolved_action)
        if resolved_err then
          vim.notify(resolved_err.code .. ": " .. resolved_err.message, vim.log.levels.ERROR)
          return
        end
        if resolved_action then
          code_action_execute(resolved_action, client.offset_encoding)
        else
          code_action_execute(action, client.offset_encoding)
        end
      end)
    else
      code_action_execute(action, client.offset_encoding)
    end
  end)

  local opts = { "--ansi", }
  if string.len(prompt) > 0 then
    table.insert(opts, "--prompt")
    table.insert(opts, prompt .. "> ")
  end
  if string.len(header) > 0 then
    table.insert(opts, "--header")
    table.insert(opts, header)
  end
  -- fzf_run(fzf_wrap("fzf_lsp", {
  --     source = lines,
  --     sink = sink_fn,
  --     options = opts
  -- }, bang))
end
-- }}}

-- LSP reponse handlers {{{
local function code_action_handler(err, result, _, _)
  if err ~= nil then
    perror(err)
    return
  end

  if not result or vim.tbl_isempty(result) then
    vim.notify("Code Action not available", vim.log.levels.INFO)
    return
  end

  for i, a in ipairs(result) do
    a.idx = i
  end

  fzf_code_actions("", "Code Actions", result)
end

local function definition_handler(err, result, ctx, config)
  local results = location_handler(
    err, result, ctx, config, "Definition not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Definitions", results, false)
  end
end

local function declaration_handler(err, result, ctx, config)
  local results = location_handler(
    err, result, ctx, config, "Declaration not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Declarations", results, false)
  end
end

local function type_definition_handler(err, result, ctx, config)
  local results = location_handler(
    err, result, ctx, config, "Type Definition not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Type Definitions", results, false)
  end
end

local function implementation_handler(err, result, ctx, config)
  local results = location_handler(
    err, result, ctx, config, "Implementation not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Implementations", results, false)
  end
end

local function references_handler(err, result, ctx, _)
  if err ~= nil then
    perror(err)
    return
  end

  if not result or vim.tbl_isempty(result) then
    vim.notify("References not found", vim.log.levels.INFO)
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)

  local lines = lines_from_locations(
    vim.lsp.util.locations_to_items(result, client.offset_encoding), true
  )
  fzf_locations("", "References", lines, false)
end

local function document_symbol_handler(err, result, ctx, _)
  if err ~= nil then
    perror(err)
    return
  end

  if not result or vim.tbl_isempty(result) then
    vim.notify("Document Symbol not found", vim.log.levels.INFO)
    return
  end

  local lines = lines_from_locations(
    vim.lsp.util.symbols_to_items(result, ctx.bufnr), false
  )
  fzf_locations("", "Document Symbols", lines, true)
end

local function workspace_symbol_handler(err, result, ctx, _)
  if err ~= nil then
    perror(err)
    return
  end

  if not result or vim.tbl_isempty(result) then
    vim.notify("Workspace Symbol not found", vim.log.levels.INFO)
    return
  end

  local lines = lines_from_locations(
    vim.lsp.util.symbols_to_items(result, ctx.bufnr), true
  )
  fzf_locations("", "Workspace Symbols", lines, false)
end

local function incoming_calls_handler(err, result, ctx, config)
  local results = call_hierarchy_handler_from(
    err, result, ctx, config, "Incoming calls not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Incoming Calls", results, false)
  end
end

local function outgoing_calls_handler(err, result, ctx, config)
  local results = call_hierarchy_handler_to(
    err, result, ctx, config, "Outgoing calls not found"
  )
  if results and not vim.tbl_isempty(results) then
    fzf_locations("", "Outgoing Calls", results, false)
  end
end
-- }}}

-- COMMANDS {{{
function M.definition(opts)
  if not check_capabilities("definitionProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "textDocument/definition", params, opts, partial(definition_handler)
  )
end

function M.declaration(opts)
  if not check_capabilities("declarationProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "textDocument/declaration", params, opts, partial(declaration_handler)
  )
end

function M.type_definition(opts)
  if not check_capabilities("typeDefinitionProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "textDocument/typeDefinition", params, opts, partial(type_definition_handler)
  )
end

function M.implementation(opts)
  if not check_capabilities("implementationProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "textDocument/implementation", params, opts, partial(implementation_handler)
  )
end

function M.references(opts)
  if not check_capabilities("referencesProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = true }
  call_sync(
    "textDocument/references", params, opts, partial(references_handler)
  )
end

function M.document_symbol(opts)
  if not check_capabilities("documentSymbolProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "textDocument/documentSymbol", params, opts, partial(document_symbol_handler)
  )
end

function M.workspace_symbol(opts)
  if not check_capabilities("workspaceSymbolProvider") then
    return
  end

  local params = {query = opts.query or ''}
  call_sync(
    "workspace/symbol", params, opts, partial(workspace_symbol_handler)
  )
end

function M.incoming_calls(opts)
  if not check_capabilities("callHierarchyProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "callHierarchy/incomingCalls", params, opts, partial(incoming_calls_handler)
  )
end

function M.outgoing_calls(opts)
  if not check_capabilities("callHierarchyProvider") then
    return
  end

  local params = vim.lsp.util.make_position_params()
  call_sync(
    "callHierarchy/outgoingCalls", params, opts, partial(outgoing_calls_handler)
  )
end

function M.code_action(opts)
  if not check_capabilities("codeActionProvider") then
    return
  end

  local params = vim.lsp.util.make_range_params()
  params.context = {
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics(),
  }
  call_sync(
    "textDocument/codeAction", params, opts, partial(code_action_handler)
  )
end

function M.range_code_action(opts)
  if not check_capabilities("codeActionProvider") then
    return
  end

  local params = vim.lsp.util.make_given_range_params()
  params.context = {
    diagnostics = vim.lsp.diagnostic.get_line_diagnostics()
  }
  call_sync(
    "textDocument/codeAction", params, opts, partial(code_action_handler)
  )
end

function M.diagnostic(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or api.nvim_get_current_buf()
  local show_all = bufnr == "*"

  local buffer_diags
  if show_all then
    buffer_diags = vim.diagnostic.get(nil)
  else
    buffer_diags = vim.diagnostic.get(bufnr)
  end

  local severity = opts.severity
  local severity_limit = opts.severity_limit

  local items = {}
  for _, diag in ipairs(buffer_diags) do
    if severity then
      if not diag.severity then
        return
      end

      if severity ~= diag.severity then
        return
      end
    elseif severity_limit then
      if not diag.severity then
        return
      end

      if severity_limit < diag.severity then
        return
      end
    end

    table.insert(items, {
      filename = vim.api.nvim_buf_get_name(diag.bufnr),
      lnum = diag.lnum + 1,
      col = diag.col + 1,
      text = diag.message,
      type = vim.lsp.protocol.DiagnosticSeverity[diag.severity or
      vim.lsp.protocol.DiagnosticSeverity.Error]
    })
  end

  table.sort(items, function(a, b) return a.lnum < b.lnum end)

  local joinfn = joindiag_pretty or joindiag_raw

  local entries = {}
  for i, e in ipairs(items) do
    entries[i] = joinfn(e, show_all)
  end

  if vim.tbl_isempty(entries) then
    vim.notify("Empty diagnostic", vim.log.levels.INFO)
    return
  end

  fzf_locations("", "Diagnostics", entries, not show_all)
end
-- }}}

M.code_action_call = partial(M.code_action, 0)
M.range_code_action_call = partial(M.range_code_action, 0)
M.definition_call = partial(M.definition, 0)
M.declaration_call = partial(M.declaration, 0)
M.type_definition_call = partial(M.type_definition, 0)
M.implementation_call = partial(M.implementation, 0)
M.references_call = partial(M.references, 0)
M.document_symbol_call = partial(M.document_symbol, 0)
M.workspace_symbol_call = partial(M.workspace_symbol, 0)
M.incoming_calls_call = partial(M.incoming_calls, 0)
M.outgoing_calls_call = partial(M.outgoing_calls, 0)
M.diagnostic_call = partial(M.diagnostic, 0)

M.code_action_handler = mk_handler(partial(code_action_handler, 0))
M.definition_handler = mk_handler(partial(definition_handler, 0))
M.declaration_handler = mk_handler(partial(declaration_handler, 0))
M.type_definition_handler = mk_handler(partial(type_definition_handler, 0))
M.implementation_handler = mk_handler(partial(implementation_handler, 0))
M.references_handler = mk_handler(partial(references_handler, 0))
M.document_symbol_handler = mk_handler(partial(document_symbol_handler, 0))
M.workspace_symbol_handler = mk_handler(partial(workspace_symbol_handler, 0))

vim.lsp.handlers["textDocument/codeAction"] = M.code_action_handler
vim.lsp.handlers["textDocument/definition"] = M.definition_handler
vim.lsp.handlers["textDocument/declaration"] = M.declaration_handler
vim.lsp.handlers["textDocument/typeDefinition"] = M.type_definition_handler
vim.lsp.handlers["textDocument/implementation"] = M.implementation_handler
vim.lsp.handlers["textDocument/references"] = M.references_handler
vim.lsp.handlers["textDocument/documentSymbol"] = M.document_symbol_handler
vim.lsp.handlers["workspace/symbol"] = M.workspace_symbol_handler
vim.lsp.handlers["callHierarchy/incomingCalls"] = M.incoming_calls_handler
vim.lsp.handlers["callHierarchy/outgoingCalls"] = M.outgoing_calls_handler

return M
