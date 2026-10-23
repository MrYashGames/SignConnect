# Required setup for the Meet feature (Agora)

Meet now runs on Agora's RTC SDK instead of Jitsi — see `README.md` for
why. Unlike Jitsi's public server, Agora has no free-to-everyone shared
server: you need your own (free) App ID.

## 1. Get a free Agora App ID

1. Go to https://console.agora.io and sign up (free).
2. Create a new project. When asked for the authentication mechanism,
   choose **"App ID"** / **Testing Mode** (sometimes labeled "Secured mode:
   APP ID" vs "Secured mode: APP ID + Token") — this lets the app join
   channels with just the App ID, no token server needed. This is fine for
   development; switch to token-based auth before any public release (see
   "Before shipping" below).
3. Copy the App ID from the project dashboard.

## 2. Paste it into the app

Open `lib/services/agora_meet_service.dart` and replace:

```dart
const String agoraAppId = 'YOUR_AGORA_APP_ID';
```

with your actual App ID. That's the only code change needed — everything
else (joining, video rendering, the waiting-room admission flow) already
works once this is set.

## 3. Android permissions

`camera` and `microphone` are already requested at runtime via
`permission_handler` (same as the sign-recognition feature uses). No
AndroidManifest changes needed beyond what earlier features already
required.

## What you get without a token server

- Full video/audio calling between two or more participants, in-app,
  no browser.
- A working "allow everyone directly" vs "always ask" admission setting
  (Options → Meeting admission) — built from Agora's own data-stream
  messaging, not a separate plugin. See the honesty note at the top of
  `agora_meet_service.dart` for its actual security scope: it stops casual
  drop-ins, it is not hardened against a deliberately modified client.

## Before shipping (not needed for development)

Testing-mode projects (App ID only, no token) are meant for development —
Agora's dashboard will nag about this, and production apps should run a
small token-server (Agora publishes reference implementations) that mints
short-lived tokens per user. Out of scope for now; flagging so it doesn't
get forgotten later.
