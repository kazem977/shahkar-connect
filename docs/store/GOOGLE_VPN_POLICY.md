# Google Play VPN policy declaration (draft)

Complete this in Play Console after a working Android VpnService build.

- VPN is the core feature (traffic is tunneled via sing-box / VpnService).
- The app does not redirect traffic for ads or affiliate injection.
- Users sign in to an existing Shahkar account; there is no silent always-on
  without an explicit Connect tap.
- Privacy policy URL: host `docs/store/PRIVACY.md` on the panel domain before
  submission.
- Data safety: account credentials, purchase tokens (Play Billing), approximate
  diagnostics (node id, bytes). No advertising ID.

Network Extension / VPN capability on Apple is configured in the developer
account (not in this repo).
