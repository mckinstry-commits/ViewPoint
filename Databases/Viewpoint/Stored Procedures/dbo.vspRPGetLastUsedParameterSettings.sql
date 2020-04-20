SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPGetLastUsedParameterSettings]  
/********************************  
* Created: Nitor 12/7/2011 
* Modified:   
*  
* Retrieve the Last used parameters with there values used for the report with the passed in ID f  
* from the database for the current user   
*  
* Input:  
* @reportid Report ID  
* @username User Name
*  
* Output:  
*  
* Return code:  
* 0 = success, 1 = failure  
*  
*********************************/  
  (@reportid int = null, @username varchar(128) = null, @errmsg varchar(512) output)  
as  
set nocount on  
  
declare @rcode int  
select @rcode = 0  
  
if @reportid is null  
 begin  
  select @errmsg = 'Missing required input parameters: Report ID', @rcode = 1  
 end  
else  
 begin  
         select u.ParameterName
              , u.Value 
           from vRPSP u   
          where u.ReportID =  @reportid   
            and u.VPUserName = suser_sname()  
 end  
  
GO
GRANT EXECUTE ON  [dbo].[vspRPGetLastUsedParameterSettings] TO [public]
GO
