SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[vpPortalDataGridColumnsLookupCheck]
(@DataGridColumnID INT, @AssociatedDataGridColumnID INT)
RETURNS BIT
AS
BEGIN 
	DECLARE @Valid AS BIT
	SET @Valid = 1
	
	SELECT @Valid = CASE WHEN keyColumnTable.DataGridID = associatedColumnTable.DataGridID THEN 1 ELSE 0 END
	FROM pPortalDataGridColumns keyColumnTable
		CROSS JOIN pPortalDataGridColumns associatedColumnTable
	WHERE keyColumnTable.DataGridColumnID = @DataGridColumnID AND associatedColumnTable.DataGridColumnID = @AssociatedDataGridColumnID

	RETURN @Valid
END


GO
