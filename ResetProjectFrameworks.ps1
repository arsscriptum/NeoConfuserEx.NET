
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Get-Frameworks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$Latest
    ) 

    Try{
        $FrameWorks = @()
        $Dirs = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework64" -Directory -Filter "v*" | Sort -Property Name
        ForEach($d in $Dirs){
            $Name = $d.Name
            $Fullname = $d.Fullname
            $Name = $Name.Replace('v','')
            $Name = $Name.SubString(0,3)
            $o = [PsCustomObject]@{
                Name = $Name
                Path = $Fullname
            }
            $FrameWorks += $o  
        }
        if($Latest){
            return $FrameWorks[$FrameWorks.Count-1]
        }
        $FrameWorks

    }catch{
        Write-Error $_ 
    }
}


function Set-ProjectsFrameworks{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0)]
        [String]$Path,
        [Parameter(Mandatory=$false)]
        [String]$Framework="net5.0-windows"
    ) 

    try{
        $projects=(gci $Path -Recurse -File -Filter "*.csproj").Fullname
        ForEach($pfile in $projects){
            Write-Host "Updating `"$pfile`""
            $c = Get-Content "$pfile" -Raw 
            [xml]$xml = $c
            if($xml.Project.PropertyGroup.TargetFramework -eq $Null){
                $Child = $xml.CreateElement("TargetFramework",$xml.Project.NamespaceURI)
                $Child.InnerText = "$Framework"
                $Null = $xml.Project.PropertyGroup[0].AppendChild($Child)
            }else{
                $Null = $xml.Project.PropertyGroup.TargetFramework = "$Framework"
            }
            
            $xml.Save($pfile)
        }
    }catch{
        Write-Error "$_"
    }

    return $null
}


function Set-ProjectsLanguageVersion{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0)]
        [String]$Path,
        [Parameter(Mandatory=$false)]
        [String]$LangVersion="latest"
    ) 

    try{
        $projects=(gci $Path -Recurse -File -Filter "*.csproj").Fullname
        ForEach($pfile in $projects){
            Write-Host "Updating `"$pfile`""
            $c = Get-Content "$pfile" -Raw 
            [xml]$xml = $c
            if($xml.Project.PropertyGroup.LangVersion -eq $Null){
                $Child = $xml.CreateElement("LangVersion",$xml.Project.NamespaceURI)
                $Child.InnerText = "$LangVersion"
                $Null = $xml.Project.PropertyGroup[0].AppendChild($Child)
            }else{
                $Null = $xml.Project.PropertyGroup.LangVersion = "$LangVersion"
            }
            
            $xml.Save($pfile)
        }
    }catch{
        Write-Error "$_"
    }

    return $null
}



function Remove-TargetFrameworkVersion{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0)]
        [String]$Path
    ) 

    try{
        Write-Host "Removing `"TargetFrameworkVersion`" " -f Red
        $projects=(gci $Path -Recurse -File -Filter "*.csproj").Fullname
        ForEach($pfile in $projects){
            Write-Host "Updating `"$pfile`" " -f DarkCyan
            $c = Get-Content "$pfile" -Raw 
            [xml]$xml = $c
            if($xml.Project.PropertyGroup.TargetFrameworkVersion -eq $Null){
                $vchild = $xml.Project.ChildNodes[0].GetElementsByTagName("TargetFrameworkVersion")
                if($vchild -ne $Null){
                    $Null = $xml.Project.ChildNodes[0].RemoveChild($vchild[0])
                    
                }
            }
            if($xml.Project.PropertyGroup.TargetFramework -eq $Null){
                $vchild = $xml.Project.ChildNodes[0].GetElementsByTagName("TargetFramework")
                if($vchild -ne $Null){
                    $Null = $xml.Project.ChildNodes[0].RemoveChild($vchild[0])
                    
                }
            }
            $xml.Save($pfile)
        }
    }catch{
        Write-Error "$_"
    }

    return $null
}

Set-ProjectsLanguageVersion -Path "$PSScriptRoot"
#Remove-TargetFrameworkVersion -Path "$PSScriptRoot"
#Set-ProjectsFrameworks -Path "$PSScriptRoot"