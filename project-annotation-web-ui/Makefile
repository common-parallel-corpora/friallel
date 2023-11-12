deploy-prod-ui:
	echo "export const prod = true;" > ./public/environment/environment.js
	firebase use fs-2022-003-mtannotation
	firebase deploy --only hosting

deploy-dev-ui:
	echo "export const prod = false;" > ./public/environment/environment.js
	firebase use fs-2022-003-mtannotation-dev
	firebase deploy --only hosting

deploy-prod-ui-windows:
	echo export const prod = true; > ./public/environment/environment.js
	firebase use fs-2022-003-mtannotation
	firebase deploy --only hosting

deploy-dev-ui-windows:
	echo export const prod = false; > ./public/environment/environment.js
	firebase use fs-2022-003-mtannotation-dev
	firebase deploy --only hosting

deploy-prod-functions:
	firebase use fs-2022-003-mtannotation
	firebase deploy --only functions

deploy-dev-functions:
	firebase use fs-2022-003-mtannotation-dev
	firebase deploy --only functions

export-prod-indexes:
	firebase firestore:indexes

	
deploy-dev-indexes:
	firebase use dev
	firebase deploy --only firestore:indexes

deploy-prod-indexes:
	firebase use prod
	firebase deploy --only firestore:indexes

start-dev-server:
	firebase emulators:start