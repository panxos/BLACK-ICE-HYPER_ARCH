local original_dofile = dofile
local surface, frame
local frame_path = os.getenv('XDG_RUNTIME_DIR') .. '/black-ice-conky/frame.lua'

function conky_preview()
    local job = original_dofile(assert(os.getenv('BLACK_ICE_PREVIEW_JOB')))
    frame = job.frame
    local ok, live = pcall(original_dofile, frame_path)
    if ok and live.data and live.data.cpu_usage ~= nil then frame.data = live.data end
    conky_surface = function() return surface end
    conky_set_update_interval = function(_) end
    dofile = function(path)
        if path == frame_path then return frame end
        return original_dofile(path)
    end
    for _, case in ipairs(job.cases) do
        frame.layout = case.layout
        surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
            case.layout.surface_width or case.layout.width, case.layout.surface_height or case.layout.height)
        conky_black_ice()
        assert(cairo_surface_write_to_png(surface, case.path) == 0, 'No se pudo guardar la miniatura')
        cairo_surface_destroy(surface)
    end
end
