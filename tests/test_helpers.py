"""Unit tests for small helpers that do not require a running desktop session."""

import importlib.util
import pathlib
import unittest
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[1]
WEATHER_PATH = ROOT / ".config" / "quickshell" / "scripts" / "weather.py"
SPEC = importlib.util.spec_from_file_location("qs_weather", WEATHER_PATH)
weather = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(weather)


class WeatherIconTests(unittest.TestCase):
    def test_snow_description(self):
        self.assertEqual(weather.get_icon("Снег"), "󰖘")

    def test_rain_description(self):
        self.assertEqual(weather.get_icon("Light rain"), "󰖗")

    def test_clear_description(self):
        self.assertEqual(weather.get_icon("Ясно"), "󰖙")

    def test_unknown_description_has_cloud_icon(self):
        self.assertEqual(weather.get_icon("Нет данных"), "󰖐")

    def test_weather_failure_does_not_fabricate_conditions(self):
        with patch.object(
            weather.urllib.request, "urlopen",
            side_effect=TimeoutError("test timeout"),
        ):
            self.assertIsNone(weather.get_weather("test-city"))


if __name__ == "__main__":
    unittest.main()
