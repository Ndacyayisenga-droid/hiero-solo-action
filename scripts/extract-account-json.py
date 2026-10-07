"""Prints the account JSON object that `solo ledger account create|info` writes among its log output."""
import re
import sys

ACCOUNT_JSON = re.compile(r'\{\s*"accountId":\s*".*?",\s*"publicKey":\s*".*?",\s*"balance":\s*\d+\s*\}')

match = ACCOUNT_JSON.search(sys.stdin.read())
if not match:
    sys.exit("No account JSON found in the Solo output")
print(match.group(0))
