# 🛠️ SQL Server .BAK Restore Script for Docker

A bash script that automatically restores a `.BAK` file into a SQL Server Docker container using `sqlcmd`.  
Perfect for developers, testers, and DevOps engineers who need to quickly restore backups into local SQL Server environments.

---

## 🚀 Features

- ✅ Automatically copies the `.BAK` file into your Docker container
- ✅ Reads logical file names from the backup
- ✅ Restores database with `WITH MOVE` to default paths
- ✅ Password-masked display
- ✅ Clear CLI output with emojis & debug mode
- ✅ Safe to run multiple times (uses `REPLACE`)
- ✅ Supports macOS and Linux environments

---

## 📦 Requirements

- Docker (running a SQL Server container)
- `sqlcmd` command-line tool
- Bash shell (macOS or Linux)

---

## 🧪 Tested On

- macOS Sonoma
- SQL Server 2022 Developer Edition (Docker image: `mcr.microsoft.com/mssql/server:2022-latest`)
- `sqlcmd` (installed via Homebrew)

---

## 🔧 Installation

Clone the repository and give execute permissions:

```bash
git clone https://github.com/YOUR_USERNAME/sqlserver-bak-restore-script.git
cd sqlserver-bak-restore-script
chmod +x restore_bak.sh
