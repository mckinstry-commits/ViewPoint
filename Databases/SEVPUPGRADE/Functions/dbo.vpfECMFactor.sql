SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 12/22/09
-- Description:	Returns the ECM Factor
-- =============================================
CREATE FUNCTION [dbo].[vpfECMFactor]
(
	@ECM AS VARCHAR(1)
)
RETURNS INT
AS
BEGIN

	RETURN CASE @ECM WHEN 'E' THEN 1 WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END

END

GO
GRANT EXECUTE ON  [dbo].[vpfECMFactor] TO [public]
GO
