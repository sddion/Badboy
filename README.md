# Bad USB - Reconnaissance PowerShell Script


<div align="center">
  <img height="150" src="https://media1.giphy.com/media/eq0QfBoBObV4WFg1lK/giphy.gif?cid=ecf05e47ab6v296ro5brtrcjf8a9pur7vn9nyex6ld52tyo5&ep=v1_gifs_search&rid=giphy.gif&ct=g" />
</div>

###

<div align="center">
  <img src="https://img.shields.io/static/v1?message=Instagram&logo=instagram&label=&color=E4405F&logoColor=white&labelColor=&style=for-the-badge" height="25" alt="instagram logo"  />
  <img src="https://img.shields.io/static/v1?message=Tutanota&logo=tutanota&label=&color=840010&logoColor=white&labelColor=&style=for-the-badge" height="25" alt="tutanota logo"  />
  <img src="https://img.shields.io/static/v1?message=Telegram&logo=telegram&label=&color=2CA5E0&logoColor=white&labelColor=&style=for-the-badge" height="25" alt="telegram logo"  />
</div>

###

<div align="center">
  <img src="https://visitor-badge.laobi.icu/badge?page_id=d10xi24.d10xi24&"  />
</div>

---

### Overview

This PowerShell script is designed to gather system information and perform various tasks for security auditing purposes.

<div align="left">
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dot-net/dot-net-original.svg" height="40" alt="dot-net logo"  />
</div>

### Features

1. **User Information:** Gathers details like username, full name, email, and geolocation.

2. **System Information:** Retrieves data on UAC and RDP state, LSASS status, and Gathers information about the computer, BIOS, operating system, CPU, mainboard, RAM, and video card

3. **Network Information:** Provides public IP, local IP with MAC address, WiFi profiles, and nearby WiFi networks

4. **Startup Contents:** Lists items in the startup folder for potential persistence mechanisms.

5. **Scheduled Tasks:** Displays scheduled tasks on the system.

6. **Logon Sessions:** Shows active logon sessions.

7. **Recent Files:** Retrieves the 50 most recent files in the user's profile

8. **HDD Information:** Retrieves details about connected hard drives.

9. **Processes:** Displays information about running processes, listeners, services, software, drivers, and video cards

10. **Browser Data:** Gathers history and bookmarks from Google Chrome, Microsoft Edge, and Mozilla Firefox.

**Automatically runs upon inserting a USB drive**

### Prerequisites

- Windows environment

- PowerShell execution policy set to allow script execution

### Usage

1. Insert the USB drive
2. The script creates a loot folder, gathers information, and generates a zip file.
3. Autorun deletes the temporary files on the local system and Data is saved in the USB drive.
4. A popup message signals the completion of the payload. 

### Script Execution

To run the script manually, use the following command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File (F:/path/to/file/)Badusb.ps1
```

or just 

```powershell
powershell.exe (F:/path/to/file/)Badusb.ps1 
```

If you find my work helpful or enjoyable, consider supporting me with a cup of coffee! ☕

[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-%E2%98%95-yellow)](https://www.buymeacoffee.com/d10xi24)


### NEW UPDATES GOES HERE :

1. Browser Password Extraction: Included functionality to extract saved passwords from popular browsers (Chrome, Firefox, Edge).

2. Installation of SQLite: The script now checks for SQLite's presence. If not found, it automatically installs SQLite to ensure seamless password extraction

3. User Registry Information: Gathers relevant information from the user's registry (UAC , Firewall , NetworkInfo , CurrentUserInfo)

### IMPORTANT NOTES :

1. Zip File and SQL URL Update: Before using the script, ensure to update the zip file name and the SQLite URL with the latest information from https://sqlite.org/index.html. This guarantees that you're using the most up-to-date resources

2. The loot file is moved to a specified destination (replace 'F:\' with your pendrive's drive letter (line 779)).