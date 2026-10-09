"""Environment and data checklist validator for HawaCommand AI-ML.

Reports detected credentials (always masked), local data files, and active fallback strategies.
Never prints raw secrets.
"""
import sys
from pathlib import Path

# Add src to sys.path
BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR / "src"))

from hawa_ml.settings import settings, mask_secret


def check_environment() -> dict:
    """Validate all required and optional API keys and external data files."""
    print("=" * 78)
    print(" HawaCommand AI-ML :: Environment & Key Verification Checklist")
    print("=" * 78)

    # 1. API Keys & Credentials
    key_specs = [
        {
            "var": "OPENAQ_API_KEY",
            "val": settings.OPENAQ_API_KEY,
            "required": "Strongly recommended",
            "fallback": "Use CPCB CSVs in data/external/cpcb/",
        },
        {
            "var": "NASA_FIRMS_MAP_KEY",
            "val": settings.NASA_FIRMS_MAP_KEY,
            "required": "Recommended",
            "fallback": "Synthetic fire counts + warning",
        },
        {
            "var": "GROQ_API_KEY",
            "val": settings.GROQ_API_KEY,
            "required": "Recommended for dev",
            "fallback": "Rule-based deterministic template text",
        },
        {
            "var": "BEDROCK_MODEL_ID",
            "val": settings.BEDROCK_MODEL_ID,
            "required": "For submission",
            "fallback": "Use Groq LLM provider",
        },
        {
            "var": "AWS_ACCESS_KEY_ID",
            "val": settings.AWS_ACCESS_KEY_ID,
            "required": "Optional (Bedrock)",
            "fallback": "Use Groq provider",
        },
        {
            "var": "AWS_SECRET_ACCESS_KEY",
            "val": settings.AWS_SECRET_ACCESS_KEY,
            "required": "Optional (Bedrock)",
            "fallback": "Use Groq provider",
        },
        {
            "var": "WAQI_TOKEN",
            "val": settings.WAQI_TOKEN,
            "required": "Optional",
            "fallback": "Skip WAQI backup source",
        },
        {
            "var": "CDS_API_KEY",
            "val": settings.CDS_API_KEY,
            "required": "Optional",
            "fallback": "Use Open-Meteo archive API",
        },
        {
            "var": "DATA_GOV_IN_API_KEY",
            "val": settings.DATA_GOV_IN_API_KEY,
            "required": "Optional",
            "fallback": "Manual CPCB CSVs in data/external/cpcb/",
        },
    ]

    print("\n[1] API Keys Status (Masked):")
    print(f"{'Variable':<24} | {'Status':<15} | {'Value (Masked)':<16} | {'Active Strategy / Fallback'}")
    print("-" * 78)

    keys_summary = {}
    for spec in key_specs:
        var = spec["var"]
        val = spec["val"]
        is_present = bool(val and str(val).strip())
        status = "PRESENT" if is_present else "MISSING"
        masked = mask_secret(val) if is_present else "[NOT SET]"
        fallback = "Using live API" if is_present else spec["fallback"]
        keys_summary[var] = {"present": is_present, "masked": masked}
        print(f"{var:<24} | {status:<15} | {masked:<16} | {fallback}")

    # 2. Local External Files Check
    print("\n[2] Required Manual Data Files:")
    print(f"{'Data Path / Resource':<35} | {'Status':<12} | {'Notes / Details'}")
    print("-" * 78)

    # CPCB CSVs check
    cpcb_dir = settings.EXTERNAL_DATA_DIR / "cpcb"
    cpcb_files = list(cpcb_dir.glob("*.csv")) if cpcb_dir.exists() else []
    cpcb_status = f"PRESENT ({len(cpcb_files)} files)" if cpcb_files else "MISSING"
    print(f"{'data/external/cpcb/':<35} | {cpcb_status:<12} | Historical Delhi station CSVs")

    # WorldPop raster check (check both worldpop and worldloop)
    wp_primary = settings.EXTERNAL_DATA_DIR / "worldpop" / "ind_ppp_2020_1km_Aggregated.tif"
    wp_alt = settings.EXTERNAL_DATA_DIR / "worldloop" / "ind_ppp_2020_1km_Aggregated.tif"
    if wp_primary.exists():
        wp_status = "PRESENT"
        wp_note = f"Primary path ({wp_primary.stat().st_size // 1024 // 1024} MB)"
    elif wp_alt.exists():
        wp_status = "PRESENT"
        wp_note = f"Found in worldloop/ ({wp_alt.stat().st_size // 1024 // 1024} MB)"
    else:
        wp_status = "MISSING"
        wp_note = "Download required or fallback to synthetic pop"
    print(f"{'worldpop raster (.tif)':<35} | {wp_status:<12} | {wp_note}")

    # Operational Mode Summary
    print("\n[3] Operational Mode & LLM Configuration:")
    print(f"  • LLM Provider : {settings.LLM_PROVIDER}")
    print(f"  • Offline Mode : {settings.OFFLINE_MODE}")
    print(f"  • Log Level    : {settings.LOG_LEVEL}")
    print("=" * 78)

    return keys_summary


if __name__ == "__main__":
    check_environment()
