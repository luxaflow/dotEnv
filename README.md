# dotEnv
forked from: rajivharris/Set-PsEnv

PowerShell DotEnv

This is a simple script to load the .env file to process environment from the current directory.

Usage
==========
Added and updated multiple functions to fully manage you .env file with this module

```powershell
# Will create .env file in working directory
# Will also add .env to .gitignore, if no .gitignore available, it will be created
New-PsEnv 

# Will return all values from .env file in a PsCustomObject
Get-PsEnv

# Removes the .env file, will prompt to confirm
Remove-PsEnv

# Adds new variable to .env
Add-PsEnvMember

# finds and removes a variablee from .env file
Remove-PsEnvMember

```

for more detailed description of each function user Get-Help to display function Synopsis, example:
```powershell
Get-Help Add-PsEnvMember -Detailed
```


Installation
============

### Cloned Version
```powershell
-Module -Name dotEnv.psm1
```