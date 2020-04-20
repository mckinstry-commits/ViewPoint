SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/26/09
-- Description:	Outputs a friendly varchar version of bYN
-- =============================================
CREATE FUNCTION [dbo].[vpfYesNo]
(@bYNValue bYN)
RETURNS VARCHAR(3)
AS
BEGIN
	RETURN(SELECT CASE WHEN @bYNValue = 'Y' THEN 'Yes' ELSE 'No' END)
END

GO
GRANT EXECUTE ON  [dbo].[vpfYesNo] TO [public]
GO
