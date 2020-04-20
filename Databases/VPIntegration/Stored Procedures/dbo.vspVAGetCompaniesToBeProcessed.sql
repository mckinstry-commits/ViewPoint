SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang vspVAGetCompaniesToBeProcessed
-- Create date: 2/12/2009
-- Description:	Returns all companies that need to be processed in the cubes
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetCompaniesToBeProcessed]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select HQCo, Name, Co from HQCO h
Left Join DDBICompanies v on h.HQCo = v.Co
Order By HQCo
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVAGetCompaniesToBeProcessed] TO [public]
GO
