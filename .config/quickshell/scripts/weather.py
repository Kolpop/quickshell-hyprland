#!/usr/bin/env python3
"""Return current weather as JSON for the Quickshell widgets.

The output keys (city, temp, desc, icon) are kept stable for existing QML
consumers. Network failures are reported on stderr and represented as missing
weather data instead of fabricated temperature/conditions.
"""

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

USER_AGENT = "quickshell-hyprland/1.0"
REQUEST_TIMEOUT = 5
UNKNOWN_TEMP = "—"
UNKNOWN_DESC = "Нет данных"


def _read_json(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT) as response:
        return json.loads(response.read().decode("utf-8"))


def get_location():
    """Return a detected city, or None when geolocation is unavailable."""
    try:
        data = _read_json("http://ip-api.com/json/?fields=status,city&lang=ru")
        city = data.get("city")
        if data.get("status") == "success" and isinstance(city, str) and city.strip():
            return city.strip()
    except (OSError, ValueError, urllib.error.URLError, TimeoutError) as exc:
        print(f"weather: geolocation unavailable: {exc}", file=sys.stderr)
    return None


def get_icon(desc):
    description = (desc or "").lower()
    if any(word in description for word in ("гроз", "молни", "thunder")):
        return "󰖓"
    if any(word in description for word in ("снег", "метел", "буран", "snow")):
        return "󰖘"
    if any(word in description for word in ("дожд", "ливен", "морос", "rain", "drizzle", "shower")):
        return "󰖗"
    if any(word in description for word in ("туман", "мгла", "дым", "fog", "mist", "haze")):
        return "󰖑"
    if any(word in description for word in ("перемен", "част", "partly")):
        return "󰖕"
    if any(word in description for word in ("облачн", "пасмурн", "overcast", "cloudy")):
        return "󰖐"
    if any(word in description for word in ("ясно", "солнечн", "clear", "sunny")):
        return "󰖙"
    return "󰖐"


def get_weather(city):
    """Fetch weather for city; return None if the service response is invalid."""
    encoded_city = urllib.parse.quote(city, safe="")
    url = f"https://wttr.in/{encoded_city}?format=%t|%C&lang=ru"
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT) as response:
            raw = response.read().decode("utf-8", errors="replace").strip()
        if "|" not in raw:
            raise ValueError("unexpected response format")
        temperature, description = (part.strip() for part in raw.split("|", 1))
        if not temperature or not description or "unknown location" in description.lower():
            raise ValueError("weather service returned no usable data")
        return temperature, description
    except (OSError, ValueError, urllib.error.URLError, TimeoutError) as exc:
        print(f"weather: failed to fetch weather for {city!r}: {exc}", file=sys.stderr)
        return None


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    city = None
    force_auto = "--auto" in args
    for index, argument in enumerate(args):
        if argument == "--city" and index + 1 < len(args):
            candidate = args[index + 1].strip()
            if candidate and candidate.lower() not in ("auto", "авто"):
                city = candidate

    if force_auto or city is None:
        city = get_location() or "Неизвестно"

    weather = get_weather(city) if city != "Неизвестно" else None
    if weather is None and city == "Неизвестно":
        # Avoid making a second request with a made-up city.
        temperature, description = UNKNOWN_TEMP, UNKNOWN_DESC
    elif weather is None:
        temperature, description = UNKNOWN_TEMP, UNKNOWN_DESC
    else:
        temperature, description = weather

    print(json.dumps({
        "city": city,
        "temp": temperature,
        "desc": description,
        "icon": get_icon(description),
        "available": weather is not None,
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
