SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/24/2008
-- Description:	Returns the default notification type for a specified user
-- =============================================
CREATE PROCEDURE [dbo].[vspVPGetDefaultNotification] 
	-- Add the parameters for the stored procedure here
	@username VARCHAR(128) = NULL, 
	@defaultType int = 0 OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT @defaultType = 
		   CASE DefaultDestType 
				WHEN 'EMail' THEN 0
				WHEN 'Viewpoint' THEN 1
		   END
	FROM DDUP
	WHERE VPUserName = @username
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetDefaultNotification] TO [public]
GO
