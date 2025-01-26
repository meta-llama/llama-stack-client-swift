#!/usr/bin/env bash

LLAMA_STACK_DIR=${LLAMA_STACK_DIR:-}

set -euo pipefail

OPENAPI_FILE="llama-stack-spec.yaml"
if [ -n "$LLAMA_STACK_DIR" ]; then
  cp "$LLAMA_STACK_DIR/docs/resources/$OPENAPI_FILE" "Sources/LlamaStackClient/$OPENAPI_FILE"
else
  URL="https://raw.githubusercontent.com/meta-llama/llama-stack/refs/heads/main/docs/resources/llama-stack-spec.yaml"
  curl -s $URL > "Sources/LlamaStackClient/$OPENAPI_FILE"
fi

cd Sources/LlamaStackClient

# Remove security section
sed '/^security:$/N;/\n- Default: \[\]/d' "$OPENAPI_FILE" | \
# https://github.com/apple/swift-openapi-generator/pull/557
# https://github.com/apple/swift-openapi-generator/pull/558#issuecomment-2034319168
sed '/[[:space:]]*- type: '\''null'\''/d' > openapi.yaml

rm $OPENAPI_FILE
