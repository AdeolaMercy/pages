param(
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$true)]
    [string]$SafeModeAdminPassword
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
