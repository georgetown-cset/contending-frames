from pathlib import Path

PROJECT_DIR = Path(__file__).parent.resolve().expanduser().absolute()
SQL_DIR = PROJECT_DIR / "data"
ANALYSIS_DIR = PROJECT_DIR / "analysis"

PROJECT_ID = "gcp-cset-projects"
DATASET_ID = "rhetorical_frames"
