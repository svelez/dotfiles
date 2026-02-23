---
name: oidc-auth-notify
description: Detect OIDC/device-flow authentication prompts in bash command output and surface them clearly to the user
---

# OIDC Authentication Prompt Notifier

When running commands that require OIDC or device-flow authentication, the authentication URL and device code can scroll by unnoticed or be hidden by a timeout. This skill ensures Claude detects and presents those prompts clearly before proceeding.

## Activation

This skill is active whenever it has been loaded. While active, Claude monitors the output of every Bash tool call for authentication prompts.

## Two-Tier Execution Strategy

### Tier 1: Known tools — immediate background execution

Read `oidc-auth-notify/known-tools.txt` for the current list of tools known to trigger device-flow authentication. When the **base command** (first token) of a Bash invocation matches an entry in this list:

1. Run the command with `run_in_background: true`.
2. Immediately check output using `TaskOutput` with `block: false`.
3. If the auth prompt has not yet appeared, wait a few seconds and check again (up to 3 attempts).
4. Once detected, present the notification.

This provides the fastest possible notification — typically within seconds.

### Tier 2: Unknown tools — timeout fallback

For commands whose base command is **not** in the known-tools list, run them normally. If the command times out and the partial output contains an auth pattern:

1. Present the notification from the timeout output.
2. The process continues running in the background — use the returned task ID to monitor it.
3. **Append the base command** to `oidc-auth-notify/known-tools.txt` so future invocations use Tier 1.

### Extending the known-tools list

When a Tier 2 command triggers auth detection, add its base command to `known-tools.txt` (one command per line, no duplicates). This is the only time the list should be modified — it grows organically as new tools are encountered.

## Detection Patterns

After every Bash tool call (or background output check), scan both stdout and stderr for any of the following.

### Trigger phrases (substring or regex match)

- `Complete the login via your OIDC provider`
- `Open the following link in your browser`
- `Please visit` or `Please open` followed by a URL
- `Waiting for OIDC authentication`
- `Waiting for.*authentication to complete`
- `To sign in, use a web browser to open the page`
- `Attempting to automatically open the SSO authorization page`
- `If the browser does not open or you wish to use a different device`
- `First copy your one-time code`
- `Press Enter to open.*in your browser`
- `Opening browser for authentication`
- `enter code`, `enter the code`, `one-time code`, or `device code` followed by an alphanumeric token

### Device code patterns

Match any of these formats when they appear near auth-related context:

- `XXXX-XXXX` — two groups of 4+ alphanumeric characters (GitHub style)
- `XXX-XXX-XXXX` — three groups separated by dashes (Google style)
- A standalone alphanumeric token of 6-12 characters immediately following "enter code", "enter the code", "one-time code", or "device code" (Azure style)

### URL detection

A URL (`https://...`) appearing within 5 lines of any of these keywords: `login`, `authenticate`, `sign in`, `authorize`, `device`, `verify`, `one-time code`, `OIDC`.

**Exclude** URLs matching `http://localhost` or `http://127.0.0.1` — these are local callback servers that handle auth automatically and should not be surfaced.

## Notification

When an authentication prompt is detected, extract the URL and/or device code and present the appropriate notification variant.

### URL + code (most common)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ACTION REQUIRED: Browser Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL in your browser:
  <URL>

When prompted, enter this code:
  <DEVICE CODE>

Waiting for you to complete authentication...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### URL only

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ACTION REQUIRED: Browser Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL in your browser:
  <URL>

Waiting for you to complete authentication...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Code only

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ACTION REQUIRED: Browser Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

When prompted, enter this code:
  <DEVICE CODE>

Waiting for you to complete authentication...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Post-Notification: Automatic Completion Monitoring

After presenting the auth notification, **do not wait for the user to confirm**. Instead, actively poll the background task to detect completion automatically.

### Polling strategy

1. After presenting the notification, poll the background task using `TaskOutput` with `block: false` at reasonable intervals (every 10-15 seconds).
2. On each poll, scan the new output for **success** or **failure** patterns.
3. Continue polling for up to 30 minutes (auth tokens typically expire after ~30 minutes).
4. **Do not run any follow-up commands** until completion is detected or the user intervenes.

### Success patterns

The auth flow completed successfully. Present a success message and proceed with follow-up work.

- `session for "https://..." valid until <timestamp>` — Vault/ddtool style
- `Login Succeeded`
- `Authenticated successfully`
- `You are now logged in`
- `Logged in as`
- `credentials saved`
- Process exits with code 0

When detected:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Authentication successful.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then proceed with whatever work was pending.

### Failure patterns

The auth flow failed or timed out. Present the failure and ask the user how to proceed.

- `Error:.*token appears to be invalid`
- `authorization failed`
- `expired_token`
- `permission denied`
- `login.*failed`
- `authentication.*failed`
- `timed out waiting`
- Process exits with a non-zero exit code

When detected:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Authentication failed.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

<Brief summary of the error from the output>

Would you like to retry?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Polling timeout

If neither success nor failure is detected after 30 minutes of polling, stop polling and inform the user that the auth flow appears to have stalled.

## Example

Given this Bash output (from a timeout or background check):

```
Complete the login via your OIDC provider. Open the following link in your browser:

    https://www.google.com/device


Waiting for OIDC authentication to complete...
When prompted, enter code XXX-XXX-XXXX
```

Present to the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ACTION REQUIRED: Browser Authentication
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Open this URL in your browser:
  https://www.google.com/device

When prompted, enter this code:
  XXX-XXX-XXXX

Waiting for you to complete authentication...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
