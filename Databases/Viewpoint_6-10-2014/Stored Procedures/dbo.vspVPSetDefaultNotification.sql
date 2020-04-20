SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/24/2008
-- Description:	Sets the default notification preference for a user from the user preferences dialog box
-- =============================================
CREATE PROCEDURE [dbo].[vspVPSetDefaultNotification] 
	-- Add the parameters for the stored procedure here
	@username varchar(128) = null, 
	@defaultType int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE DDUP SET DefaultDestType = 
									CASE @defaultType
										WHEN 0 THEN 'EMail'
										WHEN 1 THEN 'Viewpoint'
									END
	WHERE VPUserName = @username
END

GO
GRANT EXECUTE ON  [dbo].[vspVPSetDefaultNotification] TO [public]
GO
