SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		CC
-- Create date: 4/23/2008
-- Description:	Checks if there are any settings for the user that require polling for new messages
-- =============================================
CREATE PROCEDURE [dbo].[vspWFCheckNotificationSettings] 
	-- Add the parameters for the stored procedure here
	@username varchar(128) = null, 
	@ShouldCheck int = 0 OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS (SELECT 1 FROM DDUP u
				LEFT OUTER JOIN vDDNotificationPrefs n ON n.VPUserName = u.VPUserName
				WHERE u.EMail IS NOT NULL AND (u.DefaultDestType <> 'EMail' OR n.Destination <> 'EMail') AND u.VPUserName = @username
				UNION ALL
				SELECT 1 FROM DDUP u WHERE u.EMail IS NOT NULL AND u.DefaultDestType <> 'EMail' AND u.VPUserName = @username
				)
		SET @ShouldCheck = 1
	ELSE
		SET @ShouldCheck = 0

END

GO
GRANT EXECUTE ON  [dbo].[vspWFCheckNotificationSettings] TO [public]
GO
