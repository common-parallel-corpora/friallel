import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from firebase_admin import auth
from firebase_admin.auth import UserNotFoundError
from pprint import pprint
import logging


def get_firestore_client():
    cred = credentials.Certificate("keys/fbServiceAccountKey.json")
    app = firebase_admin.initialize_app(cred)
    return firebase_admin.firestore.client(app=app)



def lookup_user(db, user_id, email):
    if user_id and email:
        raise ValueError(f"only one of user_id or email should be specified")

    auth_user = None
    user_doc = None
    try:
        if user_id:
            auth_user = auth.get_user(user_id)
        elif email:
            auth_user = auth.get_user_by_email(email)
    except UserNotFoundError:
        logging.warn("Unable to find user id:{user_id}, email:{email}")

    if user_id or auth_user:
        user_id = user_id or auth_user.uid
        user_doc = db.document(f'users/{user_id}').get()
        if not user_doc.exists:
            user_doc = None

    return auth_user, user_doc


def display_user(auth_user, user_doc):
    print("--- Auth Record ---")
    if auth_user:
        for field in ['uid', 'disabled', 'display_name', 'email', 'email_verified', 'phone_number', 'photo_url', 'custom_claims', 'provider_id', 'tenant_id', 'tokens_valid_after_timestamp']:
            print(f"{field}: {getattr(auth_user, field)}")
        for pvd in auth_user.provider_data:
            print(f"Provider ID: {pvd.provider_id}, uid: {pvd.provider_id}")
            for provider_field in ['display_name', 'email', 'phone_number', 'photo_url']:
                print(f"\t{provider_field}: {getattr(pvd, provider_field)}")

        print("User Metadata")
        for user_metadata_field in ['creation_timestamp', 'last_refresh_timestamp', 'last_sign_in_timestamp']:
            user_metadata_value = getattr(
                auth_user.user_metadata, user_metadata_field
            )
            print(f"\t{user_metadata_field}: {user_metadata_value}")
    else:
        print("No auth record found for this user")
    print("--- End Auth Record ---")
    print()

    print("--- User Record ---")
    if user_doc:
        user_doc_dict = user_doc.to_dict()
        pprint(user_doc_dict)
    else:
        print("No user record found for this user")
    print("--- End User Record ---")


def get_all_auth_records():
    auth_records = []
    auth_records_by_uid = {}

    page = auth.list_users()
    while page:
        for user in page.users:
            auth_records.append(user)
            auth_records_by_uid[user.uid] = user
        page = page.get_next_page()

    return auth_records, auth_records_by_uid

def get_all_auth_records_by_email():
    auth_records_by_email = {}

    page = auth.list_users()
    while page:
        for user in page.users:
            auth_records_by_email[user.email.lower()] = user
        page = page.get_next_page()

    return auth_records_by_email

def get_all_user_docs(db):
    user_docs = []
    user_docs_by_id = {}
    for user_doc in list(db.collection(f'users').stream()):
        user_docs.append(user_doc)
        user_docs_by_id[user_doc.id] = user_doc

    return user_docs, user_docs_by_id
