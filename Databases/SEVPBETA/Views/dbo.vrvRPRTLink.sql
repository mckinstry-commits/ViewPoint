SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vrvRPRTLink] 
as 
/*
	Purpose
	View vrvRPRTLink is a copy of view RPRT with the exception of ReportID 
	being cast as a varchar(60) rather than an int.
    This allows view RPRT.ReportID to be linked to WFTemplateSteps.VPName
	because VPName is cast as a varchar(60) rather than a int

Maintenance Log
Issue	Created		Created By		Description
136443	11/17/2009	C Wirtz			New

*/
SELECT cast(ReportID as varchar(60)) as ReportID
      ,[Title]
      ,[FileName]
      ,[Location]
      ,[ReportType]
      ,[ShowOnMenu]
      ,[ReportMemo]
      ,[ReportDesc]
      ,[AppType]
      ,[Version]
      ,[IconKey]
      ,[AvailableToPortal]
      ,[Country]
 From RPRT a
GO
GRANT SELECT ON  [dbo].[vrvRPRTLink] TO [public]
GRANT INSERT ON  [dbo].[vrvRPRTLink] TO [public]
GRANT DELETE ON  [dbo].[vrvRPRTLink] TO [public]
GRANT UPDATE ON  [dbo].[vrvRPRTLink] TO [public]
GO
