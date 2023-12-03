PROD_PROJECT_NAME=soe-stanford-friallel-adlm
DEV_PROJECT_NAME=soe-stanford-friallel-adlm-dev

deploy-prod-ui:
	echo "export const prod = true;" > ./public/environment/environment.js
	firebase use $(PROD_PROJECT_NAME)
	firebase deploy --only hosting

deploy-dev-ui:
	echo "export const prod = false;" > ./public/environment/environment.js
	firebase use $(DEV_PROJECT_NAME)
	firebase deploy --only hosting

deploy-prod-ui-windows:
	echo export const prod = true; > ./public/environment/environment.js
	firebase use $(PROD_PROJECT_NAME)
	firebase deploy --only hosting

deploy-dev-ui-windows:
	echo export const prod = false; > ./public/environment/environment.js
	firebase use $(DEV_PROJECT_NAME)
	firebase deploy --only hosting

deploy-prod-functions:
	firebase use $(PROD_PROJECT_NAME)
	firebase deploy --only functions

deploy-dev-functions:
	firebase use $(DEV_PROJECT_NAME)
	firebase deploy --only functions

export-prod-indexes:
	firebase firestore:indexes

	
deploy-dev-indexes:
	firebase use $(DEV_PROJECT_NAME)
	firebase deploy --only firestore:indexes

deploy-prod-indexes:
	firebase use $(PROD_PROJECT_NAME)
	firebase deploy --only firestore:indexes

start-dev-server:
	firebase emulators:start