#!/usr/bin/env bash

set -euo pipefail

cd llama-stack/
bash ./rfcs/openapi_generator/run_openapi_generator.sh ../LlamaStack
cd ../LlamaStack

OPENAPI_FILE="llama-stack-spec.yaml"

# Remove security section
sed '/^security:$/N;/\n- Default: \[\]/d' "$OPENAPI_FILE" | \
# https://github.com/apple/swift-openapi-generator/pull/557
# https://github.com/apple/swift-openapi-generator/pull/558#issuecomment-2034319168
sed '/[[:space:]]*- type: '\''null'\''/d' > openapi.yaml

rm $OPENAPI_FILE
rm llama-stack-spec.html
