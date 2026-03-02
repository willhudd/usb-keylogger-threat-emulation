<p align="center">
  <img src="assets/banner.png" alt="Red Team Banner" width="100%">
</p>

# USB HID Attack Simulation (Pico-Ducky)

> ⚠️ **AUTHORIZED USE ONLY**
>
> This project is for **educational, research, and authorized security testing** purposes only.
> Do NOT use this project on systems you do not own or do not have explicit written permission to test.
>
> This repository is part of a **Red Team vs Blue Team portfolio**, paired with a custom Endpoint Detection & Response (EDR) system designed to detect this attack.

---

## 🔗 External Dependencies

This project uses the **Pico-Ducky framework** by user **dbisu**:

- https://github.com/dbisu/pico-ducky

> Pico-Ducky is licensed under **GPL-2.0**  
> This repository does not redistribute Pico-Ducky source code.

---

## 📌 Project Purpose

This repository demonstrates a **realistic USB HID attack simulation** using a Raspberry Pi Pico configured with the **Pico-Ducky framework**.

The goal is not exploitation, but:

- Understanding how HID-based attacks work
- Providing a controlled test case for defensive detection
- Validating the effectiveness of a custom-built EDR

---

## 🔴🗡️ Red Team Perspective (This Repo)

Attack flow:

1. USB device enumerates as a keyboard
2. Predefined keystrokes execute a PowerShell payload
3. PowerShell captures keystrokes using Windows APIs
4. Data is temporarily logged locally
5. Data is exfiltrated
6. Persistence ensures execution across reboots

> All techniques are intentionally well-known to ensure they are detectable by modern security tooling.

---

## 🔵🛡️ Blue Team Perspective (Companion Project)

👉 **EDR Repository:**  [endpoint-threat-detection-rust](https://github.com/willhudd/endpoint-threat-detection-rust)

The EDR focuses on:

- PowerShell abuse indicators
- Behavioral correlation instead of signature-only detection

Defenders should look for:

- PowerShell scripts interacting with `user32.dll`
- Registry autorun persistence in user context
- Unusual outbound webhook or HTTPS traffic
- Execution shortly after USB insertion

These indicators are explicitly targeted by the companion EDR.

---

## ⚖️ Legal & Ethical Notice

This project exists to:

- Improve defensive security
- Train detection engineering skills
- Demonstrate real-world attack tradecraft responsibly

Misuse of this code may violate:

- Computer Misuse Acts
- Privacy laws
- Organizational security policies

**You are solely responsible for how this code is used.**

---

## 📜 License

This repository contains **original code** and is released under the **MIT License**  
(External dependencies retain their original licenses.)
