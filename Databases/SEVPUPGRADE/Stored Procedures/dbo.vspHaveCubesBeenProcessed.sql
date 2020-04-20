SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL vspHaveCubesBeenProcessed
-- Create date: 6/11/2008
-- Description:	<Returns the bYN value to determine if the cubes need have been processed>
-- =============================================
CREATE PROCEDURE [dbo].[vspHaveCubesBeenProcessed]
	-- Add the parameters for the stored procedure here
	 (@rcode integer = 0 output) as
   
BEGIN

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Select CubesProcessed from DDVS

bspexit:

return @rcode
	
END

GO
GRANT EXECUTE ON  [dbo].[vspHaveCubesBeenProcessed] TO [public]
GO
