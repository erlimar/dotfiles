# https://ohmyposh.dev/
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue)
{
  oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/erlimar/oh-my-posh/master/erlimar.omp.json' | iex
}

# https://github.com/Schniz/fnm
if (Get-Command fnm -ErrorAction SilentlyContinue)
{
  fnm env --use-on-cd | Out-String | iex
}

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# + Utilitários para acesso via SSH em hosts conhecidos
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
$secureShellOnPowerShellConfigFolder = Join-Path $env:UserProfile ".ssh-pwsh"
$secureShellOnPowerShellDatabasePath = Join-Path $secureShellOnPowerShellConfigFolder "db.json"
$secureShellOnPowerShellDatabase = @{}

function Save-SecureShellDatabase() {
  $secureShellOnPowerShellDatabase | ConvertTo-Json | out-File -FilePath $secureShellOnPowerShellDatabasePath
}

function ConvertTo-Hashtable {
    [CmdletBinding()]
    [OutputType('hashtable')]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        ## Return null if the input is null. This can happen when calling the function
        ## recursively and a property is null
        if ($null -eq $InputObject) {
            return $null
        }
        ## Check if the input is an array or collection. If so, we also need to convert
        ## those types into hash tables as well. This function will convert all child
        ## objects into hash tables (if applicable)
        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
            ## Return the array but don't enumerate it because the object may be pretty complex
            Write-Output -NoEnumerate $collection
        } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
            ## Convert it to its own hash table and return it
            $hash = @{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            $hash
        } else {
            ## If the object isn't an array, collection, or other object, it's already a hash table
            ## So just return it.
            $InputObject
        }
    }
}

function Read-SecureShellDatabase() {
  $global:secureShellOnPowerShellDatabase = (Get-Content $secureShellOnPowerShellDatabasePath | ConvertFrom-Json | ConvertTo-Hashtable)
}

function Initialize-SecureShellOnPowerShell() {
  # Cria diretório de configuração se não existir ainda
  if(!(Test-Path $secureShellOnPowerShellConfigFolder)) {
    New-Item $secureShellOnPowerShellConfigFolder -ItemType Directory | Out-Null
  }

  # Cria banco de dados se não existir ainda
  if(!(Test-Path $secureShellOnPowerShellDatabasePath)) {
    Save-SecureShellDatabase
  }

  Read-SecureShellDatabase
}

function Get-SecureShellHosts() {

  if($secureShellOnPowerShellDatabase.Count -lt 1) {
    "Nenhum host seguro configurado!" | Write-Host
    return
  }

  "Listando os hosts seguros configurados:" | Write-Host
  
  foreach($k in $secureShellOnPowerShellDatabase.Keys) {
    " - ${k}" | Write-host
  }
}

function Show-SecureShellHost() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias
  )

  if($secureShellOnPowerShellDatabase.Count -lt 1) {
    "Nenhum host seguro configurado!" | Write-Host
    return
  }

  foreach($k in $secureShellOnPowerShellDatabase.Keys) {
    if($k -eq $Alias){
      $entry = $secureShellOnPowerShellDatabase[$Alias]
      $keyFilePath = $entry.KeyFilePath
      $hostName = $entry.HostName
      $userName = $entry.UserName

      "Secure host ${k} info:" | Write-Host
      " - Key file path: ${keyFilePath}" | Write-Host
      " - Host name: ${hostName}" | Write-Host
      " - User name: ${userName}" | Write-Host
      return
    }
  }

  "Não existe um host seguro com alias configurado para '${Alias}'!" | Write-Error
}

function Add-SecureShellHost() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias,

    [Parameter(Mandatory=$true)]
    [string] $HostName,

    [Parameter(Mandatory=$true)]
    [string] $UserName,

    [Parameter(Mandatory=$true)]
    [string] $KeyFilePath
  )

  if($secureShellOnPowerShellDatabase.ContainsKey($Alias)) {
    "O host '${Alias}' já existe na configuração! Tente outro nome." | Write-Error
    return
  }

  $secureShellOnPowerShellDatabase.Add($Alias, @{
    HostName = $HostName;
    UserName = $UserName;
    KeyFilePath = $KeyFilePath;
  })
  Save-SecureShellDatabase
}

Initialize-SecureShellOnPowerShell

function Connect-SecureShell() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias
  )

  if(!($secureShellOnPowerShellDatabase.ContainsKey($Alias))) {
    "O host '${Alias}' não está configurado!" | Write-Error
    return
  }

  $entry = $secureShellOnPowerShellDatabase[$Alias]
  $keyFilePath = $entry.KeyFilePath
  $hostName = $entry.HostName
  $userName = $entry.UserName

  ssh -i "${keyFilePath}" "${userName}@${hostName}"
}

function Invoke-SecureShell() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias,

    [Parameter(Mandatory=$true)]
    [string] $Cmd
  )

  if(!($secureShellOnPowerShellDatabase.ContainsKey($Alias))) {
    "O host '${Alias}' não está configurado!" | Write-Error
    return
  }

  $entry = $secureShellOnPowerShellDatabase[$Alias]
  $keyFilePath = $entry.KeyFilePath
  $hostName = $entry.HostName
  $userName = $entry.UserName

  ssh -i "${keyFilePath}" "${userName}@${hostName}" "${Cmd}"
}

function Push-SecureShell() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias,

    [Parameter(Mandatory=$true)]
    [string] $FromPath,

    [Parameter(Mandatory=$true)]
    [string] $ToPath
  )

  if(!($secureShellOnPowerShellDatabase.ContainsKey($Alias))) {
    "O host '${Alias}' não está configurado!" | Write-Error
    return
  }

  $entry = $secureShellOnPowerShellDatabase[$Alias]
  $keyFilePath = $entry.KeyFilePath
  $hostName = $entry.HostName
  $userName = $entry.UserName

  scp -i "${keyFilePath}" "${FromPath}" "${userName}@${hostName}:${ToPath}"
}

function Pull-SecureShell() {
  param(
    [Parameter(Mandatory=$true)]
    [string] $Alias,

    [Parameter(Mandatory=$true)]
    [string] $FromPath,

    [Parameter(Mandatory=$true)]
    [string] $ToPath
  )

  if(!($secureShellOnPowerShellDatabase.ContainsKey($Alias))) {
    "O host '${Alias}' não está configurado!" | Write-Error
    return
  }

  $entry = $secureShellOnPowerShellDatabase[$Alias]
  $keyFilePath = $entry.KeyFilePath
  $hostName = $entry.HostName
  $userName = $entry.UserName

  scp -i "${keyFilePath}" "${userName}@${hostName}:${FromPath}" "${ToPath}"
}


function Help-SecureShell()
{
  "Get-SecureShellHosts" | Write-Host
  "====================" | Write-Host
  "  Lista os nomes dos hosts seguros" | Write-Host
  "" | Write-Host
  "Connect-SecureShell" | Write-Host
  "===================" | Write-Host
  "  Inicia uma sessão SSH em um host remoto seguro" | Write-Host
  "" | Write-Host
  "  Parametros:" | Write-Host
  "  - Alias      Nome do host conforme retornado por 'Get-SecureShellHosts'" | Write-Host
  "" | Write-Host
  "Invoke-SecureShell" | Write-Host
  "==================" | Write-Host
  "  Executa um comando em um host remoto seguro" | Write-Host
  "" | Write-Host
  "  Parametros:" | Write-Host
  "  - Alias      Nome do host conforme retornado por 'Get-SecureShellHosts'" | Write-Host
  "  - Cmd        Comando a executar no host remoto" | Write-Host
  "" | Write-Host
  "Pull-SecureShell" | Write-Host
  "================" | Write-Host
  "  Baixa arquivos de um host remoto seguro para máquina local" | Write-Host
  "" | Write-Host
  "  Parametros:" | Write-Host
  "  - Alias      Nome do host conforme retornado por 'Get-SecureShellHosts'" | Write-Host
  "  - FromPath   Caminho no host remoto" | Write-Host
  "  - ToPath     Caminho na maquina local (Aceita curingas)" | Write-Host
  "" | Write-Host
  "Push-SecureShell" | Write-Host
  "================" | Write-Host
  "  Envia arquivos locais para um host remoto seguro" | Write-Host
  "" | Write-Host
  "  Parametros:" | Write-Host
  "  - Alias      Nome do host conforme retornado por 'Get-SecureShellHosts'" | Write-Host
  "  - FromPath   Caminho na maquina local (Aceita curingas)" | Write-Host
  "  - ToPath     Caminho no host remoto" | Write-Host
}
