SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang vspVAGetModules
-- Create date: 5/12/2007
-- Description:	Returns all modules
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetModules]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Mod FROM DDMO WHERE [Active] = 'Y' AND Mod NOT IN ('QA')
END


GO
GRANT EXECUTE ON  [dbo].[vspVAGetModules] TO [public]
GO
