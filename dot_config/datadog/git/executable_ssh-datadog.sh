#!/usr/bin/env bash
GCT_DIR="$(cd "$(dirname "$0")" && pwd)"

key_args=()
for key in "$GCT_DIR"/pubkeys/datadog-*.ghkey.pub; do
  [[ -f "$key" ]] && key_args+=(-i "$key")
done

ssh -o IdentitiesOnly=yes \
  -o ControlMaster=auto \
  -o ControlPath="/tmp/gct-%i-%r@%h:%p-datadog" \
  -o ControlPersist=600 \
  "${key_args[@]}" \
  "$@"
rc=$?
if [[ $rc -eq 255 ]]; then
  echo "" >&2
  echo "  ========================================================" >&2
  echo "  SSH authentication failed." >&2
  echo "  Is your SSH agent running? Are your keys loaded?" >&2
  echo "  Run 'git config-tool doctor' to diagnose." >&2
  echo "  ========================================================" >&2
fi
exit $rc
