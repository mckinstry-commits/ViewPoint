SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Create Date:	6/23/11
* Created By:	AR - TK-07089
* Modified By:		
*		     
* Description: Return reports, replaces RPRTShared for performance reasons
*
* Inputs: ReportID 
			
*
* Outputs:
*
*************************************************/
CREATE FUNCTION dbo.vfRPRTShared (@ReportID INT)
RETURNS TABLE
AS
RETURN
    (
	WITH  cteRPRT ( ReportID, Title, [FileName], Location, ReportType, ShowOnMenu, ReportMemo, ReportDesc, AppType, [Version], IconKey, AvailableToPortal, Country )
              AS ( SELECT   ReportID ,
                            Title ,
                            [FileName] ,
                            Location ,
                            ReportType ,
                            ShowOnMenu ,
                            ReportMemo ,
                            ReportDesc ,
                            AppType ,
                            [Version] ,
                            IconKey ,
                            AvailableToPortal ,
                            Country                            
                   FROM     dbo.vRPRT
                   WHERE    ReportID = @ReportID
                 ),
            cteRPRTc ( ReportID, Title, [FileName], Location, ReportType, ShowOnMenu, ReportMemo, ReportDesc, AppType, [Version], IconKey, AvailableToPortal, Country, UserNotes, UniqueAttchID,ReportOwner )
              AS ( SELECT   ReportID ,
                            Title ,
                            [FileName] ,
                            Location ,
                            ReportType ,
                            ShowOnMenu ,
                            ReportMemo ,
                            ReportDesc ,
                            AppType ,
                            [Version] ,
                            IconKey ,
                            AvailableToPortal ,
                            Country ,
                            UserNotes ,
                            UniqueAttchID,
                            ReportOwner
                   FROM     dbo.vRPRTc
                   WHERE    ReportID = @ReportID
                 )
    SELECT  ISNULL(c.ReportID, t.ReportID) AS ReportID ,
            ISNULL(c.Title, t.Title) AS Title ,
            ISNULL(c.[FileName], t.[FileName]) AS FileName ,
            ISNULL(c.Location, t.Location) AS Location ,
            ISNULL(c.ReportOwner, 'viewpointcs') AS ReportOwner ,
            ISNULL(c.ReportType, t.ReportType) AS ReportType ,
            ISNULL(c.ShowOnMenu, ISNULL(t.ShowOnMenu, 'N')) AS ShowOnMenu ,
            ISNULL(c.ReportMemo, t.ReportMemo) AS ReportMemo ,
            ISNULL(c.ReportDesc, t.ReportDesc) AS ReportDesc ,
            c.UserNotes ,
            c.UniqueAttchID ,
            ISNULL(c.AppType, t.AppType) AS AppType ,
            ISNULL(c.[Version], t.[Version]) AS [Version] ,
            CASE WHEN c.ReportID IS NULL
                      AND t.ReportID IS NOT NULL THEN 'Standard'
                 WHEN c.ReportID IS NOT NULL
                      AND t.ReportID IS NOT NULL THEN 'Override'
                 WHEN c.ReportID IS NOT NULL
                      AND t.ReportID IS  NULL THEN 'Custom'
                 ELSE 'Unknown'
            END AS [Status] ,
            CASE WHEN c.ReportID IS NULL THEN 0
                 ELSE 1
            END AS Custom ,
            ISNULL(c.IconKey, t.IconKey) AS IconKey ,
            ISNULL(c.Country, t.Country) AS Country ,
            ISNULL(c.AvailableToPortal, t.AvailableToPortal) AS AvailableToPortal ,
            ISNULL(c.ReportID, t.ReportID) AS KeyID	-- used for attachments
    FROM    cteRPRTc AS c
            FULL OUTER JOIN cteRPRT AS t ON t.ReportID = c.ReportID
)
GO
GRANT SELECT ON  [dbo].[vfRPRTShared] TO [public]
GO
