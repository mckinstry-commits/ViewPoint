SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Matt Pement
-- Create date: 10-0-09
-- Description:	Convert bit to bYN value
-- =============================================
CREATE FUNCTION [dbo].[vfBYNToBit] 
(
	@bYNValue CHAR(1)
)
RETURNS bit
AS
BEGIN
		RETURN (SELECT CASE WHEN @bYNValue = 'Y' THEN 1 ELSE 0 END)
END

GO
GRANT EXECUTE ON  [dbo].[vfBYNToBit] TO [public]
GO
