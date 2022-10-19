#$Computers = Get-Content C:\temp\server-names.txt
$computers = "CWPMW-FS1"
$Output = @()

Foreach ($Computer in $Computers)
    {
    $Output += Get-WmiObject Win32_Volume -Filter "DriveType='3'" -ComputerName $Computer | ForEach {
                    New-Object PSObject -Property @{
                    Name = $_.Name
                    Label = $_.Label
                    Computer = $Computer
                    FreeSpace_GB = ([Math]::Round($_.FreeSpace /1GB,2))
                    TotalSize_GB = ([Math]::Round($_.Capacity /1GB,2))
                    UsedSpace_GB = ([Math]::Round($_.Capacity /1GB,2)) - ([Math]::Round($_.FreeSpace /1GB,2))
                }
            }
    }

#$Output #| Export-Csv -NoTypeInformation -Path C:\temp\Space.csv
$Output | select UsedSpace_GB | measure-object -sum UsedSpace_GB
