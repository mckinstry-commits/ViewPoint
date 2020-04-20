SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE                PROCEDURE [dbo].[vspVPMenuGetReportingServicesFullPath]
/**************************************************
* Created:  JK 02/09/04 - NEW
* Modified: 
*
* Used by VPMenu to retrieve the ReportName and Location of an SQLReportingServices
* report.
*
* The key of vDDFU is  username + form.
*
* The output depends on the username being viewpointcs or other.
* 
* Inputs
*       @reportid		The ID of the SQL Reporting Services report.
*
* Output
*	@fullpath 		Concatenation of path and report filename.
*	@errmsg
*
****************************************************/
	(@reportid int = null, @errmsg varchar(512) output)
as

set nocount on 
declare @rcode int
select @rcode = 0

-- Check for required fields
if (@reportid is null) 
	begin
	select @errmsg = 'Missing required field:  reportid.  [vspVPMenuGetReportingServicesFullPath]', @rcode = 1
	goto vspexit
	end

begin	
-- Attempt an UPDATE first.
SELECT rprl.Path + rprt.FileName
FROM RPRTShared rprt
INNER JOIN vRPRL rprl ON rprt.Location = rprl.Location
WHERE rprt.ReportID = @reportid
end
   
vspexit:
	return @rcode














GO
GRANT EXECUTE ON  [dbo].[vspVPMenuGetReportingServicesFullPath] TO [public]
GO
