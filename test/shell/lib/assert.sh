#!/usr/bin/env bash
# Shared assertions for shell tests.

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="${3:-assert_eq}"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL [$label]: expected '$expected', got '$actual'" >&2
    exit 1
  fi
}

assert_exit() {
  local expected="$1"
  shift
  set +e
  "$@"
  local actual=$?
  set -e
  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL [assert_exit]: expected exit $expected, got $actual for: $*" >&2
    exit 1
  fi
}

assert_match() {
  local pattern="$1"
  local value="$2"
  local label="${3:-assert_match}"
  if ! echo "$value" | grep -Eq "$pattern"; then
    echo "FAIL [$label]: '$value' does not match /$pattern/" >&2
    exit 1
  fi
}

assert_not_match() {
  local pattern="$1"
  local value="$2"
  local label="${3:-assert_not_match}"
  if echo "$value" | grep -Eq "$pattern"; then
    echo "FAIL [$label]: '$value' unexpectedly matches /$pattern/" >&2
    exit 1
  fi
}
