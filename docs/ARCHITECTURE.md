# Native client ↔ Shahkar panel

Do **not** create a second `users` / `plans` / `nodes` database. The panel already has them.

```
Flutter app  --JWT-->  Shahkar /api/v1  --reads-->  existing users, plans, nodes, hosts
                                 \--writes-->  app_payment_transactions, app_identities, client_telemetry
```

Live Xray/sing-box/WG sync is unchanged. See `docs/NATIVE_APP.md` in Shahkarpanel.

Tunnel JSON is `GET /api/v1/client/tunnel-config?node_id=` (same renderer as
`/sub` sing-box). The app never displays the raw config.
