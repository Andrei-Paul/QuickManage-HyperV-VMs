# Add support for -Verbose and -WhatIf
[CmdletBinding(SupportsShouldProcess=$true)] Param
(
    [Parameter(ValueFromPipeline=$false,Mandatory=$true,ParameterSetName="Create")][Switch] $Create,
    [Parameter(ValueFromPipeline=$false,Mandatory=$true,ParameterSetName="Update")][Switch] $Update,
    [Parameter(ValueFromPipeline=$false,Mandatory=$true,ParameterSetName="Destroy")][Switch] $Destroy,
    [Parameter(ValueFromPipeline=$false,Mandatory=$false,ParameterSetName="Destroy")][Switch] $KeepDisks
)

$default = [Ordered]@{
    Name = $null
    Domain = 'example.com'
    FullName = '<Name>.<Domain>'
    HostName = 'Your-HyperV-Host'
    MemoryBytes = 3GB
    Processors = 4
    #BootDevice = 'LegacyNetworkAdapter'
    BootDevice = 'IDE'
    SwitchName = 'Internal Virtual Switch'
    Path = 'D:\Projects\Virtual Machines'
    VHDPath = '<Path>\<FullName>\Virtual Disks\sda.vhdx'
    VHDSizeBytes = 6GB
    Generation = '1'
    Version = '8.0'
    MACAddress = $null
    HorizontalResolution = 960
    VerticalResolution = 480
}

$Nodes = [Ordered]@{
            0 = [Ordered]@{
                Name = 'arbiter-1'
                MACAddress = '00:15:5d:02:c1:01'
            }
            1 = [Ordered]@{
                Name = 'arbiter-2'
                MACAddress = '00:15:5d:02:c1:02'
            }
            2 = [Ordered]@{
                Name = 'arbiter-3'
                MACAddress = '00:15:5d:02:c1:03'
            }
            3 = [Ordered]@{
                Name = 'executor-1'
                Path = 'X:\Projects\Virtual Machines'
                MACAddress = '00:15:5d:02:c1:04'
            }
            4 = [Ordered]@{
                Name = 'executor-2'
                Path = 'X:\Projects\Virtual Machines'
                MACAddress = '00:15:5d:02:c1:05'
            }
        }

Function Compile
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)] $node,
        [Parameter(ValueFromPipeline=$false,Mandatory=$false)] $default = $default
    )

    Process
    {
        Write-Verbose "Compile [ $( $node[ "Name" ] ) ]"
        $default.Keys | ForEach-Object `
        {
            If ( $false -eq $node.Contains( $PSItem ) -or ( $true -eq $node.Contains( $PSItem ) -and $null -eq $node[ $PSItem ] ) )
            {
                $node[ $PSItem ] = $default[ $PSItem ]
            }
        }

        $keys = @()

        ForEach ( $key in $default.Keys )
        {
            $keys += $key.ToString()
        }
        $keys | ForEach-Object `
        {
            $key = $PSItem.ToString()
            $translate = $false
            $original = $node[ $key ]
            $node[ $key ] | Select-String '<([^<^>]*)>' -AllMatches | ForEach-Object `
            {
                $PSItem.Matches | ForEach-Object `
                {
                    $translate = $true
                    $search = $PSItem.Value.substring( 1, $PSItem.Value.length - 2 )
                    $update = $node[ $key ] -Replace "<$search>", $node[ $search ]
                    $node[ $key ] = $update
                }
            }
            If ( $true -eq $translate )
            {
                Write-Verbose "    [ $( $key ) ]: Translate [ $original ] -> [ $update ]"
            }
            Else
            {
                Write-Verbose "    [ $( $key ) ]: [ $( $node[ $key ] ) ]"
            }
        }

        $node
    }
}

Function Create
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)] $node
    )

    Process
    {
        Write-Verbose "Create [ $( $node[ "FullName" ] ) ]"
        New-VM `
            -ComputerName $node[ "HostName" ] `
            -Name $node[ "FullName" ] `
            -MemoryStartupBytes $node[ "MemoryBytes" ] `
            -BootDevice $node[ "BootDevice" ] `
            -Path $node[ "Path" ] `
            -NewVHDPath $node[ "VHDPath" ] `
            -NewVHDSizeBytes $node[ "VHDSizeBytes" ] `
            -SwitchName $node[ "SwitchName" ] `
            -Generation $node[ "Generation" ] `
            -Version $node[ "Version"]

        Set-VMMemory `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -DynamicMemoryEnabled $false

        Set-VMProcessor `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -Count $node[ "Processors" ] `

        Set-VMNetworkAdapter `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -StaticMacAddress $node[ "MACAddress"]

        Set-VM `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -CheckpointType Disabled `
            -AutomaticStopAction ShutDown

        Enable-VMIntegrationService `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -Name "Guest Service Interface"

        Set-VMVideo `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -HorizontalResolution $node[ "HorizontalResolution" ] `
            -VerticalResolution $node[ "VerticalResolution" ] `
            -ResolutionType Maximum
    }
}

Function Update
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)] $node
    )

    Process
    {
        Write-Verbose "Update [ $( $node[ "FullName" ] ) ]"

        Set-VMMemory `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -StartupBytes $node[ "MemoryBytes" ]

        $bios = Get-VMBios `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ]

        $startupOrder = @( $node[ "BootDevice" ] )
        ForEach ( $device in $bios.StartupOrder )
        {
            If ( "$device" -ne $node[ "BootDevice" ] )
            {
                $startupOrder += "$device"
            }
        }

        Set-VMBios `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -StartupOrder $startupOrder

        Set-VMProcessor `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -Count $node[ "Processors" ] `

        Set-VMNetworkAdapter `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -StaticMacAddress $node[ "MACAddress"]

        Set-VMVideo `
            -ComputerName $node[ "HostName" ] `
            -VMName $node[ "FullName" ] `
            -HorizontalResolution $node[ "HorizontalResolution" ] `
            -VerticalResolution $node[ "VerticalResolution" ] `
            -ResolutionType Maximum
    }
}

Function Destroy
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,Mandatory=$true)] $node,
        [Parameter(ValueFromPipeline=$false,Mandatory=$false,ParameterSetName="Destroy")][Switch] $KeepDisks
    )

    Process
    {
        Write-Verbose "Destroy [ $( $node[ "FullName" ] ) ] -> KeepDisks: [ $KeepDisks ]"
        Remove-VM `
            -ComputerName $node[ "HostName" ] `
            -Name $node[ "FullName" ] `
            -Force

        If ( $false -eq $KeepDisks )
        {
            Remove-Item -LiteralPath $node[ "VHDPath" ]
        }
    }
}

Function Main
{
    If ( $true -eq $Create )
    {
        $Nodes.Keys | ForEach-Object { $Nodes[ $PSItem ] | Compile | Create }
    }
    ElseIf ( $true -eq $Update )
    {
        $Nodes.Keys | ForEach-Object { $Nodes[ $PSItem ] | Compile | Update }
    }
    ElseIf ( $true -eq $Destroy )
    {
        $Nodes.Keys | ForEach-Object { $Nodes[ $PSItem ] | Compile | Destroy -KeepDisks:($KeepDisks) }
    }
}

Main
