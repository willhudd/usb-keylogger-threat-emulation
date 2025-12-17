<p align="center">
  <img src="assets/banner.png" alt="Red Team USB HID Attack" width="100%">
</p>

# USB HID Attack Simulation (Pico-Ducky)

### Red Team Tradecraft & Blue Team Detection Research

> ⚠️ **AUTHORIZED USE ONLY**
>
> This project is for **educational, research, and authorized security testing** purposes only.
> Do NOT use this project on systems you do not own or do not have explicit written permission to test.
>
> This repository is part of a **Red Team vs Blue Team portfolio**, paired with a custom Endpoint Detection & Response (EDR) system designed to detect this attack.

---

## 🔗 External Dependencies

This project uses the **Pico-Ducky framework** by **dbisu**:

- https://github.com/dbisu/pico-ducky

> Pico-Ducky is licensed under **GPL-2.0**  
> This repository does **not** redistribute Pico-Ducky source code.

---

## 📌 Project Purpose

This repository demonstrates a **realistic USB HID (BadUSB) attack simulation** using a Raspberry Pi Pico configured with the **Pico-Ducky framework**.

The goal is **not exploitation**, but:

- Understanding how HID-based attacks work
- Demonstrating how attackers achieve initial execution
- Providing a **controlled test case** for defensive detection
- Validating the effectiveness of a **custom-built EDR**

---

## 🔴 Red Team Perspective (This Repo)

This project simulates:

- A malicious USB device emulating a keyboard (HID)
- Automated payload delivery to a Windows system
- A PowerShell-based keystroke logging script
- Common persistence techniques observed in real-world malware
- Outbound data exfiltration

> All techniques are intentionally **well-known** to ensure they are detectable by modern security tooling.

---

## 🔵 Blue Team Perspective (Companion Project)

👉 **EDR Repository:**  
_(Link this once published)_
`endpoint-threat-detection-rust`

The EDR focuses on:

- PowerShell abuse indicators
- Persistence mechanism monitoring
- Behavioral correlation instead of signature-only detection

---

## 🧠 High-Level Attack Flow

1. USB device enumerates as a keyboard (HID)
2. Predefined keystrokes execute a PowerShell payload
3. PowerShell captures keystrokes using Windows APIs
4. Data is temporarily logged locally
5. Data is transmitted externally (lab-controlled)
6. Persistence ensures execution across reboots

---

## 🛡️ Detection & Defense Notes

Defenders should look for:

- New USB HID devices appearing unexpectedly
- PowerShell launched with hidden windows
- PowerShell scripts interacting with `user32.dll`
- Registry autorun persistence in user context
- Unusual outbound webhook or HTTPS traffic
- Execution shortly after USB insertion

These indicators are **explicitly targeted** by the companion EDR.

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
