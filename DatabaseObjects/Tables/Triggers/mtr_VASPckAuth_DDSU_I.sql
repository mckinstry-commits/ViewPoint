USE [Viewpoint]
GO
/****** Object:  Trigger [dbo].[mtr_VASPckAuth_DDSU_I]    Script Date: 11/25/2014 8:55:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eric Shafer
-- Create date: 10/23/2014
-- Description:	Trigger to add/remove users from the VA Security Group for access to Security Approvals
-- =============================================
ALTER TRIGGER [dbo].[mtr_VASPckAuth_DDSU_I]
   ON  [dbo].[budVASPckAuthMembers] 
   AFTER INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	DECLARE @VPUserName bVPUserName 
	SELECT TOP 1 @VPUserName = VPUserName FROM INSERTED

	--CHECK FOR SEC GRP MEMBERSHIP AND ADD IF NO
	IF NOT EXISTS(SELECT TOP 1 1 
		FROM dbo.DDSU
		WHERE SecurityGroup = 1501
			AND VPUserName = @VPUserName
			)
		BEGIN
			INSERT INTO dbo.DDSU
					( SecurityGroup, VPUserName )
			SELECT 1501, @VPUserName
		 
		END
	--CHECK FOR Authorizor Header, ADD IF NO
	--IF NOT EXISTS(
	--	SELECT TOP 1 1 FROM udVASPckAuthorizors
	--	WHERE VPUserName = @VPUserName)
	--	BEGIN
	--		INSERT INTO dbo.udVASPckAuthorizors
	--				( VPUserName)
	--		VALUES  ( @VPUserName) 
	--    END 
	        

END
