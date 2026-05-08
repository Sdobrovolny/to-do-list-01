Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$dataFile = Join-Path $PSScriptRoot 'tasks.json'

function Load-Tasks {
    if (Test-Path $dataFile) {
        try {
            $json = Get-Content $dataFile -Raw -Encoding UTF8
            if ([string]::IsNullOrWhiteSpace($json)) { return @() }
            $arr = $json | ConvertFrom-Json
            if ($null -eq $arr) { return @() }
            return @($arr)
        } catch { return @() }
    }
    return @()
}

function Save-Tasks {
    $script:tasks | ConvertTo-Json -Depth 3 | Out-File -FilePath $dataFile -Encoding UTF8
}

$script:tasks = Load-Tasks

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Můj To-Do List'
$form.Size = New-Object System.Drawing.Size(520, 600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)
$form.MinimumSize = New-Object System.Drawing.Size(420, 400)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Můj To-Do List'
$title.Font = New-Object System.Drawing.Font('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 100)
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.Size = New-Object System.Drawing.Size(460, 30)
$title.TextAlign = 'MiddleCenter'
$title.Anchor = 'Top, Left, Right'
$form.Controls.Add($title)

$txtNew = New-Object System.Windows.Forms.TextBox
$txtNew.Location = New-Object System.Drawing.Point(20, 55)
$txtNew.Size = New-Object System.Drawing.Size(360, 28)
$txtNew.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$txtNew.Anchor = 'Top, Left, Right'
$form.Controls.Add($txtNew)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = 'Přidat'
$btnAdd.Location = New-Object System.Drawing.Point(390, 54)
$btnAdd.Size = New-Object System.Drawing.Size(90, 30)
$btnAdd.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$btnAdd.BackColor = [System.Drawing.Color]::FromArgb(102, 126, 234)
$btnAdd.ForeColor = [System.Drawing.Color]::White
$btnAdd.FlatStyle = 'Flat'
$btnAdd.FlatAppearance.BorderSize = 0
$btnAdd.Anchor = 'Top, Right'
$form.Controls.Add($btnAdd)

$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Location = New-Object System.Drawing.Point(20, 100)
$listBox.Size = New-Object System.Drawing.Size(460, 410)
$listBox.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$listBox.CheckOnClick = $true
$listBox.Anchor = 'Top, Bottom, Left, Right'
$listBox.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($listBox)

$btnDelete = New-Object System.Windows.Forms.Button
$btnDelete.Text = 'Smazat vybraný'
$btnDelete.Location = New-Object System.Drawing.Point(20, 520)
$btnDelete.Size = New-Object System.Drawing.Size(140, 32)
$btnDelete.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnDelete.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$btnDelete.ForeColor = [System.Drawing.Color]::White
$btnDelete.FlatStyle = 'Flat'
$btnDelete.FlatAppearance.BorderSize = 0
$btnDelete.Anchor = 'Bottom, Left'
$form.Controls.Add($btnDelete)

$btnClearDone = New-Object System.Windows.Forms.Button
$btnClearDone.Text = 'Smazat hotové'
$btnClearDone.Location = New-Object System.Drawing.Point(170, 520)
$btnClearDone.Size = New-Object System.Drawing.Size(140, 32)
$btnClearDone.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$btnClearDone.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$btnClearDone.ForeColor = [System.Drawing.Color]::White
$btnClearDone.FlatStyle = 'Flat'
$btnClearDone.FlatAppearance.BorderSize = 0
$btnClearDone.Anchor = 'Bottom, Left'
$form.Controls.Add($btnClearDone)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(320, 526)
$lblStatus.Size = New-Object System.Drawing.Size(160, 20)
$lblStatus.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$lblStatus.ForeColor = [System.Drawing.Color]::Gray
$lblStatus.TextAlign = 'MiddleRight'
$lblStatus.Anchor = 'Bottom, Right'
$form.Controls.Add($lblStatus)

function Refresh-List {
    $listBox.Items.Clear()
    foreach ($t in $script:tasks) {
        $idx = $listBox.Items.Add($t.text)
        $listBox.SetItemChecked($idx, [bool]$t.done)
    }
    $left = @($script:tasks | Where-Object { -not $_.done }).Count
    $total = $script:tasks.Count
    $lblStatus.Text = "Zbývá: $left | Celkem: $total"
}

$btnAdd.Add_Click({
    $text = $txtNew.Text.Trim()
    if ([string]::IsNullOrEmpty($text)) { return }
    $script:tasks = @($script:tasks) + @([PSCustomObject]@{ text = $text; done = $false })
    $txtNew.Text = ''
    Save-Tasks
    Refresh-List
    $txtNew.Focus()
})

$txtNew.Add_KeyDown({
    if ($_.KeyCode -eq 'Enter') {
        $btnAdd.PerformClick()
        $_.SuppressKeyPress = $true
    }
})

$listBox.Add_ItemCheck({
    param($s, $e)
    $script:tasks[$e.Index].done = ($e.NewValue -eq 'Checked')
    $form.BeginInvoke([Action]{
        Save-Tasks
        $left = @($script:tasks | Where-Object { -not $_.done }).Count
        $total = $script:tasks.Count
        $lblStatus.Text = "Zbývá: $left | Celkem: $total"
    }) | Out-Null
})

$btnDelete.Add_Click({
    $i = $listBox.SelectedIndex
    if ($i -lt 0) { return }
    $script:tasks = @($script:tasks | Where-Object { $script:tasks.IndexOf($_) -ne $i })
    $newList = New-Object System.Collections.ArrayList
    for ($k = 0; $k -lt $script:tasks.Count; $k++) {
        if ($k -ne $i) { [void]$newList.Add($script:tasks[$k]) }
    }
    $script:tasks = @($newList.ToArray())
    Save-Tasks
    Refresh-List
})

$btnClearDone.Add_Click({
    $doneCount = @($script:tasks | Where-Object { $_.done }).Count
    if ($doneCount -eq 0) { return }
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Smazat všechny hotové úkoly ($doneCount)?",
        'Potvrzení',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne 'Yes') { return }
    $script:tasks = @($script:tasks | Where-Object { -not $_.done })
    Save-Tasks
    Refresh-List
})

$form.Add_Shown({ $txtNew.Focus() })

Refresh-List
[void]$form.ShowDialog()
