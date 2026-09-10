import io

SCOPES = [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/spreadsheets',
]
FOLDER_ID = '1qFNgoP8_PasrFSyMFjONUvqFTTtnkk79'


def get_drive_service(credentials_json_path):
    from google.oauth2.service_account import Credentials
    from googleapiclient.discovery import build

    creds = Credentials.from_service_account_file(credentials_json_path, scopes=SCOPES)
    return build('drive', 'v3', credentials=creds)


def upload_text_file(service, filename, content, folder_id=FOLDER_ID):
    """Sube o actualiza un archivo de texto en Drive."""
    from googleapiclient.http import MediaIoBaseUpload

    results = service.files().list(
        q=f"name='{filename}' and '{folder_id}' in parents and trashed=false",
        fields='files(id, name)',
    ).execute()

    media = MediaIoBaseUpload(io.BytesIO(content.encode()), mimetype='text/plain')

    if results['files']:
        file_id = results['files'][0]['id']
        service.files().update(fileId=file_id, media_body=media).execute()
    else:
        metadata = {'name': filename, 'parents': [folder_id]}
        service.files().create(body=metadata, media_body=media).execute()
