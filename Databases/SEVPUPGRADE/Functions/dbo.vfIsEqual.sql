SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/2/11
-- Description:	IsEqual will return whether the 2 supplied values are the same.
--				This will also take into account if they are both null (meaning if both are null 1 will be returned).
-- =============================================
CREATE FUNCTION [dbo].[vfIsEqual]
(
	@valueOne sql_variant, @valueTwo sql_variant
)
RETURNS bit
AS
BEGIN
	IF (@valueOne IS NULL AND @valueTwo IS NULL) OR (@valueOne = @valueTwo)
		RETURN 1
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vfIsEqual] TO [public]
GO
