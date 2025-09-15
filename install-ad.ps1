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

# After reboot, create a domain user
$scriptBlock = {
    param($DomainUser, $DomainUserPassword)

    Import-Module ActiveDirectory

    $SecurePassword = ConvertTo-SecureString $DomainUserPassword -AsPlainText -Force

    if (Get-ADUser -Filter { SamAccountName -eq $DomainUser } -ErrorAction SilentlyContinue) {
        Write-Output "User $DomainUser already exists."
    } else {
        New-ADUser `
            -Name $DomainUser `
            -SamAccountName $DomainUser `
            -AccountPassword $SecurePassword `
	    -Enabled $true `
            -PasswordNeverExpires $true `
            -Path "CN=Users,DC=test,DC=local"

        Write-Output "Domain user $DomainUser created successfully."
    }
}

# Schedule domain user creation after reboot
$TaskName = "CreateDomainUser"
$Action   = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"& { & $using:scriptBlock -DomainUser '$DomainUser' -DomainUserPassword '$DomainUserPassword' }`""
$Trigger  = New-ScheduledTaskTrigger -AtStartup -Once
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -RunLevel Highest -Force
