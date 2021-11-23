C:\windows\Microsoft.NET\Framework64\v4.0.30319\InstallUtil.exe C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell.dll
Add-PSSnapin VeeamPSSnapin

Get-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server <serverFQDN>
