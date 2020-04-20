SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Joe AmRhein
-- Create date: 2011-12-05
--
-- Description:	Updates the AvailableForPortal flag in the RPRTShared 
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdateReportPortalAvailability]
(@ReportID int,
@newSetting varchar(1))

AS

UPDATE RPRTShared
SET AvailableToPortal = @newSetting
WHERE ReportID = @ReportID


GO
GRANT EXECUTE ON  [dbo].[vpspUpdateReportPortalAvailability] TO [VCSPortal]
GO
