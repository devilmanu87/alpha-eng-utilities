$clientId = $args[0]
$clientSecret = $args[1]
$tenantId = $args[2]
$tempPassword = ConvertTo-SecureString "$clientSecret" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($clientId ,
$tempPassword)

Write-Host "Connect to AZ Account using SPN"
Connect-AzAccount -Credential $psCred -TenantId $tenantId  -ServicePrincipal

Write-Host "Copying Azure Key Vault Secrets from source to dest."

$secrets = (Get-AzKeyVaultSecret -VaultName "agrid-06-e1-hub-kv-001")
$keys = (Get-AzKeyVaultKey -VaultName "agrid-06-e1-hub-kv-001")

foreach ($secret in $secrets) {

    $name = $secret.Name
    $expires = $secret.Expires
    $nbf = $secret.NotBefore
    $type = $secret.ContentType
    $tag = $secret.Tags

    $secretText = (Get-AzKeyVaultSecret -VaultName "agrid-07-e1-hub-kv-001" -Name $name -AsPlainText)

    if ( [string]::IsNullOrEmpty($secretText) ) {
        Set-AzKeyVaultSecret -VaultName "agrid-07-e1-hub-kv-001" -Name $name -SecretValue (Get-AzKeyVaultSecret -VaultName "agrid-06-e1-hub-kv-001" -Name $name).SecretValue -Expires $expires -NotBefore $nbf -ContentType $type -Tags $tag
    }

}

foreach ($key in $keys) {

    $name = $key.Name
    $created = $key.Created
    $updated = $key.Updated
    $type = (Get-AzKeyVaultKey -VaultName "agrid-06-e1-hub-kv-001" -KeyName "$name").KeyType
    $size = (Get-AzKeyVaultKey -VaultName "agrid-06-e1-hub-kv-001" -	 "$name").KeySize
    $nbf = $key.NotBefore
    $expires = $key.Expires
    $tag = $key.Tags

    Add-AzKeyVaultKey -VaultName 'agrid-07-e1-hub-kv-001' -Destination 'Software' -Name $name -Expires $expires -NotBefore $nbf -Tag $Tags -Size $size -KeyType $type
}
