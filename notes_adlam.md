python3.10 -m venv .venv310
source .venv310/bin/activate
pip install -r requirements.txt

generate fb service account
mkdir keys
copy generated key to keys/fbServiceAccountKey-prod.json

