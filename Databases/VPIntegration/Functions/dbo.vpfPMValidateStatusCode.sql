SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* Created:     8/26/09		JB
* Modified:	
* 
* Description:	Return true if the status code is valid for that category.
************************************************************/
CREATE FUNCTION [dbo].[vpfPMValidateStatusCode]
(@Status bStatus, @DocCat VARCHAR(10))
RETURNS BIT
AS
BEGIN
	DECLARE @returnValue BIT
	SET @returnValue = 0
	
	IF @Status IS NULL OR EXISTS(SELECT 1 FROM [PMSC] WHERE ([ActiveAllYN] = 'Y' OR [DocCat] = @DocCat) AND [Status] = @Status)
		BEGIN
			SET @returnValue = 1
		END
		
	RETURN @returnValue
END

GO
GRANT EXECUTE ON  [dbo].[vpfPMValidateStatusCode] TO [public]
GO
