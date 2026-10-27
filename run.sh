#!/usr/bin/env bash
# Runs Campus Lost and Found from a clean clone.
#
#   ./run.sh          install, set up the database, start the server
#   ./run.sh test     install, then run the automated tests (Week 7)
#   ./run.sh start    start the server only (skips install and database setup)
#
# Needs: Node.js 18+ and a running MySQL server.
# Windows: run it from Git Bash, or run the npm commands below by hand.
set -euo pipefail
cd "$(dirname "$0")"

MODE="${1:-all}"

fail() { echo "Error: $1" >&2; exit 1; }

case "$MODE" in
  all|test|start) ;;
  *) fail "Unknown option '$MODE'. Use: ./run.sh, ./run.sh test, or ./run.sh start" ;;
esac

# ---- 1. Check the tools are installed ----
command -v node >/dev/null 2>&1 || fail "Node.js is not installed. Get version 18 or newer from https://nodejs.org"
command -v npm  >/dev/null 2>&1 || fail "npm is not installed (it comes with Node.js)."
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" -ge 18 ] || fail "Node.js 18 or newer is needed; you have $(node -v)."

# ---- 2. Create .env on first run ----
if [ ! -f .env ]; then
  cp .env.example .env
  # Replace the placeholder API key with a real random one, so the server can start.
  NEW_KEY="$(node -e "console.log(require('crypto').randomBytes(24).toString('hex'))")"
  node -e "
    const fs = require('fs');
    const text = fs.readFileSync('.env', 'utf8').replace(/^API_KEYS=.*$/m, 'API_KEYS=$NEW_KEY');
    fs.writeFileSync('.env', text);
  "
  echo "Created .env from .env.example with a new API key."
  echo "Set DB_PASSWORD in .env to your MySQL password (leave it empty if root has none), then run ./run.sh again."
  echo "Give the API key in .env to your partner team privately. Never commit .env."
  exit 0
fi

# ---- 3. Install dependencies ----
if [ "$MODE" != "start" ]; then
  if [ -f package-lock.json ]; then
    npm ci
  else
    npm install
  fi
fi

# ---- 4. Run the chosen mode ----
case "$MODE" in
  test)
    # The tests create and use their own database (<DB_NAME>_test), so real data is untouched.
    npm test
    ;;
  start)
    npm start
    ;;
  all)
    # Recreates the tables and loads sample data. This erases existing data in DB_NAME.
    npm run db:setup
    npm start
    ;;
  *)
    fail "Unknown option '$MODE'. Use: ./run.sh, ./run.sh test, or ./run.sh start"
    ;;
esac
