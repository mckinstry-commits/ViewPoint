SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--****************************************************
--  Purpose:
--  Extract Informational and Error data to aid customers 
--  to isolate errors in Crystal reports
--
--  Maintenance Log
--  Issue  Date		Coder		Description
--  126900 01/28/08	C.Wirtz		Added "Reports with Errors" SQL
--								Added Nolock option to SQL Tables
--								Added RPRF.Description field to Select 
-----------------------------------------------------------
--	xxxxxx mm/dd/yy xxxxxxxx	next update description
--
--
--*******************************************************************
CREATE view [dbo].[vrvRPV6Upgrade]

as
/**Reports with Attachments**/
select distinct 
  RPObjectType='Attach', 
  RPRTc.ReportID,
  RPRTc.Title,
  RPRTc.ReportOwner,
  RPRTc.Location,
  RPRTc.FileName,
  RPRF.FieldType,
  RPRF.Name,
  RPRF.ReportText,
  RPRF.Description
From RPRF (nolock)
Join RPRTc (nolock) on RPRTc.ReportID=RPRF.ReportID
Join RPRL (nolock)on RPRL.Location=RPRTc.Location
Where 
 RPRF.FieldType='Tables' and 
 (RPRF.ReportText like '%HQAT%' or RPRF.ReportText like '%brvAttachments%')
 --and RPRTc.ReportID>=10000

union all

/**Reports using CRUFLE**/

Select distinct
  RPObjectType='CRUFLE',
  RPRF.ReportID,
  RPRTc.Title,
  RPRTc.ReportOwner,
  RPRTc.Location,
  RPRTc.FileName,
  RPRF.FieldType,
  RPRF.Name,
  RPRF.ReportText,
  RPRF.Description
  
From RPRF (nolock)
Inner Join RPRTc (nolock) on RPRTc.ReportID=RPRF.ReportID
Join RPRL (nolock) on RPRL.Location=RPRTc.Location
Where (ReportText Like ('%EFCityStateZip%')or ReportText Like ('%EFDateToMonth%')or ReportText Like ('%EFNumDivide%')
or ReportText Like ('%EFBeginEndLabel%')or ReportText Like ('%EFEmployeeName%')or ReportText Like ('%EFCityStateZip%')
or ReportText Like ('%EFUserName%')or ReportText Like ('%EFRandom%') or ReportText Like ('%EFDisplayReportName%')
or ReportText Like ('%EFDateFormat%')) 
--and RPRTc.ReportID>=10000

union all

/**Reports using stored procedure and views or 2+ stored procedures**/

select distinct 
  RPObjectType='Stored Proc', 
  RPRTc.ReportID,
  RPRTc.Title,
  RPRTc.ReportOwner,
  RPRTc.Location,
  RPRTc.FileName,
  RPRF.FieldType,
  RPRF.Name,
  RPRF.ReportText,
  RPRF.Description
From RPRF (nolock)
Join RPRTc (nolock) on RPRTc.ReportID=RPRF.ReportID
Join RPRL (nolock) on RPRL.Location=RPRTc.Location
Where 
 --RPRTc.ReportID>=10000 and
 RPRF.FieldType='Stored Procedure' 
   and exists (select distinct r.ReportID From RPRF r 
                where r.ReportID=RPRF.ReportID 
                      and r.FieldType in ('Tables','Stored Procedure')
                      and r.ReportType=RPRF.ReportType
                      and 
                      r.ReportText<>RPRF.ReportText and
                      (case when r.ReportType='Sub Report' then RPRF.Description else '' end)=
                      (case when r.ReportType='Sub Report' then r.Description else '' end)
                )

Union All
/**Reports with Errors**/
select distinct 
  RPObjectType='Report', 
  RPRTc.ReportID,
  RPRTc.Title,
  RPRTc.ReportOwner,
  RPRTc.Location,
  RPRTc.FileName,
  RPRF.FieldType,
  RPRF.Name,
  RPRF.ReportText,
  RPRF.Description
From RPRF (nolock)
Join RPRTc (nolock) on RPRTc.ReportID=RPRF.ReportID
Join RPRL (nolock) on RPRL.Location=RPRTc.Location
Where 
 RPRF.FieldType='Saved Data' OR
 (RPRF.ReportText like '%Error in%')

GO
GRANT SELECT ON  [dbo].[vrvRPV6Upgrade] TO [public]
GRANT INSERT ON  [dbo].[vrvRPV6Upgrade] TO [public]
GRANT DELETE ON  [dbo].[vrvRPV6Upgrade] TO [public]
GRANT UPDATE ON  [dbo].[vrvRPV6Upgrade] TO [public]
GO
