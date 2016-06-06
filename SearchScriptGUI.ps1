#ERASE ALL THIS AND PUT XAML BELOW between the @" "@ 
$inputXML = @"
<Window x:Class="TextSearchGUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:TextSearchGUI"
        mc:Ignorable="d"
        Title="Text Search" Height="450" Width="1000">
    <Grid Margin="10,10,-0.333,-0.333">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="86*"/>
            <ColumnDefinition Width="0*"/>
            <ColumnDefinition Width="0*"/>
            <ColumnDefinition Width="859*"/>
        </Grid.ColumnDefinitions>
        <TextBox x:Name="directoryBox" HorizontalAlignment="Left" Height="23" Margin="25,50,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="317" Grid.Column="2" Grid.ColumnSpan="2"/>
        <TextBox x:Name="filetypeBox" HorizontalAlignment="Left" Height="23" Margin="25,100,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="317" Grid.Column="2" Grid.ColumnSpan="2"/>
        <TextBox x:Name="searchkeyBox" HorizontalAlignment="Left" Height="23" Margin="25,150,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="317" Grid.Column="2" Grid.ColumnSpan="2"/>
        <TextBlock x:Name="directoryLabel" HorizontalAlignment="Left" Margin="35,50,0,0" TextWrapping="Wrap" Text="Directory:" VerticalAlignment="Top" Height="16" Width="57" Grid.ColumnSpan="4"/>
        <TextBlock x:Name="filetypeLabel" HorizontalAlignment="Left" Margin="32,100,0,0" TextWrapping="Wrap" Text="Filetype:" VerticalAlignment="Top" Height="16" Width="60" Grid.ColumnSpan="4"/>
        <TextBlock x:Name="searchkeyLabel" HorizontalAlignment="Left" Margin="32,150,0,0" TextWrapping="Wrap" Text="Search key:" VerticalAlignment="Top" Height="16" Width="60" Grid.ColumnSpan="4"/>
        <Button x:Name="searchButton" Content="Search" HorizontalAlignment="Left" Margin="25,219,0,0" VerticalAlignment="Top" Width="144" Height="22" Grid.Column="2" Grid.ColumnSpan="2"/>
        <ListView x:Name="listView" HorizontalAlignment="Left" Height="320" VerticalAlignment="Top" Width="450" Grid.Column="3" Margin="400,33,0,0" IsSynchronizedWithCurrentItem="False" Background="White">
            <ListView.View>
                <GridView>
                    <GridViewColumn/>
                </GridView>
            </ListView.View>
        </ListView>
        <TextBlock x:Name="resultText" Grid.Column="3" HorizontalAlignment="Left" Margin="399.667,17,0,0" TextWrapping="Wrap" Text="Results" VerticalAlignment="Top" Width="71"/>
        <Button x:Name="exportButton" Content="Export to CSV" Grid.Column="3" HorizontalAlignment="Left" Margin="399.667,358,0,0" VerticalAlignment="Top" Width="100"/>
        <TextBox x:Name="exportLocation" Grid.Column="3" HorizontalAlignment="Left" Height="23" Margin="504.667,358,0,0" TextWrapping="NoWrap" VerticalAlignment="Top" Width="345"/>

    </Grid>
</Window>
"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
    $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
#Get-FormVariables
 
#===========================================================================
# Actually make the objects work
#===========================================================================
 
 
#Sample entry of how to add data to a field
 
#$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})
 
#===========================================================================
# Shows the form
#===========================================================================
$results = New-Object System.Collections.Generic.List[System.Object]
$WPFdirectoryBox.AddText(($pwd).path)
$WPFexportLocation.AddText(($pwd).path+"\results.csv")
Function Get-Results{
    param(
	[string]$Directory,
    [string[]]$Filetype,
    [string[]]$Search
    )
    Write-Host "Working..."
    foreach($Type in $Filetype){
        foreach($Key in $Search){
            Get-ChildItem $Directory -Include ('*.' + $Type) -Recurse | Select-String -Pattern $Key
        }
    }
}

$ctxMenu = New-Object System.Windows.Controls.ContextMenu
$ctxCopy = New-Object System.Windows.Controls.MenuItem
$ctxOpen = New-Object System.Windows.Controls.MenuItem
$ctxExplore = New-Object System.Windows.Controls.MenuItem
$ctxCopy.InputGestureText = "Copy Path"
$ctxOpen.InputGestureText = "Open"
$ctxExplore.InputGestureText = "Open location"
$ctxCopy.Add_Click({
    $dir = $WPFlistView.SelectedItem.Path | clip.exe
    })
$ctxOpen.Add_Click({
    $dir = $WPFlistView.SelectedItem.Path
    ii $dir
    })
$ctxExplore.Add_Click({
    $dir = $WPFlistView.SelectedItem.Path
    Invoke-Expression "explorer '/select,$dir'"
    })
$ctxOpen.Name = "Open"
$ctxMenu.AddChild($ctxCopy)
$ctxMenu.AddChild($ctxOpen)
$ctxMenu.AddChild($ctxExplore)
$WPFlistView.ContextMenu = $ctxMenu
$WPFexportButton.Add_Click({
    $results | Select-Object @{expression={$_.LineNumber}; label = 'Number'},Filename,Path,@{expression={$_.Pattern}; label = 'Search'} | Export-CSV -Path $WPFexportLocation.Text -NoTypeInformation
})
$WPFsearchButton.Add_Click({ 
    $WPFlistView.Items.Clear()
    $results.Clear()
    $Directory = $WPFDirectoryBox.Text
    [string[]] $filetypes = $WPFfiletypeBox.Text.Split(',')
    [string[]] $searchkeys = $WPFsearchkeyBox.Text.Split(',')
    
    Get-Results -Directory $Directory -Filetype $filetypes -Search $searchkeys | %{$WPFlistView.AddChild($_); $results.Add($_)}
})
$Form.ShowDialog() | out-null