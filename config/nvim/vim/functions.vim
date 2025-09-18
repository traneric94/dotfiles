" Show documentation function for CoC
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Function to open PR for current line's commit
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

" Simplified test toggle function
function! ToggleTestFile()
  let current_file = expand('%:p')
  let file_ext = expand('%:e')

  if file_ext ==# 'rb'
    " Ruby: spec <-> source
    if current_file =~# '_spec\.rb$'
      let target = substitute(current_file, '_spec\.rb$', '.rb', '')
      let target = substitute(target, '/spec/', '/lib/', '')
    else
      let target = substitute(current_file, '\.rb$', '_spec.rb', '')
      let target = substitute(target, '/lib/', '/spec/', '')
    endif
  elseif file_ext =~# '\(ts\|tsx\|js\|jsx\)$'
    " TypeScript/JS: .test. <-> source
    if current_file =~# '\.test\.\(ts\|tsx\|js\|jsx\)$'
      let target = substitute(current_file, '\.test\.', '.', '')
    else
      let target = substitute(current_file, '\.\(ts\|tsx\|js\|jsx\)$', '.test.\1', '')
    endif
  elseif file_ext ==# 'go'
    " Go: _test.go <-> .go
    if current_file =~# '_test\.go$'
      let target = substitute(current_file, '_test\.go$', '.go', '')
    else
      let target = substitute(current_file, '\.go$', '_test.go', '')
    endif
  else
    echo "No test pattern for: " . file_ext
    return
  endif

  execute 'edit ' . fnameescape(target)
  echo "Toggled to: " . fnamemodify(target, ':t')
endfunction

" Go formatting function
function! GoFormat()
  if &filetype == 'go'
    " First run goimports to remove unused imports and add missing ones
    let goimports_cmd = "~/go/bin/goimports -w " . shellescape(expand('%'))
    let goimports_result = system(goimports_cmd)
    if v:shell_error != 0
      return
    endif

    " Then run gci to group imports properly
    let cmd = "~/go/bin/gci write --skip-generated --skip-vendor -s standard -s default -s \"prefix(github.com/1debit)\" " . shellescape(expand('%'))
    let result = system(cmd)
    edit
  endif
endfunction

" Setup CoC signs with less intrusive symbols
function! SetupCocSigns()
  sign define CocError text=● texthl=CocErrorSign linehl= numhl=
  sign define CocWarning text=● texthl=CocWarningSign linehl= numhl=
  sign define CocInfo text=● texthl=CocInfoSign linehl= numhl=
  sign define CocHint text=● texthl=CocHintSign linehl= numhl=
endfunction

" Auto-fold imports function
function! AutoFoldImports()
  let current_line = 1
  let total_lines = line('$')

  " Clear existing manual folds
  normal! zE

  while current_line <= total_lines
    let line_content = getline(current_line)

    " Detect import blocks for different languages
    if &filetype == 'go'
      " Go imports: look for "import (" block
      if line_content =~ '^\s*import\s*('
        let import_start = current_line
        let current_line = current_line + 1

        " Find the end of import block
        while current_line <= total_lines && getline(current_line) !~ '^\s*)'
          let current_line = current_line + 1
        endwhile

        if current_line <= total_lines
          " Create fold for import block
          execute import_start . ',' . current_line . 'fold'
        endif
      endif

    elseif &filetype == 'typescript' || &filetype == 'typescriptreact' || &filetype == 'javascript' || &filetype == 'javascriptreact'
      " TypeScript/JavaScript imports
      if line_content =~ '^\s*import\s\+.*from'
        let import_start = current_line

        " Find consecutive import lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*import\s\+.*from'
          let current_line = current_line + 1
        endwhile

        " Create fold if there are multiple consecutive imports
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif

    elseif &filetype == 'ruby'
      " Ruby requires
      if line_content =~ '^\s*require'
        let import_start = current_line

        " Find consecutive require lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*require'
          let current_line = current_line + 1
        endwhile

        " Create fold if there are multiple consecutive requires
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif

    elseif &filetype == 'python'
      " Python imports
      if line_content =~ '^\s*\(import\|from\)\s'
        let import_start = current_line

        " Find consecutive import lines
        while current_line + 1 <= total_lines && getline(current_line + 1) =~ '^\s*\(import\|from\)\s'
          let current_line = current_line + 1
        endwhile

        " Create fold if there are multiple consecutive imports
        if current_line > import_start
          execute import_start . ',' . current_line . 'fold'
        endif
      endif
    endif

    let current_line = current_line + 1
  endwhile
endfunction

" Manual command to fold imports
command! FoldImports call AutoFoldImports()