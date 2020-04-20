SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang vspVAUpdateCompaniesToBeProcessed
-- Create date: 2/12/2009
-- Description:	Inserts companies that need to be processed in the cubes
-- =============================================
CREATE PROCEDURE [dbo].[vspVAUpdateCompaniesToBeProcessed]

(@CoArray VARCHAR(8000))

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	

--Delete all current rows
Delete From DDBICompanies
    
--Insert all the new records    
Insert into DDBICompanies (Co)
SELECT Company FROM vfCoTableFromArray(@CoArray)
Where Company not in(Select Co from DDBICompanies)
	
END


GO
GRANT EXECUTE ON  [dbo].[vspVAUpdateCompaniesToBeProcessed] TO [public]
GO
