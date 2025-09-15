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

    $SecurePassword = ConvertTo-SecureString $DomainUserPassword -AsPlainText -Force

		New-ADUser `
            -Name $DomainUser `
            -SamAccountName $DomainUser `
            -AccountPassword $SecurePassword `
	    	-Enabled $true `
            -PasswordNeverExpires $true `

        Write-Output "Domain user $DomainUser created successfully."
    }
}

