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
git clone https://github.com/EfekanAlpsa/docker-restore.git
cd docker-restore
chmod +x restore_bak.sh
```

---

## 📥 Usage

```bash
./restore_bak.sh </path/to/your.bak> <container_id> <sa_password>
```

---

## 🧾 Example:

```bash
./restore_bak.sh ~/Desktop/TESTDATA1.BAK 68728237392 'YourStrong!Pass123'
```

---

## 🧠 How It Works

1 - Verifies that Docker and sqlcmd are installed.

2 - Copies the .BAK file into the container under /var/opt/mssql/backup/.

3 - Reads logical file names using RESTORE FILELISTONLY.

4 - Restores the database to /var/opt/mssql/data/ using WITH MOVE.

5 - Shows success or error messages clearly.

---

## 🔐 Security Note

The password is masked during display, but passed in plain text via command-line arguments.
Avoid using this in production environments without modifications.

---

## Troubleshooting

❌ "Exclusive access could not be obtained": Another process is using the database. Make sure it's not in use.

❌ "Could not get logical names": The .BAK file might be corrupted or incompatible with the SQL Server version.

---

## 🤝 Contributions

Pull requests are welcome!
If you find a bug or want to suggest a feature, open an issue.


Made by Efekan Alipasha.
