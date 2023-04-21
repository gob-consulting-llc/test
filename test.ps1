"Start of customization script" | Add-Content -Path "C:\buildArtifacts\windows_customization.log"
$PSScriptRoot | Add-Content -Path "C:\buildArtifacts\windows_customization.log"

#
# Start Metric Beats
#
$Response = Invoke-RestMethod -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -Method GET -Headers @{Metadata = "true" }
$KeyVaultToken = $Response.access_token
$secret_response = Invoke-RestMethod -Uri ${elastic_enrollment_token_url}?api-version=2016-10-01 -Method GET -Headers @{Authorization = "Bearer $KeyVaultToken" }
$secret = echo $secret_response.value
#.\elastic-agent.exe install --non-interactive --url=${elastic_url} --enrollment-token=$secret

if (Compare-Object "${storage_account_name}" "default") {
    #
    # Mount Shared File System
    #
    "Mounting a shared file system" | Add-Content -Path "C:\buildArtifacts\windows_customization.log"
    $connectTestResult = Test-NetConnection -ComputerName ${storage_account_name}.file.core.windows.net -Port 445

    if ($connectTestResult.TcpTestSucceeded) {
        $secret_response = Invoke-RestMethod -Uri ${shared_file_system_access_key_url}?api-version=2016-10-01 -Method GET -Headers @{Authorization = "Bearer $KeyVaultToken" }
        $secret = echo $secret_response.value
        # Save the password so the drive will persist on reboot
        cmd.exe /C "cmdkey /add:`"${storage_account_name}.file.core.windows.net`" /user:`"localhost\${storage_account_name}`" /pass:`"$secret`""
        # Mount the drive
        New-PSDrive -Name Z -PSProvider FileSystem -Root "\\${storage_account_url_trimmed}" -Scope Global -Persist
    }
    else {
        "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port." | Add-Content -Path "C:\windows_setup.log"
    }
}
else {
    "Not mounting a shared file system" | Add-Content -Path "C:\buildArtifacts\windows_customization.log"
}
"End of customization script" | Add-Content -Path "C:\buildArtifacts\windows_customization.log" 