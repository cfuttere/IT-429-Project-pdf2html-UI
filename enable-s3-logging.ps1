# PowerShell script to enable S3 server access logging on existing buckets
# Usage: .\enable-s3-logging.ps1 -TargetBucket <bucket-name> -LogBucket <log-bucket-name>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetBucket,
    
    [Parameter(Mandatory=$true)]
    [string]$LogBucket
)

$LogPrefix = "$TargetBucket-logs/"

Write-Host "Enabling server access logging for bucket: $TargetBucket"
Write-Host "Logs will be stored in: $LogBucket with prefix: $LogPrefix"

# Check if log bucket exists, create if it doesn't
try {
    aws s3 ls "s3://$LogBucket" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating log bucket: $LogBucket"
        aws s3 mb "s3://$LogBucket"
        
        # Block public access on log bucket
        aws s3api put-public-access-block `
            --bucket $LogBucket `
            --public-access-block-configuration `
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    }
} catch {
    Write-Host "Error checking/creating log bucket: $_"
    exit 1
}

# Enable server access logging
$loggingConfig = @"
{
    "LoggingEnabled": {
        "TargetBucket": "$LogBucket",
        "TargetPrefix": "$LogPrefix"
    }
}
"@

aws s3api put-bucket-logging --bucket $TargetBucket --bucket-logging-status $loggingConfig

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Server access logging enabled successfully!" -ForegroundColor Green
    Write-Host "Logs location: s3://$LogBucket/$LogPrefix"
} else {
    Write-Host "✗ Failed to enable server access logging" -ForegroundColor Red
    exit 1
}
