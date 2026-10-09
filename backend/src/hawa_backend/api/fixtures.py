"""Baseline demo data fixtures matching frontend contracts and Proposal v3."""
from datetime import datetime, timezone
from typing import Any, Dict, List

SCHOOLS = [
    {"id": "sch-1", "name": "Govt. Sarvodaya Vidyalaya", "distanceKm": 0.6, "assemblyAt": "08:00"},
    {"id": "sch-2", "name": "MCD Primary School", "distanceKm": 1.1, "assemblyAt": "08:00"},
    {"id": "sch-3", "name": "Sr. Secondary School", "distanceKm": 1.8, "assemblyAt": "08:00"},
]

RAW_HOTSPOTS = [
    ("ghazipur", "Ghazipur", "Ghazipur landfill, East Delhi", "East Delhi", 77.329, 28.625, 388, "Burning", 0.74, 0.79, "Landfill edge, open burning", 18420, 1, ["I-3", "T-12"]),
    ("anand", "Anand Vihar", "Anand Vihar ISBT, East Delhi", "East Delhi", 77.316, 28.647, 212, "Dust", 0.82, 0.84, "Unpaved shoulder, ISBT road", 15960, 3, ["T-12", "ASG-07", "SW-03"]),
    ("shahdara", "Shahdara", "GT Road, Shahdara", "Shahdara", 77.289, 28.673, 341, "Traffic", 0.69, 0.72, "GT Road corridor, idling HGVs", 16880, 2, ["SW-03"]),
    ("ito", "ITO", "ITO junction, Central Delhi", "Central", 77.241, 28.629, 296, "Traffic", 0.77, 0.75, "Vikas Marg junction", 11240, 6, ["T-07"]),
    ("wazirpur", "Wazirpur", "Wazirpur industrial area, North West Delhi", "North West", 77.165, 28.7, 402, "Burning", 0.63, 0.68, "Industrial area, waste pile", 12910, 5, []),
    ("bawana", "Bawana", "Bawana, North West Delhi", "North West", 77.051, 28.776, 421, "Regional smoke", 0.69, 0.74, "Industrial belt, farm-fire smoke inflow", 9640, 10, []),
    ("mundka", "Mundka", "Mundka, West Delhi", "West", 77.035, 28.682, 437, "Regional smoke", 0.71, 0.77, "North-west inflow, farm fires upwind", 14020, 4, []),
    ("jahangirpuri", "Jahangirpuri", "Jahangirpuri, North West Delhi", "North West", 77.171, 28.733, 364, "Dust", 0.66, 0.7, "Construction site, C-block", 10330, 7, []),
    ("okhla", "Okhla", "Okhla Phase II, South East Delhi", "South East", 77.271, 28.531, 318, "Dust", 0.72, 0.74, "Phase II road works", 8760, 8, ["T-19"]),
    ("punjabi", "Punjabi Bagh", "Punjabi Bagh, West Delhi", "West", 77.131, 28.674, 279, "Traffic", 0.7, 0.71, "Ring Road flyover queue", 7920, 9, []),
]


def pm25_band_label(pm25: float) -> str:
    if pm25 <= 30:
        return "Good"
    elif pm25 <= 60:
        return "Satisfactory"
    elif pm25 <= 90:
        return "Moderate"
    elif pm25 <= 120:
        return "Poor"
    elif pm25 <= 250:
        return "Very Poor"
    else:
        return "Severe"


def _diurnal(hour: int) -> float:
    return 1.0 + 0.15 * ((hour % 24 - 8) / 12.0)


def get_mock_hotspots(hour: int = 0) -> List[Dict[str, Any]]:
    # Dynamic diurnal multiplier based on hour
    mult = _diurnal(hour)
    items = []
    for cell_id, place, place_full, ward, lon, lat, pm, cause, conf, cause_conf, suspect, ph, rank, assets in RAW_HOTSPOTS:
        calc_pm = round(pm * mult)
        items.append({
            "cellId": cell_id,
            "place": place,
            "placeFull": place_full,
            "ward": ward,
            "at": [lon, lat],
            "pm25": calc_pm,
            "band": pm25_band_label(calc_pm),
            "cause": cause,
            "conf": conf,
            "causeConf": cause_conf,
            "suspectPin": {
                "label": suspect,
                "bearing": "north-west",
                "distanceKm": 1.9,
                "travelMin": 40,
            },
            "exposurePh": round(ph * mult),
            "rank": rank,
            "schools": SCHOOLS,
            "assets": assets,
            "forecast": [
                {
                    "h": h,
                    "p10": round(pm * _diurnal(h) * 0.85),
                    "p50": round(pm * _diurnal(h)),
                    "p90": round(pm * _diurnal(h) * 1.2),
                }
                for h in range(73)
            ],
        })
    return items


def get_mock_forecast() -> Dict[str, Any]:
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    series = [
        {"h": h, "p10": round(210 + h * 1.5), "p50": round(260 + h * 1.8), "p90": round(320 + h * 2.1)}
        for h in range(73)
    ]
    return {
        "issuedAt": now_iso,
        "ward": "All Wards",
        "grap": {
            "stage": "II",
            "likelyAt": now_iso,
            "probability": 0.82,
            "headline": "Stage II (Very Poor) expected Thursday 08:00 due to northwest smoke inflow.",
        },
        "series": series,
        "wards": [
            {"ward": "Mundka", "peopleHours": 24000, "peakPm25": 440, "confidence": 0.85},
            {"ward": "Bawana", "peopleHours": 19500, "peakPm25": 420, "confidence": 0.81},
            {"ward": "Wazirpur", "peopleHours": 18200, "peakPm25": 405, "confidence": 0.78},
        ],
    }


def get_mock_assets() -> List[Dict[str, Any]]:
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    return [
        {
            "id": "T-12",
            "kind": "sprinkler",
            "label": "Sprinkler 12 (West)",
            "depot": "Punjabi Bagh Depot",
            "task": "Mundka Industrial Road",
            "status": "Spraying",
            "tagSummary": "Spraying · 62 LPM · 1,420 L used",
            "lastPingAt": now_iso,
            "at": [77.035, 28.682],
            "simulated": True,
            "tag": {
                "tagId": "HTG-0012",
                "fw": "v1.4.2",
                "pumpOn": True,
                "flowLpm": 62.0,
                "litresThisRun": 1420.0,
                "tankLitres": 5000.0,
                "pm10Before": 380.0,
                "pm10Now": 240.0,
                "sprayWindows": [{"start": "06:10", "end": "07:30"}],
                "tamperIntact": True,
                "signalDbm": -68,
                "trust": 0.94,
                "lastSeq": 428,
            },
        },
        {
            "id": "ASG-07",
            "kind": "smog_gun",
            "label": "Anti-Smog Gun 07",
            "depot": "Rohini Sector 3",
            "task": "Bawana Industrial Gate 2",
            "status": "En route",
            "tagSummary": "En route to stop 2",
            "lastPingAt": now_iso,
            "at": [77.051, 28.776],
            "simulated": True,
            "tag": {
                "tagId": "HTG-0007",
                "fw": "v1.4.2",
                "pumpOn": False,
                "flowLpm": 0.0,
                "litresThisRun": 0.0,
                "tankLitres": 9000.0,
                "sprayWindows": [{"start": "07:45", "end": "09:00"}],
                "tamperIntact": True,
                "signalDbm": -72,
                "trust": 0.91,
                "lastSeq": 182,
            },
        },
    ]


def impact_series(impact: Dict[str, Any], started_at: str, baseline: float = 330.0, n: int = 36, step_min: int = 5, spray_from: int = 12) -> List[Dict[str, Any]]:
    """Observed vs synthetic-control series consistent with a verified effect: dip of `effectPct` for `durationMin`, then recovery."""
    import math
    from datetime import timedelta

    t0 = datetime.fromisoformat(started_at.replace("Z", "+00:00")) - timedelta(minutes=step_min * spray_from)
    eff = float(impact["effectPct"]) / 100.0
    hold = max(1, round(float(impact["durationMin"]) / step_min))
    band = max(0.03, abs(float(impact["ciHigh"]) - float(impact["ciLow"])) / 200.0)
    out: List[Dict[str, Any]] = []
    for i in range(n):
        control = baseline * (1 + 0.04 * math.sin(i / 5.0))
        k = i - spray_from
        f = 0.0 if k < 0 else min(1.0, (k + 1) / 2) if k <= hold else max(0.0, 1 - (k - hold) / 3)
        observed = control * (1 + eff * f) + 2.5 * math.sin(i * 2.1)
        out.append({
            "t": (t0 + timedelta(minutes=step_min * i)).isoformat().replace("+00:00", "Z"),
            "observed": round(observed, 1),
            "control": round(control, 1),
            "lo": round(control * (1 - band), 1),
            "hi": round(control * (1 + band), 1),
        })
    return out


def get_mock_impact() -> Dict[str, Any]:
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    effect = {"effectPct": -18.4, "ciLow": -24.1, "ciHigh": -12.2, "durationMin": 45}
    series = impact_series(effect, now_iso)
    return {
        "asOf": now_iso,
        "simulated": True,
        "summary": {"verifiedPct": 78.4, "targetPct": 85.0, "noEffect": 3, "wrongTool": 1},
        "items": [
            {
                "id": "int-01",
                "asset": "T-12",
                "action": "Water Spray",
                "cellId": "g500-041-077",
                "place": "Mundka Main Road",
                "cause": "Dust",
                "startedAt": now_iso,
                "simulated": True,
                "impact": {
                    "pollutant": "pm25",
                    "effectPct": -18.4,
                    "ciLow": -24.1,
                    "ciHigh": -12.2,
                    "durationMin": 45,
                    "method": "synthetic_control",
                    "donorCells": [{"cellId": "g500-041-076", "weight": 0.6}, {"cellId": "g500-042-077", "weight": 0.4}],
                    "verdict": "Verified",
                    "series": series,
                },
            }
        ],
    }


def get_mock_alerts() -> Dict[str, Any]:
    now_iso = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    return {
        "asOf": now_iso,
        "simulated": True,
        "counts": {"All": 2, "School": 1, "Citizens": 1, "Citizen Eyes": 0},
        "items": [
            {
                "id": "alt-01",
                "sentAt": now_iso,
                "audience": "School",
                "target": "3 schools in Mundka",
                "channel": "WhatsApp",
                "lang": "hi+en",
                "message": "High PM2.5 (380 ug/m3) expected at 08:00. Safe window for outdoor activities: 12:30 to 14:00.",
                "messageHi": "सुबह 8:00 बजे उच्च PM2.5 (380 ug/m3) की आशंका। बच्चों की बाहरी गतिविधियों के लिए सुरक्षित समय: दोपहर 12:30 से 2:00 बजे तक।",
                "delivered": "3 delivered, 0 failed",
                "leadTimeH": 13.5,
                "draftedBy": "Communicator",
            },
            {
                "id": "alt-02",
                "sentAt": now_iso,
                "audience": "Citizens",
                "target": "Mundka residents",
                "channel": "SMS",
                "lang": "en",
                "message": "Air quality alert: Severe pollution peak between 07:00-09:30 AM. Outdoor workers advised to wear N95 masks.",
                "delivered": "4,120 delivered",
                "leadTimeH": 11.0,
                "draftedBy": "Communicator",
            },
        ],
    }


def get_mock_driver_route(asset_id: str) -> Dict[str, Any]:
    return {
        "asset": asset_id,
        "assetLabelHi": "वॉटर स्प्रिंकलर १२",
        "planId": "plan-master-20261112",
        "dateLabel": "Thursday, 12 Nov 2026",
        "window": "06:00 – 10:00 IST",
        "stops": [
            {
                "n": 1,
                "placeHi": "मुंडका मुख्य मार्ग, मेट्रो पिलर ३४०-३६०",
                "placeEn": "Mundka Main Road, Metro Pillars 340-360",
                "actionEn": "Continuous median misting",
                "from": "06:10",
                "to": "07:20",
                "status": "done",
            },
            {
                "n": 2,
                "placeHi": "रोहतक रोड जंक्शन, उद्योग नगर",
                "placeEn": "Rohtak Road Junction, Udyog Nagar",
                "actionEn": "Shoulder dust suppression",
                "from": "07:35",
                "to": "08:45",
                "status": "active",
            },
            {
                "n": 3,
                "placeHi": "नांगलोई डिपो वाटर फिलिंग स्टेशन",
                "placeEn": "Nangloi Depot Water Refill Station",
                "actionEn": "Water refill (5,000 L)",
                "from": "09:00",
                "to": "09:30",
                "status": "todo",
            },
        ],
        "lastSpray": {
            "placeHi": "मुंडका मुख्य मार्ग",
            "litres": 1420.0,
            "pumpMin": 22.0,
            "pumpOn": True,
        },
    }
