SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Aaron Lang, vspVADDFSFormSecurity>
-- Create date: <05/22/03>
-- Description:	<Description>
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDFSFormSecurity]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM DDFS
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDFSFormSecurity] TO [public]
GO
