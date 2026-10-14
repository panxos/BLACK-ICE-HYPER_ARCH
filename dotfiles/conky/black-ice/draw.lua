require('cairo')

local frame_path = os.getenv('BLACK_ICE_CONKY_FRAME') or (os.getenv('XDG_RUNTIME_DIR') .. '/black-ice-conky/frame.lua')
local cr, palette, opacity
local selected_language = 'es'
local translations = {
    {'CPU / TEMPERATURA', 'CPU / TEMPERATURE'}, {'CPU / CARGA', 'CPU / LOAD'},
    {'CARGA CPU', 'CPU LOAD'}, {'ALMACENAMIENTO', 'STORAGE'}, {'TELEMETRÍA LOCAL', 'LOCAL TELEMETRY'},
    {'ACTIVIDAD CPU', 'CPU ACTIVITY'}, {'RAM / MEMORIA', 'RAM / MEMORY'}, {'USO TOTAL', 'TOTAL USAGE'},
    {'VENTILACIÓN', 'FAN'}, {'DISPONIBLES', 'AVAILABLE'}, {'CORRIENTE', 'AC POWER'},
    {'BATERÍA', 'BATTERY'}, {'MEMORIA', 'MEMORY'}, {'MUESTREO', 'SAMPLE'},
    {'TEMPERATURA', 'TEMPERATURE'}, {'HILOS', 'THREADS'}, {'CARGA', 'LOAD'},
    {'DISCO', 'DISK'}, {'RED', 'NETWORK'}, {'ENERGÍA', 'POWER'}, {'LIBRES', 'FREE'},
    {'libres', 'free'}, {'EN USO', 'IN USE'}, {'MES', 'MONTH'}, {'DÍA', 'DAY'},
    {'HORA', 'HOUR'}, {'MINUTO', 'MINUTE'}
}

local function localized(value)
    if selected_language ~= 'en' then return value end
    for _, pair in ipairs(translations) do
        local start = 1
        while true do
            local first, last = value:find(pair[1], start, true)
            if not first then break end
            value = value:sub(1, first - 1) .. pair[2] .. value:sub(last + 1)
            start = first + #pair[2]
        end
    end
    return value
end
local extents = cairo_text_extents_t:create()
tolua.takeownership(extents)

local function rgb(hex)
    return tonumber(hex:sub(2, 3), 16) / 255,
        tonumber(hex:sub(4, 5), 16) / 255,
        tonumber(hex:sub(6, 7), 16) / 255
end

local function color(hex, alpha)
    local r, g, b = rgb(hex)
    cairo_set_source_rgba(cr, r, g, b, alpha or 1)
end

local function text(x, y, value, size, hex, bold, align)
    value = localized(tostring(value))
    local numeric = value:match('^%-?%d') or value == 'N/D'
    cairo_select_font_face(cr, (numeric and palette.data_font or palette.font) or 'Roboto', CAIRO_FONT_SLANT_NORMAL,
        bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
    cairo_set_font_size(cr, size)
    cairo_text_extents(cr, value, extents)
    if align == 'center' then x = x - extents.x_advance / 2
    elseif align == 'right' then x = x - extents.x_advance end
    color(hex or palette.fg)
    cairo_move_to(cr, x, y)
    cairo_show_text(cr, value)
end

local function line(x1, y1, x2, y2, hex, alpha, width)
    color(hex, alpha)
    cairo_set_line_width(cr, width or 1)
    cairo_move_to(cr, x1, y1)
    cairo_line_to(cr, x2, y2)
    cairo_stroke(cr)
end

local function rect(x, y, width, height, hex, alpha)
    color(hex, alpha)
    cairo_rectangle(cr, x, y, width, height)
    cairo_fill(cr)
end

local function polygon(points, fill, alpha, stroke)
    cairo_move_to(cr, points[1][1], points[1][2])
    for i = 2, #points do cairo_line_to(cr, points[i][1], points[i][2]) end
    cairo_close_path(cr)
    if fill then color(fill, alpha); cairo_fill_preserve(cr) end
    if stroke then
        color(stroke, .65)
        cairo_set_line_width(cr, 1)
        cairo_stroke(cr)
    else cairo_new_path(cr) end
end

local function number(value, suffix, digits)
    if value == nil then return 'N/D' end
    return string.format('%.' .. (digits or 0) .. 'f', value) .. (suffix or '')
end

local function thermal(value)
    if value and value >= 85 then return '#ff7777' end
    if value and value >= 70 then return '#ffc46b' end
    return palette.acc1
end

local function ink(hex)
    local r, g, b = rgb(hex)
    local function linear(v)
        return v <= .04045 and v / 12.92 or ((v + .055) / 1.055) ^ 2.4
    end
    local luminance = .2126 * linear(r) + .7152 * linear(g) + .0722 * linear(b)
    return luminance > .179 and '#09111b' or '#ffffff'
end

local function speed(value)
    if value == nil then return 'N/D' end
    if value >= 1048576 then return number(value / 1048576, ' MiB/s', 1) end
    return number(value / 1024, ' KiB/s', 1)
end

local function free_space(data)
    if data.free_gib >= 1024 then return number(data.free_gib / 1024, ' TiB', 1) end
    return number(data.free_gib, ' GiB')
end

local function reading_value(data, key)
    if data[key] ~= nil then return data[key] end
    if key == 'cpu' then return data.cpu_usage end
    if key == 'nvme' then return data.disk_percent end
    if key == 'fan' then return data.cpu_count end
end

local function reading(data, key, suffix)
    if data[key] ~= nil then return number(data[key], suffix) end
    if key == 'cpu' then return number(data.cpu_usage, '%') end
    if key == 'nvme' then return number(data.disk_percent, '%') end
    return number(data.cpu_count)
end

local function caption(data, key, original)
    if key == 'cpu' then return data.cpu ~= nil and 'CPU / TEMP.' or 'CPU / CARGA' end
    if data[key] ~= nil then return original end
    if key == 'nvme' then return 'DISCO' end
    return data.virtualization and 'vCPU' or 'HILOS'
end

local function reading_level(data, key)
    if data[key] ~= nil then return data[key] end
    return reading_value(data, key)
end

local function power_label(data)
    if data.virtualization then
        local uptime = data.uptime
        if uptime == nil then return 'VM / ' .. data.virtualization:upper() end
        return 'VM / ' .. data.virtualization:upper() .. ' · ' .. math.floor(uptime / 3600)
            .. 'h ' .. math.floor(uptime / 60) % 60 .. 'm'
    end
    local label = data.source == 'AC' and 'CORRIENTE' or data.source == 'BAT' and 'BATERÍA' or data.source
    if data.battery then label = label .. ' / ' .. data.battery .. '%' end
    return label
end

local function segments(x, y, width, value, hex)
    local count, gap, height = 28, 3, 7
    local segment = (width - gap * (count - 1)) / count
    local active = value and math.ceil(math.max(0, math.min(100, value)) / 100 * count) or 0
    for i = 0, count - 1 do
        rect(x + i * (segment + gap), y, segment, height, hex, i < active and 1 or .16)
    end
end

local function history(values, x, y, width, height)
    if #values < 2 then return end
    color(palette.acc1, .85)
    cairo_set_line_width(cr, 1.3)
    for i, value in ipairs(values) do
        local px = x + (i - 1) / 59 * width
        local py = y + height - math.min(value, 100) / 100 * height
        if i == 1 then cairo_move_to(cr, px, py) else cairo_line_to(cr, px, py) end
    end
    cairo_stroke(cr)
end

local function cpu_icon(x, y, hex)
    color(hex)
    cairo_set_line_width(cr, 1.3)
    cairo_rectangle(cr, x + 4, y + 4, 13, 13)
    for i = 0, 2 do
        local n = 7 + i * 4
        cairo_move_to(cr, x + n, y); cairo_line_to(cr, x + n, y + 4)
        cairo_move_to(cr, x + n, y + 17); cairo_line_to(cr, x + n, y + 21)
        cairo_move_to(cr, x, y + n); cairo_line_to(cr, x + 4, y + n)
        cairo_move_to(cr, x + 17, y + n); cairo_line_to(cr, x + 21, y + n)
    end
    cairo_stroke(cr)
end

local function thermal_block(x, y, width, data)
    local accent = thermal(data.cpu)
    local foreground = ink(accent)
    polygon({{x + 20, y}, {x + width - 20, y}, {x + width, y + 20},
        {x + width - 22, y + 126}, {x + 20, y + 126}, {x, y + 106}, {x, y + 20}}, accent, math.min(.94, opacity + .12))
    cpu_icon(x + 19, y + 14, foreground)
    text(x + 50, y + 28, caption(data, 'cpu', 'CPU / TEMP.'), 11, foreground, true)
    text(x + 22, y + 91, reading(data, 'cpu', '°'), 58, foreground, true)
    text(x + width - 30, y + 114, (data.cpu ~= nil and 'CELSIUS' or 'USO TOTAL'), 11, foreground, true, 'right')
end

local function compute_block(x, y, width, data)
    text(x, y + 13, 'CARGA CPU', 11, palette.fg)
    text(x + width, y + 17, number(data.cpu_usage, '%'), 19, palette.acc1, true, 'right')
    segments(x, y + 31, width, data.cpu_usage, palette.acc1)
    text(x, y + 70, 'RAM', 11)
    text(x + width, y + 72, number(data.ram_used, '', 1) .. ' / ' .. number(data.ram_total, ' GiB'), 16, palette.acc2, true, 'right')
    segments(x, y + 85, width, data.ram_percent, palette.acc2)
    history(data.history, x, y + 105, width, 18)
end

local function secondary(x, y, width, data, kind)
    if kind == 'storage' then
        text(x, y, 'ALMACENAMIENTO', 11)
        text(x, y + 29, reading(data, 'nvme', '°'), 25, thermal(data.nvme), true)
        text(x, y + 51, free_space(data) .. ' libres', 11)
    elseif kind == 'fan' then
        text(x, y, caption(data, 'fan', 'VENTILACIÓN'), 11)
        text(x, y + 29, reading(data, 'fan', ''), 25, palette.fg, true)
        text(x, y + 51, (data.fan ~= nil and 'RPM' or 'DISPONIBLES'), 11, palette.acc2)
    else
        text(x, y, 'RED / ' .. data.interface:sub(1, 16), 11)
        text(x, y + 28, 'RX', 11, palette.acc1, true)
        text(x + width, y + 28, speed(data.rx), 14, palette.fg, true, 'right')
        text(x, y + 52, 'TX', 11, palette.acc2, true)
        text(x + width, y + 52, speed(data.tx), 14, palette.fg, true, 'right')
    end
end

local function fracture(plan, data)
    local w, h = plan.width, plan.height
    local tab_left = (w - math.min(320, w - 48)) / 2
    local tab_right = w - tab_left
    polygon({{2, 52}, {25, 29}, {tab_left, 29}, {tab_left + 20, 7},
        {tab_right - 20, 7}, {tab_right, 29}, {w - 25, 29}, {w - 2, 52},
        {w - 2, h - 28}, {w - 27, h - 3}, {27, h - 3}, {2, h - 28}},
        palette.bg, opacity, palette.acc1)
    polygon({{tab_left, 29}, {tab_left + 20, 7}, {tab_right - 20, 7}, {tab_right, 29}}, palette.acc1, 1)
    text(w / 2, 23, 'BLACK-ICE / FRACTURE', 11, ink(palette.acc1), true, 'center')
    line(3, 66, 3, 111, palette.acc1, 1, 3)
    line(w - 3, h - 70, w - 3, h - 32, palette.acc2, 1, 3)
    line(27, h - 3, 140, h - 3, palette.acc1, 1, 3)
    line(w - 140, 29, w - 26, 29, palette.acc2, 1, 2)

    if not plan.compact then
        thermal_block(22, 48, 208, data)
        compute_block(260, 52, 230, data)
        line(516, 54, 516, 173, palette.acc2, .28)
        secondary(544, 69, 156, data, 'storage')
        text(544, 150, caption(data, 'fan', 'FAN'), 11)
        text(706, 150, reading(data, 'fan', ' RPM'), 16, palette.acc2, true, 'right')
        line(731, 54, 731, 173, palette.acc2, .28)
        secondary(756, 69, w - 785, data, 'network')
        text(756, 163, power_label(data), 11, palette.acc1)
        text(w - 28, h - 17, 'MUESTREO ' .. data.interval .. ' s', 11, palette.fg, false, 'right')
    else
        local block_width = plan.narrow and 170 or 200
        thermal_block(22, 52, block_width, data)
        compute_block(block_width + 48, 56, w - block_width - 77, data)
        line(24, 205, w - 24, 205, palette.acc2, .3)
        if plan.narrow then
            secondary(28, 230, w / 2 - 50, data, 'storage')
            secondary(w / 2 + 12, 230, w / 2 - 40, data, 'fan')
            secondary(28, 326, w - 56, data, 'network')
        else
            local cell = (w - 84) / 3
            secondary(28, 230, cell, data, 'storage')
            secondary(42 + cell, 230, cell, data, 'fan')
            secondary(56 + cell * 2, 230, cell, data, 'network')
        end
        text(w / 2, h - 24, power_label(data) .. ' · ' .. data.interval .. ' s', 11, palette.acc1, false, 'center')
    end
end

local function signal_panel(plan, data)
    local w, h = plan.width, plan.height
    local clock_y = 8
    local clock_width = math.min(348, w - 48)
    local clock_x = (w - clock_width) / 2
    polygon({{clock_x + 18, clock_y}, {clock_x + clock_width, clock_y},
        {clock_x + clock_width, 110}, {clock_x + clock_width - 18, 128},
        {clock_x, 128}, {clock_x, clock_y + 18}}, palette.bg, opacity)
    line(clock_x + 18, clock_y, clock_x + 66, clock_y, palette.acc1, 1, 2)
    line(clock_x + clock_width - 66, 128, clock_x + clock_width - 18, 128, palette.acc2, 1, 2)
    text(w / 2, 76, os.date('%H:%M'), 68, palette.fg, false, 'center')
    text(w / 2, 109, os.date('%d.%m.%Y') .. ' / SIGNAL', 11, palette.acc1, true, 'center')

    local y = 150
    polygon({{2, y + 18}, {20, y}, {w - 20, y}, {w - 2, y + 18},
        {w - 2, h - 23}, {w - 20, h - 5}, {20, h - 5}, {2, h - 23}},
        palette.bg, opacity)
    line(20, y, w - 20, y, palette.acc1, .7)
    if not plan.compact then
        rect(22, y + 24, 4, 90, thermal(data.cpu))
        text(44, y + 38, caption(data, 'cpu', 'CPU / °C'), 11)
        text(42, y + 94, reading(data, 'cpu', '°'), 49, thermal(data.cpu), true)
        line(188, y + 26, 188, h - 30, palette.fg, .22)
        compute_block(215, y + 23, 205, data)
        line(447, y + 26, 447, h - 30, palette.fg, .22)
        secondary(474, y + 38, 125, data, 'storage')
        secondary(640, y + 38, 115, data, 'fan')
        secondary(795, y + 38, w - 821, data, 'network')
        text(w / 2, h - 17, power_label(data) .. ' · ' .. data.interval .. ' s', 11, palette.acc2, false, 'center')
    else
        text(30, y + 33, caption(data, 'cpu', 'CPU / °C'), 11)
        text(28, y + 91, reading(data, 'cpu', '°'), 52, thermal(data.cpu), true)
        compute_block(195, y + 20, w - 225, data)
        local sy = y + 174
        if plan.narrow then
            secondary(28, sy, w / 2 - 50, data, 'storage')
            secondary(w / 2 + 12, sy, w / 2 - 40, data, 'fan')
            secondary(28, sy + 85, w - 56, data, 'network')
        else
            local cell = (w - 84) / 3
            secondary(28, sy, cell, data, 'storage')
            secondary(42 + cell, sy, cell, data, 'fan')
            secondary(56 + cell * 2, sy, cell, data, 'network')
        end
        text(w / 2, h - 17, power_label(data) .. ' · ' .. data.interval .. ' s', 11, palette.acc2, false, 'center')
    end
end

local function arc(x, y, radius, value, hex)
    cairo_set_line_width(cr, 5)
    color(hex, .18)
    cairo_arc(cr, x, y, radius, math.pi * .75, math.pi * 2.25)
    cairo_stroke(cr)
    if value then
        color(hex)
        cairo_arc(cr, x, y, radius, math.pi * .75,
            math.pi * (.75 + 1.5 * math.max(0, math.min(value, 100)) / 100))
        cairo_stroke(cr)
    end
end

local function footer(w, y, data, title)
    text(24, y, 'BLACK-ICE / ' .. title, 11, palette.acc1, true)
    text(w - 24, y, power_label(data) .. ' · ' .. data.interval .. ' s', 11, palette.fg, false, 'right')
end

local function orbit(plan, data)
    local w = plan.width
    local cy, radius = 127, plan.narrow and 45 or 75
    local centers = {w * .23, w * .5, w * .77}
    local values = {data.cpu_usage, data.ram_percent, reading_level(data, 'cpu')}
    local labels = {'CARGA CPU', 'MEMORIA', caption(data, 'cpu', 'CPU / °C')}
    local numbers = {number(data.cpu_usage, '%'), number(data.ram_percent, '%'), reading(data, 'cpu', '°')}
    for i, x in ipairs(centers) do
        color(palette.bg, opacity)
        cairo_arc(cr, x, cy, radius + 13, 0, 2 * math.pi); cairo_fill(cr)
        local accent = i == 2 and palette.acc2 or i == 3 and thermal(data.cpu) or palette.acc1
        arc(x, cy, radius, values[i], accent)
        text(x, cy + 8, numbers[i], plan.narrow and 28 or 39, accent, true, 'center')
        text(x, cy + 33, labels[i], 11, palette.fg, false, 'center')
        line(x - 16, cy - 34, x + 16, cy - 34, accent, .8)
    end
    text(w / 2, 21, 'ORBIT / TELEMETRÍA LOCAL', 11, palette.acc1, true, 'center')
    local y = 246
    rect(12, y - 18, w - 24, plan.height - y + 12, palette.bg, opacity)
    if plan.compact then
        secondary(28, y + 4, w / 2 - 52, data, 'storage')
        secondary(w / 2 + 12, y + 4, w / 2 - 40, data, 'network')
        text(28, y + 85, caption(data, 'fan', 'FAN') .. ' ' .. reading(data, 'fan', ' RPM'), 11, palette.acc2)
    else
        text(28, y, caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°') .. ' / ' .. free_space(data) .. ' libres', 11)
        text(w / 2, y, caption(data, 'fan', 'FAN') .. ' ' .. reading(data, 'fan', ' RPM'), 11, palette.acc2, false, 'center')
        text(w - 28, y, 'RX ' .. speed(data.rx) .. ' / TX ' .. speed(data.tx), 11, palette.fg, false, 'right')
    end
    text(w / 2, plan.height - 10, power_label(data), 11, palette.acc1, false, 'center')
end

local function ribbon(plan, data)
    local w, h = plan.width, plan.height
    polygon({{2, 26}, {24, 4}, {w - 24, 4}, {w - 2, 26},
        {w - 2, h - 24}, {w - 24, h - 2}, {24, h - 2}, {2, h - 24}}, palette.bg, opacity * .85)
    line(24, 4, w - 24, 4, palette.acc1, .9, 2)
    local entries = {{caption(data, 'cpu', 'CPU'), reading(data, 'cpu', '°'), thermal(data.cpu)},
        {'CARGA', number(data.cpu_usage, '%'), palette.acc1},
        {'RAM', number(data.ram_used, ' GiB', 1), palette.acc2},
        {caption(data, 'nvme', 'NVMe'), reading(data, 'nvme', '°'), thermal(data.nvme)}}
    local columns = plan.compact and 2 or 4
    for i, entry in ipairs(entries) do
        local x = 28 + ((i - 1) % columns) * ((w - 56) / columns)
        local y = 29 + math.floor((i - 1) / columns) * 73
        text(x, y, entry[1], 11)
        text(x, y + 35, entry[2], plan.narrow and 25 or 32, entry[3], true)
    end
    footer(w, h - 15, data, 'RIBBON')
end

local function terminal(plan, data)
    local w, h = plan.width, plan.height
    rect(6, 6, w - 12, h - 12, palette.bg, opacity)
    rect(6, 6, w - 12, 32, palette.acc1, .16)
    text(24, 27, '> black-ice / terminal', 11, palette.acc1, true)
    text(w - 24, 27, os.date('%H:%M'), 11, palette.acc2, false, 'right')
    line(6, 6, 6, 65, palette.acc1, 1, 2)
    line(w - 6, h - 65, w - 6, h - 6, palette.acc2, 1, 2)
    local x2 = plan.compact and 24 or w * .54
    local y2 = plan.compact and 191 or 72
    local split = plan.compact and w - 24 or w * .46
    local rows = {{caption(data, 'cpu', 'CPU / TEMP.'), reading(data, 'cpu', ' °C')},
        {'cpu.load', number(data.cpu_usage, ' %')},
        {'memory.used', number(data.ram_used, ' GiB', 1) .. ' / ' .. number(data.ram_total, ' GiB')},
        {caption(data, 'fan', 'fan.speed'), reading(data, 'fan', ' RPM')}}
    for i, row in ipairs(rows) do
        text(26, 72 + (i - 1) * 33, row[1], 13, palette.acc1)
        text(split, 72 + (i - 1) * 33, row[2], 14, palette.fg, true, 'right')
    end
    local network = {{caption(data, 'nvme', 'nvme.temp'), reading(data, 'nvme', ' °C')}, {'disk.free', free_space(data)},
        {'rx / tx', speed(data.rx) .. ' / ' .. speed(data.tx)}}
    for i, row in ipairs(network) do
        text(x2 + 2, y2 + (i - 1) * 33, row[1], 13, palette.acc2)
        text(w - 26, y2 + (i - 1) * 33, row[2], 13, palette.fg, false, 'right')
    end
    footer(w, h - 22, data, 'TERMINAL')
end

local function pulse(plan, data)
    local w, h = plan.width, plan.height
    polygon({{4, 22}, {24, 2}, {w - 4, 2}, {w - 4, h - 22},
        {w - 24, h - 2}, {4, h - 2}}, palette.bg, opacity * .9, palette.acc2)
    text(26, 33, 'PULSE / HISTORIAL CPU', 11, palette.acc1, true)
    text(w - 26, 33, number(data.cpu_usage, '%'), 25, palette.acc1, true, 'right')
    for i = 0, 3 do line(28, 57 + i * 25, w - 28, 57 + i * 25, palette.fg, .1) end
    history(data.history, 28, 57, w - 56, 75)
    local items = {{caption(data, 'cpu', 'CPU / °C'), reading(data, 'cpu', '°'), thermal(data.cpu)},
        {'RAM / GiB', number(data.ram_used, '', 1), palette.acc2},
        {caption(data, 'nvme', 'NVMe / °C'), reading(data, 'nvme', '°'), thermal(data.nvme)},
        {'RX', speed(data.rx), palette.acc1}}
    local columns = plan.compact and 2 or 4
    for i, item in ipairs(items) do
        local x = 28 + ((i - 1) % columns) * ((w - 56) / columns)
        local y = 163 + math.floor((i - 1) / columns) * 80
        text(x, y, item[1], 11)
        text(x, y + 31, item[2], i == 4 and 16 or 28, item[3], true)
    end
    footer(w, h - 15, data, 'PULSE')
end

local function cut_panel(x, y, w, h)
    polygon({{x + 16, y}, {x + w, y}, {x + w, y + h - 16},
        {x + w - 16, y + h}, {x, y + h}, {x, y + 16}}, palette.bg, opacity * .88)
    line(x + 16, y, x + 80, y, palette.acc1, .8)
    line(x + w - 80, y + h, x + w - 16, y + h, palette.acc2, .8)
end

local function atlas(plan, data)
    local w, h = plan.width, plan.height
    local tile = math.min(280, w - 32)
    local right_x, right_y = w - tile - 10, 36
    if plan.narrow then right_y = 214 end
    text(w / 2, 17, 'ATLAS / BLACK-ICE', 11, palette.acc1, true, 'center')
    cut_panel(10, 36, tile, 154)
    cpu_icon(30, 54, palette.acc1)
    text(62, 70, caption(data, 'cpu', 'CPU / TEMP.'), 11)
    text(30, 128, reading(data, 'cpu', '°'), 52, thermal(data.cpu), true)
    text(tile - 8, 126, number(data.cpu_usage, '%'), 25, palette.acc1, true, 'right')
    segments(30, 159, tile - 40, data.cpu_usage, palette.acc1)
    cut_panel(right_x, right_y, tile, 154)
    secondary(right_x + 20, right_y + 33, tile - 40, data, 'network')
    text(right_x + 20, right_y + 126, power_label(data), 11, palette.acc2)
    local lower_y = h - (plan.narrow and 236 or 160)
    cut_panel(10, lower_y, tile, 136)
    text(30, lower_y + 30, 'RAM / MEMORIA', 11, palette.acc2)
    text(30, lower_y + 69, number(data.ram_used, ' GiB', 1), 30, palette.fg, true)
    segments(30, lower_y + 92, tile - 40, data.ram_percent, palette.acc2)
    if plan.narrow then
        text(w - 20, h - 50, caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°') .. ' / ' .. caption(data, 'fan', 'FAN') .. ' ' .. reading(data, 'fan', ' RPM'), 11, palette.fg, false, 'right')
    else
        cut_panel(right_x, lower_y, tile, 136)
        secondary(right_x + 20, lower_y + 30, tile - 40, data, 'storage')
        text(right_x + 20, lower_y + 108, caption(data, 'fan', 'FAN') .. ' ' .. reading(data, 'fan', ' RPM'), 11, palette.acc2)
        text(w / 2, 68, os.date('%H:%M'), 34, palette.fg, false, 'center')
        text(w / 2, h - 30, os.date('%d.%m.%Y'), 11, palette.acc1, false, 'center')
    end
end

local function horizon(plan, data)
    local w, h = plan.width, plan.height
    local clock_w = math.min(330, w - 48)
    cut_panel((w - clock_w) / 2, 20, clock_w, 130)
    text(w / 2, 94, os.date('%H:%M'), 64, palette.fg, false, 'center')
    text(w / 2, 130, os.date('%d.%m.%Y') .. ' / HORIZON', 11, palette.acc1, true, 'center')
    local wing = math.min(350, (w - 70) / 2)
    local left_y, right_y = h - 182, h - 182
    if plan.narrow then
        wing = w - 32
        left_y, right_y = h - 352, h - 176
    end
    polygon({{10, left_y + 20}, {30, left_y}, {wing - 20, left_y}, {wing + 10, left_y + 30},
        {wing + 10, left_y + 154}, {10, left_y + 154}}, palette.bg, opacity * .85, palette.acc1)
    text(30, left_y + 34, caption(data, 'cpu', 'CPU / °C'), 11)
    text(30, left_y + 94, reading(data, 'cpu', '°'), 52, thermal(data.cpu), true)
    text(wing - 10, left_y + 78, number(data.cpu_usage, '%'), 25, palette.acc1, true, 'right')
    text(30, left_y + 129, 'RAM ' .. number(data.ram_used, ' GiB', 1), 14, palette.acc2)
    local x = w - wing - 10
    polygon({{x, right_y + 30}, {x + 30, right_y}, {w - 30, right_y}, {w - 10, right_y + 20},
        {w - 10, right_y + 154}, {x, right_y + 154}}, palette.bg, opacity * .85, palette.acc2)
    secondary(x + 20, right_y + 34, wing - 40, data, 'network')
    text(x + 20, right_y + 121, caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°') .. ' / ' .. caption(data, 'fan', 'FAN') .. ' ' .. reading(data, 'fan', ''), 11, palette.acc2)
    text(w / 2, h - 4, power_label(data) .. ' · ' .. data.interval .. ' s', 11, palette.fg, false, 'center')
end

local function observatory(plan, data)
    local w, h = plan.width, plan.height
    text(w / 2, 32, 'OBSERVATORY / BLACK-ICE', 11, palette.acc1, true, 'center')
    text(w / 2, 90, os.date('%H:%M'), 48, palette.fg, false, 'center')
    local radius = plan.narrow and 49 or 68
    local cy = plan.narrow and 205 or h * .43
    local left, right = plan.narrow and w * .25 or 108, plan.narrow and w * .75 or w - 108
    for i, x in ipairs({left, right}) do
        color(palette.bg, opacity * .9)
        cairo_arc(cr, x, cy, radius + 14, 0, 2 * math.pi); cairo_fill(cr)
        arc(x, cy, radius, i == 1 and data.cpu_usage or data.ram_percent, i == 1 and palette.acc1 or palette.acc2)
        text(x, cy + 6, i == 1 and number(data.cpu_usage, '%') or number(data.ram_percent, '%'), 30,
            i == 1 and palette.acc1 or palette.acc2, true, 'center')
        text(x, cy + 29, i == 1 and 'CPU' or 'RAM', 11, palette.fg, false, 'center')
    end
    cut_panel(10, cy + 110, math.min(220, w / 2 - 18), 94)
    text(30, cy + 138, caption(data, 'cpu', 'CPU / TEMPERATURA'), 11)
    text(30, cy + 180, reading(data, 'cpu', '°'), 32, thermal(data.cpu), true)
    local box = math.min(220, w / 2 - 18)
    cut_panel(w - box - 10, cy + 110, box, 94)
    text(w - 30, cy + 138, caption(data, 'nvme', 'NVMe / °C'), 11, palette.fg, false, 'right')
    text(w - 30, cy + 180, reading(data, 'nvme', '°'), 32, thermal(data.nvme), true, 'right')
    local graph_w = math.min(480, w - 32)
    local graph_x = (w - graph_w) / 2
    cut_panel(graph_x, h - 118, graph_w, 108)
    text(w / 2, h - 94, 'ACTIVIDAD CPU / ' .. data.interval .. ' s', 11, palette.acc1, true, 'center')
    history(data.history, graph_x + 20, h - 84, graph_w - 40, 40)
    text(w / 2, h - 22, 'RX ' .. speed(data.rx) .. ' / TX ' .. speed(data.tx), 11, palette.fg, false, 'center')
end

local function polar(plan, data)
    local w, h = plan.width, plan.height
    local x, y = w / 2, 174
    local radius = math.min(151, w / 2 - 24)
    local now = os.date('*t')
    local month_days = tonumber(os.date('%d', os.time({year=now.year, month=now.month + 1, day=0})))
    local values = {now.month / 12 * 100, now.day / month_days * 100, now.hour / 24 * 100, now.min / 60 * 100}
    for i, value in ipairs(values) do
        arc(x, y, radius - (i - 1) * 20, value, i % 2 == 1 and palette.acc1 or palette.acc2)
    end
    color(palette.bg, opacity * .8)
    cairo_arc(cr, x, y, radius - 72, 0, math.pi * 2); cairo_fill(cr)
    text(x, y + 5, os.date('%H:%M'), 36, palette.fg, true, 'center')
    text(x, y + 29, os.date('%d.%m.%Y'), 11, palette.acc2, false, 'center')
    text(w / 2, 16, 'POLAR / MES · DÍA · HORA · MINUTO', 11, palette.acc1, true, 'center')
    cut_panel(16, h - 52, w - 32, 46)
    text(w / 2, h - 24, caption(data, 'cpu', 'CPU') .. ' ' .. reading(data, 'cpu', '°') .. ' / RAM ' .. number(data.ram_used, ' GiB', 1), 13, palette.fg, false, 'center')
end

local function chronos(plan, data)
    local w, h = plan.width, plan.height
    local x, y, radius = w / 2, 169, math.min(140, w / 2 - 30)
    color(palette.bg, opacity * .85)
    cairo_arc(cr, x, y, radius + 13, 0, math.pi * 2); cairo_fill(cr)
    for i = 0, 59 do
        local angle = i / 60 * math.pi * 2 - math.pi / 2
        local inner = radius - (i % 5 == 0 and 12 or 5)
        line(x + math.cos(angle) * inner, y + math.sin(angle) * inner,
            x + math.cos(angle) * radius, y + math.sin(angle) * radius,
            i % 5 == 0 and palette.acc1 or palette.fg, i % 5 == 0 and 1 or .28)
    end
    local now = os.date('*t')
    for i, hand in ipairs({{(now.hour % 12 + now.min / 60) / 12, radius * .48}, {now.min / 60, radius * .78}}) do
        local angle = hand[1] * math.pi * 2 - math.pi / 2
        line(x, y, x + math.cos(angle) * hand[2], y + math.sin(angle) * hand[2],
            i == 1 and palette.fg or palette.acc1, 1, i == 1 and 5 or 2)
    end
    arc(x - radius * .44, y + 42, 26, data.cpu_usage, palette.acc1)
    arc(x + radius * .44, y + 42, 26, data.ram_percent, palette.acc2)
    text(x - radius * .44, y + 45, number(data.cpu_usage), 13, palette.fg, true, 'center')
    text(x + radius * .44, y + 45, number(data.ram_percent), 13, palette.fg, true, 'center')
    text(x - radius * .44, y + 84, 'CPU %', 11, palette.acc1, false, 'center')
    text(x + radius * .44, y + 84, 'RAM %', 11, palette.acc2, false, 'center')
    text(x, y - 47, 'CHRONOS', 11, palette.acc2, true, 'center')
    text(x, 337, os.date('%H:%M') .. ' / ' .. os.date('%d.%m.%Y'), 14, palette.fg, false, 'center')
    text(x, h - 15, caption(data, 'cpu', 'CPU') .. ' ' .. reading(data, 'cpu', '°') .. ' / ' .. caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°'), 13, palette.acc1, false, 'center')
end

local function nexus(plan, data)
    local w, h = plan.width, plan.height
    local cx, cy = w / 2, h / 2
    local left, right = plan.narrow and 92 or w * .19, plan.narrow and w - 92 or w * .81
    local nodes = {{left, 88, 'RAM', number(data.ram_used, ' GiB', 1), palette.acc2},
        {right, 88, caption(data, 'cpu', 'CPU / °C'), reading(data, 'cpu', '°'), thermal(data.cpu)},
        {left, h - 94, caption(data, 'nvme', 'NVMe / °C'), reading(data, 'nvme', '°'), palette.acc2},
        {right, h - 94, 'RED / RX', speed(data.rx), palette.acc1}}
    for _, node in ipairs(nodes) do
        color(node[5], .6); cairo_set_line_width(cr, 1.5)
        cairo_move_to(cr, cx, cy)
        cairo_curve_to(cr, cx + (node[1] - cx) * .65, cy, cx, node[2], node[1], node[2]); cairo_stroke(cr)
        cut_panel(node[1] - 76, node[2] - 40, 152, 91)
        text(node[1], node[2] - 13, node[3], 11, node[5], true, 'center')
        text(node[1], node[2] + 26, node[4], node[3] == 'RED / RX' and 16 or 30, palette.fg, true, 'center')
    end
    color(palette.bg, opacity)
    cairo_arc(cr, cx, cy, 51, 0, math.pi * 2); cairo_fill(cr)
    arc(cx, cy, 52, data.cpu_usage, palette.acc1)
    text(cx, cy - 3, 'BLACK', 14, palette.fg, true, 'center')
    text(cx, cy + 19, 'ICE', 19, palette.acc1, true, 'center')
    text(w / 2, 17, 'NEXUS / TELEMETRÍA LOCAL', 11, palette.acc1, true, 'center')
    text(w / 2, h - 12, power_label(data), 11, palette.fg, false, 'center')
end

local function gotham(plan, data)
    local w, h = plan.width, plan.height
    cut_panel(10, 12, w - 20, h - 24)
    text(28, 52, 'GOTHAM / BLACK-ICE', 11, palette.acc1, true)
    text(24, 149, os.date('%H:%M'), plan.narrow and 67 or 103, palette.fg, true)
    text(w - 28, 111, os.date('%d'), 53, palette.acc2, true, 'right')
    text(w - 28, 141, os.date('%m.%Y'), 14, palette.acc1, false, 'right')
    line(28, 174, w - 28, 174, palette.acc1, .4)
    text(28, 201, caption(data, 'cpu', 'CPU') .. ' ' .. reading(data, 'cpu', '°') .. ' / RAM ' .. number(data.ram_used, ' GiB', 1) .. ' / ' .. caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°'), 13)
    text(28, 226, 'RX ' .. speed(data.rx) .. ' / TX ' .. speed(data.tx), 11, palette.acc2)
end

local function prism(plan, data)
    local w, h = plan.width, plan.height
    local columns = plan.compact and 2 or 4
    local items = {{caption(data, 'cpu', 'CPU / °C'), reading(data, 'cpu', '°'), thermal(data.cpu)},
        {'CARGA %', number(data.cpu_usage), palette.acc1}, {'RAM %', number(data.ram_percent), palette.acc2},
        {caption(data, 'nvme', 'NVMe / °C'), reading(data, 'nvme', '°'), thermal(data.nvme)}}
    for i, item in ipairs(items) do
        local x = ((i - 1) % columns + .5) * w / columns
        local y = 105 + math.floor((i - 1) / columns) * 165
        local r = math.min(77, w / columns / 2 - 17)
        polygon({{x, y - r}, {x + r, y}, {x, y + r}, {x - r, y}}, palette.bg, opacity, item[3])
        text(x, y - 21, item[1], 11, item[3], true, 'center')
        text(x, y + 22, item[2], 37, palette.fg, true, 'center')
    end
    text(w / 2, h - 15, 'PRISM / ' .. power_label(data), 11, palette.acc1, false, 'center')
end

local function circuit(plan, data)
    local w, h = plan.width, plan.height
    local panel_w = math.min(260, w / 2 - 32)
    text(24, 25, 'BLACK-ICE / CIRCUIT', 11, palette.acc1, true)
    text(w - 24, 25, os.date('%H:%M'), 19, palette.fg, true, 'right')
    for _, x in ipairs({16, w - 16}) do
        local direction = x < w / 2 and 1 or -1
        line(x, 62, x, h - 162, palette.acc1, .35)
        line(x, h - 162, x + direction * 28, h - 134, palette.acc1, .6)
        line(x + direction * 28, h - 134, x + direction * panel_w, h - 134, palette.acc1, .6)
    end
    cut_panel(25, 66, panel_w, 103)
    text(44, 96, 'CARGA CPU', 11)
    text(44, 134, number(data.cpu_usage, '%'), 30, palette.acc1, true)
    segments(44, 149, panel_w - 38, data.cpu_usage, palette.acc1)
    cut_panel(w - panel_w - 25, 66, panel_w, 103)
    text(w - 44, 96, 'RAM / GiB', 11, palette.acc2, false, 'right')
    text(w - 44, 134, number(data.ram_used, '', 1), 30, palette.fg, true, 'right')
    segments(w - panel_w - 6, 149, panel_w - 38, data.ram_percent, palette.acc2)
    cut_panel(25, h - 120, panel_w, 95)
    text(44, h - 90, caption(data, 'cpu', 'CPU / °C'), 11)
    text(44, h - 46, reading(data, 'cpu', '°'), 39, thermal(data.cpu), true)
    cut_panel(w - panel_w - 25, h - 120, panel_w, 95)
    text(w - 44, h - 90, caption(data, 'nvme', 'NVMe / °C'), 11, palette.acc2, false, 'right')
    text(w - 44, h - 46, reading(data, 'nvme', '°'), 39, thermal(data.nvme), true, 'right')
    if not plan.narrow then
        history(data.history, w / 2 - 150, h - 76, 300, 45)
        text(w / 2, h - 12, 'RX ' .. speed(data.rx) .. ' / TX ' .. speed(data.tx), 11, palette.fg, false, 'center')
    end
end

local function scope(plan, data)
    local w, h = plan.width, plan.height
    local items = {{'CARGA CPU', data.cpu_usage, '%', palette.acc1},
        {'RAM', data.ram_percent, '%', palette.acc2}, {caption(data, 'cpu', 'CPU / °C'), reading_level(data, 'cpu'), data.cpu ~= nil and '°' or '%', thermal(data.cpu)}}
    for i, item in ipairs(items) do
        local x = (i - .5) * w / 3
        cut_panel(x - 55, 21, 110, h - 50)
        text(x, 47, item[1], 11, palette.fg, false, 'center')
        rect(x - 12, 70, 24, 130, item[4], .18)
        local value = math.max(0, math.min(100, item[2] or 0)) / 100 * 130
        rect(x - 12, 200 - value, 24, value, item[4], .9)
        for tick = 0, 10 do
            line(x + 18, 200 - tick * 13, x + (tick % 5 == 0 and 31 or 25), 200 - tick * 13, palette.fg, .45)
        end
        text(x, 241, number(item[2], item[3]), 25, item[4], true, 'center')
    end
    text(w / 2, h - 7, 'SCOPE / BLACK-ICE', 11, palette.acc1, true, 'center')
end

local function stack(plan, data)
    local w = plan.width
    local items = {{caption(data, 'cpu', 'CPU / °C'), reading(data, 'cpu', '°'), thermal(data.cpu), 'CARGA ' .. number(data.cpu_usage, '%')},
        {'MEMORIA', number(data.ram_used, ' GiB', 1), palette.acc2, number(data.ram_percent, '%') .. ' EN USO'},
        {caption(data, 'nvme', 'NVMe / °C'), reading(data, 'nvme', '°'), thermal(data.nvme), free_space(data) .. ' LIBRES'},
        {'RED / RX', speed(data.rx), palette.acc1, 'TX ' .. speed(data.tx)}}
    for i, item in ipairs(items) do
        local x, y = i % 2 == 1 and 12 or 28, 7 + (i - 1) * 115
        cut_panel(x, y, w - 42, 106)
        text(x + 18, y + 23, item[1], 11, item[3], true)
        text(x + 18, y + 65, item[2], i == 4 and 24 or 35, palette.fg, true)
        text(x + 18, y + 91, item[4], 11, item[3])
    end
end

local function focus(plan, data)
    local w, h = plan.width, plan.height
    local cx = plan.narrow and w / 2 or 160
    local cy, radius = 145, 108
    color(palette.bg, opacity * .85)
    cairo_arc(cr, cx, cy, radius + 13, 0, math.pi * 2); cairo_fill(cr)
    arc(cx, cy, radius, tonumber(os.date('%M')) / 60 * 100, palette.acc1)
    text(cx, cy + 2, os.date('%H:%M'), 43, palette.fg, true, 'center')
    text(cx, cy + 32, os.date('%d.%m.%Y'), 11, palette.acc2, false, 'center')
    if plan.narrow then
        cut_panel(16, 280, w - 32, 69)
        text(w / 2, 308, caption(data, 'cpu', 'CPU') .. ' ' .. reading(data, 'cpu', '°') .. ' / RAM ' .. number(data.ram_used, ' GiB', 1), 14, palette.fg, true, 'center')
        text(w / 2, 334, caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°'), 11, palette.acc2, false, 'center')
    else
        cut_panel(310, 47, w - 326, 240)
        text(332, 80, caption(data, 'cpu', 'CPU / TEMPERATURA'), 11)
        text(332, 144, reading(data, 'cpu', '°'), 53, thermal(data.cpu), true)
        text(332, 192, 'RAM ' .. number(data.ram_used, ' GiB', 1), 19, palette.acc2, true)
        text(332, 229, caption(data, 'nvme', 'NVMe') .. ' ' .. reading(data, 'nvme', '°'), 14, palette.fg)
        text(332, 260, 'CARGA ' .. number(data.cpu_usage, '%'), 14, palette.acc1)
    end
    text(w / 2, h - 15, 'FOCUS / ' .. power_label(data), 11, palette.acc1, false, 'center')
end

local function obsidian(plan, data)
    local w, h = plan.width, plan.height
    polygon({{12, 3}, {w - 3, 3}, {w - 3, h - 15}, {w - 15, h - 3},
        {3, h - 3}, {3, 15}}, palette.bg, opacity)
    line(12, 3, w - 3, 3, palette.acc1, .65, 1)
    line(3, h - 3, w - 15, h - 3, palette.acc2, .35, 1)
    local entries = {{'CPU', number(data.cpu_usage, '%'), palette.acc1},
        {'RAM', number(data.ram_used, ' GiB', 1), palette.acc2},
        {caption(data, 'cpu', 'TEMP'), reading(data, 'cpu', '°C'), thermal(data.cpu)}}
    local step = (w - 48) / 3
    for i, entry in ipairs(entries) do
        local x = 24 + (i - 1) * step
        text(x, 36, entry[1], plan.narrow and 10 or 12, palette.dim)
        text(x + step - 22, 36, entry[2], plan.narrow and 14 or 17, entry[3], true, 'right')
        if i < 3 then line(x + step - 10, 20, x + step - 10, 43, palette.dim, .3, 1) end
    end
end

local function fsociety(plan, data)
    local w, h = plan.width, plan.height
    rect(1, 1, w - 2, h - 2, palette.bg, opacity * .72)
    line(1, 1, w - 1, 1, palette.acc1, .9, 2)
    text(20, 29, 'fsociety', 24, palette.acc1, true)
    text(w - 20, 27, os.date('%H:%M'), 18, palette.fg, false, 'right')
    local entries = {
        {'CPU', number(data.cpu_usage, '%'), caption(data, 'cpu', 'TEMP') .. ' ' .. reading(data, 'cpu', '°C')},
        {'RAM', number(data.ram_percent, '%'), number(data.ram_used, ' GiB', 1)},
        {caption(data, 'nvme', 'NVMe'), reading(data, 'nvme', '°C'), free_space(data)},
        {'RED', speed(data.rx), speed(data.tx)}
    }
    local step = (w - 40) / 4
    for i, entry in ipairs(entries) do
        local x = 20 + (i - 1) * step
        text(x, 52, entry[1], 10, palette.dim)
        text(x, 77, entry[2], plan.narrow and 17 or 20, palette.fg, true)
        text(x, 97, entry[3], plan.narrow and 9 or 10, palette.dim)
        if i < 4 then line(x + step - 12, 43, x + step - 12, 98, palette.dim, .22, 1) end
    end
end

local renderers = {fsociety=fsociety, obsidian=obsidian, fracture=fracture, signal=signal_panel, orbit=orbit,
    ribbon=ribbon, terminal=terminal, pulse=pulse, atlas=atlas,
    horizon=horizon, observatory=observatory, polar=polar, chronos=chronos,
    nexus=nexus, gotham=gotham, prism=prism, circuit=circuit, scope=scope, stack=stack, focus=focus}

function conky_black_ice()
    local ok, frame = pcall(dofile, frame_path)
    if not ok or not frame.layout or not frame.data.ram_percent then return end
    local surface = conky_surface()
    if not surface then return end
    cr = cairo_create(surface)
    cairo_scale(cr, frame.layout.zoom or 1, frame.layout.zoom or 1)
    palette = frame.theme
    opacity = frame.opacity or .78
    selected_language = frame.language == 'en' and 'en' or 'es'
    conky_set_update_interval(frame.data.interval)
    local render = renderers[frame.layout.variant] or fracture
    render(frame.layout, frame.data)
    cairo_destroy(cr)
end
