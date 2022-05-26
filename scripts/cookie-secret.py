import secrets
import base64

print(str(base64.b64encode(base64.b64encode(secrets.token_bytes(16)))).strip('b').strip('\''))
