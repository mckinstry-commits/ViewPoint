SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPGetReportsByAppType]
/********************************
* Created:  2012-06-05 Chris Crewdson
* Modified: 
*
* Returns information about all reports that match the AppType and LocType parameters
*
* Inputs:
* @apptype - apptype of the reports we want to select
* @loctype - loctype of the reports we want to select
* 
* Output:
* 
* Return code:
*	0 = success, 1 = failure
* 
*********************************/
(@apptype varchar(512) = null,
 @loctype varchar(20) = null)
AS
BEGIN
SET NOCOUNT ON

SELECT [ReportID]
      ,[Title]
      ,[FileName]
      ,rt.[Location]
      ,rl.[Path]
  FROM [dbo].[RPRTShared] rt
  JOIN dbo.RPRL rl ON rt.Location = rl.Location
  WHERE [AppType] = @apptype
  AND [LocType] = @loctype

END
GO
GRANT EXECUTE ON  [dbo].[vspRPGetReportsByAppType] TO [public]
GO
