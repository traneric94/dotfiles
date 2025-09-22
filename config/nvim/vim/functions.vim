" Clean, refactored functions

" Config
let g:go_bin_path = "/Users/eric.tran/go/bin/"

" Shared quickfix error parsing
function! ParseErrorsToQuickfix(output, clear=v:true)
  if a:clear | call setqflist([], 'r') | endif

  let qf_items = []
  for line in split(a:output, '\n')
    if line =~ ':\d\+:\d\+:' || line =~ 'FAIL:'
      let parts = matchlist(line, '\(.\{-}\):\(\d\+\):\(\d\+\):\s*\(.*\)')
      if len(parts) >= 5
        call add(qf_items, {'filename': parts[1], 'lnum': parts[2], 'col': parts[3], 'text': parts[4]})
      else
        call add(qf_items, {'text': line})
      endif
    endif
  endfor

  call setqflist(qf_items, a:clear ? 'r' : 'a')
  return len(qf_items)
endfunction

" Simple async runner
function! RunAsync(cmd, msg, callback)
  echo a:msg . " (async)..."
  let s:output = []

  function! s:OnOutput(job_id, data, event) closure
    call extend(s:output, a:data)
  endfunction

  function! s:OnExit(job_id, exit_code, event) closure
    call a:callback(a:exit_code, s:output)
    let s:output = []
  endfunction

  call jobstart(a:cmd, {
    \ 'on_stdout': function('s:OnOutput'),
    \ 'on_stderr': function('s:OnOutput'),
    \ 'on_exit': function('s:OnExit'),
    \ 'stdout_buffered': v:true,
    \ 'stderr_buffered': v:true
    \ })
endfunction

" CoC documentation
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Git PR opener
function! OpenPullRequest()
  let line_num = line('.')
  let commit_hash = systemlist('git blame -L' . line_num . ',' . line_num . ' --porcelain ' . expand('%'))[0]
  let commit_hash = split(commit_hash)[0]

  if len(commit_hash) == 40
    let pr_num = trim(system('gh pr list --search "' . commit_hash . '" --json number --jq ".[0].number // empty"'))
    if pr_num != '' && pr_num != 'null'
      echo 'Opening PR #' . pr_num . ' for commit ' . commit_hash[0:7]
      call system('gh pr view ' . pr_num . ' --web')
    else
      echo 'No PR found for commit ' . commit_hash[0:7]
    endif
  else
    echo 'Could not get commit hash for current line'
  endif
endfunction

" Test file toggle
function! ToggleTestFile()
  let patterns = {
    \ 'rb': [['_spec\.rb$', '.rb', '/spec/', '/lib/'], ['\.rb$', '_spec.rb', '/lib/', '/spec/']],
    \ 'go': [['_test\.go$', '.go'], ['\.go$', '_test.go']],
    \ 'ts\|tsx\|js\|jsx': [['\.test\.', '.'], ['\.\(ts\|tsx\|js\|jsx\)$', '.test.\1']]
  \ }

  let ext = expand('%:e')
  let file = expand('%:p')

  for [pattern_ext, transforms] in items(patterns)
    if ext =~# pattern_ext
      for transform in transforms
        if file =~# get(transform, 0)
          let target = substitute(file, get(transform, 0), get(transform, 1), '')
          if len(transform) > 2
            let target = substitute(target, get(transform, 2), get(transform, 3), '')
          endif
          execute 'edit ' . fnameescape(target)
          echo "Toggled to: " . fnamemodify(target, ':t')
          return
        endif
      endfor
    endif
  endfor

  echo "No test pattern for: " . ext
endfunction

" Go format (simplified)
function! GoFormat()
  if &filetype != 'go' | return | endif

  let file = shellescape(expand('%'))
  let result = system(g:go_bin_path . 'goimports -w ' . file . ' 2>&1')

  if v:shell_error != 0
    call ParseErrorsToQuickfix(result)
    copen
  else
    let result = system(g:go_bin_path . 'gci write --skip-generated --skip-vendor -s standard -s default -s "prefix(github.com/1debit)" ' . file)
    edit
  endif
endfunction

" Go test (async)
function! GoTestQuick()
  function! s:TestCallback(exit_code, output)
    if a:exit_code != 0
      let error_count = ParseErrorsToQuickfix(join(a:output, "\n"))
      if error_count > 0 | copen | endif
      echo "Tests failed - check quickfix"
    else
      echo "All tests passed"
    endif
  endfunction

  call RunAsync(['go', 'test', './...'], 'Running tests', function('s:TestCallback'))
endfunction

" Go vet (sync)
function! GoVetQuick()
  let result = system('go vet ./... 2>&1')
  let error_count = ParseErrorsToQuickfix(result)

  if error_count > 0
    copen
  else
    echo "Go vet passed"
  endif
endfunction

" Go build (sync)
function! GoBuildQuick()
  let result = system('go build ./... 2>&1')
  let error_count = ParseErrorsToQuickfix(result)

  if error_count > 0
    copen
  else
    echo "Build successful"
  endif
endfunction

" Simple import folder
function! FoldImports()
  let patterns = {
    \ 'go': '^\s*import\s*(',
    \ 'typescript\|typescriptreact\|javascript\|javascriptreact': '^\s*import\s\+.*from',
    \ 'ruby': '^\s*require',
    \ 'python': '^\s*\(import\|from\)\s'
  \ }

  for [ft, pattern] in items(patterns)
    if &filetype =~# ft
      let lines = getline(1, '$')
      let start = -1

      for i in range(len(lines))
        if lines[i] =~# pattern
          if start == -1 | let start = i + 1 | endif
        elseif start != -1 && lines[i] !~ '^\s*$'
          if i > start
            execute start . ',' . i . 'fold'
          endif
          let start = -1
        endif
      endfor
      break
    endif
  endfor
endfunction


command! FoldImports call FoldImports()