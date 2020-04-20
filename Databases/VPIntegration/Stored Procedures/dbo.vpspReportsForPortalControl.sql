SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:        Joe AmRhein
-- Create date: 2011-09-08
-- Modified:    2011-10-12 TomJ Added some logic to pull all available reports for PortalAdmin and ViewpointCS
--              2011-11-27 TomJ Fixed join that was missing reports that were added but didn't have any security
--                         records added yet
--				2012-05-16 JoeA Added Reports without parameters to conditional access
--
-- Description:   Returns active reports to be launched for a particular portal control
-- =============================================
CREATE PROCEDURE [dbo].[vpspReportsForPortalControl]
(@PortalControlID int,
@RoleID int)

AS

WITH NullList AS
(
      SELECT ReportID, COUNT(1) NullCount FROM RPRPShared WHERE PortalParameterDefault IS NOT NULL GROUP BY ReportID
),
--Valid Reports is a list of all ReportIDs that either have ALL of their PortalParameterDefaults not null, or don't have any parameters
ValidReports AS
(
      SELECT 
            FullList.ReportID
      FROM 
            RPRPShared FullList JOIN NullList ON NullList.ReportID = FullList.ReportID
      GROUP BY FullList.ReportID, NullCount
      HAVING COUNT(1) = NullCount
      UNION 
      SELECT      RPRTShared.ReportID
      FROM  RPRTShared LEFT OUTER JOIN RPRPShared ON RPRPShared.ReportID = dbo.RPRTShared.ReportID
      WHERE RPRPShared.ParameterName IS NULL
)

SELECT DISTINCT rcs.ReportID, rprt.Title
FROM [pvReportControlsShared] AS rcs
JOIN [RPRTShared] AS rprt ON rcs.ReportID = rprt.ReportID
LEFT JOIN [pvReportSecurityShared] AS rs ON rcs.ReportID = rs.ReportID
WHERE rcs.PortalControlID = @PortalControlID AND
      (
            ((rs.RoleID = @RoleID OR @RoleID IN (0,1)) AND
            rcs.AccessASbYN = 'Y' AND 
            rprt.AvailableToPortal = 'Y' AND 
            rs.Access <> 0)
      AND
            (rs.Access = 2
      OR
            (rs.Access = 1 AND rs.ReportID IN (SELECT ReportID FROM ValidReports))))
GO
GRANT EXECUTE ON  [dbo].[vpspReportsForPortalControl] TO [VCSPortal]
GO
