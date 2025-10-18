
# Autochecker Launchers (Quick Start)
1) Host `Checks.zip` somewhere with a direct download URL (GitHub Releases recommended).
2) Open the launcher you plan to ship and set the `BUNDLE_URL`/`$BundleUrl` to that URL.
3) (Recommended) Compute SHA256 of `Checks.zip` and set `EXPECTED_SHA256`/`$ExpectedSha256`.
4) Ensure your zip has a clear entrypoint per OS (e.g., `run.sh`, `run.ps1`, or `main.exe`).
5) Commit one or both launchers to your repo; users run the launcher, not the zip directly.
