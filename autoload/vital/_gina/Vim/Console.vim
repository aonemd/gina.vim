" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not mofidify the code nor insert new lines before '" ___vital___'
if v:version > 703 || v:version == 703 && has('patch1170')
  function! vital#_gina#Vim#Console#import() abort
    return map({'ask': '', 'clear': '', 'capture': '', 'echomsg': '', 'echo': '', 'confirm': '', 'warn': '', 'error': '', 'select': '', 'info': '', 'input': '', 'inputlist': '', 'echon': '', '_vital_created': '', 'debug': ''},  'function("s:" . v:key)')
  endfunction
else
  function! s:_SID() abort
    return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
  endfunction
  execute join(['function! vital#_gina#Vim#Console#import() abort', printf("return map({'ask': '', 'clear': '', 'capture': '', 'echomsg': '', 'echo': '', 'confirm': '', 'warn': '', 'error': '', 'select': '', 'info': '', 'input': '', 'inputlist': '', 'echon': '', '_vital_created': '', 'debug': ''}, \"function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
  delfunction s:_SID
endif
" ___vital___
let s:save_cpo = &cpo
set cpo&vim

let s:t_number = type(0)
let s:t_string = type('')
let s:STATUS_DEBUG = 'debug'
let s:STATUS_BATCH = 'batch'


function! s:_vital_created(module) abort
  let a:module.STATUS_DEBUG = s:STATUS_DEBUG
  let a:module.STATUS_BATCH = s:STATUS_BATCH
  lockvar a:module.STATUS_DEBUG
  lockvar a:module.STATUS_BATCH
  let a:module.status = ''
  let a:module.prefix = ''
endfunction

function! s:echo(msg, ...) abort dict
  let hl = get(a:000, 0, 'None')
  let msg = s:_ensure_string(a:msg)
  let msg = s:_assign_prefix(a:msg, self.prefix)
  execute 'echohl' hl
  echo msg
  echohl None
endfunction

function! s:echon(msg, ...) abort dict
  let hl = get(a:000, 0, 'None')
  let msg = s:_ensure_string(a:msg)
  execute 'echohl' hl
  echon msg
  echohl None
endfunction

function! s:echomsg(msg, ...) abort dict
  let hl = get(a:000, 0, 'None')
  let msg = s:_ensure_string(a:msg)
  let msg = s:_assign_prefix(a:msg, self.prefix)
  execute 'echohl' hl
  for line in split(msg, '\r\?\n')
    echomsg line
  endfor
  echohl None
endfunction

function! s:input(hl, msg, ...) abort dict
  if s:_is_status_batch(self)
    return ''
  endif
  let msg = s:_ensure_string(a:msg)
  let msg = s:_assign_prefix(a:msg, self.prefix)
  let text = get(a:000, 0, '')
  if a:0 > 1
    let args = [
          \ type(a:1) == s:t_string
          \   ? a:1
          \   : 'customlist,' . s:_get_function_name(a:1)
          \]
  else
    let args = []
  endif
  execute 'echohl' a:hl
  call inputsave()
  try
    cnoremap <buffer> <Esc> <C-u>=====ESCAPE=====<CR>
    let result = call('input', [msg, text] + args)
    return result ==# '=====ESCAPE=====' ? 0 : result
  finally
    redraw
    cunmap <buffer> <Esc>
    echohl None
    call inputrestore()
  endtry
endfunction

function! s:inputlist(hl, textlist) abort dict
  if s:_is_status_batch(self)
    return 0
  endif
  let textlist = map(copy(a:textlist), 's:_ensure_string(v:val)')
  execute 'echohl' a:hl
  call inputsave()
  try
    return inputlist(textlist)
  finally
    echohl None
    call inputrestore()
  endtry
endfunction

function! s:debug(msg) abort dict
  if !s:_is_status_debug(self)
    return
  endif
  call self.echomsg(a:msg, 'Comment')
endfunction

function! s:info(msg) abort dict
  let v:statusmsg = s:_ensure_string(a:msg)
  call self.echomsg(a:msg, 'Title')
endfunction

function! s:warn(msg) abort dict
  let v:warningmsg = s:_ensure_string(a:msg)
  call self.echomsg(a:msg, 'WarningMsg')
endfunction

function! s:error(msg) abort dict
  let v:errmsg = s:_ensure_string(a:msg)
  call self.echomsg(a:msg, 'ErrorMsg')
endfunction

function! s:ask(...) abort dict
  if s:_is_status_batch(self)
    return ''
  endif
  let result = call('s:input', ['Question'] + a:000, self)
  redraw
  return result
endfunction

function! s:select(msg, candidates, ...) abort dict
  let canceled = get(a:000, 0, '')
  if s:_is_status_batch(self)
    return canceled
  endif
  let candidates = map(
        \ copy(a:candidates),
        \ 'v:key+1 . ''. '' . s:_ensure_string(v:val)'
        \)
  let result = self.inputlist('Question', [a:msg] + candidates)
  redraw
  return result == 0 ? canceled : a:candidates[result-1]
endfunction

function! s:confirm(msg, ...) abort dict
  if s:_is_status_batch(self)
    return 0
  endif
  let default = get(a:000, 0, '')
  if default !~? '^\%(y\%[es]\|n\%[o]\|\)$'
    throw 'vital: Vim.Console: An invalid default value has specified.'
  endif
  let choices = default =~? 'y\%[es]'
        \ ? 'Y[es]/n[o]'
        \ : default =~? 'n\%[o]'
        \   ? 'y[es]/N[o]'
        \   : 'y[es]/n[o]'
  let result = 'invalid'
  while result !~? '^\%(y\%[es]\|n\%[o]\)$'
    let result = self.input(
          \ 'Question',
          \ printf('%s (%s): ', a:msg, choices),
          \ '',
          \ function('s:_confirm_complete'),
          \)
    if type(result) != s:t_string
      redraw | echo ''
      call self.echo('Canceled.', 'WarningMsg')
      return 0
    endif
    let result = empty(result) ? default : result
  endwhile
  redraw | echo ''
  return result =~? 'y\%[es]'
endfunction

if exists('*execute')
  function! s:capture(command) abort
    let content = execute(a:command)
    return split(content, '\r\?\n', 1)
  endfunction
else
  function! s:capture(command) abort
    try
      redir => content
      silent execute a:command
    finally
      redir END
    endtry
    return split(content, '\r\?\n', 1)
  endfunction
endif

if has('patch-7.4.1738')
  function! s:clear() abort
    messages clear
  endfunction
else
  " @vimlint(EVL102, 1, l:i)
  function! s:clear() abort
    for i in range(201)
      echomsg ''
    endfor
  endfunction
  " @vimlint(EVL102, 0, l:i)
endif

function! s:_confirm_complete(arglead, cmdline, cursorpos) abort
  return filter(['yes', 'no'], 'v:val =~# ''^'' . a:arglead')
endfunction

function! s:_is_status_debug(module) abort
  if a:module.status ==# s:STATUS_DEBUG
    return 1
  elseif &verbose
    return 1
  endif
  return 0
endfunction

function! s:_is_status_batch(module) abort
  if a:module.status ==# s:STATUS_BATCH
    return 1
  endif
  return 0
endfunction

function! s:_ensure_string(x) abort
  return type(a:x) == s:t_string ? a:x : string(a:x)
endfunction

function! s:_assign_prefix(msg, prefix) abort
  return join(map(split(a:msg, '\r\?\n'), 'a:prefix . v:val'), "\n")
endfunction

if has('patch-7.4.1842')
  function! s:_get_function_name(fn) abort
    return get(a:fn, 'name')
  endfunction
else
  function! s:_get_function_name(fn) abort
    return matchstr(string(a:fn), 'function(''\zs.*\ze''')
  endfunction
endif

let &cpo = s:save_cpo
unlet! s:save_cpo
