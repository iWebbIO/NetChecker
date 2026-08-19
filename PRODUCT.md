# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (confirmed): one codebase targeting Android, Windows, and Linux. GitHub Actions produces APK, Windows zip, and Linux `.deb` / `.rpm`.

## Users

VPN and network engineers who keep this open while they change tunnels, routes, DNS, and interfaces. They need to see immediately whether a change improved or broke reachability. This is not a consumer app.

## Product Purpose

Continuously probe a curated list of destinations and DNS resolvers, one at a time, so an engineer can watch the live effect of infrastructure tweaks. Success is a glanceable, dense screen that is truthful about timeout, failure, and latency.

## Positioning

A always-running reachability instrument for filtered networks (especially Iran), not a scanner suite or config toolbox. One screen, sequential checks, platform-native chrome.

## Operating Context

Used beside other tools: a VPN client, terminal, and browser. On Windows it often sits pinned in a corner, always on top, bound to a specific NIC. On Android it is a full-screen glance while walking a tunnel. Checks run on a default timeout and a default delay between items; both are tunable.

## Capabilities and Constraints

Included (testing only):

- Sequential HTTPS reachability of a default top-30 list biased toward sites commonly filtered in Iran, plus custom targets
- Continuous DNS latency row (UDP A-query to well-known resolvers, including Iranian ones)
- DNS hunt: what selected Iranian / public resolvers return for a watched name
- Edge/CDN IP HTTPS probes (Cloudflare and similar anycast IPs)
- SNI spoof / TLS handshake probe
- IPv4 / IPv6 / HTTPS protocol chips
- Copyable result dump
- Settings: timeout, inter-item delay, DNS delay, target list
- Windows: always-on-top compact chrome, network interface bind
- Linux: same desktop instrument, packaged as deb and rpm

Excluded (not testing, extra menus): VLESS/config modifiers, SMS encoder, Netlify generators, Xray core scanners, AI analysis, about/update chrome.

Default HTTP timeout 3s. Default delay between domain items 400ms. DNS timeout 2s. DNS row runs independently and continuously.

## Brand Commitments

Name: NetChecker. Typography must match moreweb.ir (Poppins + Space Mono). Visual direction is minimalist and dense, not cyberpunk: no neon glow, no gradient hero type, no decorative mesh. Dark near-black ground as on moreweb.ir. Fit as much live data as possible; do not pad with cards.

## Evidence on Hand

moreweb.ir live site: Poppins 100/400/700, Space Mono 400/700, background `rgb(3, 0, 5)`, body text `rgb(209, 209, 209)`. Reference implementation: `mirarr-app/network-checker` (testing methods only). No existing UI in this repo.

## Product Principles

1. Truth over ornament: every cell is a live probe result.
2. Sequential by default so a change in the tunnel is attributable.
3. Density is a feature for this audience; chrome is not.
4. Platform chrome is native; the type and tone stay moreweb.
5. Testing features stay on the one screen; extra product menus stay out.

## Accessibility & Inclusion

Honor system font scale and Reduce Motion / animation off. Touch targets on Android meet 48dp even when visual cells are denser. Color is not the only status channel: show ms, `ok`, `to`, and `fail` in type.
