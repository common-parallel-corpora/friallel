
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


create-translation-workflows-flores-dev-adlam:
	python scripts/create_translation_workflows.py  \
		--env dev \
		--dataset-names flores-dev \
		--target-lang ful_Adlm \
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


target:
	for number in 1 2 3 4 ; do \
		echo $$number ; \
	done

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


## Export Data
data/exports/flores/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name flores-dev --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/flores/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

data/exports/flores/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name flores-devtest --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/flores/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

data/exports/multitext-nllb-seed/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/
	python scripts/export_dataset.py \
		--dataset-name nllb-seed-bam --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/multitext-nllb-seed/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

data/exports/ntrex-128/ntrex-128__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv:
	mkdir -p data/exports/ntrex-128
	python scripts/export_dataset.py \
		--dataset-name ntrex-128 --env prod \
		--ref-langs eng_Latn bam_Latn ary_Arab arz_Arab \
		> data/exports/ntrex-128/ntrex-128__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv

export-data: \
	data/exports/flores/flores-dev__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv \
	data/exports/flores/flores-devtest__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv \
	data/exports/multitext-nllb-seed/nllb-seed__eng_Latn__bam_Latn__ary_Arab__arz_Arab__nqo_Nkoo.csv


# Users
# 4eDB45vdvvdzUK3BFOCSpoVYas03 babadiane2023@gmail.com
# GyN0vJHJ4teQahWlFy8uIigLM5k2 cissekalinko2023@gmail.com
# kYa6BAz7SFhjxGLYV2Z1tgVfWSb2 solofarabado@gmail.com
# ucSTXrOw5DZpa7YMo8mBLjsFfws2 babamamadidiane@gmail.com

data/exports/flores/nqo_Nkoo.dev:
	mkdir -p data/exports/flores/
	python scripts/export_lang_file.py \
		--dataset-name flores-dev --env prod \
		--target-lang nqo_Nkoo \
		> data/exports/flores/nqo_Nkoo.dev

data/exports/flores/nqo_Nkoo.devtest:
	mkdir -p data/exports/flores/
	python scripts/export_lang_file.py \
		--dataset-name flores-devtest --env prod \
		--target-lang nqo_Nkoo \
		> data/exports/flores/nqo_Nkoo.devtest

data/exports/multitext-nllb-seed/nqo_Nkoo:
	mkdir -p data/exports/multitext-nllb-seed/
	python scripts/export_lang_file.py \
		--dataset-name nllb-seed-bam --env prod \
		--target-lang nqo_Nkoo \
		> data/exports/multitext-nllb-seed/nqo_Nkoo

nqo-flores: \
	data/exports/flores/nqo_Nkoo.dev \
	data/exports/flores/nqo_Nkoo.devtest \
	data/exports/multitext-nllb-seed/nqo_Nkoo 