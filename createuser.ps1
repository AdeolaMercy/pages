param(
    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$Password
)

Import-Module ActiveDirectory

# Convert password
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Check if user already exists
if (Get-ADUser -Filter { SamAccountName -eq $Username } -ErrorAction SilentlyContinue) {
    Write-Output "User $Username already exists in domain."
} else {
    New-ADUser `
        -Name $Username `
        -SamAccountName $Username `
        -AccountPassword $SecurePassword `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -Path "CN=Users,DC=corp,DC=local"

    Write-Output "Domain user $Username created successfully."
}
