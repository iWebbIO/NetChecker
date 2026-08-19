# NetChecker

Dense reachability instrument for VPN engineers. One screen. Sequential probes. Typography from [moreweb.ir](https://moreweb.ir) (Poppins + Space Mono), without the neon.

Watches whether a tunnel change actually moved the internet, not whether a dashboard looks busy.

## What it checks

Runs continuously, **one item at a time**:

- **DNS** — UDP latency to public and Iranian resolvers (Shecan, Electro, Radar, 403, …)
- **NET** — IPv4, IPv6, TLS, SNI spoof (`youtube.com` on `1.1.1.1`), Cloudflare edge IPs
- **HUNT** — what each resolver returns for a watched name (default `youtube.com`)
- **SITES** — HTTPS to the top 30 destinations people actually hit, biased toward names commonly filtered in Iran

Settings: HTTP timeout (default 3s), delay between sites (default 400ms), DNS timeout/delay, extra hosts, hunt name.

Windows: always-on-top compact window and NIC bind. Linux: the same desktop chrome, shipped as `.deb` and `.rpm`.

Not included: VLESS editors, SMS encoders, Xray scanners, or other non-testing menus.

## Run

```bash
flutter pub get
flutter run
```

Android, Windows, and Linux are enabled.

## Release artifacts

GitHub Actions builds on every commit (APK, Windows zip, Linux zip + deb + rpm) and publishes:

- a **nightly** prerelease on `main`
- a versioned GitHub Release on tags `v*`

Optional Android signing secrets: `KEYSTORE` (base64 `.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Without them, CI signs with the debug key so the APK is still installable.

## License

MIT. Poppins and Space Mono are SIL Open Font License.
