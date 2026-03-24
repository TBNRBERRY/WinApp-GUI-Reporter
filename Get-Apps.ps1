# This script retrieves a list of every installed application (64-bit and 32-bit)

# --- PART 1: DATA COLLECTION & CATEGORIZATION ---
$computername = $env:COMPUTERNAME
$hives = @{
    "LocalMachine" = @(
        "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
        "SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    )
    "CurrentUser"  = @(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    )
}

$excludePatterns = "Driver Package|Windows Software Development Kit|SDK|Redistributable|Update for|Web Deploy|Target|Templates|Runtime"

# Define our Categories
$Categories = @{
    "STEAM GAMES" = New-Object System.Collections.Generic.List[string]
    "DEV & CODING TOOLS" = New-Object System.Collections.Generic.List[string]
    "DRIVERS & HARDWARE" = New-Object System.Collections.Generic.List[string]
    "APPLICATIONS" = New-Object System.Collections.Generic.List[string]
}

foreach ($hive in $hives.Keys) {
    $reg = [microsoft.win32.registrykey]::OpenRemoteBaseKey($hive, $computername)
    foreach ($path in $hives[$hive]) {
        $regkey = $reg.OpenSubKey($path)
        if ($null -eq $regkey) { continue }
        foreach ($key in $regkey.GetSubKeyNames()) {
            $thisSubKey = $reg.OpenSubKey("$path\\$key")
            $DisplayName   = $thisSubKey.GetValue("DisplayName")
            $IsComponent   = $thisSubKey.GetValue("SystemComponent")
            $UninstallPath = $thisSubKey.GetValue("UninstallString")
            
            if ($DisplayName -and ($IsComponent -ne 1) -and $UninstallPath -and ($DisplayName -notmatch $excludePatterns)) {
                
                # --- CATEGORIZATION LOGIC ---
                if ($UninstallPath -match "steam://" -or $path -match "Steam") {
                    $Categories["STEAM GAMES"].Add($DisplayName)
                }
                elseif ($DisplayName -match "Git|Visual Studio|Node\.js|Python|Unity|Rustup|SQL|Cocos|Cursor|Sublime") {
                    $Categories["DEV & CODING TOOLS"].Add($DisplayName)
                }
                elseif ($DisplayName -match "Driver|Realtek|NVIDIA|AMD|GIGABYTE|Intel|USB|WIA|Controller") {
                    $Categories["DRIVERS & HARDWARE"].Add($DisplayName)
                }
                else {
                    $Categories["APPLICATIONS"].Add($DisplayName)
                }
            }
        }
    }
}

# Build the final text string with headers
$finalText = ""
foreach ($cat in $Categories.Keys | Sort-Object) {
    if ($Categories[$cat].Count -gt 0) {
        $finalText += "[$cat]`r`n"
        $finalText += ($Categories[$cat] | Sort-Object -Unique | Out-String).Trim()
        $finalText += "`r`n`r`n"
    }
}

# --- PART 2: THE GUI ---
$form = New-Object Windows.Forms.Form
$form.Text = "Categorized App Inventory"
$form.Size = New-Object Drawing.Size(700, 850)
$form.StartPosition = "CenterScreen"
$form.KeyPreview = $true # Needed for shortcuts

# Text Box (Editable)
$textBox = New-Object Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.ScrollBars = "Vertical"
$textBox.Dock = "Fill"
$textBox.Font = New-Object Drawing.Font("Consolas", 10)
$textBox.Text = $finalText.Trim()
$form.Controls.Add($textBox)
# FIX: Remove auto-highlight on load
$form.Add_Shown({
    $textBox.SelectionStart = 0
    $textBox.SelectionLength = 0
})

# --- FIND / REPLACE LOGIC ---
$form.Add_KeyDown({
    if ($_.Control -and $_.KeyCode -eq "F") { Show-Search -ReplaceMode $false }
    if ($_.Control -and $_.KeyCode -eq "H") { Show-Search -ReplaceMode $true }
})

function Show-Search($ReplaceMode) {
    $searchForm = New-Object Windows.Forms.Form
    $searchForm.Text = if ($ReplaceMode) { "Find and Replace" } else { "Find" }
    $searchForm.Size = New-Object Drawing.Size(350, 180)
    $searchForm.StartPosition = "CenterParent"
    $searchForm.FormBorderStyle = "FixedDialog"

    $txtFind = New-Object Windows.Forms.TextBox
    $txtFind.Location = "100,20"
    $txtFind.Width = 200
    $searchForm.Controls.Add($txtFind)

    $lblFind = New-Object Windows.Forms.Label
    $lblFind.Text = "Find:"
    $lblFind.Location = "10,22"
    $searchForm.Controls.Add($lblFind)

    if ($ReplaceMode) {
        $txtRep = New-Object Windows.Forms.TextBox
        $txtRep.Location = "100,60"
        $txtRep.Width = 200
        $searchForm.Controls.Add($txtRep)

        $lblRep = New-Object Windows.Forms.Label
        $lblRep.Text = "Replace with:"
        $lblRep.Location = "10,62"
        $searchForm.Controls.Add($lblRep)
    }

    $btnDo = New-Object Windows.Forms.Button
    $btnDo.Text = if ($ReplaceMode) { "Replace All" } else { "Find Next" }
    $btnDo.Location = "225,100"
    $searchForm.Controls.Add($btnDo)

    $btnDo.Add_Click({
        if ($ReplaceMode) {
            $textBox.Text = $textBox.Text.Replace($txtFind.Text, $txtRep.Text)
        } else {
            $startIndex = $textBox.Text.IndexOf($txtFind.Text, $textBox.SelectionStart + $textBox.SelectionLength)
            if ($startIndex -eq -1) { $startIndex = $textBox.Text.IndexOf($txtFind.Text) } # Wrap around
            if ($startIndex -ne -1) {
                $textBox.Focus()
                $textBox.Select($startIndex, $txtFind.Text.Length)
                $textBox.ScrollToCaret()
            }
        }
    })
    $searchForm.ShowDialog()
}

# Panel for Buttons
$buttonPanel = New-Object Windows.Forms.Panel
$buttonPanel.Dock = "Bottom"
$buttonPanel.Height = 60
$form.Controls.Add($buttonPanel)

# Copy Button
$copyButton = New-Object Windows.Forms.Button
$copyButton.Text = "Copy All"
$copyButton.Size = "120, 35"
$copyButton.Location = "420, 10"
$copyButton.Add_Click({
    [Windows.Forms.Clipboard]::SetText($textBox.Text)
    [Windows.Forms.MessageBox]::Show("Copied to clipboard!")
})
$buttonPanel.Controls.Add($copyButton)

# Save Button
$saveButton = New-Object Windows.Forms.Button
$saveButton.Text = "Save List"
$saveButton.Size = New-Object Drawing.Size(120, 35)
$saveButton.Location = New-Object Drawing.Point(550, 10)
$saveButton.Add_Click({
    $saveDialog = New-Object Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text Files (*.txt)|*.txt"
    if ($saveDialog.ShowDialog() -eq "OK") {
        $textBox.Text | Out-File $saveDialog.FileName
        [Windows.Forms.MessageBox]::Show("File saved!", "Done")
    }
})
$buttonPanel.Controls.Add($saveButton)

# Show the GUI
$form.ShowDialog()
