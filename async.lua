areas = rawget(_G, "areas") or {}

local safe_file_write = core.safe_file_write
if safe_file_write == nil then
    safe_file_write = function(path, content)
        local file, err = io.open(path, "w")
        if err then
            return err
        end
        file:write(content)
        file:close()
    end
end

-- Save the areas table to a file
function areas._internal_do_save(areas_tb, filename)
    local datastr = core.write_json(areas_tb)
    if not datastr then
        core.log("error", "[areas] Failed to serialize area data!")
        return
    end
    return safe_file_write(filename, datastr)
end
