# Windows Storage Rebalance Toolkit

A practical toolkit for diagnosing C: drive space usage and safely relocating selected large user-data folders to another drive using robocopy and Windows junctions.

## 日本語要約

Cドライブ容量不足の原因を調べ、Dドライブなどへ安全に一部データを移動するための実用ツールキットです。

## What this toolkit is for

This toolkit is for common Windows PC situations such as:

* C: drive is almost full.
* D: drive or another internal/external drive has enough free space.
* Large user data exists under Documents, AppData, or application-specific folders.
* The application expects the original path to remain unchanged.
* You want a safer process than simply cutting and pasting folders.

The toolkit focuses on:

1. Scanning large folders.
2. Identifying likely candidates for cleanup or relocation.
3. Copying data with robocopy.
4. Verifying copied file counts.
5. Renaming the original folder as a backup.
6. Creating a Windows junction from the original path to the new path.
7. Keeping rollback possible until the user confirms everything works.

## What this toolkit does not do

This is not a magic "free up C: drive automatically" tool.

It does not automatically move:

```
C:\Windows
C:\Program Files
C:\Program Files (x86)
C:\ProgramData
C:\Users\<user>\AppData
C:\Users\<user>\AppData\Local
C:\Users\<user>\AppData\Roaming
```

Move only selected folders that you understand.

## Common good candidates

Typical relocation candidates include:

* Kindle content folder
* Apple MobileSync local iPhone/iPad backups
* Large application-specific cache or backup folders
* User-created project or archive folders

Examples:

```
C:\Users\hoge\Documents\My Kindle Content
D:\Documents\My Kindle Content

C:\Users\hoge\AppData\Roaming\Apple Computer\MobileSync\Backup
D:\AppleMobileSync\Backup
```

## Common unsafe candidates

Avoid moving these manually:

```
C:\Windows
C:\Program Files
C:\Program Files (x86)
C:\ProgramData
C:\Users\hoge\AppData
C:\Users\hoge\AppData\Local\Microsoft
C:\Users\hoge\AppData\Local\Packages
C:\Users\hoge\AppData\Local\Programs
```

For WSL distributions, prefer official export/import migration rather than junction-based relocation.

## Basic workflow

```
1. Scan disk usage.
2. Identify a large, application-specific folder.
3. Close the related application.
4. Copy the folder to another drive with robocopy.
5. Verify file counts.
6. Rename the original folder to *_backup_YYYYMMDD.
7. Create a junction at the original path.
8. Test the application.
9. Delete the backup later only after confirming everything works.
```

## Quick start

Scan the C: drive:

```
.\scripts\scan_drive.ps1 -Path C:\
```

Scan a user profile:

```
.\scripts\scan_folder.ps1 -Path "C:\Users\hoge"
```

Scan AppData:

```
.\scripts\scan_folder.ps1 -Path "C:\Users\hoge\AppData"
```

Move a selected folder with a junction:

```
.\scripts\move_folder_with_junction.ps1 `
  -Source "C:\Users\hoge\Documents\My Kindle Content" `
  -Target "D:\Documents\My Kindle Content"
```

Apple MobileSync backup example:

```
.\scripts\move_folder_with_junction.ps1 `
  -Source "C:\Users\hoge\AppData\Roaming\Apple Computer\MobileSync\Backup" `
  -Target "D:\AppleMobileSync\Backup"
```

Find large individual files under a selected folder:

```
    .\scripts\scan_files.ps1 -Path "C:\Users\hoge\AppData" -Top 30 -MinimumSizeMB 100
```

## Example: Kindle content

Source:

```
C:\Users\hoge\Documents\My Kindle Content
```

Target:

```
D:\Documents\My Kindle Content
```

This is a relatively simple case because Kindle content is user data and the original path can usually be preserved with a junction.

## Example: Apple MobileSync backup

Source:

```
C:\Users\hoge\AppData\Roaming\Apple Computer\MobileSync\Backup
```

Target:

```
D:\AppleMobileSync\Backup
```

This folder may contain local iPhone or iPad backups. It can grow to tens of GB.

Before moving this folder, close Apple-related applications such as:

* iTunes
* Apple Devices
* iCloud
* Any active backup or sync window

If local device backups are not needed, deleting old backups may be enough. If you want to keep them, moving the folder and creating a junction is a safer option.

## Safety model

This toolkit is intentionally conservative.

It copies first, verifies, renames the original folder, creates a junction, and leaves the old folder as a backup.

It does not delete the backup automatically.

## Why junctions are used

Some Windows applications expect data to remain at a fixed path. A junction allows the original path to continue working while the actual data is stored on another drive.

Example:

```
Original path:
C:\Users\hoge\AppData\Roaming\Apple Computer\MobileSync\Backup

Actual data location:
D:\AppleMobileSync\Backup
```

The application can continue using the original path, while the data is physically stored on D:.

## Suggested cleanup targets

These are often safe to inspect:

* Recycle Bin
* Temporary files
* Old installer files
* Old application logs
* Old local device backups

These require more caution:

* WSL distributions
* Browser profiles
* Mail client data
* Microsoft Store application data
* Development tool caches

## WSL note

WSL can consume a large amount of disk space, but it should not be moved by simply copying the folder and creating a junction.

Use the official export/import workflow instead:

```
wsl --shutdown
wsl --export Ubuntu-24.04 D:\WSL\backup\Ubuntu-24.04.tar
wsl --unregister Ubuntu-24.04
wsl --import Ubuntu-24.04 D:\WSL\Ubuntu-24.04 D:\WSL\backup\Ubuntu-24.04.tar --version 2
```

This should be done carefully and only when there is enough time to test the environment afterward.

## Recommended repository structure

```
windows-storage-rebalance-toolkit/
├── README.md
├── scripts/
│   ├── scan_drive.ps1
│   ├── scan_folder.ps1
│   ├── count_files.ps1
│   ├── scan_files.ps1
│   └── move_folder_with_junction.ps1
├── docs/
│   ├── safety-policy.md
│   ├── common-large-folders.md
│   ├── kindle-content-move.md
│   ├── apple-mobilesync-backup-move.md
│   ├── wsl-migration-notes.md
│   └── cleanup-checklist.md
├── examples/
│   ├── sample_paths.md
│   ├── sample_scan_report.txt
│   ├── sample_appdata_report.txt
│   └── sample_roaming_report.txt
├── .gitignore
└── LICENSE
```

## Disclaimer

Use this toolkit at your own risk.

Always confirm what a folder contains before moving or deleting it. Keep backups until the related application has been tested.

## License

MIT
