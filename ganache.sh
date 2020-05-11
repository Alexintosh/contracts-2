#!/bin/bash

INFURA_API_KEY=$(grep INFURA_API_KEY .env | xargs -0 | tr -d '"')
INFURA_API_KEY=${INFURA_API_KEY#*=}
URL="https://kovan.infura.io/v3/${INFURA_API_KEY}"
ganache-cli --fork ${URL}
