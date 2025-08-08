# Eventura Flutter App Environment Variable Loader for Windows
# This script reads a .env file and converts environment variables to Flutter's --dart-define format.

param(
    [Parameter(Mandatory=$true)]
    [string[]]$Command,
    
    [string]$EnvFile = ".env",
    [switch]$ShowEnv
)

# Get the project root directory
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$EnvFilePath = Join-Path $ProjectRoot $EnvFile

# Function to load environment variables from .env file
function Load-EnvFile {
    param([string]$FilePath)
    
    $envVars = @{}
    
    if (-not (Test-Path $FilePath)) {
        Write-Warning "$FilePath not found. Using default values."
        return $envVars
    }
    
    Get-Content $FilePath | ForEach-Object {
        $line = $_.Trim()
        
        # Skip empty lines and comments
        if ($line -and -not $line.StartsWith('#')) {
            if ($line -match '^([^=]+)=(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                # Remove quotes if present
                if (($value.StartsWith('"') -and $value.EndsWith('"')) -or 
                    ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                    $value = $value.Substring(1, $value.Length - 2)
                }
                
                $envVars[$key] = $value
            }
        }
    }
    
    return $envVars
}

# Function to build dart-define arguments
function Build-DartDefineArgs {
    param([hashtable]$EnvVars)
    
    $dartDefines = @()
    
    foreach ($key in $EnvVars.Keys) {
        $value = $EnvVars[$key]
        $dartDefines += "--dart-define=$key=$value"
    }
    
    return $dartDefines
}

# Function to run Flutter command
function Invoke-FlutterCommand {
    param([string[]]$Command, [string[]]$DartDefines)
    
    $fullCommand = @('flutter') + $Command + $DartDefines
    $commandString = $fullCommand -join ' '
    
    Write-Host "Running: $commandString" -ForegroundColor Green
    
    try {
        & $fullCommand[0] $fullCommand[1..($fullCommand.Length-1)]
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter command failed with exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Error running Flutter command: $_"
        exit 1
    }
}

# Main execution
try {
    # Load environment variables
    $envVars = Load-EnvFile -FilePath $EnvFilePath
    
    if ($ShowEnv) {
        Write-Host "Loaded environment variables:" -ForegroundColor Yellow
        foreach ($key in $envVars.Keys) {
            $value = $envVars[$key]
            
            # Mask sensitive values
            if ($key -match 'password|secret|key' -and $value.Length -gt 8) {
                $maskedValue = $value.Substring(0, 4) + ('*' * ($value.Length - 8)) + $value.Substring($value.Length - 4)
                Write-Host "  $key=$maskedValue" -ForegroundColor Gray
            }
            else {
                Write-Host "  $key=$value" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    # Convert to dart-define format
    $dartDefines = Build-DartDefineArgs -EnvVars $envVars
    
    # Run Flutter command
    Invoke-FlutterCommand -Command $Command -DartDefines $dartDefines
}
catch {
    Write-Error "Script error: $_"
    exit 1
} 