
data/:
	mkdir -p data

data/flores200_dataset.tar.gz: data/
	wget --trust-server-names https://tinyurl.com/flores200dataset -O data/flores200_dataset.tar.gz

data/flores200_dataset: data/flores200_dataset.tar.gz
	tar -xvf data/flores200_dataset.tar.gz -C data/


.venv39:
	python3.9 -m venv .venv39


data/csv/flores_dev_fr_en.csv:
	mkdir -p data/csv/
	python scripts/makeparallelcsv.py data/flores200_dataset/dev/fra_Latn.dev data/flores200_dataset/dev/eng_Latn.dev --output-file data/csv/flores_dev_fr_en.csv


data/csv/flores_devtest_fr_en_ar.csv:
	mkdir -p data/csv/
	python scripts/makeparallelcsv.py \
		data/flores200_dataset/devtest/fra_Latn.devtest \
		data/flores200_dataset/devtest/eng_Latn.devtest \
		data/flores200_dataset/devtest/arb_Arab.devtest \
	--output-file data/csv/flores_devtest_fr_en_ar.csv



load-flores-dev:
	python scripts/load_dataset.py  \
		--env dev \
		--dataset-root-dir data/flores200_dataset/dev \
		--dataset-name flores-dev 
#		--langs eng_Latn fra_Latn

load-flores-dev-test:
	python scripts/load_dataset.py  \
		--env dev \
		--dataset-root-dir data/flores200_dataset/devtest \
		--dataset-name flores-devtest 
#		--langs eng_Latn fra_Latn

load-devtest-data:
	python scripts/load_dataset.py  \
		--env dev \
		--dataset-root-dir data/dev_dataset/dev \
		--dataset-name datatest-dev 
#		--langs eng_Latn fra_Latn


create-translation-workflows-flores-dev:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names flores-dev flores-devtest \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 1000


import-flores-dev-translations:
	python scripts/import_translation_tasks.py \
		--env dev \
		--dataset-name flores-dev \
		--input-csv-file-path data/csv/translated/flores_dev_fr_en__nko_final.csv \
		--output-csv-report-path data/csv/import_reports/report_flores_dev_fr_en__nko_final.csv \
		--input-csv-translation-colname nqo_Nkoo.dev \
		--translation-target-lang nqo_Nkoo

import-flores-devtest-translations:
	python scripts/import_translation_tasks.py \
		--env dev \
		--dataset-name flores-devtest \
		--input-csv-file-path data/csv/translated/flores_devtest_fr_en_ar__nko__final.csv \
		--output-csv-report-path data/csv/import_reports/report_flores_devtest_fr_en_ar__nko__final.csv \
		--input-csv-translation-colname nqo_Nkoo.devtest \
		--translation-target-lang nqo_Nkoo
	