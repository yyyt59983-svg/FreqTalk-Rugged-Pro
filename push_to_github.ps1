# FreqTalk Push to GitHub Helper

$repoName = "FreqTalk-Rugged-Pro"
Write-Host "Initializing GitHub Repository: $repoName" -ForegroundColor Cyan

# Check if logged in to gh
# Since gh is not in path, we will use standard git commands

$remoteUrl = Read-Host "Please enter your new GitHub Repository URL (e.g., https://github.com/username/FreqTalk-Rugged-Pro.git)"

if ($remoteUrl) {
    git remote add origin $remoteUrl
    git branch -M main
    git push -u origin main
    Write-Host "Success! Code pushed to $remoteUrl" -ForegroundColor Green
} else {
    Write-Host "Remote URL not provided. Please add it manually using: git remote add origin <URL>" -ForegroundColor Yellow
}
