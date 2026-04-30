#!/bin/bash

# Load environment variables
set -a
[ -f .env ] && source .env
set +a

# Default values
SYNAPSE_SERVER_NAME=${SYNAPSE_SERVER_NAME:-matrix.leonet.site}
SYNAPSE_REPORT_STATS=${SYNAPSE_REPORT_STATS:-yes}

echo "Generating Synapse configuration for $SYNAPSE_SERVER_NAME..."

docker run -it --rm \
    -v $(pwd)/synapse:/data \
    -e SYNAPSE_SERVER_NAME=$SYNAPSE_SERVER_NAME \
    -e SYNAPSE_REPORT_STATS=$SYNAPSE_REPORT_STATS \
    matrixdotorg/synapse:latest generate

echo "Configuration generated successfully!"
echo "Next steps:"
echo "1. Edit ./synapse/homeserver.yaml to configure your homeserver"
echo "2. Run: docker-compose up -d"
