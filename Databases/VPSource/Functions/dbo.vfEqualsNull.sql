SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 7/7/11
-- Description:	Returns whether the value passed is null
-- =============================================
CREATE FUNCTION [dbo].[vfEqualsNull]
(
	@value sql_variant
)
RETURNS bit
AS
BEGIN
	RETURN CASE WHEN @value IS NULL THEN 1 ELSE 0 END
END
GO
GRANT EXECUTE ON  [dbo].[vfEqualsNull] TO [public]
GO
