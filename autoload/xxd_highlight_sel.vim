
function! s:get_xxd_ui_layout()
    let ui_layout = {
                \ "addr_start":1,
                \ "addr_end":9,
                \ "hex_start":11,
                \ "hex_end":50,  
                \ "hex_cell_width":4,
                \ "ascii_start":52,
                \ "ascii_end":68
                \ }
    if &ft == 'xxd'
        let line_content = getline(1)
        if len(line_content) < 4
            return {}
        endif
        let p = stridx(line_content, ':')
        if p >= 0 
            let ui_layout['addr_end'] = p+1
            let ui_layout['hex_start'] = p+3
        else
            echoerr "xxd_highlight_sel failed to get ui_layout"
            return {}
        endif

        let p = stridx(line_content, ' ',ui_layout['hex_start'])
        if p > 0
            let ui_layout['hex_cell_width'] = p + 1 - ui_layout['hex_start']
        else
            echoerr "xxd_highlight_sel failed to get ui_layout"
            return {}
        endif

        let p = stridx(line_content, '  ')
        if p > 0
            let ui_layout['hex_end'] = p+1
        else
            echoerr "xxd_highlight_sel failed to get ui_layout"
            return {}
        endif

        let hex_len = ui_layout['hex_end'] - ui_layout['hex_start']
        let cell_num = hex_len / (ui_layout['hex_cell_width'] + 1)
        let remaind = hex_len - cell_num * (ui_layout['hex_cell_width'] + 1)
        let ascii_len = remaind/2+cell_num*(ui_layout['hex_cell_width']/2)
        let ui_layout['ascii_end'] = len(line_content)+1
        let ui_layout['ascii_start'] = ui_layout['ascii_end'] - ascii_len
    endif
    return ui_layout
endfunction


function! s:xxd_highlight_sel_update_highlights(buf_nr) abort
    if &ft != 'xxd'
        execute 'autocmd! xxd_highlight_sel_cursor_event_augroup' . a:buf_nr
        return
    endif 

    if !exists('b:xxd_ui_layout')
        let b:xxd_ui_layout = s:get_xxd_ui_layout()
    else
        if b:xxd_ui_layout == {}
            return
        endif
    endif

    if !exists('b:highlights_list')
        let b:highlights_list = []
    endif

    let rgs = s:get_selected_ranges()

    "clear old highlights
    for h in b:highlights_list
        call prop_remove({'type':s:prop_type_name,'all':v:true},h)
    endfor
    let b:highlights_list = []

    try
        call s:highlight_ranges(rgs)
    endtry
endfunction

function! s:ascii_col_to_hex_col(col)
    let col_offset = a:col - b:xxd_ui_layout.ascii_start
    let cell_offsets = col_offset/(b:xxd_ui_layout.hex_cell_width/2)
    let inner_cell_offsets = col_offset - cell_offsets * (b:xxd_ui_layout.hex_cell_width/2)
    let col = b:xxd_ui_layout.hex_start + cell_offsets * (b:xxd_ui_layout.hex_cell_width + 1)
                \ + inner_cell_offsets*2
    return col
endfunction

function! s:is_hex_cell_gap_col(col)
    if a:col > b:xxd_ui_layout.hex_end
        return v:true
    endif
    let col_offset = a:col - b:xxd_ui_layout.hex_start
    let cell_offsets = col_offset/(b:xxd_ui_layout.hex_cell_width+1)
    let inner_cell_offsets = col_offset - cell_offsets * (b:xxd_ui_layout.hex_cell_width+1)
    return (inner_cell_offsets == b:xxd_ui_layout.hex_cell_width)
endfunction

"if col at the gap between hex cells
"return the left side 
function! s:hex_col_to_ascii_col(col)
    let col_offset = a:col - b:xxd_ui_layout.hex_start
    let cell_offsets = col_offset/(b:xxd_ui_layout.hex_cell_width+1)
    let inner_cell_offsets = col_offset - cell_offsets * (b:xxd_ui_layout.hex_cell_width+1)
    let col = b:xxd_ui_layout.ascii_start + cell_offsets * (b:xxd_ui_layout.hex_cell_width/2)
                \ + inner_cell_offsets/2
    return col
endfunction

function! xxd_highlight_sel#get_binary_pos()
endfunction

"a 'range' must within a line
"{lnum,col_start,col_end}
function! s:ascii_range_to_hex_range(rg) abort
    if a:rg.col_start > a:rg.col_end
        let tmp = a:rg.col_start
        let a:rg.col_start = a:rg.col_end
        let a:rg.col_end = tmp
    elseif a:rg.col_start == a:rg.col_end
        return v:null
    endif
    let r = {'lnum':a:rg.lnum}
    if a:rg.col_start < b:xxd_ui_layout['ascii_start']
        let a:rg.col_start = b:xxd_ui_layout['ascii_start']
    endif
    if a:rg.col_end > b:xxd_ui_layout['ascii_end']
        let a:rg.col_end = b:xxd_ui_layout['ascii_end']
    endif
    let r.col_start = s:ascii_col_to_hex_col(a:rg.col_start)
    let r.col_end = s:ascii_col_to_hex_col(a:rg.col_end) - 1
    return r
endfunction

function! s:hex_range_to_ascii_range(rg) abort
    if a:rg.col_start > a:rg.col_end
        let tmp = a:rg.col_start
        let a:rg.col_start = a:rg.col_end
        let a:rg.col_end = tmp
    elseif a:rg.col_start == a:rg.col_end
        return v:null
    endif
    let r = {'lnum':a:rg.lnum}

    if a:rg.col_start == a:rg.col_end
        if s:is_hex_cell_gap_col(a:rg.col_start)
            return v:null
        endif
    endif

    let r.col_start = s:hex_col_to_ascii_col(a:rg.col_start)
    let r.col_end = s:hex_col_to_ascii_col(a:rg.col_end+1)
    return r
endfunction

function! s:unify_visual_pos()

endfunction

function! s:get_selected_block_visual_ascii_ranges(pos) abort
    let [line_start,col_start,line_end,col_end] = a:pos
    let re = []
    if col_end > b:xxd_ui_layout['ascii_end']
        let col_end = b:xxd_ui_layout['ascii_end']
    endif
    if col_start < b:xxd_ui_layout['ascii_start']
        let col_start = b:xxd_ui_layout['ascii_start']
    endif
    if col_end == col_start
        return re
    endif
    let l = line_start
    while l <= line_end
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':col_end}
        let r = s:ascii_range_to_hex_range(r)
        if r != v:null
            call add(re,r)
        endif
        let l += 1
    endwhile
    return re
endfunction

function! s:get_selected_block_visual_hex_ranges(pos) abort
    let [line_start,col_start,line_end,col_end] = a:pos
    let re = []
    if col_end > b:xxd_ui_layout['hex_end']
        let col_end = b:xxd_ui_layout['hex_end']
    endif
    if col_start < b:xxd_ui_layout['hex_start']
        let col_start = b:xxd_ui_layout['hex_start']
    endif
    let l = line_start
    while l <= line_end
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':col_end}
        let r = s:hex_range_to_ascii_range(r)
        if r != v:null
            call add(re,r)
        endif
        let l += 1
    endwhile
    return re
endfunction

function! s:get_selected_normal_visual_ascii_ranges(pos) abort
    let re = []
    let [line_start,col_start,line_end,col_end] = a:pos
    let line_num = line_end - line_start + 1
    let l = line_start

    "first line
    if line_num == 1
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':col_end}
        let r = s:ascii_range_to_hex_range(r)
        if r != v:null
            call add(re,r)
        endif
    else
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':b:xxd_ui_layout['ascii_end']}
        let r = s:ascii_range_to_hex_range(r)
        if r != v:null
            call add(re,r)
        endif
    endif
    let l+= 1

    if line_num > 2
        "middle lines
        while l < line_end
            let r = {'lnum':l,'col_start':b:xxd_ui_layout['ascii_start'],
                        \ 'col_end':b:xxd_ui_layout['ascii_end']}
            let r = s:ascii_range_to_hex_range(r)
            if r != v:null
                call add(re,r)
            endif
            let l += 1
        endwhile
    endif

    if line_num > 1
        " last line
        let r = {'lnum':l,'col_start':b:xxd_ui_layout['ascii_start'],
                    \ 'col_end':col_end}
        let r = s:ascii_range_to_hex_range(r)
        if r != v:null
            call add(re,r)
        endif
    endif
    return re
endfunction

function! s:get_selected_normal_visual_hex_ranges(pos) abort
    let re = []
    let [line_start,col_start,line_end,col_end] = a:pos
    let line_num = line_end - line_start + 1
    let l = line_start

    "first line
    if line_num == 1
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':col_end}
        let r = s:hex_range_to_ascii_range(r)
        if r != v:null
            call add(re,r)
        endif
    else
        let r = {'lnum':l,'col_start':col_start,
                    \ 'col_end':b:xxd_ui_layout['hex_end']}
        let r = s:hex_range_to_ascii_range(r)
        if r != v:null
            call add(re,r)
        endif
    endif
    let l+= 1

    if line_num > 2
        "middle lines
        while l < line_end
            let r = {'lnum':l,'col_start':b:xxd_ui_layout['hex_start'],
                        \ 'col_end':b:xxd_ui_layout['hex_end']}
            let r = s:hex_range_to_ascii_range(r)
            if r != v:null
                call add(re,r)
            endif
            let l += 1
        endwhile
    endif

    if line_num > 1
        " last line
        let r = {'lnum':l,'col_start':b:xxd_ui_layout['hex_start'],
                    \ 'col_end':col_end}
        let r = s:hex_range_to_ascii_range(r)
        if r != v:null
            call add(re,r)
        endif
    endif
    return re
endfunction

"return [range]
function! s:get_selected_ranges() abort
    let mode = mode()
    let re = []

    if mode[0] == 'n'
        let pos = getcurpos()
        let col_start = pos[2]
        let line_start = pos[1]
        if col_start >= b:xxd_ui_layout['ascii_start']
            let r = {'lnum':line_start,'col_start':col_start,'col_end':col_start+1}
            let r = s:ascii_range_to_hex_range(r)
            if r != v:null
                call add(re,r)
            endif
        elseif col_start >= b:xxd_ui_layout['hex_start']
            let r = {'lnum':line_start,'col_start':col_start,'col_end':col_start+1}
            let r = s:hex_range_to_ascii_range(r)
            if r != v:null
                call add(re,r)
            endif
        else
        endif
    elseif (mode[0] == 'v') || (mode[0] == 'V') || (mode == "\<C-V>")
        let [line_start, col_start] = getpos('v')[1:2]
        let [line_end, col_end] = getcurpos()[1:2]
        let init_col_start = col_start

        if &selection == 'exclusive'
            if mode == "\<C-V>"
                "adjust col for block visual
                if line_start < line_end
                    if col_end <= col_start
                        let col_start += 1
                    endif
                elseif line_start == line_end
                    if col_end == col_start
                        let col_end += 1
                    endif
                else
                    if col_end >= col_start
                        let col_end += 1
                    endif
                endif
            endif
        else
            if mode == "\<C-V>"
                if col_end <= col_start
                    let col_start += 1
                else
                    let col_end += 1
                endif
            else
                "adjust col for block visual
                if line_start < line_end
                    let col_end += 1
                elseif line_start == line_end
                    if col_end <= col_start
                        let col_start += 1
                    else
                        let col_end += 1
                    endif
                else
                    let col_start += 1
                endif
            endif
        endif

        "keep end line num bigger than start line
        if (line_start > line_end) || ((line_start == line_end) && (col_start > col_end))
            let tmp = [line_start, col_start]
            let [line_start, col_start] = [line_end, col_end]
            let [line_end, col_end] = tmp
        endif

        if mode == "\<C-V>"
            "it's ok to force visual block's 
            "col_end > col_start
            if col_start > col_end
                let tmp = col_start
                let col_start = col_end
                let col_end = tmp 
            endif

            "visual block
            if init_col_start >= b:xxd_ui_layout['ascii_start']
                let re = s:get_selected_block_visual_ascii_ranges(
                            \ [line_start,col_start,line_end,col_end])
            elseif init_col_start >= b:xxd_ui_layout['hex_start']
                if s:is_hex_cell_gap_col(col_start)
                    let col_start += 1
                endif
                if s:is_hex_cell_gap_col(col_end)
                    let col_end -= 1
                endif
                let re = s:get_selected_block_visual_hex_ranges(
                            \ [line_start,col_start,line_end,col_end])
            else
            endif
        else
            if init_col_start >= b:xxd_ui_layout['ascii_start']
                let re = s:get_selected_normal_visual_ascii_ranges(
                            \ [line_start,col_start,line_end,col_end])
            elseif init_col_start >= b:xxd_ui_layout['hex_start']
                if (line_start != line_end) || (col_start != col_end)
                    if s:is_hex_cell_gap_col(col_start)
                        let col_start += 1
                    endif
                    if s:is_hex_cell_gap_col(col_end)
                        let col_end -= 1
                    endif
                endif
                let re = s:get_selected_normal_visual_hex_ranges(
                            \ [line_start,col_start,line_end,col_end])
            else
            endif
        endif
    else
        " echomsg '#' . mode . '#'
    endif
    return re
endfunction

function! s:highlight_ranges(ranges) abort
    for r in a:ranges
        let length =  r['col_end'] - r['col_start']
        if length > 0
            call prop_add(r['lnum'], r['col_start'], 
                        \ {'length':length,
                        \ 'type': s:prop_type_name})
            call add(b:highlights_list,r['lnum'])
        endif
    endfor
endfunction

function! xxd_highlight_sel#init() abort
    if !hlexists('XxdHighlightSel')
        highlight XxdHighlightSel term=reverse cterm=reverse gui=reverse
    endif

    let s:prop_type_name = 'xxd_highlight_sel'

    if prop_type_get(s:prop_type_name) == {}
        call prop_type_add(s:prop_type_name, {'highlight': 'XxdHighlightSel'})
    endif

    "store ui layout in xxd mode
    let b:xxd_ui_layout = s:get_xxd_ui_layout()
    "store all highlights here
    let b:highlights_list = []

    let l:bn = bufnr('%')
    execute 'augroup xxd_highlight_sel_cursor_event_augroup' . l:bn
    execute '  autocmd!'
    execute '  autocmd CursorMoved <buffer=' . l:bn 
                \ . '> call s:xxd_highlight_sel_update_highlights(' . l:bn . ')'
    execute 'augroup end'

    "This did't work with two xxd bufers. The CursorMoved will only work for
    "the newly opened one. Don't know why
    " augroup xxd_highlight_sel_cursor_event_augroup 
        " autocmd!
        " autocmd CursorMoved <buffer> call s:xxd_highlight_sel_update_highlights()
    " augroup END
endfunction

