# Discord Webhook WGSM Messenger (PowerShell)

A PowerShell automation script that sends **timed message sequences** to a Discord channel using a webhook.  
Designed to run manually or automatically via **Windows Task Scheduler**, making it ideal for scheduled maintenance notifications or command-style messaging workflows.

---

## ✨ Features

- 📢 Sends multiple Discord messages via webhook
- ⏱️ Supports configurable delays between messages
- 🔁 Built-in retry logic for failed webhook calls
- 🕒 Includes a timed countdown before start messages
- ⚙️ Designed for **Windows Task Scheduler automation**
- 🔒 Uses placeholders for safe public sharing

---

## 🧠 What This Script Does

This script sends **three message sequences** to a Discord channel:

1. A **Stop** message series
2. An **Update** message series
3. A **Start** message series after a timed delay

Each message is sent individually with configurable delays to avoid rate limits and ensure reliability.

> ⚠️ This script only sends messages to Discord.  
> It does **not** directly control WindowsGSM or game servers.

---

## 🔧 Requirements

- Windows 10 / Windows Server 2016 or newer
- PowerShell 5.1 or newer
- A Discord server where you can create a webhook
- Internet access to `discord.com`

---

## ⚙️ Configuration

Open the PowerShell script and configure the following values:

### Discord Webhook URL
```powershell
$webhookUrl = "YOUR_WEBHOOK_URL_HERE"
```

### Bot Display Name
```powershell
$webhookUsername = "BOTNAMEHERE"
```

### Avatar Image (Optional)
Leave blank to avoid image links:
```powershell
$avatarImageUrl = ""
```

---

## 🧩 Message Flow

### 🛑 Stop Series
- Messages: `wgsm stop 1` → `wgsm stop 11`
- Delay: **5 seconds** between each message

### 🔄 Update Series
- Messages: `wgsm update 1` → `wgsm update 11`
- Delay: **30 seconds** between each message

### ▶️ Start Series
1. Waits **5 minutes** with a live countdown
2. Sends `wgsm start 1`
3. Sends `wgsm start 2` → `wgsm start 11`
4. Delay: **5 seconds** between messages

---

## 🕒 Automate with Windows Task Scheduler

1. Open **Task Scheduler**
2. Click **Create Task**
3. **General Tab**
   - Name: `Discord WGSM Messenger`
   - Run whether user is logged on or not
   - Run with highest privileges
4. **Triggers Tab**
   - Daily / Weekly / At startup
5. **Actions Tab**
   - Program: `powershell.exe`
   - Arguments:
     ```
     -ExecutionPolicy Bypass -File "C:\Path\To\Your\Script\DiscordWgsmMessenger.ps1"
     ```
6. Click **OK**

---

## ⚠️ Important Notes

- Keep your webhook URL private
- The script retries failed messages up to 5 times
- Delays help prevent Discord rate limiting
- Test manually before scheduling
- This script does not control servers directly
