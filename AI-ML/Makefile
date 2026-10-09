.PHONY: help setup env-check data train demo test clean api

help:
	@echo "HawaCommand AI-ML Engine Commands:"
	@echo "  make setup      - Install dependencies and build directories"
	@echo "  make env-check  - Run environment credentials and dataset validation"
	@echo "  make data       - Fetch external datasets or build fixtures"
	@echo "  make train      - Train forecaster, classifier, and calibrator"
	@echo "  make demo       - Seed demo scenario and run 3-hour execution cycle"
	@echo "  make test       - Run test suite"
	@echo "  make api        - Launch FastAPI serving server on port 8000"

setup:
	python -m pip install -r requirements.txt
	python -c "import hawa_ml.settings; print('Setup completed successfully')"

env-check:
	python scripts/check_env.py

data:
	python scripts/fetch_all.py
	python scripts/build_dataset.py

train:
	python scripts/train_all.py

demo:
	python scripts/demo_seed.py
	python scripts/run_cycle.py --once

test:
	pytest -v tests/

api:
	uvicorn hawa_ml.api.main:app --host 0.0.0.0 --port 8000 --reload

clean:
	python -c "import shutil, pathlib; [shutil.rmtree(p, ignore_errors=True) for p in pathlib.Path('.').rglob('__pycache__')]"
	python -c "import shutil, pathlib; [shutil.rmtree(p, ignore_errors=True) for p in pathlib.Path('.').rglob('.pytest_cache')]"
