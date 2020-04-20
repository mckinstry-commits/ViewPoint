SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspDDSetSecurityForm
-- Create date: 9/18/07
-- Description:	Changes the Security Form in DDFH for the 
--				form that is passed in.
-- =============================================
CREATE PROCEDURE [dbo].[vspDDSetSecurityForm] 
-- Add the parameters for the stored procedure here
(@form VARCHAR(30), @securityForm VARCHAR(30))
as
set nocount on

BEGIN
	DECLARE @rcode int
	SET @rcode = 0
    -- update statements for procedure here
	UPDATE DDFH
	SET [SecurityForm] = @securityForm
	WHERE [Form] = @form
	if @@rowcount = 0 select @rcode = 1
 
	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspDDSetSecurityForm] TO [public]
GO
