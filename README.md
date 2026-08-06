# Khata Dalo (کھاتہ ڈالو) — Phase 2

Offline Windows Desktop POS Retail System.
Built with **Electron.js + React + Tailwind CSS** on the frontend and a
**FastAPI (Python) + SQLite** backend. Not a web app — this compiles into
a native `.exe` that runs like Chrome / VS Code / any other Windows
desktop program, with a local database file that lives entirely on the
user's PC.

Phase 2 replaced Phase 1's localStorage-only storage with a real local
database: Electron auto-starts a FastAPI server on `127.0.0.1:8000` in
the background, the React app talks to it over HTTP, and everything is
persisted in `backend/khata_dalo.db` (SQLite — a single file, zero
external server to install).

---

## 1. Quick Start (Windows) — one click

Double-click **`build.bat`** (or `setup.bat`, same thing). It will:

1. Check for Node.js / npm — opens the download page if missing.
2. Set up the Python backend (`backend-setup.bat`): checks for Python,
   creates `backend/.venv`, and installs FastAPI/SQLAlchemy/uvicorn.
3. Run `npm install` and `npm run build` to compile the React frontend.
4. Run `electron-builder` to package a Windows installer.
5. Drop **`KhataDalo-Setup-v1.0.0.exe`** inside the `release/` folder.

**Requires Python 3.10+** installed and on PATH (in addition to Node.js).
Both `build.bat` and `backend-setup.bat` will open the official download
page automatically if either is missing.

Run the generated installer on any Windows PC to install Khata Dalo like
any other desktop app (Start Menu shortcut + Desktop shortcut included).
The database file is created automatically the first time the app runs
— no manual setup needed after installing.

> **Important:** the installed app is a separate copy of the project,
> in its own folder (wherever you chose during installation — e.g.
> `C:\Users\<you>\AppData\Local\Programs\Khata Dalo\`). Running
> `backend-setup.bat` inside your *source* folder (this project) only
> sets up the backend for **development mode** here — it does not
> affect the installed copy. The first time you launch the installed
> app, if its backend isn't set up yet, Khata Dalo will show a popup
> with a **"Run Setup Now"** button that does this for you automatically
> (a terminal window opens showing progress — Python 3.10+ must already
> be installed on that PC). You only need to do this once per install.

## 2. Development mode (live reload)

```
backend-setup.bat      REM once, to create backend/.venv
start-dev.bat           REM or: npm install && npm run electron:dev
```

Starts the Vite dev server and opens the Electron window pointed at it;
Electron also spawns the FastAPI backend automatically. Edit anything in
`src/` and the window hot-reloads; edit anything in `backend/app/` and
restart the app to pick up backend changes (uvicorn isn't in `--reload`
mode by default).

## 3. Manual build (without build.bat)

```
backend-setup.bat
npm install
npm run build          # compiles src/ -> dist/
npx electron-builder --win
```

## 4. Demo login

| Role     | Username  | PIN  |
|----------|-----------|------|
| Admin    | admin     | 1234 |
| Manager  | manager   | 2222 |
| Cashier  | cashier1  | 1111 |

Seeded automatically the first time the backend creates the database.

---

## Project structure

```
khata-dalo/
├── build.bat / setup.bat     1-click backend + frontend setup + .exe build
├── backend-setup.bat         1-click Python venv + dependency install
├── start-dev.bat             1-click dev-mode launcher
├── electron-builder.yml      Windows installer (NSIS) configuration
├── electron/
│   ├── main.cjs               Spawns/stops the FastAPI backend, creates the window
│   └── preload.cjs            Exposes the API base URL to the renderer
├── backend/
│   ├── requirements.txt       fastapi, uvicorn, sqlalchemy, pydantic
│   ├── run.py                 Uvicorn launcher (what Electron spawns)
│   ├── khata_dalo.db          SQLite database (auto-created, not shipped)
│   └── app/
│       ├── main.py             FastAPI app, CORS, table creation, seed data
│       ├── database.py         SQLAlchemy engine/session
│       ├── models.py           ORM tables (users, products, sales, ...)
│       ├── schemas.py          Pydantic request/response models
│       └── routers/            auth, inventory, accounts, khata, pos, shifts, settings, system
├── src/
│   ├── lib/api.js              fetch wrapper for the backend
│   ├── hooks/useApiCollection.js   server-backed collection hook (add/update/remove/refresh)
│   ├── contexts/               Theme, Language (EN/UR + RTL/LTR), Auth, Data — all API-backed
│   ├── i18n/translations.js    English + Urdu label dictionary
│   ├── components/
│   │   ├── layout/             HeaderBar, Sidebar (full nav), MainLayout
│   │   └── common/              Modal, Tabs, ui.jsx primitives, PriceCheckModal, etc.
│   └── pages/                  One dedicated page per sidebar item
├── package.json
└── vite.config.js
```

## What's implemented (Phase 2)

Everything from Phase 1, now backed by a real database instead of
localStorage:

- **Atomic POS checkout** — a single API call creates the sale, deducts
  stock, and (for Udhar sales) updates the customer's balance + ledger,
  all in one database transaction.
- **Purchases** update product stock and, if unpaid, the supplier's
  balance automatically on the server.
- **Stock movements** (Debit Note / Credit Note / Adjustment) adjust
  product stock server-side.
- **Shifts**: created on login, running totals updated on every sale,
  closed from the End Of Day page.
- **Settings** (shop profile, printer, hardware/tax, WhatsApp) stored as
  key/value rows in SQLite.
- **Backup**: "Backup Now" copies the live `khata_dalo.db` file to
  `backend/backups/` and downloads it; Restore uploads a `.db` file and
  swaps it in (keeping a safety copy of the previous database first).
- **Notifications** (low stock, pending Udhar) are computed by the
  backend on request; read/unread state stays local to the device.
- User management, PIN changes, categories, suppliers, customers, sales
  and stock reports, dashboard analytics — all read/write through the
  API now.

## Notes for Phase 3+

- PINs are stored as plain text in Phase 2 (matching the spec); hash them
  (e.g. bcrypt) before this ever leaves a trusted local machine.
- `uvicorn` runs without `--reload`; wire that up in `run.py` for a nicer
  backend dev loop if you're iterating on `backend/app/` a lot.
- The packaged app does **not** bundle a Python interpreter or the
  `.venv` — the first launch prompts to run `backend-setup.bat`
  automatically (see the note in Quick Start above) if it's missing.
  Bundling a portable Python runtime would remove the Python-must-be-
  preinstalled requirement entirely, if that's ever worth the size cost.
- The official app icon is set at `build/icon.png` / `build/icon.ico` and
  is wired into the title bar, taskbar, favicon, sidebar logo, login
  screen, and the Windows installer. Replace those two files to rebrand.
- The installer and uninstaller wizards use branded sidebar graphics
  (`build/installer-sidebar.bmp`, `build/uninstaller-sidebar.bmp` — 164×314
  BMP, per NSIS requirements) plus the app icon as the header/taskbar icon.
  Regenerate those two BMPs to rebrand the install/uninstall screens.
