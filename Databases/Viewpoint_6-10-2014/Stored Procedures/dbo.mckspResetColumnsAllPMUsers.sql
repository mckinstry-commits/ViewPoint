SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 3/6/2014
-- Description:	Cursor to update all user projection column settings
-- =============================================
CREATE PROCEDURE [dbo].[mckspResetColumnsAllPMUsers] 
	-- Add the parameters for the stored procedure here
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM dbo.JCUO
	WHERE UserName <> 'viewpointcs' AND UserName <> 'PML1'

		DECLARE mck_UserColumn_Settings CURSOR FOR 
			SELECT up.DefaultCompany, up.VPUserName 
			FROM dbo.DDUP up
			INNER JOIN dbo.DDSU su ON su.VPUserName = up.VPUserName
			WHERE su.SecurityGroup IN (200,201,202)
			AND su.VPUserName NOT LIKE 'PML%' AND su.VPUserName <> 'viewpointcs'

		DECLARE @Company bCompany, @VPUserName bVPUserName

		OPEN mck_UserColumn_Settings
		FETCH FROM mck_UserColumn_Settings INTO @Company, @VPUserName

		WHILE @@FETCH_STATUS = 0
		BEGIN

			EXEC mckspJCCPColDef @Company, @VPUserName

			FETCH NEXT FROM mck_UserColumn_Settings INTO @Company, @VPUserName
		END

		CLOSE mck_UserColumn_Settings
		DEALLOCATE mck_UserColumn_Settings

END
GO
