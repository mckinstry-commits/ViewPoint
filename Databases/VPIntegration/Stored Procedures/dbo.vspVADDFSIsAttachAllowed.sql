SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL
-- Create date: 06/22/07
-- Description:	Retrieves the AllowAttachment value for a 
--				single record in the DDFHShared table.
-- =============================================
CREATE PROCEDURE  [dbo].[vspVADDFSIsAttachAllowed]
	-- Add the parameters for the stored procedure here
	(@form VARCHAR(30))
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [AllowAttachments] FROM [DDFHShared]
	WHERE [Form] = @form
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSIsAttachAllowed] TO [public]
GO
