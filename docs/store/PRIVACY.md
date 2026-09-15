# Privacy Policy — Shahkar Connect

Last updated: 15 September 2026

Shahkar Connect is a VPN client for accounts that already exist on a Shahkar
panel. It is not a separate identity provider.

## Data processed

- Portal username and password, used only to obtain a short-lived JWT.
- Subscription status (expiry, traffic remaining) from the same `users` row
  the web portal and subscription clients already use.
- Selected node hostname (public `hosts` address), session byte counters, and
  app platform for telemetry.
- Optional Telegram chat id, stored as `app_identities`, to show the same
  entitlement in the bot.

## Data not collected

- Browsing history or DNS queries of tunneled traffic (the panel sees
  aggregate byte counts from the node, as with any existing client).
- Raw App Store / Play receipts as payment proof (the panel queries Apple or
  Google).
- External payment URLs inside the app.

## Contact

Use the support channel of the Shahkar panel that issued the account.
