.pragma library

function region(screens, name, mode, panorama) {
    if (mode === "auto" && !panorama)
        mode = "mirror";
    var outputs = [];
    for (var i = 0; i < screens.length; i++) {
        var screen = screens[i];
        if (screen.width > 0 && screen.height > 0)
            outputs.push({name: screen.name, x: screen.virtualX, y: screen.virtualY,
                          width: screen.width, height: screen.height});
    }
    outputs.sort(function(a, b) { return a.y - b.y || a.x - b.x; });
    var groups = [];
    for (var j = 0; j < outputs.length; j++) {
        var output = outputs[j];
        var group = null;
        if (mode === "scene") {
            group = groups.length ? groups[0] : null;
        } else if (mode !== "mirror") {
            for (var k = 0; k < groups.length; k++) {
                var first = groups[k][0];
                var ratio = first.height / output.height;
                if (Math.abs(first.y - output.y) <= Math.min(first.height, output.height) * 0.2
                        && ratio >= 0.75 && ratio <= 1.33) {
                    group = groups[k];
                    break;
                }
            }
        }
        if (group)
            group.push(output);
        else
            groups.push([output]);
    }
    for (var g = 0; g < groups.length; g++) {
        var row = groups[g];
        var current = null;
        var left = Infinity, top = Infinity, right = -Infinity, bottom = -Infinity;
        for (var n = 0; n < row.length; n++) {
            var item = row[n];
            if (item.name === name)
                current = item;
            left = Math.min(left, item.x);
            top = Math.min(top, item.y);
            right = Math.max(right, item.x + item.width);
            bottom = Math.max(bottom, item.y + item.height);
        }
        if (current)
            return {x: current.x - left, y: current.y - top,
                    width: current.width, height: current.height,
                    canvasWidth: right - left, canvasHeight: bottom - top,
                    panorama: mode !== "scene" && row.length > 1 && panorama};
    }
    return {x: 0, y: 0, width: 1, height: 1, canvasWidth: 1, canvasHeight: 1, panorama: false};
}
