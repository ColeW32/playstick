# playstick.golf

Stick.ai — tour-level golf practice for the FlightScope Mevo+.

- `docs/` — landing page (GitHub Pages) served at https://playstick.golf
- `installer/` — NSIS script for the Windows installer
- `.github/workflows/build-installer.yml` — builds `Stick-Setup.exe` on a Windows runner and attaches it to the `v1.0.0` release

The app payload (`stick-app.zip`) is uploaded to the `v1.0.0` release; the workflow wraps it into the installer.
