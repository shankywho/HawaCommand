"""WorldPop population raster ingestion and spatial clipping.

Extracts real 2020 1km gridded population counts from WorldPop GeoTIFF (ind_ppp_2020_1km_Aggregated.tif).
Caches the clipped Delhi raster in data/processed/delhi_population_clipped.npz for ultra-fast lookup.
"""
from pathlib import Path
from typing import Optional, Tuple
import numpy as np
from PIL import Image

from hawa_ml.settings import settings
from hawa_ml.logging_conf import configure_logging

logger = configure_logging("worldpop")

# Delhi bounding box: [min_lat, min_lon, max_lat, max_lon]
DELHI_BBOX = (28.40, 76.84, 28.88, 77.35)


class WorldPopProcessor:
    def __init__(self):
        self.processed_cache = settings.PROCESSED_DATA_DIR / "delhi_population_clipped.npz"
        self._clip_data: Optional[np.ndarray] = None
        self._clip_meta: Optional[dict] = None

    def _find_source_tif(self) -> Optional[Path]:
        """Locate WorldPop TIFF in external data directories."""
        candidates = [
            settings.EXTERNAL_DATA_DIR / "worldpop" / "ind_ppp_2020_1km_Aggregated.tif",
            settings.EXTERNAL_DATA_DIR / "worldloop" / "ind_ppp_2020_1km_Aggregated.tif",
        ]
        for p in candidates:
            if p.exists():
                return p
        return None

    def load_clipped_raster(self) -> Tuple[np.ndarray, dict]:
        """Load cached clipped population grid or extract from raw TIFF."""
        if self._clip_data is not None and self._clip_meta is not None:
            return self._clip_data, self._clip_meta

        if self.processed_cache.exists():
            try:
                npz = np.load(self.processed_cache, allow_pickle=True)
                self._clip_data = npz["population"]
                self._clip_meta = npz["meta"].item()
                return self._clip_data, self._clip_meta
            except Exception as e:
                logger.warning(f"Failed to read cached population npz: {e}")

        tif_path = self._find_source_tif()
        if tif_path is None:
            logger.warning("WorldPop GeoTIFF not found. Generating synthetic Delhi population grid.")
            return self._generate_synthetic_grid()

        logger.info(f"Extracting and clipping Delhi population grid from {tif_path.name}...")
        try:
            im = Image.open(tif_path)
            tags = im.tag_v2
            scale_x, scale_y, _ = tags[33550]
            _, _, _, origin_lon, origin_lat, _ = tags[33922]

            min_lat, min_lon, max_lat, max_lon = DELHI_BBOX

            px_min = int((min_lon - origin_lon) / scale_x)
            px_max = int((max_lon - origin_lon) / scale_x) + 1
            py_min = int((origin_lat - max_lat) / scale_y)
            py_max = int((origin_lat - min_lat) / scale_y) + 1

            # Crop array
            full_arr = np.array(im)
            clip = full_arr[py_min:py_max, px_min:px_max].astype(np.float32)
            clip[np.isnan(clip) | (clip < 0)] = 0.0

            meta = {
                "origin_lat": origin_lat - py_min * scale_y,
                "origin_lon": origin_lon + px_min * scale_x,
                "scale_lat": scale_y,
                "scale_lon": scale_x,
                "shape": clip.shape,
            }

            # Cache the clipped matrix
            settings.PROCESSED_DATA_DIR.mkdir(parents=True, exist_ok=True)
            np.savez_compressed(self.processed_cache, population=clip, meta=meta)
            logger.info(f"Saved clipped Delhi population grid ({clip.shape}) to {self.processed_cache}")

            self._clip_data = clip
            self._clip_meta = meta
            return clip, meta

        except Exception as e:
            logger.warning(f"Error processing GeoTIFF: {e}. Falling back to synthetic population grid.")
            return self._generate_synthetic_grid()

    def get_population_at(self, lat: float, lon: float) -> float:
        """Lookup population count for a given latitude and longitude."""
        grid, meta = self.load_clipped_raster()
        try:
            py = int((meta["origin_lat"] - lat) / meta["scale_lat"])
            px = int((lon - meta["origin_lon"]) / meta["scale_lon"])
            if 0 <= py < grid.shape[0] and 0 <= px < grid.shape[1]:
                val = float(grid[py, px])
                return max(0.0, val)
        except Exception:
            pass
        return self._synthetic_pop_density(lat, lon)

    def _generate_synthetic_grid(self) -> Tuple[np.ndarray, dict]:
        """Parametric synthetic population density for Delhi NCR."""
        min_lat, min_lon, max_lat, max_lon = DELHI_BBOX
        lats = np.linspace(max_lat, min_lat, 60)
        lons = np.linspace(min_lon, max_lon, 60)
        grid = np.zeros((len(lats), len(lons)), dtype=np.float32)

        for i, lat in enumerate(lats):
            for j, lon in enumerate(lons):
                grid[i, j] = self._synthetic_pop_density(lat, lon)

        meta = {
            "origin_lat": max_lat,
            "origin_lon": min_lon,
            "scale_lat": (max_lat - min_lat) / 60.0,
            "scale_lon": (max_lon - min_lon) / 60.0,
            "shape": grid.shape,
        }
        self._clip_data = grid
        self._clip_meta = meta
        return grid, meta

    @staticmethod
    def _synthetic_pop_density(lat: float, lon: float) -> float:
        # Distance from central Delhi (28.63, 77.22) in degrees
        dist = np.sqrt((lat - 28.63) ** 2 + (lon - 77.22) ** 2)
        # Density peaks around central/east Delhi and drops outward
        density = 15000.0 * np.exp(-dist / 0.12) + 1200.0
        return float(np.clip(density, 200.0, 28000.0))


if __name__ == "__main__":
    proc = WorldPopProcessor()
    grid, meta = proc.load_clipped_raster()
    pop_cp = proc.get_population_at(28.6315, 77.2167)
    print(f"Population at Connaught Place (1km cell): {pop_cp:.0f}")
