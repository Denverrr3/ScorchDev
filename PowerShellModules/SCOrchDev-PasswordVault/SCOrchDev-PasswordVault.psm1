﻿<#
.Synopsis
    Returns credential objects from the local password vault

.Parameter UserName
    The name of the credential to return. Case sensative

.Parameter Resource
    The resource store this credential is stored in

.Parameter AsPSCredential
    Use this flag if you would like a PSCredential object returned. Includes the
    password of the object

.Example
    Get-PasswordVaultCredential

.Example
    Get-PasswordVaultCredential -Name 'SCOrchDev\SMA'

.Example
    Get-PasswordVaultCredential -Name 'SCOrchDev\SMA' -Resource 'LocalDev'

.Example
    Get-PasswordVaultCredential -Name 'SCOrchDev\SMA' -Resource 'LocalDev' -AsPSCredential
#>
Function Get-PasswordVaultCredential
{
    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [AllowNull()]
        [string]
        $UserName,

        [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [string]
        $Resource,

        [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
        [Switch]
        $AsPSCredential
    )
    [void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
    $PasswordVault = new-object Windows.Security.Credentials.PasswordVault
    if($UserName -and $Resource)
    {
        $Credential = $PasswordVault.Retrieve($Resource,$UserName)
    }
    elseif($UserName)
    {
        $Credential = $PasswordVault.FindAllByUserName($UserName)
    }
    elseif($Resource)
    {
        $Credential = $PasswordVault.FindAllByResource($Resource)
    }
    else
    {
        $Credential = $PasswordVault.RetrieveAll()
    }

    if($AsPSCredential.IsPresent)
    {
        $Credential | ForEach-Object { 
            $_.RetrievePassword(); 
            $Password = $_.Password | ConvertTo-SecureString -AsPlainText -Force
            New-Object -TypeName System.Management.Automation.PSCredential $_.UserName, $Password
        }
    }
    else
    {
        $Credential
    }
}
<#
.Synopsis
    Sets or Creates a new Password Vault Credential

.Parameter UserName
    The username to store

.Parameter Resource
    The Resouce store to place the credential in

.Parameter Password
    Password of the credential

.Example
    Set-PasswordVaultCredential -Name 'SCOrchDev\SMA' -Resource 'LocalDev' -Password 'P@55W0Rd'
#>
Function Set-PasswordVaultCredential
{
    Param(
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
        [AllowNull()]
        [string]
        $UserName,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [string]
        $Resource,

        [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [string]
        $Password
    )
    [void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
    $PasswordVault = new-object Windows.Security.Credentials.PasswordVault
    
    $Credential = New-Object Windows.Security.Credentials.PasswordCredential
    $Credential.UserName = $UserName
    $Credential.Resource = $Resource
    $Credential.Password = $Password

    try
    {
        $OldCredential = Get-PasswordVaultCredential -Name $UserName -Resource $Resource
        $PasswordVault.Remove($OldCred)
        $PasswordVault.Add($Credential)
    }
    catch
    {
        $PasswordVault.Add($Credential)
    }
}
<#
.Synopsis
    Removes a credental from the password vault

.Parameter UserName
    The username to to remove

.Parameter Resource
    The resource container to remove from

.Example
    # Remove all Password Vault Credentials
    Remove-PasswordVaultCredential

.Example
    # Remove all Password Vault Credentials Named SCOrchDev\SMA
    Remove-PasswordVaultCredential -UserName 'SCOrchDev\SMA'

.Example
    # Remove all Password Vault Credentials from LocalDev resource
    Remove-PasswordVaultCredential -Resource 'LocalDev'

.Example
    # Remove all Password Vault Credentials from LocalDev resource named SCOrchDev\SMA
    Remove-PasswordVaultCredential -Resource 'LocalDev' -UserName 'SCOrchDev\SMA'
#>
Function Remove-PasswordVaultCredential
{
    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [AllowNull()]
        [string]
        $UserName,

        [Parameter(Mandatory = $False, ValueFromPipelineByPropertyName = $True)]
        [AllowNull()]
        [string]
        $Resource
    )

    [void][Windows.Security.Credentials.PasswordVault,Windows.Security.Credentials,ContentType=WindowsRuntime]
    $PasswordVault = new-object Windows.Security.Credentials.PasswordVault
    $Parameters = @{ 
        'UserName' = $UserName ;
        'Resource' = $Resource ;
    }              
    Get-PasswordVaultCredential @Parameters | ForEach-Object { $PasswordVault.Remove($_) }
}