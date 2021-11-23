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


# Start of Settings
# List of VM to exclude (by name) separated by a comma i.e: @("vm1","vm2")
$excludevms=@()
# Number of days to check, if a VM is not backed up within this interval it will be considered as not backed up         
$DaysToCheck= 7
# End of Settings

#Don't change below here!
#Try to load VEEAM snapin, otherwise stop the process
asnp "VeeamPSSnapIn" -ErrorAction Stop 

# Build hash table with excluded VMs
$excludedvms=@{}
foreach ($vm in $excludevms) {
    $excludedvms.Add($vm, "Excluded")
}

# Get a list of all VMs from vCenter and add to hash table, assume Unprotected
$Result=@()
foreach ($vm in ($FullVM | Where { $_.Runtime.PowerState -eq "poweredOn" } | ForEach-Object {$_ | Select-object @{Name="VMname";Expression={$_.Name}}}))  {
   if (!$excludedvms.ContainsKey($vm.VMname)) {
        $vm | Add-Member -MemberType NoteProperty -Name "backed_up" -Value $False 
        $Result += $vm
    }
}

# Find all backup job sessions that have ended in the last week
$vbrsessions = Get-VBRBackupSession | Where-Object {$_.JobType -eq "Backup" -or $_.JobType -eq "Replica" -and $_.EndTime -ge (Get-Date).adddays(-$DaysToCheck)}

# Find all successfully backed up VMs in selected sessions (i.e. VMs not ending in failure) and update status to "Protected"
foreach ($session in $vbrsessions) {
    foreach ($vm in ($session.gettasksessions() | Where-Object {$_.Status -ne "Failed"} | ForEach-Object { $_ | Select-object @{Name="VMname";Expression={$_.Name}}})) {
		$VMObj = $Result | where {$_.VMName -eq $vm.VMname }
		if ($VMObj){
			$VMObj.backed_up = $true
		}
    }
}

$Result | where {$_.backed_up -eq $false}
$Title = "Running VMs that were not backed up in the last $DaysToCheck day(s)"
$Header =  "Running VMs that were not backed up in the last $DaysToCheck day(s)"
$Comments = "The following VMs were not backed up in the last $DaysToCheck day(s). They are probably not in a backup job or were in a failure state"
$Display = "Table"
$Author = "Geoffroi Genot"
$PluginVersion = 1.0
$PluginCategory = "VEEAM"