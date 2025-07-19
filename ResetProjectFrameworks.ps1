[CmdletBinding(SupportsShouldProcess = $true)]
[OutputType([void])]
param()
function Get-Frameworks {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$Latest
    )

    try {
        $FrameWorks = @()
        $Dirs = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64" -Directory -Filter "v*" | Sort -Property Name
        foreach ($d in $Dirs) {
            $Name = $d.Name
            $Fullname = $d.FullName
            $Name = $Name.Replace('v', '')
            $Name = $Name.SubString(0, 3)
            $o = [pscustomobject]@{
                Name = $Name
                Path = $Fullname
            }
            $FrameWorks += $o
        }
        if ($Latest) {
            return $FrameWorks[$FrameWorks.Count - 1]
        }
        $FrameWorks

    } catch {
        Write-Error $_
    }
}

function Set-ProjectsFrameworks {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the folder containing .csproj files")]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter(Mandatory = $false, HelpMessage = "Framework to set (e.g., net5.0-windows)")]
        [string]$Framework = "net5.0-windows"
    )

    try {
        $projectFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.csproj' -File -ErrorAction Stop

        foreach ($file in $projectFiles) {
            Write-Verbose "Processing: $($file.FullName)"

            try {
                [xml]$xml = Get-Content -Path $file.FullName -Raw

                # Setup namespace manager if needed
                $nsMgr = New-Object System.Xml.XmlNamespaceManager ($xml.NameTable)
                $nsMgr.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)

                $propertyGroups = $xml.SelectNodes("//ns:Project/ns:PropertyGroup", $nsMgr)
                $updated = $false

                foreach ($pg in $propertyGroups) {
                    $tfNode = $pg.SelectSingleNode("ns:TargetFramework", $nsMgr)
                    if ($tfNode) {
                        $tfNode.InnerText = $Framework
                        $updated = $true
                    }
                }

                if (-not $updated -and $propertyGroups.Count -gt 0) {
                    $newNode = $xml.CreateElement("TargetFramework", $xml.DocumentElement.NamespaceURI)
                    $newNode.InnerText = $Framework
                    $null = $propertyGroups[0].AppendChild($newNode)
                }

                if ($PSCmdlet.ShouldProcess($file.FullName, "Set TargetFramework to $Framework")) {
                    $xml.Save($file.FullName)
                    Write-Verbose "Updated: $($file.Name)"
                }
            }
            catch {
                Write-Warning "Failed to update '$($file.FullName)': $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Error "Unhandled error in function: $($_.Exception.Message)"
    }
}



function Set-ProjectsLanguageVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to search for .csproj files")]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path,

        [Parameter(Mandatory = $false, HelpMessage = "Language version to set (e.g., 'latest')")]
        [string]$LangVersion = "latest"
    )

    try {
        $projectFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.csproj' -File -ErrorAction Stop

        foreach ($file in $projectFiles) {
            Write-Verbose "Processing: $($file.FullName)"

            try {
                [xml]$xml = Get-Content -Path $file.FullName -Raw

                # Namespace-aware handling
                $nsMgr = New-Object System.Xml.XmlNamespaceManager ($xml.NameTable)
                $nsMgr.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)

                $propertyGroups = $xml.SelectNodes("//ns:Project/ns:PropertyGroup", $nsMgr)
                $updated = $false

                foreach ($pg in $propertyGroups) {
                    $langNode = $pg.SelectSingleNode("ns:LangVersion", $nsMgr)
                    if ($langNode) {
                        $langNode.InnerText = $LangVersion
                        $updated = $true
                        break
                    }
                }

                if (-not $updated -and $propertyGroups.Count -gt 0) {
                    $newNode = $xml.CreateElement("LangVersion", $xml.DocumentElement.NamespaceURI)
                    $newNode.InnerText = $LangVersion
                    $null = $propertyGroups[0].AppendChild($newNode)
                }

                $xml.Save($file.FullName)
                Write-Verbose "Updated: $($file.Name)"
            }
            catch {
                Write-Warning "Failed to update '$($file.FullName)': $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Error "Unhandled error in function: $($_.Exception.Message)"
    }
}


function Remove-TargetFrameworkVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Path to the folder containing .csproj files")]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$Path
    )

    try {
        Write-Verbose "Searching for .csproj files under '$Path'..."

        $projectFiles = Get-ChildItem -Path $Path -Recurse -Filter '*.csproj' -File -ErrorAction Stop

        foreach ($file in $projectFiles) {
            Write-Verbose "Processing: $($file.FullName)"

            try {
                [xml]$xml = Get-Content -Path $file.FullName -Raw

                $nsMgr = New-Object System.Xml.XmlNamespaceManager ($xml.NameTable)
                $nsMgr.AddNamespace("ns", $xml.DocumentElement.NamespaceURI)

                $removed = $false

                foreach ($tagName in 'TargetFrameworkVersion', 'TargetFramework') {
                    $nodes = $xml.SelectNodes("//ns:Project/ns:PropertyGroup/ns:$tagName", $nsMgr)
                    foreach ($node in $nodes) {
                        $null = $node.ParentNode.RemoveChild($node)
                        $removed = $true
                        Write-Verbose "Removed <$tagName> from $($file.Name)"
                    }
                }

                if ($removed -and $PSCmdlet.ShouldProcess($file.FullName, "Remove target framework tags")) {
                    $xml.Save($file.FullName)
                }
            }
            catch {
                Write-Warning "Failed to update '$($file.FullName)': $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Error "Unhandled error: $($_.Exception.Message)"
    }
}



function Restore-NuGetPackages {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param()

    try {
        $RootPath = (Resolve-Path -Path "$($PWD.Path)").Path
        $NuGetExe = (get-command nuget).Source
        $projectFiles=gci -Path "$RootPath" -Recurse -filter "*.csproj"  -file | select -ExpandProperty Fullname
        foreach ($file in $projectFiles) {
            $toUpdate = $file.Replace("$RootPath\","")
             Write-Host "toUpdate $($toUpdate)"
          & "$NuGetExe" "restore" "$toUpdate"
       }
    }
    catch {
        Write-Error "Unhandled error: $($_.Exception.Message)"
    }
}

function Update-NuGetPackages {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param()

    try {
        $RootPath = (Resolve-Path -Path "$($PWD.Path)").Path
        $NuGetExe = (get-command nuget).Source
        $projectFiles=gci -Path "$RootPath" -Recurse -filter "*.csproj"  -file | select -ExpandProperty Fullname
        foreach ($file in $projectFiles) {
            $toUpdate = $file.Replace("$RootPath\","")
             Write-Host "toUpdate $($toUpdate)"
          & "$NuGetExe" "update" "$toUpdate"
       }
    }
    catch {
        Write-Error "Unhandled error: $($_.Exception.Message)"
    }
}

function Update-TargetFrameworkVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([void])]
    param()

    try {
        $RootPath = (Resolve-Path -Path "$($PWD.Path)").Path
        Write-Host "RootPath $($RootPath)"
        Set-ProjectsFrameworks -Path "$($RootPath)" -Framework "net8.0" -Verbose
    }
    catch {
        Write-Error "Unhandled error: $($_.Exception.Message)"
    }
}

 

#Set-ProjectsFrameworks -Path "$($PWD.Path)" -Framework "net8.0" -Verbose