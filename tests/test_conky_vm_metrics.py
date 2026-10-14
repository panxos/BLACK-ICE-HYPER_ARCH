"""Datos del invitado y etiquetas reales para diseños sin sensores físicos."""
import ctypes
import ctypes.util
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch

import test_desktop_monitor as desktop

monitor = desktop.monitor
ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ctypes.util.find_library("lua5.4")


class VirtualMachineMetricsTests(unittest.TestCase):
    def sample(self, virtualization, sensors):
        files = {"/proc/stat": "cpu 10 0 10 80 0 0 0 0\n", "/proc/meminfo": "MemTotal: 8388608 kB\nMemAvailable: 6291456 kB\n",
                 "/proc/net/dev": "header\nheader\nenp2s0: 100 0 0 0 0 0 0 0 50 0 0 0 0 0 0 0\n",
                 "/proc/net/route": "header\nenp2s0 00000000 01000000 0003\n", "/proc/loadavg": "0.42 0.30 0.20 1/100 2\n",
                 "/proc/uptime": "1900.0 7000.0\n"}
        disk = SimpleNamespace(f_blocks=100, f_bfree=30, f_bavail=25, f_frsize=1073741824)
        with patch.object(monitor, "read", side_effect=lambda path: files.get(str(path), "")), \
                patch.object(monitor, "sensors", return_value={}), \
                patch.object(monitor, "sensor_values", return_value=sensors), \
                patch.object(monitor, "power", return_value={"interval": 2, "source": "ENERGÍA", "battery": None}), \
                patch.object(monitor.os, "statvfs", return_value=disk), \
                patch.object(monitor.os, "cpu_count", return_value=4), \
                patch.object(monitor.subprocess, "run", return_value=Mock(returncode=0 if virtualization else 1, stdout=virtualization or "none")):
            collector = monitor.Metrics()
            collector.sample()
            return collector.sample()

    def test_guest_without_hwmon_keeps_sensor_absence_and_reports_resources(self):
        data = self.sample("kvm", {})
        for key in ("cpu", "nvme", "fan"):
            self.assertIsNone(data.get(key))
        self.assertEqual(data["virtualization"], "kvm")
        self.assertEqual((data["cpu_count"], data["load1"], data["uptime"]), (4, .42, 1900))
        self.assertEqual((data["ram_used"], data["ram_total"], data["free_gib"]), (2, 8, 25))
        self.assertAlmostEqual(data["disk_percent"], 70)
        self.assertEqual(data["interface"], "enp2s0")

    def test_physical_sensor_values_including_stopped_fan_are_preserved(self):
        data = self.sample(None, {"cpu": 63, "nvme": 45, "fan": 0})
        self.assertIsNone(data["virtualization"])
        self.assertEqual((data["cpu"], data["nvme"], data["fan"]), (63, 45, 0))

    @unittest.skipUnless(LIBRARY, "Se requiere Lua 5.4 para comprobar los veinte renderizadores")
    def test_twenty_layouts_preserve_sensors_and_adapt_guest_data(self):
        lib = ctypes.CDLL(LIBRARY)
        lib.luaL_newstate.restype = ctypes.c_void_p
        lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
        lib.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
        lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
        lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
        lib.lua_tolstring.restype = ctypes.c_char_p
        lib.lua_close.argtypes = [ctypes.c_void_p]
        state = lib.luaL_newstate()
        self.addCleanup(lib.lua_close, state)
        lib.luaL_openlibs(state)
        data = self.sample("kvm", {})
        data.update(cpu_usage=25, rx=65536, tx=1024, history=[10, 20, 25])
        theme = {"bg": "#101010", "fg": "#eeeeee", "dim": "#aaaaaa", "acc1": "#00aaff", "acc2": "#ff88aa", "font": "Sans", "data_font": "Sans"}
        frames = []
        physical = {**data, "virtualization": None, "cpu": 63, "nvme": 45, "fan": 0}
        for readings in (data, physical):
            for width in (600, 1366):
                for variant in monitor.STYLES:
                    for selected_language in ("es", "en"):
                        frames.append({"layout": monitor.layout({"name": "Virtual-1", "width": width, "height": 900}, variant),
                                       "data": readings, "theme": theme, "opacity": .7, "language": selected_language})
        script = '''package.preload.cairo = function() return {} end
os.getenv = function() return 'fixture' end
cairo_text_extents_t = {create=function() return {x_advance=0} end}
tolua = {takeownership=function() end}
setmetatable(_G, {__index=function(_, key)
    if key:match('^cairo_') then return function() end end
end})
conky_surface = function() return {} end
conky_set_update_interval = function() end
local written = {}
cairo_show_text = function(_, value) table.insert(written, value) end
'''
        script += "assert(loadfile(" + monitor.lua(str(ROOT / "dotfiles/conky/black-ice/draw.lua")) + "))()\n"
        script += "local frames=" + monitor.lua(frames) + "\n"
        script += '''for _, frame in ipairs(frames) do
    written = {}
    dofile = function() return frame end
    conky_black_ice()
    assert(#written > 0, frame.layout.variant .. ': sin dibujo')
    for _, value in ipairs(written) do
        assert(not value:find('N/D', 1, true), frame.layout.variant .. ': ' .. value)
        assert(not value:find('PAQUETE', 1, true), frame.layout.variant .. ': ' .. value)
        assert(not value:find('cpu.package', 1, true), frame.layout.variant .. ': ' .. value)
        if frame.data.virtualization then
            assert(not value:find('°', 1, true), frame.layout.variant .. ': ' .. value)
            for _, unavailable in ipairs({'CELSIUS','NVMe','FAN','VENTILACIÓN','TEMPERATURA'}) do
                assert(not value:find(unavailable, 1, true), frame.layout.variant .. ': ' .. value)
            end
        end
        if frame.language == 'en' then
            for _, untranslated in ipairs({'CARGA', 'MEMORIA', 'DISCO', 'ALMACENAMIENTO', 'VENTILACIÓN',
                    'CORRIENTE', 'BATERÍA', 'TELEMETRÍA', 'ACTIVIDAD CPU', 'EN USO', 'LIBRES'}) do
                assert(not value:find(untranslated, 1, true), frame.layout.variant .. ': texto sin traducir: ' .. value)
            end
        end
    end
    if not frame.data.virtualization then
        assert(table.concat(written, ' '):find('°', 1, true), frame.layout.variant .. ': sin sensores físicos')
    end
    if frame.layout.variant == 'fracture' then
        local labels = table.concat(written, ' ')
        if frame.data.virtualization and frame.language == 'es' then
            assert(labels:find('CPU / CARGA', 1, true) and labels:find('25%', 1, true), labels)
        elseif frame.data.virtualization then
            assert(labels:find('CPU / LOAD', 1, true) and labels:find('CPU LOAD', 1, true), labels)
            assert(not labels:find('MEDIA 1 MIN', 1, true), labels)
        elseif frame.language == 'es' then
            assert(labels:find('CPU / TEMP.', 1, true) and labels:find('63°', 1, true), labels)
        else
            assert(labels:find('CPU / TEMP.', 1, true) and labels:find('63°', 1, true), labels)
        end
    end
end
'''
        status = lib.luaL_loadstring(state, script.encode())
        if status == 0:
            status = lib.lua_pcallk(state, 0, 0, 0, 0, None)
        error = lib.lua_tolstring(state, -1, None)
        self.assertEqual(status, 0, error.decode() if error else "")


if __name__ == "__main__":
    unittest.main()
