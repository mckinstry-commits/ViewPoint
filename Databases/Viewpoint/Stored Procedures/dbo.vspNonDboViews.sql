SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 5/9/07
-- Description:	Returns any views that are not a dbo object
-- =============================================
CREATE PROCEDURE [dbo].[vspNonDboViews]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT Table_Name FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA <> 'dbo' 
GROUP BY Table_Name 
ORDER BY Table_Name

END

GO
GRANT EXECUTE ON  [dbo].[vspNonDboViews] TO [public]
GO
