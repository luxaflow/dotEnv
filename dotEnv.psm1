$Script:envPath = Join-Path -Path $(Get-Location) -ChildPath '\.env'

<#
.SYNOPSIS
Create a environmental file that stores$Script variables for you project in $Script:env.

.DESCRIPTION
Creates a .env file with a empty json object
Sets variable $Script:env
Exclusion for .env will be added to .gitignore, if file doesn't exist it will be created

.NOTES
Data type of $Script:env is [PSCustomObject]
#>
function New-PsEnv {
    [CmdletBinding()]
    param()

    if (Test-PsEnv) {
        Write-Verbose "VERBOSE: File://" + (Get-Item -Path $Script:envPath -Force).FullName
        Write-Error 'Environmental Variables file already exists!'
        break
    }
    else {
        New-Item -Path $Script:envPath -ItemType File -Force
    }

    $gitIgnorePath = '.\.gitignore'
    Write-Verbose 'Looking for .gitignore file to update'
    if (Test-Path -Path $gitIgnorePath) {
        if ((Get-Content -Path $gitIgnorePath) -notlike '*.env*') {
            Add-Content -Path $gitIgnorePath -Value "`n.env`n"
        }
    }
    else {
        Set-Content -Path $gitIgnorePath -Value "`n.env`n"
    }

    Write-Verbose 'Write environmental variables to $Script:env'
    $Script:env = [PSCustomObject]@{ }

    return $Script:env
}

<#
.SYNOPSIS
Creates the variable $Script:env with .env values

.DESCRIPTION
Checks working directory for .env file.
Sets up $Script:env with values in .env file
#>
function Get-PsEnv {
    [CmdletBinding()]
    param()
    
    if (Test-PsEnv) {

        $Script:env = ConvertFrom-PsEnv -psEnvContent (Get-Content -Path $Script:envPath)

        return $Script:env

    }
    else {

        $currentWorkingDirectory = (Get-Item -Path '.\' -Force).FullName
        Write-Error "No .env file found in $($currentWorkingDirectory)"
    }
}

<#
.SYNOPSIS
Removes the environmental file

.DESCRIPTION
Searches for a .env file in the current working directory and removes it
#>
function Remove-PsEnv {
    [CmdletBinding()]
    param()

    if (Test-PsEnv) {
        
        $remove = $null
        while ($remove -ine 'y' -and $remove -ine 'n') {
            $remove = Read-Host 'Are you sure you want to remove ALL environment variables? (y/n)'
            
            if ($remove -ieq 'y') {
                Write-Verbose 'Removing ALL Environmental variables'
                Remove-Item -Path $Script:envPath -Force
            }
            elseif ($remove -eq 'n') {
                Write-Verbose 'Canceled removal of environmental variables'
            
                if ($null -ieq $Script:env) {
                    $Script:env = Get-Content -Path $Script:envPath -Raw | ConvertFrom-Json
                } 

                return $Script:env
            }
        }  
    }
    else {
        
        $currentWorkingDirectory = (Get-Item Path '.\').FullName
        Write-Error "No .env file found in $($currentWorkingDirectory)" 
    }
}

<#
.SYNOPSIS
Adds a variable to the .env file and the $Script:env

.DESCRIPTION
Use this to add variables to your .env file and update the $Script:env

.PARAMETER key
Name you want to store you value in
Variable type is [STRING]

.PARAMETER value
value you want to store
Type can be anything

.EXAMPLE
Storing credentials in the .env file
Add-PsEnvMember -key 'user.name' -value 'My53cur3P@ss'
#>
function Add-PsEnvMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$key,
        [Parameter(Mandatory = $true)]$value
    )
    
    if (Test-PsEnv) {
        
        if ($null -ieq $Script:env) {

            $Script:env = ConvertFrom-PsEnv -psEnvContent (Get-Content -Path $Script:envPath)
        }

        Write-Verbose 'Adding value to $Script:env'
        $Script:env | Add-Member -MemberType NoteProperty -Name $key -Value $value
        Add-Content -Path $Script:envPath -Value ("$key=$value".trim()) -Force
        
        return $Script:env
    }
    else {

        $currentWorkingDirectory = (Get-Item -Path '.\' -Force).FullName
        Write-Error "No .env file found in $($currentWorkingDirectory)"
    }
    
}
<#
.SYNOPSIS
Removes a variable from the .env file based the key name

.DESCRIPTION
By passing a key to the this function will check the and remove key
#>
function Remove-PsEnvMember {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][String]$key
    )
    
    if (Test-PsEnv) {
        
        if ($null -eq $Script:env.$($key)) {
            Write-Error "Key: $key not found in .env"
            break
        }
        else {
            Write-Verbose "Removing key '$Key' from environment"

            $remove = $null
            while ($remove -ine 'y' -and $remove -ine 'n') {
                $remove = Read-Host "Are you sure you want to remove $($Script:env.$($key))? (y/n)"
            
                if ($remove -ieq 'y') {

                    $Script:env.PSObject.Properties.Remove($key)
                    
                    $envContent = Get-Content -Path $Script:envPath
                    foreach ($line in $envContent) {
                        $keyPair = $line -split '='

                        if ($keyPair[0] -ieq $key) {
                            $envContent = $envContent.Replace($line, '')
                            $envContent | Set-Content -Path $Script:envPath -Force
                        }
                    }
                }
                elseif ($remove -ieq 'n') {
                    Write-Verbose "Removal of key: $($key) canceled"
                }
            }
        }
        return $Script:env
    }
    else {
        $currentWorkingDirectory = (Get-Item -Path '.\' -Force).FullName
        Write-Error "No .env file found in $($currentWorkingDirectory)"
    }

}

function Test-PsEnv {
    [CmdletBinding()]
    param()

    if (Test-Path -Path $Script:envPath -ErrorAction SilentlyContinue) {
    
        $psEnvFullPath = (Get-Item -Path $Script:envPath -Force).FullName
        Write-Verbose "Environmental found at $($psEnvFullPath)"
        return $true
    }
    else {
        Write-Verbose 'No .\.env file found, use New-PsEnv to create environmental'
        return $false
    }
}

<#
.SYNOPSIS
Converts a standard type .env file to ps object

.DESCRIPTION
Converts a standard type .env file to a ps object and accepts pipline text from env

.PARAMETER psEnvContent
Type [String] 
Accepts Content of .env file and parses this into a powershell object
File paths will not work

.EXAMPLE
.env file content
ConvertFrom-PsEnv -psEnvContent (Get-Content -Path $Script:envPath)

Singele value
ConvertFrom-PsEnv -psEnvContent "user=username`npassword=password"

#>
function ConvertFrom-PsEnv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$psEnvContent
    )

    foreach ($line in $psEnvContent) {
        if ($null -ieq $line -or $line.trim()[0] -ieq '#') { continue }
        $keyPair = $line -split '='

        if ($null -ieq $Script:env) {

            $Script:env = [PsCustomObject]@{ } 
        }

        $Script:env | Add-Member -MemberType NoteProperty -Name $keyPair[0] -Value $keyPair[1] 
    }

    return $Script:env

}

if (Test-PsEnv -ErrorAction SilentlyContinue) {
    $Script:env = Get-PsEnv
}

Export-ModuleMember -Function @('New-PsEnv', 'Get-PsEnv', 'Remove-PsEnv', 'Remove-PsEnvMember', 'Add-PsEnvMember')