SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  procedure [dbo].[vsp_AddFormReportSecurity]
/***********************************************************
* CREATED: GG 01/20/06
* MODIFIED 
*
* Adds security entries to vDDFS and vDDRS for Security Groups 100 and 101
* for all Version 6 forms and reports.
*
* 
*****************************************************/
   
as
   
set nocount on
   
declare @rcode int
   
select @rcode = 0

-- add Form Security entries for Security Group 100
insert vDDFS (Co, Form, SecurityGroup, VPUserName, Access, RecAdd, RecUpdate, RecDelete)
select -1, Form, 100, '', 0, 'Y', 'Y', 'Y'
from DDFHShared 
where Form not in (select Form from vDDFS where SecurityGroup = 100 and Co = -1)
and Version = 6

-- remove Form Security entries for forms that no longer exist
delete vDDFS
where Form not in (select Form from DDFHShared)


-- add Report Security entries for Security Group 101
insert vRPRS (Co, ReportID, SecurityGroup, VPUserName, Access)
select -1, ReportID, 101, '', 0
from RPRTShared 
where ReportID not in (select ReportID from vRPRS where SecurityGroup = 101 and Co = -1)


-- remove Report Security entries for reports that no longer exist
delete vRPRS
where ReportID not in (select ReportID from RPRTShared)


return








GO
GRANT EXECUTE ON  [dbo].[vsp_AddFormReportSecurity] TO [public]
GO
