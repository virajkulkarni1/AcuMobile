# AcuMobile

AcuMobile pre-heats or pre-cools your car on your real schedule—different times each day, not fixed timers. Connect vehicles via Smartcar (Tesla, Mercedes-Benz, and more), add departure plans, and the app starts climate ahead of each leave time. Trigger it manually or pause automation anytime.

---

This application is a **cross-brand “smart climate scheduler”** for vehicles. It lets users automatically pre-heat or pre-cool their car based on **real schedules** (not just static daily timers), including varying times across the week and event-driven triggers. The goal is to make vehicle comfort automation work like a modern calendar: if you leave at 5 PM on Tuesday, 8 PM on Wednesday, and 3 PM on Friday, the car climate adapts accordingly.

The app uses the **Smartcar API** as a unified integration layer to securely connect to supported vehicles across multiple manufacturers (e.g., Tesla, Mercedes-Benz, and other Smartcar-compatible brands). Instead of building separate integrations for each OEM, the application relies on Smartcar’s standardized endpoints and OAuth flow to read vehicle data and send remote commands when supported by the vehicle and brand.

---

## Core Capabilities

- **Dynamic scheduling (calendar-aware):** Automatically triggers cabin preconditioning based on the user’s schedule, rather than fixed repeating timers.
- **Multi-vehicle support:** Users can connect one or more vehicles through Smartcar and select which vehicle to automate.
- **Remote climate control (when supported):** Starts heating/cooling ahead of departure, optionally using user preferences (temperature, seat heat, defrost presets) when the vehicle exposes those controls.
- **Rules + safety checks:** Prevents commands when the vehicle is in an incompatible state (e.g., low battery thresholds for EVs, vehicle offline), and avoids excessive triggers.
- **User-controlled automation:** Users can pause automation, override settings anytime, and manually trigger climate control directly from the app.

---

## How It Works (High Level)

1. **Connect Vehicle:** The user authenticates via Smartcar (OAuth) and grants permissions for their vehicle.
2. **Schedule Source:** The app pulls upcoming departures from the user’s schedule (e.g., Google Calendar or custom “departure plans” created in-app).
3. **Trigger Engine:** A scheduler determines when to start preconditioning based on the next departure time (and optionally lead time rules like “start 15 minutes before”).
4. **Command Dispatch:** At runtime, the app calls Smartcar endpoints to send remote commands (when available for that vehicle/brand) and logs the outcome for transparency.

This project is designed to be **extensible:** as Smartcar adds support for more brands and capabilities, the same automation engine can immediately benefit those vehicles without major changes.

---

## Setup

1. **Smartcar:** Create an app at [dashboard.smartcar.com](https://dashboard.smartcar.com) and note your **Client ID**. In the app, set it in **Settings → Smartcar Client ID** (or via `SMARTCAR_CLIENT_ID` env / UserDefaults key `smartcar_client_id`).

2. **Redirect URI:** Add a redirect URI in the Smartcar Dashboard in the form `sc{YOUR_CLIENT_ID}://exchange`. In Xcode, add a **URL Type** for the AcuMobile target: set **URL Scheme** to `sc{YOUR_CLIENT_ID}` (no `://exchange`), and **Identifier** to e.g. `smartcar`, so the app can receive the OAuth callback.

3. **Backend:** The app does not hold access tokens; it sends the authorization code to your backend. Set **Settings → Backend URL** (or `ACU_BACKEND_URL` / `backend_base_url`) to your server. The backend must:
   - `GET /exchange?code=...` — exchange the code for Smartcar access/refresh tokens and store them (return optional `{ "vehicles": [...] }`).
   - `GET /vehicles` — return `{ "vehicles": [ { "id", "make", "model", "year", "vin" } ] }`.
   - `POST /vehicles/:id/climate` — body `{ "action": "START"|"STOP"|"SET", "temperature"?: number }`; proxy to Smartcar `POST /v2.0/vehicles/:id/:make/climate/cabin`.

4. **Departure plans** are stored locally; optional backend endpoints `GET/POST/DELETE /departure_plans` can be added to sync.
