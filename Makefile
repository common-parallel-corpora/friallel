
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

load-dataset-fria-dataset-01:
	python scripts/load_dataset.py  \
		--env dev \
		--dataset-root-dir data/dev_dataset/dev \
		--dataset-name fria-dataset-01 
#		--langs eng_Latn fra_Latn

create-translation-workflows-fria-dataset-01:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names fria-dataset-01 \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 1000




create-translation-workflows-flores-dev:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names flores-dev flores-devtest \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 1000


create-test-workflows-multitext-nllb-seed:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--random-subset-size 500 \
		--dataset-names multitext-nllb \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 0



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

	
generate-prod-accounting-report:
	mkdir -p data/csv/prod_accounting_reports
	python scripts/accounting_statements.py  --env prod > data/csv/prod_accounting_reports/accounting_report.csv




## NLLB Seed Dataset
data/NLLB-Seed.zip: data/
	wget --trust-server-names https://tinyurl.com/NLLBSeed -O data/NLLB-Seed.zip

data/NLLB-Seed: data/NLLB-Seed.zip
	unzip data/NLLB-Seed.zip -d data/

data/NLLB-Seed/bam_Latn-eng_Latn/bam_Nkoo:
	cat data/NLLB-Seed/bam_Latn-eng_Latn/bam_Latn | python -m detransliterator.tool --model-name latin2nqo_001.35 > data/NLLB-Seed/bam_Latn-eng_Latn/bam_Nkoo

load-nllb-bam:
	python scripts/load_dataset.py  --env dev --dataset-root-dir data/NLLB-Seed/bam_Latn-eng_Latn --dataset-name nllb-seed-bam --batch-size 500

create-translation-workflows-nllb-seed-bam:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names nllb-seed-bam \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 5000 \
		--batch-size 500

match-nllb-lines:
	python scripts/match_file_lines.py \
		data/Multitext-NLLB-Seed/eng_Latn \
		data/NLLB-Seed/ace_Arab-eng_Latn/eng_Latn \
		--output-files data/Multitext-NLLB-Seed/order_files/reference_ace_Arab-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/ace_Arab-eng_Latn.order.txt


generate-nllb-alignment-command-lines:
	for l in data/NLLB-Seed/* ; do \
		echo "python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn $${l}/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_`basename $$l`.order.txt data/Multitext-NLLB-Seed/order_files/`basename $$l`.order.txt"; \
		for lang_file in $$l/* ; do \
			echo "python scripts/sort_file.py --input-file $${lang_file} --order-file data/Multitext-NLLB-Seed/order_files/`basename $$l`.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/`basename $$l`/`basename $$lang_file`"; \
		done; \
	done



align-nllb-eng:
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/ace_Arab-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_ace_Arab-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/ace_Arab-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/ace_Arab-eng_Latn/ace_Arab --order-file data/Multitext-NLLB-Seed/order_files/ace_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ace_Arab-eng_Latn/ace_Arab
	python scripts/sort_file.py --input-file data/NLLB-Seed/ace_Arab-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/ace_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ace_Arab-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/ace_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_ace_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/ace_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/ace_Latn-eng_Latn/ace_Latn --order-file data/Multitext-NLLB-Seed/order_files/ace_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ace_Latn-eng_Latn/ace_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/ace_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/ace_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ace_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/ary_Arab-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_ary_Arab-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/ary_Arab-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/ary_Arab-eng_Latn/ary_Arab --order-file data/Multitext-NLLB-Seed/order_files/ary_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ary_Arab-eng_Latn/ary_Arab
	python scripts/sort_file.py --input-file data/NLLB-Seed/ary_Arab-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/ary_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ary_Arab-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/arz_Arab-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_arz_Arab-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/arz_Arab-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/arz_Arab-eng_Latn/arz_Arab --order-file data/Multitext-NLLB-Seed/order_files/arz_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/arz_Arab-eng_Latn/arz_Arab
	python scripts/sort_file.py --input-file data/NLLB-Seed/arz_Arab-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/arz_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/arz_Arab-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/bam_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_bam_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/bam_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/bam_Latn-eng_Latn/bam_Latn --order-file data/Multitext-NLLB-Seed/order_files/bam_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bam_Latn-eng_Latn/bam_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/bam_Latn-eng_Latn/bam_Nkoo --order-file data/Multitext-NLLB-Seed/order_files/bam_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bam_Latn-eng_Latn/bam_Nkoo
	python scripts/sort_file.py --input-file data/NLLB-Seed/bam_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/bam_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bam_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/ban_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_ban_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/ban_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/ban_Latn-eng_Latn/ban_Latn --order-file data/Multitext-NLLB-Seed/order_files/ban_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ban_Latn-eng_Latn/ban_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/ban_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/ban_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/ban_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/bho_Deva-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_bho_Deva-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/bho_Deva-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/bho_Deva-eng_Latn/bho_Deva --order-file data/Multitext-NLLB-Seed/order_files/bho_Deva-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bho_Deva-eng_Latn/bho_Deva
	python scripts/sort_file.py --input-file data/NLLB-Seed/bho_Deva-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/bho_Deva-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bho_Deva-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/bjn_Arab-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_bjn_Arab-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/bjn_Arab-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/bjn_Arab-eng_Latn/bjn_Arab --order-file data/Multitext-NLLB-Seed/order_files/bjn_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bjn_Arab-eng_Latn/bjn_Arab
	python scripts/sort_file.py --input-file data/NLLB-Seed/bjn_Arab-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/bjn_Arab-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bjn_Arab-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/bjn_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_bjn_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/bjn_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/bjn_Latn-eng_Latn/bjn_Latn --order-file data/Multitext-NLLB-Seed/order_files/bjn_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bjn_Latn-eng_Latn/bjn_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/bjn_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/bjn_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bjn_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/bug_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_bug_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/bug_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/bug_Latn-eng_Latn/bug_Latn --order-file data/Multitext-NLLB-Seed/order_files/bug_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bug_Latn-eng_Latn/bug_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/bug_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/bug_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/bug_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/crh_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_crh_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/crh_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/crh_Latn-eng_Latn/crh_Latn --order-file data/Multitext-NLLB-Seed/order_files/crh_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/crh_Latn-eng_Latn/crh_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/crh_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/crh_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/crh_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/dik_Latn-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_dik_Latn-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/dik_Latn-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/dik_Latn-eng_Latn/dik_Latn --order-file data/Multitext-NLLB-Seed/order_files/dik_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/dik_Latn-eng_Latn/dik_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/dik_Latn-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/dik_Latn-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/dik_Latn-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/dzo_Tibt-eng_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_dzo_Tibt-eng_Latn.order.txt data/Multitext-NLLB-Seed/order_files/dzo_Tibt-eng_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/dzo_Tibt-eng_Latn/dzo_Tibt --order-file data/Multitext-NLLB-Seed/order_files/dzo_Tibt-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/dzo_Tibt-eng_Latn/dzo_Tibt
	python scripts/sort_file.py --input-file data/NLLB-Seed/dzo_Tibt-eng_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/dzo_Tibt-eng_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/dzo_Tibt-eng_Latn/eng_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-fur_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-fur_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-fur_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-fur_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-fur_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-fur_Latn/fur_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-fur_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-fur_Latn/fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-fuv_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-fuv_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-fuv_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-fuv_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-fuv_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-fuv_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-fuv_Latn/fuv_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-fuv_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-fuv_Latn/fuv_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-grn_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-grn_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-grn_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-grn_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-grn_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-grn_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-grn_Latn/grn_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-grn_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-grn_Latn/grn_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-hne_Deva/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-hne_Deva.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-hne_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-hne_Deva/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-hne_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-hne_Deva/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-hne_Deva/hne_Deva --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-hne_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-hne_Deva/hne_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-kas_Arab/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-kas_Arab.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Arab.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-kas_Arab/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-kas_Arab/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-kas_Arab/kas_Arab --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-kas_Arab/kas_Arab
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-kas_Deva/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-kas_Deva.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-kas_Deva/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-kas_Deva/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-kas_Deva/kas_Deva --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-kas_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-kas_Deva/kas_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-knc_Arab/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-knc_Arab.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Arab.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-knc_Arab/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-knc_Arab/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-knc_Arab/knc_Arab --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-knc_Arab/knc_Arab
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-knc_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-knc_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-knc_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-knc_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-knc_Latn/knc_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-knc_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-knc_Latn/knc_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-lij_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-lij_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-lij_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lij_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lij_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lij_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lij_Latn/lij_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lij_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lij_Latn/lij_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-lim_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-lim_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-lim_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lim_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lim_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lim_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lim_Latn/lim_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lim_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lim_Latn/lim_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-lmo_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-lmo_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-lmo_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lmo_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lmo_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lmo_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-lmo_Latn/lmo_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-lmo_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-lmo_Latn/lmo_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-ltg_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-ltg_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-ltg_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-ltg_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-ltg_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-ltg_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-ltg_Latn/ltg_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-ltg_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-ltg_Latn/ltg_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-mag_Deva/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-mag_Deva.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-mag_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mag_Deva/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mag_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mag_Deva/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mag_Deva/mag_Deva --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mag_Deva.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mag_Deva/mag_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-mni_Beng/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-mni_Beng.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-mni_Beng.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mni_Beng/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mni_Beng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mni_Beng/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mni_Beng/mni_Beng --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mni_Beng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mni_Beng/mni_Beng
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-mri_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-mri_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-mri_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mri_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mri_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mri_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-mri_Latn/mri_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-mri_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-mri_Latn/mri_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-nus_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-nus_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-nus_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-nus_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-nus_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-nus_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-nus_Latn/nus_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-nus_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-nus_Latn/nus_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-pbt_Arab/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-pbt_Arab.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-pbt_Arab.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-pbt_Arab/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-pbt_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-pbt_Arab/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-pbt_Arab/pbt_Arab --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-pbt_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-pbt_Arab/pbt_Arab
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-prs_Arab/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-prs_Arab.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-prs_Arab.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-prs_Arab/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-prs_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-prs_Arab/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-prs_Arab/prs_Arab --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-prs_Arab.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-prs_Arab/prs_Arab
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-scn_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-scn_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-scn_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-scn_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-scn_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-scn_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-scn_Latn/scn_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-scn_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-scn_Latn/scn_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-shn_Mymr/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-shn_Mymr.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-shn_Mymr.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-shn_Mymr/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-shn_Mymr.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-shn_Mymr/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-shn_Mymr/shn_Mymr --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-shn_Mymr.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-shn_Mymr/shn_Mymr
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-srd_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-srd_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-srd_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-srd_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-srd_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-srd_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-srd_Latn/srd_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-srd_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-srd_Latn/srd_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-szl_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-szl_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-szl_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-szl_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-szl_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-szl_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-szl_Latn/szl_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-szl_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-szl_Latn/szl_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-taq_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-taq_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-taq_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-taq_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-taq_Latn/taq_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-taq_Latn/taq_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-taq_Tfng/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-taq_Tfng.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Tfng.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-taq_Tfng/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Tfng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-taq_Tfng/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-taq_Tfng/taq_Tfng --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-taq_Tfng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-taq_Tfng/taq_Tfng
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-tzm_Tfng/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-tzm_Tfng.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-tzm_Tfng.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-tzm_Tfng/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-tzm_Tfng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-tzm_Tfng/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-tzm_Tfng/tzm_Tfng --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-tzm_Tfng.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-tzm_Tfng/tzm_Tfng
	python scripts/match_file_lines.py data/Multitext-NLLB-Seed/eng_Latn data/NLLB-Seed/eng_Latn-vec_Latn/eng_Latn --output-files data/Multitext-NLLB-Seed/order_files/reference_eng_Latn-vec_Latn.order.txt data/Multitext-NLLB-Seed/order_files/eng_Latn-vec_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-vec_Latn/eng_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-vec_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-vec_Latn/eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-Seed/eng_Latn-vec_Latn/vec_Latn --order-file data/Multitext-NLLB-Seed/order_files/eng_Latn-vec_Latn.order.txt --output-file data/Multitext-NLLB-Seed/re_ordered/eng_Latn-vec_Latn/vec_Latn


data/Multitext-NLLB-Seed/multitext:
	rm -rf data/Multitext-NLLB-Seed/multitext/
	mkdir -p data/Multitext-NLLB-Seed/multitext/

	# copy reordered lang files (along with multiple eng_Latn)
	cp data/Multitext-NLLB-Seed/re_ordered/*/* data/Multitext-NLLB-Seed/multitext/
	
	# override eng_Latn with reference
	cp data/Multitext-NLLB-Seed/eng_Latn data/Multitext-NLLB-Seed/multitext/



load-nllb-seed:
	python scripts/load_dataset.py  \
		--env dev --dataset-root-dir data/Multitext-NLLB-Seed/multitext/ \
		--dataset-name nllb-seed-bam \
		--batch-size 200

data/NTREX-128/preprocessed:
	python scripts/preprocess-ntrex-128.py \
		--input-dir data/NTREX-128/ \
		--mapping-file data/NTREX-128/mapping/mapping-file.csv \
		--output-dir data/NTREX-128/preprocessed

load-ntrex-128:
	python scripts/load_dataset.py  \
		--env dev \
		--dataset-root-dir data/NTREX-128/preprocessed \
		--dataset-name ntrex-128 \
		--batch-size 100


create-translation-workflows-nllb-ntrex-128:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names ntrex-128 \
		--target-lang nqo_Nkoo \
		--workflow-name default-translation-workflow \
		--initial-priority 20000 \
		--batch-size 500

## Export Data
data/exports/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name flores-dev --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

data/exports/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name flores-devtest --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

data/exports/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name nllb-seed-bam --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

export-data: \
	data/exports/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv \
	data/exports/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv \
	data/exports/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

generate-nllb-md-alignment-command-lines:
	python .\scripts\prepare_nllb_md.py --input-folder data/NLLB-MD --output-folder data/Multitext-NLLB-MD

	
align-nllb-mb-eng:
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/chat/test.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/chat/test.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/chat/test.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/chat/test.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/chat/test.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/test.eng_Latn data/NLLB-MD/chat/test.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/test.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/test.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/chat/test.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/chat/train.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/chat/train.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/chat/train.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/chat/train.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/chat/train.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/train.eng_Latn data/NLLB-MD/chat/train.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/train.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/train.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/chat/train.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/chat/valid.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/chat/valid.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/chat/valid.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/chat/valid.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/chat/valid.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/chat/valid.eng_Latn data/NLLB-MD/chat/valid.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/chat/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/chat/valid.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/chat/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/chat/valid.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/chat/valid.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/health/test.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/health/test.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/health/test.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/health/test.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/health/test.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/test.eng_Latn data/NLLB-MD/health/test.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/test.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/health/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/health/test.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/health/test.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/health/train.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/health/train.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/health/train.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/health/train.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/health/train.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/train.eng_Latn data/NLLB-MD/health/train.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/train.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/health/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/health/train.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/health/train.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/health/valid.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/health/valid.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/health/valid.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/health/valid.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/health/valid.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/health/valid.eng_Latn data/NLLB-MD/health/valid.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/health/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/health/valid.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/health/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/health/valid.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/health/valid.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/news/test.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/news/test.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/news/test.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/news/test.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/news/test.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/test.eng_Latn data/NLLB-MD/news/test.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-test.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/test.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/news/test.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/news/test.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/news/test.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/news/train.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/news/train.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/news/train.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/news/train.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/news/train.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/train.eng_Latn data/NLLB-MD/news/train.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-train.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/train.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/news/train.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/news/train.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/news/train.wol_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-ayr_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-ayr_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-ayr_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-ayr_Latn.ayr_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-ayr_Latn.ayr_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-ayr_Latn.ayr_Latn
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-ayr_Latn.ayr_Latn data/Multitext-NLLB-MD/news/valid.ayr_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-bho_Deva.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-bho_Deva.bho_Deva.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-bho_Deva.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-bho_Deva.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-bho_Deva.bho_Deva --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-bho_Deva.bho_Deva.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-bho_Deva.bho_Deva
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-bho_Deva.bho_Deva data/Multitext-NLLB-MD/news/valid.bho_Deva
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-dyu_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-dyu_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-dyu_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-dyu_Latn.dyu_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-dyu_Latn.dyu_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-dyu_Latn.dyu_Latn
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-dyu_Latn.dyu_Latn data/Multitext-NLLB-MD/news/valid.dyu_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-fur_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-fur_Latn.fur_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-fur_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-fur_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-fur_Latn.fur_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-fur_Latn.fur_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-fur_Latn.fur_Latn
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-fur_Latn.fur_Latn data/Multitext-NLLB-MD/news/valid.fur_Latn
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-rus_Cyrl.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-rus_Cyrl.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-rus_Cyrl.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-rus_Cyrl.rus_Cyrl data/Multitext-NLLB-MD/news/valid.rus_Cyrl
	python scripts/match_file_lines.py data/Multitext-NLLB-MD/news/valid.eng_Latn data/NLLB-MD/news/valid.eng_Latn-wol_Latn.eng_Latn --output-files data/Multitext-NLLB-MD/order_files/news/reference-valid.eng_Latn.order.txt data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-wol_Latn.wol_Latn.order.txt
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-wol_Latn.eng_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-wol_Latn.eng_Latn
	python scripts/sort_file.py --input-file data/NLLB-MD/news/valid.eng_Latn-wol_Latn.wol_Latn --order-file data/Multitext-NLLB-MD/order_files/news/valid.eng_Latn-wol_Latn.wol_Latn.order.txt --output-file data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-wol_Latn.wol_Latn
	cp data/Multitext-NLLB-MD/reordered/news/valid.eng_Latn-wol_Latn.wol_Latn data/Multitext-NLLB-MD/news/valid.wol_Latn
