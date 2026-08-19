# NetChecker

Network reachability checker for VPN engineers. Android, Windows, and Linux.

## Checks

Sequential probes, one at a time:

- **DNS** — UDP latency to public and Iranian resolvers (Shecan, Electro, Radar, 403, …)
- **NET** — IPv4, IPv6, TLS, SNI spoof (`youtube.com` on `1.1.1.1`), Cloudflare edge IPs
- **HUNT** — A records each resolver returns for a watched name (default `youtube.com`)
- **SITES** — HTTPS to ~30 destinations, including names commonly filtered in Iran

Settings: HTTP timeout (default 3s), delay between sites (default 400ms), DNS timeout/delay, extra hosts, hunt name.

Windows: always-on-top window and NIC bind. Linux: `.deb` and `.rpm`.

## Run

```bash
flutter pub get
flutter run
```

## CI

GitHub Actions builds APK, Windows zip, and Linux zip/deb/rpm on every commit.

- Nightly prerelease on `main`
- GitHub Release on tags `v*`

Optional Android signing secrets: `KEYSTORE` (base64 `.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Without them, CI uses the debug key.

## License

MIT
