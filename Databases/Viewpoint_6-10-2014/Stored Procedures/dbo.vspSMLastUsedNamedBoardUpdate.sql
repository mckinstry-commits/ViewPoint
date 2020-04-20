SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 6/4/13
-- Description:	Stores that last used Named board by user and company
-- =============================================
CREATE PROCEDURE [dbo].[vspSMLastUsedNamedBoardUpdate]
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

	IF EXISTS(SELECT * FROM SMDispatchLastUsedNamedBoard
			  WHERE VPUserName = @user AND SMCo = @SMCo)
		UPDATE SMDispatchLastUsedNamedBoard
		SET SMBoardName = @SMBoardName
		WHERE VPUserName = @user AND SMCo = @SMCo
	ELSE
		INSERT INTO SMDispatchLastUsedNamedBoard
			   (VPUserName
				,SMCo
			   ,SMBoardName
			   )
		 VALUES
			   (@user,
				@SMCo,
				@SMBoardName
				)


END
GO
GRANT EXECUTE ON  [dbo].[vspSMLastUsedNamedBoardUpdate] TO [public]
GO
