SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 5/20/10
-- Description:	Returns the upload value for a related record. Best used with an outer apply.
-- =============================================
CREATE FUNCTION [dbo].[vfIMGetRelatedValues]
(
	@ImportId varchar(20), @ImportTemplate varchar(10), @RecordType varchar(30), @RecordSeq int, @ColumnName varchar(30)
)
RETURNS TABLE
AS
RETURN
(
	SELECT ImportedVal, UploadVal
	FROM IMWE
		INNER JOIN DDUD ON IMWE.Identifier = DDUD.Identifier AND IMWE.Form = DDUD.Form
	WHERE ImportId = @ImportId AND ImportTemplate = @ImportTemplate AND RecordType = @RecordType AND RecordSeq = @RecordSeq AND DDUD.ColumnName = @ColumnName
)
GO
GRANT SELECT ON  [dbo].[vfIMGetRelatedValues] TO [public]
GO
