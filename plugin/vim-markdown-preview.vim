"============================================================
"                    Vim Markdown Preview
"   git@github.com:JamshedVesuna/vim-markdown-preview.git
"============================================================

" this version by default works for chromium on Linux and chrome on WSL. Add your own system's checks if you want.
" I don't use the local function so that is not maintained.
" On Linux, I use auto-preview on save. ON WSL, I set auto-compile on save and
" view with set hotkey. 
" Be careful about browser names. Their cmmand line names and window names are different.
let g:vmp_script_path = resolve(expand('<sfile>:p:h'))

let g:vmp_osname = 'Unidentified'

if has('win32') || has('win64')
  " Not yet used
  let g:vmp_osname = 'win32'
elseif has('unix')
  let s:uname = system("uname")

  if has('mac') || has('macunix') || has("gui_macvim") || s:uname == "Darwin\n"
    let g:vmp_osname = 'mac'
    let g:vmp_search_script = g:vmp_script_path . '/applescript/search-for-vmp.scpt'
    let g:vmp_activate_script = g:vmp_script_path . '/applescript/activate-vmp.scpt'
  else
    let g:vmp_osname = 'unix'
  endif
endif

if !exists("g:vim_markdown_preview_browser")
  if g:vmp_osname == 'mac'
    let g:vim_markdown_preview_browser = 'Safari'
  else
    let g:vim_markdown_preview_browser = 'Google Chrome'
  endif
  if has('unix')
      let uname = system('uname -a') 
      """ test WSL is running
      if uname=~"Microsoft"
          let g:vim_markdown_preview_toggle=0
          let g:vim_markdown_preview_browser='Google Chrome'
          let g:vim_markdown_preview_browser_cmd='chrome'
      else
          let g:vim_markdown_preview_toggle=3
          let g:vim_markdown_preview_browser='Chromium'
          let g:vim_markdown_preview_browser_cmd='chromium-browser'
      endif
  endif
endif


if !exists("g:vim_markdown_preview_temp_file")
  let g:vim_markdown_preview_temp_file = 0
endif

if !exists("g:vim_markdown_preview_toggle")
  let g:vim_markdown_preview_toggle = 0
endif

if !exists("g:vim_markdown_preview_github")
  let g:vim_markdown_preview_github = 0
endif

if !exists("g:vim_markdown_preview_perl")
  let g:vim_markdown_preview_perl = 0
endif

if !exists("g:vim_markdown_preview_pandoc")
  let g:vim_markdown_preview_pandoc = 0
endif

if !exists("g:vim_markdown_preview_use_xdg_open")
    let g:vim_markdown_preview_use_xdg_open = 0
endif

if !exists("g:vim_markdown_preview_hotkey")
    let g:vim_markdown_preview_hotkey='<C-p>'
endif

function! VmpActuallyCompile()
    call VmpSetCompileCmd()
    call system(g:cmd_compile_vmp . ' & ')
    " if v:shell_error
    "     echo 'Please install the necessary requirements: https://github.com/JamshedVesuna/vim-markdown-preview#requirements'
    " endif
endfunction

function! VmpSetCompileCmd()
  let b:curr_file = expand('%:p')
  let b:short_noext_name = expand('%:t:r')
  if g:vim_markdown_preview_github == 1
      let g:cmd_compile_vmp =  'grip "' . b:curr_file . '" --export /tmp/vim-markdown-preview.html --title vim-markdown-preview.html&'
  elseif g:vim_markdown_preview_perl == 1
      let g:cmd_compile_vmp =  'Markdown.pl "' . b:curr_file . '" > /tmp/vim-markdown-preview.html &'
  elseif g:vim_markdown_preview_pandoc == 1
      let g:cmd_compile_vmp = 'pandoc --mathjax -f markdown --standalone "' . b:curr_file . '" > /tmp/vim-markdown-preview.html'
  else
      let g:cmd_compile_vmp =  'markdown "' . b:curr_file . '" > /tmp/vim-markdown-preview.html &'
  endif
endfunction

function! Vim_Markdown_Preview()
  let b:curr_file = expand('%:p')
  let b:short_noext_name = expand('%:t:r')
  call system('rm -rf /tmp/vim-markdown-preview.html')
  "" get the compile command
  call VmpSetCompileCmd()
  if g:vmp_osname == 'unix'
      let uname = system('uname -a') 
      """ test WSL is running. Requires wslpath from https://github.com/darealshinji/scripts/blob/master/wslpath
      if uname=~"Microsoft"
          "" only launch browser after pandoc is done.
          let l:tmp_string =system('wslpath -w /tmp/vim-markdown-preview.html')
          let g:tmp_file_vmp_win = substitute(l:tmp_string,".$","","")
          let g:cmd_view_vmp=g:vim_markdown_preview_browser_cmd  . ' "' . g:tmp_file_vmp_win . '"  '
          let g:cmd_vmp=  g:cmd_compile_vmp . ' ; ' .  g:cmd_view_vmp . ' & '
          call system( g:cmd_vmp )
          echom "done"
      else "no WSL. Original behavior
          call system(g:cmd_compile_vmp) 
          let chrome_wid = system('xdotool search --name "' . b:short_noext_name . ' - "' . g:vim_markdown_preview_browser)
          if !chrome_wid
              if g:vim_markdown_preview_use_xdg_open == 1
                  call system('xdg-open /tmp/vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
              else
                  call system( g:vim_markdown_preview_browser_cmd . ' /tmp/vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
              endif
          else
              " echoerr "lucky"
              let curr_wid = system('xdotool getwindowfocus')
              call system('xdotool windowmap ' . chrome_wid)
              call system('xdotool windowactivate ' . chrome_wid)
              call system("xdotool key 'ctrl+r'")
              call system('xdotool windowactivate ' . curr_wid)
          endif
      endif
  endif

  if g:vmp_osname == 'mac'
      call system(g:cmd_compile_vmp) 
      if g:vim_markdown_preview_browser == "Google Chrome"
          let b:vmp_preview_in_browser = system('osascript "' . g:vmp_search_script . '"')
          if b:vmp_preview_in_browser == 1
              call system('open -g /tmp/vim-markdown-preview.html')
          else
              call system('osascript "' . g:vmp_activate_script . '"')
          endif
      else
          call system('open -a "' . g:vim_markdown_preview_browser_cmd . '" -g /tmp/vim-markdown-preview.html')
      endif
  endif
endfunction

"Renders html locally and displays images
function! Vim_Markdown_Preview_Local()
  let b:curr_file = expand('%:p')

  if g:vim_markdown_preview_github == 1
    call system('grip "' . b:curr_file . '" --export vim-markdown-preview.html --title vim-markdown-preview.html')
  elseif g:vim_markdown_preview_perl == 1
    call system('Markdown.pl "' . b:curr_file . '" > /tmp/vim-markdown-preview.html')
  elseif g:vim_markdown_preview_pandoc == 1
    call system('pandoc --standalone "' . b:curr_file . '" > /tmp/vim-markdown-preview.html')
  else
    call system('markdown "' . b:curr_file . '" > vim-markdown-preview.html')
  endif
  if v:shell_error
    echo 'Please install the necessary requirements: https://github.com/JamshedVesuna/vim-markdown-preview#requirements'
  endif

  if g:vmp_osname == 'unix'
    let chrome_wid = system('xdotool search --name "' . b:short_noext_name . ' - "' . g:vim_markdown_preview_browser)
    if !chrome_wid
      if g:vim_markdown_preview_use_xdg_open == 1
        call system('xdg-open vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
      else
        call system('see vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
      endif
    else
      let curr_wid = system('xdotool getwindowfocus')
      call system('xdotool windowmap ' . chrome_wid)
      call system('xdotool windowactivate ' . chrome_wid)
      call system("xdotool key 'ctrl+r'")
      call system('xdotool windowactivate ' . curr_wid)
    endif
  endif

  if g:vmp_osname == 'mac'
    if g:vim_markdown_preview_browser == "Google Chrome"
      let b:vmp_preview_in_browser = system('osascript "' . g:vmp_search_script . '"')
      if b:vmp_preview_in_browser == 1
        call system('open -g vim-markdown-preview.html')
    else
        call system('osascript "' . g:vmp_activate_script . '"')
      endif
    else
      call system('open -a "' . g:vim_markdown_preview_browser_cmd . '" -g vim-markdown-preview.html')
    endif
  endif

  if g:vim_markdown_preview_temp_file == 1
    sleep 200m
    call system('rm vim-markdown-preview.html')
  endif
endfunction

if g:vim_markdown_preview_toggle == 0
  "Maps vim_markdown_preview_hotkey to Vim_Markdown_Preview()
  if has('unix')
      let uname = system('uname -a') 
      """ test WSL is running
      if uname=~"Microsoft"
          augroup VimMdPreview
              autocmd!
              autocmd BufWritePost *.markdown,*.md call VmpActuallyCompile() 
          augroup END
      endif
  else
      exec 'autocmd Filetype markdown,md map <buffer> ' . g:vim_markdown_preview_hotkey . ':call Vim_Markdown_Preview()<CR>'
  endif
elseif g:vim_markdown_preview_toggle == 1
  "Display images - Maps vim_markdown_preview_hotkey to Vim_Markdown_Preview_Local() - saves the html file locally
  "and displays images in path
  :exec 'autocmd Filetype markdown,md map <buffer> ' . g:vim_markdown_preview_hotkey . ' :call Vim_Markdown_Preview_Local()<CR>'
elseif g:vim_markdown_preview_toggle == 2
  "Display images - Automatically call Vim_Markdown_Preview_Local() on buffer write
  augroup VimMdPreview
      autocmd!
      autocmd BufWritePost *.markdown,*.md call Vim_Markdown_Preview_Local()
  augroup END
elseif g:vim_markdown_preview_toggle == 3
  "Automatically call Vim_Markdown_Preview() on buffer write
  augroup VimMdPreview
      autocmd!
      autocmd BufWritePost *.markdown,*.md call Vim_Markdown_Preview()
  augroup END
endif
