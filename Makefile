data/:
	mkdir -p data

data/cpc-2023-06-19.zip: data/
	wget https://github.com/common-parallel-corpora/common-parallel-corpora/archive/refs/tags/2023-06-19.zip -O data/cpc-2023-06-19.zip

data/common-parallel-corpora-2023-06-19: data/cpc-2023-06-19.zip
	unzip data/cpc-2023-06-19.zip -d data/
	rm -rf data/cpc-2023-06-19.zip

load-cpc-flores-dev:
	python scripts/load_dataset.py  \
		--env prod \
		--dataset-root-dir data/common-parallel-corpora-2023-06-19/data/common-parallel-corpora/flores-200-dev \
		--dataset-name cpc-flores-dev 
#		--langs eng_Latn fra_Latn

