SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/23/09
-- Description:	Gets the header record from vPRMyTimesheet
-- =============================================
CREATE PROCEDURE [dbo].[vpspPRMyPersonalTimeSheetGet]
	(@Key_PRCo bCompany, @Key_EntryEmployee bEmployee)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC vpspPRMyTimeSheetGet 'Y', @Key_PRCo, @Key_EntryEmployee
END


GO
GRANT EXECUTE ON  [dbo].[vpspPRMyPersonalTimeSheetGet] TO [VCSPortal]
GO
