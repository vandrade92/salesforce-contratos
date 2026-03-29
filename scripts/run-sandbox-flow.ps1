param(
    [string]$Alias = "minha-sandbox",
    [string]$InstanceUrl = "https://test.salesforce.com",
    [switch]$SkipDeploy,
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path "$PSScriptRoot\..").Path
$homeDrive = Split-Path -Qualifier $projectRoot
$homePath = $projectRoot.Substring($homeDrive.Length)
if ([string]::IsNullOrWhiteSpace($homePath)) {
    $homePath = "\"
}
if (-not $homePath.StartsWith("\")) {
    $homePath = "\" + $homePath
}

$env:HOME = $projectRoot
$env:USERPROFILE = $projectRoot
$env:HOMEDRIVE = $homeDrive.TrimEnd("\")
$env:HOMEPATH = $homePath
$env:SF_STATE_FOLDER = Join-Path $projectRoot ".sf"
$env:SFDX_STATE_FOLDER = Join-Path $projectRoot ".sfdx"
$env:LOCALAPPDATA = Join-Path $projectRoot ".localappdata"
$env:APPDATA = Join-Path $projectRoot ".appdata"
$env:SF_DISABLE_TELEMETRY = "true"
$env:SFDX_DISABLE_TELEMETRY = "true"

New-Item -ItemType Directory -Force -Path $env:SF_STATE_FOLDER, $env:SFDX_STATE_FOLDER, $env:LOCALAPPDATA, $env:APPDATA | Out-Null

function Invoke-Sf {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    & npx.cmd sf @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no comando: sf $($Args -join ' ')"
    }
}

Write-Host "1/7 Autenticando org sandbox '$Alias'..."
Invoke-Sf org login web --instance-url $InstanceUrl --alias $Alias --set-default

Write-Host "2/7 Validando orgs autenticadas..."
Invoke-Sf org list

Write-Host "3/7 Exibindo detalhes da org..."
Invoke-Sf org display --target-org $Alias

Write-Host "4/7 Gerando manifest da org..."
Invoke-Sf project generate manifest --from-org $Alias --name package.xml --output-dir manifest

Write-Host "5/7 Fazendo retrieve para o projeto local..."
Invoke-Sf project retrieve start --manifest manifest/package.xml --target-org $Alias

if (-not $SkipDeploy) {
    Write-Host "6/7 Fazendo deploy do source local para a org..."
    Invoke-Sf project deploy start --source-dir force-app --target-org $Alias
} else {
    Write-Host "6/7 Deploy pulado (-SkipDeploy)."
}

if (-not $SkipTests) {
    Write-Host "7/7 Rodando testes Apex (RunLocalTests)..."
    Invoke-Sf apex run test --target-org $Alias --test-level RunLocalTests --wait 30
} else {
    Write-Host "7/7 Testes pulados (-SkipTests)."
}

Write-Host "Fluxo concluido."