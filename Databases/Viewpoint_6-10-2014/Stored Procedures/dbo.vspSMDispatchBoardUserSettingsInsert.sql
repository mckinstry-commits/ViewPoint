SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 4/10/13
-- Description:	SM DispatchBoard User Settings
-- =============================================
CREATE PROCEDURE [dbo].[vspSMDispatchBoardUserSettingsInsert]
	@SMCo bCompany,
	@user bVPUserName,
	@SMBoardName varchar(50),
	@settings XML,
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

	IF EXISTS(SELECT * FROM SMDispatchBoardUserSettings 
			  WHERE VPUserName = @user AND SMCo = @SMCo AND SMBoardName = @SMBoardName)
		UPDATE SMDispatchBoardUserSettings
		SET UserSettingsData = @settings
		WHERE VPUserName = @user AND SMCo = @SMCo AND SMBoardName = @SMBoardName
	ELSE
		INSERT INTO SMDispatchBoardUserSettings
			   (VPUserName
				,SMCo
			   ,SMBoardName
			   ,UserSettingsData
			   )
		 VALUES
			   (@user,
				@SMCo,
				@SMBoardName,
				@settings
				)


END
GO
GRANT EXECUTE ON  [dbo].[vspSMDispatchBoardUserSettingsInsert] TO [public]
GO
