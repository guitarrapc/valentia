function Get-GitHubRepositryURI
{
    [CmdletBinding()]
    param
    (
        [string]$GitHub,
        [string]$RepositoryName
    )

    Write-Verbose ("Get URI for {0} with Repository {1}" -f $GitHub, $RepositoryName)
    return [uri]("https://github.com/{0}/{1}/archive/master.zip" -f $github, $RepositoryName)
}

function New-Directory
{
    param
    (
        [string]$tempDir
    )

    if (-not [System.IO.Directory]::Exists($tempDir))
    {
        [System.IO.Directory]::CreateDirectory($tempDir)
    }
}

function Download-File
{
    [CmdletBinding()]
    param
    (
        [string]$Source,
        [string]$Destination
    )

    Write-Verbose ("Downloading {0} to {1}" -f $uri, $source)
    Start-BitsTransfer -Source $source -Destination $destination
}

function New-ZipExtract
{
    [CmdletBinding(DefaultParameterSetName="safe")]
    param
    (
        [parameter(
            mandatory,
            position = 0,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $source,

        [parameter(
            mandatory = 0,
            position = 1,
            valuefrompipeline,
            valuefrompipelinebypropertyname)]
        [string]
        $destination,

        [parameter(
            mandatory = 0,
            position = 2)]
        [switch]
        $quiet,

        [parameter(
            mandatory = 0,
            position = 3,
            ParameterSetName="safe")]
        [switch]
        $safe,

        [parameter(
            mandatory = 0,
            position = 3,
            ParameterSetName="force")]
        [switch]
        $force
    )

    begin
    {
        # only run with Verbose mode
        if ($PSBoundParameters.Verbose.IsPresent)
        {
            # start Stopwatch
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $starttime = Get-Date
        }

        Write-Debug "import .NET Class for ZipFile"
        try
        {
            Add-Type -AssemblyName "System.IO.Compression.FileSystem"
        }
        catch
        {
        }
    }

    process
    {
        $zipExtension = ".zip"

        Write-Debug "Check source is input as .zip"
        if (-not($source.EndsWith($zipExtension)))
        {
            throw ("source parameter value [{0}] not end with extension {1}" -f $source, $zipExtension)
        }

        Write-Debug ("set desktop as destination path destination {0} is null" -f $destination)
        if ([string]::IsNullOrWhiteSpace($destination))
        {
            $desktop = [System.Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
            $directoryname = [System.IO.Path]::GetFileNameWithoutExtension($source)
        
            Write-Verbose ("Desktop : {0}" -f $desktop)
            Write-Verbose ("GetFileName : {0}" -f $directoryname)

            $destination = Join-Path $desktop $directoryname
        }
        
        Write-Debug "check destination is already exist, ExtractToDirectory Method will fail with same name of destination file."
        if (Test-Path $destination)
        {
            if ($safe)
            {
                Write-Debug "safe output zip file to new destination path, avoiding destination zip name conflict."

                # show warning for same destination exist.
                Write-Verbose ("Detected destination name {0} is already exist. safe trying output to new destination zip name." -f $destination)

                $olddestination = $destination

                # get current destination information
                $destinationRoot = [System.IO.Path]::GetDirectoryName($destination)
                $destinationfile = [System.IO.Path]::GetFileNameWithoutExtension($destination)
                $destinationExtension = [System.IO.Path]::GetExtension($destination)

                # renew destination name with (2)...(x) until no more same name catch.
                $count = 2
                $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")" + $destinationExtension)
                while (Test-Path $destination)
                {
                    ++$count
                    $destination = Join-Path $destinationRoot ($destinationfile + "(" + $count + ")" + $destinationExtension)
                }

                # show warning as destination name had been changed due to escape error.
                Write-Warning ("Safe old deistination {0} change to new name {1}" -f $olddestination, $destination)
            }
            else
            {
                if($force)
                {
                    Write-Warning ("force replacing old zip file {0}" -f $destination)
                    Remove-Item -Path $destination -Recurse -Force
                }
                else
                {
                    Remove-Item -Path $destination -Recurse -Confirm
                }

                if (Test-Path $destination)
                {
                    Write-Warning "Cancelled removing item. Quit cmdlet execution."
                    return
                }
            }
        }
        else
        {
            Write-Debug ("Destination not found. Check parent folder for destination {0} is exist." -f $destination)
            $parentpath = Split-Path $destination -Parent

            if (-not(Test-Path $parentpath))
            {
                Write-Warning ("Parent folder {0} not found. Creating path." -f $parentpath)
                New-Item -Path $parentpath -ItemType Directory -Force
            }
        }

        try
        {
            Write-Debug "create source zip and complression"
            $sourcezip = [System.IO.Compression.Zipfile]::Open($source,"Update")
            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal

            Write-Verbose ("sourcezip : {0}" -f $sourcezip)
            Write-Verbose ("destination : {0}" -f $destination)

            Write-Debug "Execute Main Process ExtractToDirectory."
            if ($quiet)
            {
                [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($sourcezip,$destination) > $null
                $?
            }
            else
            {
                [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($sourcezip,$destination)
            }

            $sourcezip.Dispose()
        }
        catch
        {
            Write-Error $_
        }
        finally
        {
            Write-Debug ("Dispose Object {0} to remove file handler." -f $sourcezip)
            $sourcezip.Dispose()
        }
    }

    end
    {
        # only run with Verbose mode
        if ($PSBoundParameters.Verbose.IsPresent)
        {
            # end Stopwatch
            $endsw = $sw.Elapsed.TotalMilliseconds
            $endtime = Get-Date

            Write-Verbose ("Start time`t: {0:o}" -f $starttime)
            Write-Verbose ("End time`t: {0:o}" -f $endtime)
            Write-Verbose ("Duration`t: {0} ms" -f $endsw)
        }
    }
}


function Install-Repogisty
{
    [CmdletBinding()]
    param
    (
        [string]$installerPath
    )

    .$installerPath
}

function Main
{
    # Uri
    $GitHubURI = @{
        github = "guitarrapc"
        repository = "valentia"
    }
    $uri = Get-GitHubRepositryURI @GitHubURI -Verbose

    # Directory
    $dir = Join-Path $env:TEMP "valentia"
    $tempDir = Join-Path $dir "Install"
    $source = Join-Path $tempDir "master.zip"
    $destination = Join-Path $tempDir "master"
    New-Directory -tempDir $tempDir

    # Download
    $Download = @{
        Source    = $uri.AbsoluteUri
        Destination = $source
    }
    Download-File @Download -Verbose

    # Unzip
    $Unzip = @{
        Source = $source
        Destination = $destination
    }
    New-ZipExtract @Unzip -force -Verbose

    # Install
    Write-Verbose ("Installing {0} to the computer" -f $gitHubURI.repository)
    $installer = "Install.bat"
    $toolFolder = Join-Path $destination ("{0}-Master\{0}" -f $gitHubURI.repository)
    $InstallerPath = Join-Path $toolFolder "Install.bat"
    Install-Repogisty -installerPath $InstallerPath
}

. Main