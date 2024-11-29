
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force
$token = "your_canvas_API_token"
$headers =@{}
$headers.Add("Authorization","Bearer "+$token)
$baseurl = "https://your_instance_instructure.com"
$server = "database_server_name"
$database = "database_name"

function GetImportStatus
{ param([int]$ImportID)

         $apiurl="/api/v1/accounts/1/sis_imports/" + $ImportID 
         $url=$baseurl + $apiurl;
         $results = Invoke-WebRequest -Headers $headers -Method GET -Uri $url
         $userobj=ConvertFrom-Json $results.content;

  
  return $userobj 
}

function SISImport
{ param([string]$file)
          
         $apiurl="/api/v1/accounts/1/sis_imports.json?import_type=instructure_csv&extension=csv" 
         $url=$baseurl + $apiurl;
         $results = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -InFile $file
         $userobj = $results;

  return $userobj
}

function GetCourseCSVData #Make Course CSV from database
{
    $query = " SELECT 
                course_id
                , start_date
                , end_date
                , account_id
                , term_id
                , short_name
                , long_name
                
    * FROM [CanvasCourses]"

    $data = Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query -TrustServerCertificate
    $data | Export-Csv -Path "C:\temp\ImportData\2Courses.csv" -NoTypeInformation

}

function GetUsersCSVData #Make Users CSV from database
{
    $query = "select
     user_id
    , last_name
    , first_name
    , integration_id
    ,  login_id
    , 'active' as status
    from [CanvasUsers]"

    $data = Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query -TrustServerCertificate
    $data | Export-Csv -Path "C:\temp\ImportData\1Users.csv" -NoTypeInformation

}

function GetEnrollmentsCSVData #Make Enrollments CSV from database
{
    $query = "
    select course_id
    , role
    , status
    , completedind
    
    from CanvasCoursesStudents


    UNION

    course_id
    , role
    , status
    , completedind

	select * from CanvasCoursesStaff"
    
    $data = Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query -TrustServerCertificate
    $data | Export-Csv -Path "C:\temp\ImportData\3Enrollments.csv" -NoTypeInformation
}

GetUsersCSVData
Write-Host("Exporting Users CSV")
GetCourseCSVData 
Write-Host("Exporting Course CSV")
GetEnrollmentsCSVData 
Write-Host("Exporting Enrollments CSV")


$folderPath = "C:\temp\ImportData"
$files = Get-ChildItem -Path $folderPath -File | Where-Object length -ne 0 #Only import files which have data


foreach ($file in $files) 
{

    $SISImportData = SISImport $file.FullName
    Write-Host($SISImportData.id.ToString()  + " starting import for " + $file)

    $data = GetImportStatus $SISImportData.id
    while($data.progress -ne 100 -and $data.workflow_state -ne 'failed_with_messages')
    {
        $data = GetImportStatus $SISImportData.id
        Start-Sleep -Seconds 10
        Write-Host("Progress: " + $data.progress)
    }

    if($data.workflow_state -ne "imported")
    {
        if($data.progress -eq 0)
        {
            Write-Host($data.id.ToString() + " " +  $file + " failed. Error: ")
            $data.processing_warnings
        }
        else
        {
            Write-Host($data.id.ToString() + " " +  $file + " completed but has warnings: ")
            $data.processing_warnings
        }
        
    }
    else
    {
        write-host($data.id.ToString() + " " +  $file +  " is successful")
    }

}
