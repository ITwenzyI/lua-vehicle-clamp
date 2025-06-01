# 🚫 Vehicle Clamp System (`kilian_clamp`)

A custom vehicle clamp (wheel lock) system for ESX-based FiveM servers. This script allows authorized jobs (e.g. police) to apply or remove wheel clamps from vehicles based on license plates. Clamped vehicles cannot be driven and will show a visual clamp prop. Includes full Discord logging and permission control.

---

## 🔧 Features

- Apply or remove clamps via in-game menu (`/clamp`)
- Clamped vehicles cannot be driven (engine locked + movement disabled)
- Visual clamp prop appears in front of the vehicle
- Clamp state saved in database (`vehicle_clamps` table)
- Permissions restricted by job and rank (fully configurable)
- Discord logging with custom webhook
- Synchronization between all clients
- Notifications with custom messages and color

---

## 🛠 Requirements

- [ESX Legacy](https://github.com/esx-framework/esx-legacy)
- MySQL / MariaDB
- Notification system (`TriggerEvent("notifications", ...)`) or modify accordingly
- Config.lua file with:
  - `AllowedJobs`
  - `RequiredRank`
  - `ClampProp`
  - `Webhook`

## 🧑‍💻 Developer Notes

- The vehicle is blocked using FreezeEntityPosition and SetVehicleUndriveable.
- Control actions are disabled for realism.
- Clamp visuals are attached in front of the vehicle and cleaned up if unclamped.
- Everything is synced via server-client events and stored persistently.

##📄 License

MIT License – free to use, modify, and redistribute.

## 👤 Author
**Kilian**
