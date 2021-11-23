<#	
	.NOTES
	===========================================================================
	 Created on:   	11/23/2021
	 Created by:    Noah Huotari
	 Organization: 	HBS
	 Filename:     	GetVMsNotBackedUp.ps1
	===========================================================================
	.DESCRIPTION
    
    Verify if all Virtual Machines have been backed up
 
#>

# Load Plugin and module
#Need to add checking here to install if not already
# Install-Module VMware.VimAutomation.Core
# Install-Module Veeam.Backup.PowerShell
Import-Module Veeam.Backup.PowerShell
Import-Module VMware.VimAutomation.Core

# Configure PowerCLI for multiple vCenter Connections
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Scope Session -Confirm:$false
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false

# Connect to local B&R Server
Connect-VBRServer -Server localhost

# Create folder if not already
$WorkingDir = "C:\hbs\veeam_script"
if (Test-Path -Path $WorkingDir) {
} else {
    New-Item -ItemType "directory" -Path $WorkingDir
}

# Connect to vCenter servers, added to B&R server
Get-VBRServer | Where-Object {$_.Type -eq "VC" -or $_.Type -eq "ESXi"} | ForEach-Object {
    Connect-VIServer $_.name -Credential (Get-Credential) -ErrorAction Continue
}

# Read VMs in blocklist
if (Test-Path -Path ($WorkingDir + "\Blocklist.txt")) {
} else {
    New-Item -ItemType "file" -Path ($WorkingDir + "\Blocklist.txt")
}
$Blocklist = Get-Content -path ($WorkingDir + "Blocklist.txt") -ErrorAction SilentlyContinue | ForEach-Object {$_.TrimEnd()} 

# Get all VMs
$VMs = Get-VM | Select-Object Name, MemoryGB, PowerState, VMHost, Folder

# Get Veeam Restore Points
$result = @()
$VbrRestore = Get-VBRBackup | Where-Object {$_.jobtype -eq "Backup"} | ForEach-Object {$Jobname = $_.jobname; Write-Output $_;} | Get-VBRRestorePoint | Select-Object vmname, @{n="Jobname"; e={$Jobname}} |Group-Object vmname
$VbrRestore = $VbrRestore | ForEach-Object {$_.Group | Select-Object -first 1}

# Check for a restore point, if not in the blocklist.txt file
$VMs | ForEach-Object {
    if (($_.name -notin $Blocklist) -and ($_.name -notin $VbrRestore.vmname)) {
        $result += $_
    }
}
$result  | Format-Table -AutoSize

# Create log file
$outPath = $WorkingDir+"\"+"VMs_Not_BackedUp_"+(Get-Date).tostring("dd-MM-yyyy-hh-mm")+".csv"
$result | Export-Csv $outPath -NoTypeInformation

# Close connections
Disconnect-VIServer * -Confirm:$false
Disconnect-VBRServer