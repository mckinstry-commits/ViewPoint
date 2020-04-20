SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Matt Pement
-- Create date: 10-0-09
-- Description:	Convert bit to bYN value
-- Modified:	JVH 6-24-11 Modified to return null when null is passed in
-- =============================================
CREATE FUNCTION [dbo].[vfBitToBYN]
(@bitValue bit)
RETURNS CHAR(1)
AS
BEGIN 
	RETURN (SELECT CASE @bitValue WHEN 0 THEN 'N' WHEN 1 THEN 'Y' ELSE NULL END)
END

GO
GRANT EXECUTE ON  [dbo].[vfBitToBYN] TO [public]
GO
