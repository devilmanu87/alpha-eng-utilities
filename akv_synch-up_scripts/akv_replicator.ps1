param
(
    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

write-output "start"
write-output ("object type: {0}" -f $WebhookData.gettype())
write-output $WebhookData
$Payload = $WebhookData
write-output "`n`n"
write-output $Payload.WebhookName
write-output $Payload.RequestBody
write-output $Payload.RequestHeader
write-output "end"

if ($Payload.RequestBody) { 
    $eventData = (ConvertFrom-Json -InputObject $Payload.RequestBody) | ForEach-Object { $_.data } | ConvertTo-Json
	$eventName = (ConvertFrom-Json -InputObject $eventData) | ForEach-Object { $_.ObjectName } 
	$eventType = (ConvertFrom-Json -InputObject $eventData) | ForEach-Object { $_.ObjectType } 
	$vaultName = (ConvertFrom-Json -InputObject $eventData) | ForEach-Object { $_.VaultName }     
}
else {
    Write-Output "Empty Event!"
}

write-output "Event Triggered for: $eventName - type: $eventType - vault name: $vaultName"

if($vaultName -eq 'cpe-dr-kv-eng-001-eus2') {
	$destVaultName = 'cpe-dr-kv-001-cus'
	write-output "Destination Vault: $destVaultName"
}

if($vaultName -eq 'test-dr-kv-eng-001-eus2') {
	$destVaultName = 'test-dr-kv-eng-001-cus'
	write-output "Destination Vault: $destVaultName"
}

if($vaultName -eq 'agrid-06-p1-hub-kv-001') {
	$destVaultName = 'agrid-07-p1-hub-kv-001'
	write-output "Destination Vault: $destVaultName"
}

try
{
    write-output "Logging in to Azure using Managed Identity..."
    
	$connectionResult = Connect-AzAccount -Identity						
    
	write-output "Logged in!!!"

}
catch {
    if (!$connectionResult)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

if ($eventType -eq 'Key') {

	Write-Host "Copying Azure Key Vault Keys from source to dest..."

	$key = (Get-AzKeyVaultKey -VaultName $vaultName -KeyName $eventName)

    $name = $key.Name
    $created = $key.Created
    $updated = $key.Updated
    $type = (Get-AzKeyVaultKey -VaultName $vaultName -KeyName "$name").KeyType
    $size = (Get-AzKeyVaultKey -VaultName $vaultName -KeyName "$name").KeySize
    $nbf = $key.NotBefore
    $expires = $key.Expires
    $tag = $key.Tags

    Add-AzKeyVaultKey -VaultName $destVaultName -Destination 'Software' -Name $name -Expires $expires -NotBefore $nbf -Tag $Tags -Size $size -KeyType $type
}

if ($eventType -eq 'Secret') {

	Write-Host "Copying Azure Key Vault Secrets from source to dest..."

	$secret = (Get-AzKeyVaultSecret -VaultName $vaultName -Name $eventName)
    
	$name = $secret.Name
    $expires = $secret.Expires
	$nbf = $secret.NotBefore
    $type = $secret.ContentType
	$tag = $secret.Tags

    Set-AzKeyVaultSecret -VaultName $destVaultName -Name $name -SecretValue (Get-AzKeyVaultSecret -VaultName $vaultName -Name $name).SecretValue -Expires $expires -NotBefore $nbf -ContentType $type -Tags $tag

}
