import sys

input_text = sys.stdin.read()
account_id = re.search(r'Account ID:\s*(.*)', input_text).group(1)
public_key = re.search(r'Public Key:\s*(.*)', input_text).group(1)
balance = re.search(r'Balance:\s*(\d+)', input_text).group(1)

json_block = f'{{"accountId": "{account_id}", "publicKey": "{public_key}", "balance": {balance}}}'
print(json_block)
