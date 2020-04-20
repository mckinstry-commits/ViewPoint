SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Charles Courchaine
-- Create date: 2/7/2008
-- Description:	Retrieves new messages for a given user and markes them as not new
-- =============================================
CREATE PROCEDURE [dbo].[vspWFCheckForNewMessages] 
	-- Add the parameters for the stored procedure here
	@UserName bVPUserName = null, 
	@NewMessageCount int = 0 OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select @NewMessageCount = count(*) from WFMail where [UserID] = @UserName and [IsNew] = 'Y'
	update WFMail set [IsNew] = 'N' where [UserID] = @UserName and [IsNew] = 'Y'
END

GO
GRANT EXECUTE ON  [dbo].[vspWFCheckForNewMessages] TO [public]
GO
