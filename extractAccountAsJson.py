import sys
import json

def extract_json(input_text):
    try:
        # Attempt to parse the entire input as JSON
        data = json.loads(input_text)
        return json.dumps(data)
    except json.JSONDecodeError:
        # If parsing fails, search for a JSON block using regex
        json_regex = r'\{\s*\"accountId\":\s*\"[^\"]*\",\s*\"publicKey\":\s*\"[^\"]*\"(?:,\s*\"[^\"]*\":\s*[^,}]*)*\}'
        json_match = re.search(json_regex, input_text)
        if json_match:
            return json_match.group(0)
        else:
            raise ValueError("No valid JSON block found in input")

if __name__ == "__main__":
    input_text = sys.stdin.read().strip()
    try:
        json_block = extract_json(input_text)
        print(json_block)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
