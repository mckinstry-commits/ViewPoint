SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[vspDDFSDeleteTabEntries] 
	
(@co SMALLINT, @form VARCHAR(30), @securitygroup int, @username VARCHAR(128))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF EXISTS (SELECT * FROM DDTS WHERE [Co] = @co AND [Form] = @form AND [SecurityGroup] = @securitygroup AND [VPUserName] = @username)
   DELETE [DDTS]
	WHERE [Co] = @co AND [Form] = @form AND [SecurityGroup] = @securitygroup AND [VPUserName] = @username

END

GO
GRANT EXECUTE ON  [dbo].[vspDDFSDeleteTabEntries] TO [public]
GO
