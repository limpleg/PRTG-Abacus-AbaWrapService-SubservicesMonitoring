param(
    [int]$Minutes = 10,
    [string]$LogFolder = "\\localhost\c$\ABAC\log\abawrapservice"
)

# ----------------------------
#  XML DOCUMENT INITIALIZATION
# ----------------------------
$global:xml = New-Object System.Xml.XmlDocument
$global:prtg = $global:xml.CreateElement("prtg")
$global:xml.AppendChild($global:prtg) | Out-Null

# ----------------------------
#  ADD CHANNEL HELPER
# ----------------------------
function Add-Channel {
    param(
        [string]$name,
        [int]$value,
        [bool]$warning = $false,
        [bool]$error = $false
    )

    $channel = $global:xml.CreateElement("result")

    $nodeName = $global:xml.CreateElement("channel")
    $nodeName.InnerText = $name
    $channel.AppendChild($nodeName) | Out-Null

    $nodeValue = $global:xml.CreateElement("value")
    $nodeValue.InnerText = $value
    $channel.AppendChild($nodeValue) | Out-Null

    if ($warning) {
        $nodeWarn = $global:xml.CreateElement("warning")
        $nodeWarn.InnerText = "1"
        $channel.AppendChild($nodeWarn) | Out-Null
    }

    if ($error) {
        $nodeErr = $global:xml.CreateElement("error")
        $nodeErr.InnerText = "1"
        $channel.AppendChild($nodeErr) | Out-Null
    }

    $global:prtg.AppendChild($channel) | Out-Null
}


# ----------------------------
#  UNC ACCESS TEST (SAFE)
# ----------------------------
$uncAccessible = $false
try {
    $uncAccessible = Test-Path -Path $LogFolder -ErrorAction Stop
}
catch {
    $uncAccessible = $false
}

if (-not $uncAccessible) {

    # Channel ausgeben
    Add-Channel -name "UNC Path Accessible" -value 0 -warning:$false -error:$true

    # Textmeldung ausgeben
    $txt = $global:xml.CreateElement("text")
    $txt.InnerText = "UNC-Pfad nicht erreichbar: $LogFolder . 
Der PRTG Probe Service hat keinen Zugriff. 
Bitte Service-Konto prüfen (Lokales System kann nicht auf E$ zugreifen)."
    $global:prtg.AppendChild($txt) | Out-Null

    # Saubere PRTG-Ausgabe
    Write-Output $global:xml.OuterXml
    exit 0
}

# Erfolgsfall: UNC erreichbar → Channel OK
Add-Channel -name "UNC Path Accessible" -value 1 -warning:$false -error:$false

# ----------------------------
#  GET RELEVANT LOG FILES
# ----------------------------
$files = Get-ChildItem -Path $LogFolder -Filter "*.log" `
    -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending


if ($files.Count -eq 0) {
    Add-Channel "Abacus Logs" 0 $false $true
    $txt = $global:xml.CreateElement("text")
    $txt.InnerText = "Keine Logdateien im angegebenen Ordner."
    $global:prtg.AppendChild($txt) | Out-Null

    # KORREKTE PRTG-AUSGABE
    Write-Output $global:xml.OuterXml
    exit 0
}


$latest = $files[0]
$previous = if ($files.Count -ge 2) { $files[1] } else { $null }

# ----------------------------
#  COLLECT LAST X MINUTES OF LOG ENTRIES
# ----------------------------
$cutoff = (Get-Date).AddMinutes(-$Minutes)
$logText = @()

foreach ($f in @($latest, $previous)) {
    if ($null -ne $f) {
        Get-Content $f.FullName -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_ -match "^\d{4}\/\d{2}\/\d{2}") {
                $ts = $_.Substring(0,23)
                $tsDate = [datetime]::ParseExact($ts, "yyyy/MM/dd HH:mm:ss.fff", $null)
                if ($tsDate -ge $cutoff) {
                    $logText += $_
                }
            }
        }
    }
}

# ----------------------------
#  SERVICE LIST (ALL SERVICES)
# ----------------------------
$services = @(
    "abaapplicationserver-0",
    "abaapplicationserver-1",
    "abaapplicationserver-2",
    "abaapplicationserver-3",
    "abaapplicationserver-4",
    "abaapplicationserver-5",
    "abaportalserver-0",
    "abaapiserver-0",
    "abainterfaceserver-0",
    "abaintegrationserver-0",
    "abaprocessengine-0",
    "abareportserverphoenix-0",
    "abareportserverphoenix-1",
    "abasearchserver-0",
    "abalogprocessor-0",
    "abanotify-0",
    "abaebcommserver-0",
    "abaauditserver-0",
    "abaprintspooler-0",
    "abastatisticsserver-0",
    "abawebserver-0",
    "abataskscheduler-0",
    "abasimplestorageservice-0",
    "abaauthserver-0"
)

# ----------------------------
#  FRIENDLY NAMES (VARIANTE B)
# ----------------------------
$friendly = @{
    "abaapplicationserver-0"="Aba Application Server-0"
    "abaapplicationserver-1"="Aba Application Server-1"
    "abaapplicationserver-2"="Aba Application Server-2"
    "abaapplicationserver-3"="Aba Application Server-3"
    "abaapplicationserver-4"="Aba Application Server-4"
    "abaapplicationserver-5"="Aba Application Server-5"
    "abaportalserver-0"="AbaPortalServer"
    "abaapiserver-0"="AbaAPIServer"
    "abainterfaceserver-0"="AbaInterfaceServer"
    "abaintegrationserver-0"="AbaIntegrationServer"
    "abaprocessengine-0"="AbaProcessEngine"
    "abareportserverphoenix-0"="AbaReportServerPhoenix-0"
    "abareportserverphoenix-1"="AbaReportServerPhoenix-1"
    "abasearchserver-0"="AbaSearchServer"
    "abalogprocessor-0"="AbaLogProcessor"
    "abanotify-0"="AbaNotify"
    "abaebcommserver-0"="AbaEBCommServer"
    "abaauditserver-0"="AbaAuditServer"
    "abaprintspooler-0"="AbaPrintSpooler"
    "abastatisticsserver-0"="AbaStatisticsServer"
    "abawebserver-0"="AbaWebServer"
    "abataskscheduler-0"="AbaTaskScheduler"
    "abasimplestorageservice-0"="AbaSimpleStorageService"
    "abaauthserver-0"="AbaAuthServer"
}

$globalErrors = @()
$globalWarnings = @()

# ----------------------------
#  PROCESS EACH SERVICE
# ----------------------------
foreach ($svc in $services) {

    $friendlyName = $friendly[$svc]
    $entries = $logText | Select-String -Pattern $svc

    # Default OK (Option 1)
    $status = 1
    $isError = $false
    $isWarning = $false
    $lastMessage = "OK"

    # Collect patterns
    $crashes = @()
    $starts = @()

    foreach ($e in $entries) {
        $line = $e.ToString()

        if ($line -match "Start '") {
            $starts += $line
        }
        elseif ($line -match "Timeout starting" -or 
                $line -match "Timeout killing" -or 
                $line -match "Killing the process") {

            # HARD ERROR
            $status = 0
            $isError = $true
            $lastMessage = $line
            $globalErrors += "${friendlyName}: $line"
            break
        }
        elseif ($line -match "Process finished") {
            $crashes += $line
        }
    }

    # If error already → skip warning logic
    if ($isError) {
        Add-Channel $friendlyName $status $false $true
        continue
    }

    # Detect restart
    $wasRestart = $false

    foreach ($c in $crashes) {
        $cts = [datetime]::ParseExact($c.Substring(0,23),"yyyy/MM/dd HH:mm:ss.fff",$null)

        foreach ($s in $starts) {
            $sts = [datetime]::ParseExact($s.Substring(0,23),"yyyy/MM/dd HH:mm:ss.fff",$null)

            if (($sts - $cts).TotalSeconds -ge 0 -and ($sts - $cts).TotalSeconds -lt 30) {
                $wasRestart = $true
            }
        }
    }

    if ($wasRestart) {
        $isWarning = $true
        $lastMessage = "Restart detected"
        $globalWarnings += "${friendlyName}: Restart detected"
    }

    Add-Channel $friendlyName $status $isWarning $isError
}

# ----------------------------
#  OVERALL MESSAGE
# ----------------------------
$textNode = $global:xml.CreateElement("text")

if ($globalErrors.Count -gt 0) {
    $textNode.InnerText = "Fehlerhafte Abacus-Dienste: " + ($globalErrors -join "; ")
}
elseif ($globalWarnings.Count -gt 0) {
    $textNode.InnerText = "Warnungen: " + ($globalWarnings -join "; ")
}
else {
    $textNode.InnerText = "Alle Abacus-Unterdienste laufen stabil (letzte 10 Minuten)."
}

$global:prtg.AppendChild($textNode) | Out-Null

# --- 1 OUTPUT FOR PRTG ---
$xmlString = $global:xml.OuterXml
Write-Output $xmlString
exit 0

# --- 2 OUTPUT FOR Powershell Testing ---
# $global:xml.Save("C:\AbacusWrapMonitor_output.xml")
