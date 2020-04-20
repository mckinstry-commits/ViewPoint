SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang vspVAGetCompanies
-- Create date: 5/12/2007
-- Description:	Returns all companies
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetCompanies]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT HQCo FROM [HQCO]
	UNION
	SELECT -1 AS HQCo
	
END



GO
GRANT EXECUTE ON  [dbo].[vspVAGetCompanies] TO [public]
GO
