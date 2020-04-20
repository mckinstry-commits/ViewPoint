SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspRPGetViewerSettings]
/********************************
* Created: TEJ 10/15/10 
* Modified: 
*
* Retrieve the Report Viewer settings used for the report with the passed in ID f
* from the database for the current user 
*
* Input:
*	@reportid	Report ID
*
* Output:
*
* Return code:
*	0 = success, 1 = failure
*
*********************************/
  (@reportid int = null, @errmsg varchar(512) output)
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
         select u.Zoom
              , u.ViewerWidth
              , u.ViewerHeight
           from vRPUP u 
          where u.ReportID =  @reportid 
            and u.VPUserName = suser_sname()
	end


GO
GRANT EXECUTE ON  [dbo].[vspRPGetViewerSettings] TO [public]
GO
