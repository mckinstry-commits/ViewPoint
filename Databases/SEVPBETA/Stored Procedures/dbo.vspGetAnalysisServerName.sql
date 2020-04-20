SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL vspGetAnalysisServerName
-- Create date: 6/11/2008
-- Description:	Returns the Analysis Server Name
-- Modification: AL 7/22/09 #134907 gets JobName and DatabaseName as well
-- =============================================
CREATE PROCEDURE [dbo].[vspGetAnalysisServerName]
	-- Add the parameters for the stored procedure here
	 (@rcode integer = 0, @msg varchar(255) = null output) as
   
BEGIN

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select AnalysisServer, OLAPJobName, OLAPDatabaseName from DDVS
	
bspexit:

return @rcode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspGetAnalysisServerName] TO [public]
GO
