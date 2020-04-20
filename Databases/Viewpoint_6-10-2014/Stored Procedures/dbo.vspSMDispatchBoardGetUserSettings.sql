SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 6/4/13
-- Description:	Returns SM DispatchBoard User Settings
-- =============================================
Create PROCEDURE [dbo].[vspSMDispatchBoardGetUserSettings]
	@SMCo bCompany,
	@user bVPUserName,
	@SMBoardName varchar(50),
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @SMCo IS NULL
	BEGIN
		SET @msg = 'Missing SM Company'
		RETURN 1
	END

	IF @user IS NULL
	BEGIN
		SET @msg = 'Missing VPUserName'
		RETURN 1
	END

		IF @SMBoardName IS NULL
	BEGIN
		SET @msg = 'Missing Board Name'
		RETURN 1
	END

	SELECT UserSettingsData FROM SMDispatchBoardUserSettings
	WHERE VPUserName = @user AND SMCo = @SMCo AND SMBoardName = @SMBoardName


END
GO
GRANT EXECUTE ON  [dbo].[vspSMDispatchBoardGetUserSettings] TO [public]
GO
