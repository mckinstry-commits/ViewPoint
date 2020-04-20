
import-module activedirectory

$FilePath = "\\MCKVIEWPOINT\Viewpoint Repository\bulk inserts\TEST6.txt"
$Group = "ViewpointUsers"
$Package = "PM"
$Stuff = Import-CSV $FilePath 
#WRITE $Group
try{
$members=@() 
    Get-ADGroupMember -Identity $Group | Select-Object -ExpandProperty SamAccountName | ForEach-Object{ $members += $_.toLower() }
}
catch{
    $error.Message
}
#WRITE $members.mail

$members -eq $NULL

#ForEach ($member IN $members)
#{
#    WRITE-HOST $member 
#}

$File = Import-Csv $FilePath -delimiter "`t"
    ForEach ($Record IN $File) 
    {

        $User = $Record.Email -replace '@mckinstry.com',''
     
        If ($members -notcontains $User)
        {
        Add-ADGroupMember -Identity $Group -Member $User -PassThru -ErrorAction SilentlyContinue
        $members += $User
        WRITE-HOST $User "Added to domain group " $Group
        }
        Else
        {
            WRITE-HOST $User "Already a member of "$Group
            CONTINUE
        }

        $DefCompany = $Record.PRCo.Substring(0,2) -replace '"',''
        $Name = $Record.Name
        $Employee=$Record.Employee
        
        
        
        
        #$AddUser = ADAddUser $Record.Email $Group
        #SProcs $User $Record.Email $DefCompany $Name $Employee $Package
    
    
    
    
    
        #Stored proc to execute
        [string]$StoredProcedure = "dbo.mckspAddUserAccount"

        # Stored procedure return parameter name
        [string]$StoredProcedureReturnParameter = "@rcode"
        # Stored procedure output parameter name
        [string]$StoredProcedureOutputParameter = "@ReturnMessage"

        
        
        [System.Collections.Hashtable]$ProcParameterValueMappings = @{"@UserName"=$User; "Email" = $Record.Email; "@DefCompany"=$DefCompany;"@FullName"=$Name;"@Employee"= $Employee;"@Package" = $Package;}


        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = "Server=MCKTESTSQL04\VIEWPOINT ;Database=Viewpoint; Integrated Security=SSPI"

        $SqlConnection.Open() | Out-Null
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConnection
        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $SqlCmd.CommandText = $StoredProcedure

        $SqlCmd.Parameters.Add($StoredProcedureReturnParameter,  [System.Data.SqlDbType]::Int) | Out-Null
        $SqlCmd.Parameters[$StoredProcedureReturnParameter].Direction = [System.Data.ParameterDirection]::ReturnValue;

        $SqlCmd.Parameters.Add($StoredProcedureOutputParameter,  [System.Data.SqlDbType]::VarChar, 255) | Out-Null
        $SqlCmd.Parameters[$StoredProcedureOutputParameter].Direction = [System.Data.ParameterDirection]::Output;


        foreach ($ProcParameter in $ProcParameterValueMappings.Keys)
            {
                $SqlCmd.Parameters.Add($ProcParameter, $ProcParameterValueMappings[$ProcParameter]) | Out-Null
            }

        $SqlCmd.ExecuteNonQuery() | Out-Null

          
        $OutputValue = $SqlCmd.Parameters[$StoredProcedureOutputParameter].Value;
        WRITE-HOST $OutputValue

        $SqlConnection.Close() | Out-Null
        $SqlCmd.Dispose() | Out-Null
            
        RETURN $OutputValue
    }