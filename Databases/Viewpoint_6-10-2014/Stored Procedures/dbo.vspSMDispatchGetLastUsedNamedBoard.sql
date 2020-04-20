SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 6/5/13
-- Description:	Returns Last used SMDispatchBoard
-- =============================================
CREATE PROCEDURE [dbo].[vspSMDispatchGetLastUsedNamedBoard]
	@SMCo bCompany,
	@user bVPUserName,
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

	SELECT SMBoardName FROM SMDispatchLastUsedNamedBoard
	WHERE VPUserName = @user AND SMCo = @SMCo


END
GO
GRANT EXECUTE ON  [dbo].[vspSMDispatchGetLastUsedNamedBoard] TO [public]
GO
