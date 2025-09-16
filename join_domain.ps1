param(
    [Parameter(Mandatory=$true)]
    [string]$DomainUser,

    [Parameter(Mandatory=$true)]
    [string]$DomainUserPassword
)

# Convert password to SecureString
$SecurePassword = ConvertTo-SecureString $DomainUserPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential("$DomainName\$DomainUser", $SecurePassword)

Write-Output "Joining computer to domain $DomainName ..."
Add-Computer -DomainName test.local -Credential $Credential -Force -Restart
