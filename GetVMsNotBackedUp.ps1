<#	
	.NOTES
	===========================================================================
	 Created on:   	11/17/2021
	 Created by:    Noah Huotari
	 Organization: 	HBS
	 Filename:     	GetVMsNotBackedUp.ps1
	===========================================================================
	.DESCRIPTION
    
    Verify if all Virtual Machines have been backed up
 
#>

# Load Plugin and module
#Need to add checking here to install if not already
Import-Module Veeam.Backup.PowerShell
Import-Module VMware.VimAutomation.Core

# Configure for multiple vCenter Connections
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

#Need to check for blocklist.txt file, if not create it

# Connect to local B&R Server
Connect-VBRServer -Server localhost

# Read Credential-File
#Need to add checking here to see if folder is there already
$WorkingDir = "C:\hbs\veeam_script\"

# Connect to vCenter servers, added to B&R server
Get-VBRServer | Where-Object {$_.Type -eq "VC" -or $_.Type -eq "ESXi"} | ForEach-Object {
    Connect-VIServer $_.name -Credential (Get-Credential) -ErrorAction Continue
}

# Read VMs in blocklist
$Blocklist = Get-Content -path ($WorkingDir + "Blocklist.txt") -ErrorAction SilentlyContinue | ForEach-Object {$_.TrimEnd()} 

# Read all VMs
$VMs = Get-VM | Select-Object Name, MemoryGB, PowerState, VMHost, Folder

# Query Veeam Restore Points
$result = @()
$VbrRestore = Get-VBRBackup | Where-Object {$_.jobtype -eq "Backup"} | ForEach-Object {$Jobname = $_.jobname; Write-Output $_;} | Get-VBRRestorePoint | Select-Object vmname, @{n="Jobname"; e={$Jobname}} |Group-Object vmname
$VbrRestore = $VbrRestore | ForEach-Object {$_.Group | Select-Object -first 1}

# Check, if VM on blocklist and a restore point exists
$VMs | ForEach-Object {
    if (($_.name -notin $Blocklist) -and ($_.name -notin $VbrRestore.vmname)) {
        $result += $_
    }
}
$result  | Format-Table -AutoSize

# Close connections
Disconnect-VIServer * -Confirm:$false
Disconnect-VBRServer