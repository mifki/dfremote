function set_restriction(item_type, item_subtype, mat_type, mat_index, restricted)
    local k = df.global.ui.kitchen
    
    for i,v in ipairs(k.item_types) do
        if v == item_type and k.item_subtypes[i] == item_subtype and
           k.mat_types[i] == mat_type and k.mat_indices[i] == mat_index then
            if restricted ~= 0 then
                k.exc_types[i] = restricted
            else
                k.item_types:erase(i)
                k.item_subtypes:erase(i)
                k.mat_types:erase(i)
                k.mat_indices:erase(i)
                k.exc_types:erase(i)
            end

            return
        end
    end    

    k.item_types:insert(#k.item_types, item_type)
    k.item_subtypes:insert(#k.item_subtypes, item_subtype)
    k.mat_types:insert(#k.mat_types, mat_type)
    k.mat_indices:insert(#k.mat_indices, mat_index)
    k.exc_types:insert(#k.exc_types, restricted)
end

--luacheck: in=
function kitchen_get_data()
    return execute_with_status_page(status_pages.Kitchen, function(ws)
        local ws = ws --as:df.viewscreen_kitchenprefst
        local ret = { { 'Plants', {} }, { 'Seeds', {} }, { 'Drinks', {} }, { 'Meat', {} } }

        for i,cat in ipairs(ret) do
            for j,v in ipairs(ws.item_str[i-1]) do
                local title = string.utf8capitalize(dfhack.df2utf(v.value))
                local id = { ws.item_type[i-1][j], ws.item_subtype[i-1][j], ws.mat_type[i-1][j], ws.mat_index[i-1][j] }
                
                table.insert(ret[i][2], { title, ws.count[i-1][j], whole(ws.forbidden[i-1][j]), whole(ws.possible[i-1][j]), id })
            end
        end

        local precision = df.global.ui.nobles.bookkeeper_precision    
        table.insert(ret, precision)

        return ret
    end)    
end

--luacheck: in=number[],bool
function kitchen_set(id, restricted)
    set_restriction(id[1], id[2], id[3], id[4], restricted)
    return true
end

--print(pcall(function() return json:encode(kitchen_get_data()) end))