clear-host
$prox  = Get-WmiObject Win32_Process -Filter "Name like '%handbrake%'" | Select-Object Commandline
$Proxc = $Prox | measure
if ($Proxc.Count -gt 0)     {exit}  

$watchFolders = @()
#$watchFolders += 'c:\Test'
$watchFolders += 'c:\Media'

$folder_Script = (Get-Variable PSScriptRoot).value
set-location  $folder_Script

$files =@()
forEach ($folder in $watchFolders)
    {
    $File_Current = (Get-ChildItem $Folder\* -recurse -include *.tp,*.mpg,*.ts,*.mkv).fullname
    If ($file_current -ne $null) 
        {$files += $File_current}
    }

$count     = 0
$handbrake = $Folder_Script + "\HandBrakeCli.exe"
$mediaInfo = $folder_script + "\MediaInfo.exe"

foreach ($file in $files)
    {
    $count += 1
    $CurrentFile = (Get-item -Path $file)
    If ($CurrentFile -like '*\.grab\*') {continue}
    $newFileName = $CurrentFile.Directory.FullName + '\' + $CurrentFile.BaseName + '.mp4'
    $host.ui.RawUI.WindowTitle = "Encoding: " + $count + " of " +$files.Count + '  --  '   + $CurrentFile.basename

    If (Test-Path $newFileName)   # Remove failed MP4 encode attempts
        {
        $newFileName = Get-Item $newFileName
        $length_MP4  = $null
        $length_mp4  = . $MediaInfo --Inform="Video;%Duration/String3%" $newFileName.FullName
        If ($Length_mp4.Length -eq '0')
            {
            write-host 'Removing: ' $newFileName
            Remove-Item $newFileName
            }   
        }

    If (!(Test-Path $newFileName))
        {
        #  Old Settings:  . $handbrake -i $currentFile.FullName -o $newFileName --format mp4 --width 640 --optimize --loose-anamorphic --modulus 2 --encoder x264 --vb 600 --two-pass  --turbo  --rate 29.97 --cfr --audio 1 --aencoder faac --mixdown stereo --arate Auto --ab 160 --audio-fallback ffac3 --x264-preset=VerySlow  --x264-profile=main  --h264-level="4.0"
        #  To add decombing, use these switches:       --decomb --comb-detect fast 
        #  If using Constant Quality, you have to enforce a framerate or else you'll get audio/video sync issues.   --cfr --rate 29.97
        #  To increase the quality of the video, lower the quality argument to 21, or even 20.  Don't go lower than 20 cause the file size will be huge.
        #. $handBrake   --input $currentFile.FullName  --output $newFileName  --format mp4    --optimize  --encoder x264  --quality 22  --cfr --rate 29.97  --encoder-preset Veryslow  --encoder-profile main     --encoder-level 4.0   --maxHeight 720

        # $height = [int]''
        $height   = . $MediaInfo --Inform="Video;%Height%" $currentFile.FullName
        Start-Sleep -Seconds 1

        If ([int]$height -gt [int]'500')   # High Def
            {
            . $handBrake   --input $currentFile.FullName  --output $newFileName  --format mp4    --optimize  --encoder x264  --quality 23  --cfr --rate 29.97  --encoder-preset veryslow  --encoder-profile main     --encoder-level 4.0
            }
        Else                               # Low Def
            {
            . $handBrake   --input $currentFile.FullName  --output $newFileName  --format mp4    --optimize  --encoder x264  --quality 21  --cfr --rate 29.97  --encoder-preset veryslow  --encoder-profile main     --encoder-level 4.0    --decomb --comb-detect fast
            }
        }
   }