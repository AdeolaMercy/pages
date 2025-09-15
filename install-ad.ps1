param(
    [string]$DomainName,
    [string]$SafeModeAdminPassword,
    [string]$DomainUser,
    [string]$DomainUserPassword
)

# Convert plain text password to secure string
$SecureDSRMPassword = ConvertTo-SecureString $SafeModeAdminPassword -AsPlainText -Force

Write-Output "Installing AD DS role..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Output "Promoting server to Domain Controller for $DomainName ..."
Install-ADDSForest `
    -DomainName $DomainName `
    -SafeModeAdministratorPassword $SecureDSRMPassword `
    -DomainNetbiosName ($DomainName.Split('.')[0]) `
    -InstallDns:$true `
    -Force:$true

# Wait until domain services are fully up
Start-Sleep -Seconds 60

# Create domain user if it doesn't exist
if (-not (Get-ADUser -Filter { SamAccountName -eq '$DomainUser' } -ErrorAction SilentlyContinue)) {
    New-ADUser -Name "$DomainUser" -SamAccountName "$DomainUser" -AccountPassword $SecureUserPass -Enabled $true
    Add-ADGroupMember -Identity "Domain Admins" -Members "$DomainUser"
}
"@

# Save post-reboot script
$PostScriptPath = "C:\PostDomainSetup.ps1"
$PostScript | Out-File -FilePath $PostScriptPath -Encoding UTF8

# Register scheduled task to run post-reboot script
$Action  = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File $PostScriptPath"
$Trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "PostDomainSetup" -RunLevel Highest -Force

# Reboot after forest installation
Restart-Computer -Force
