SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/22/10
-- Description:	Returns the header record seq for a given IMWE record
--		so that you can join the correct records to a given set of IMWE records
-- =============================================
CREATE FUNCTION [dbo].[vfIMGetHeaderRecordSeq]
(	
	@ImportTemplate VARCHAR(20), @ImportId VARCHAR(20), @DetailRecordType VARCHAR(10), @DetailKeyRecColumn VARCHAR(60), @HeaderRecordType VARCHAR(10), @HeaderKeyRecColumn VARCHAR(60)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT IMWE.RecordSeq AS DetailRecordSeq, Header.RecordSeq AS HeaderRecordSeq
	FROM IMWE WITH (NOLOCK)
		INNER JOIN IMWE Header WITH (NOLOCK) ON IMWE.ImportTemplate = Header.ImportTemplate 
			AND IMWE.ImportId = Header.ImportId
			AND IMWE.UploadVal = Header.UploadVal
		INNER JOIN DDUD HeaderKeyRecorderIdentifier WITH (NOLOCK) ON IMWE.Form = HeaderKeyRecorderIdentifier.Form AND IMWE.Identifier = HeaderKeyRecorderIdentifier.Identifier
		INNER JOIN DDUD DetailKeyRecorderIdentifier WITH (NOLOCK) ON Header.Form = DetailKeyRecorderIdentifier.Form AND Header.Identifier = DetailKeyRecorderIdentifier.Identifier
	WHERE IMWE.ImportTemplate = @ImportTemplate AND IMWE.ImportId = @ImportId AND IMWE.RecordType = @DetailRecordType AND DetailKeyRecorderIdentifier.ColumnName = @DetailKeyRecColumn
		AND Header.RecordType = @HeaderRecordType AND HeaderKeyRecorderIdentifier.ColumnName = @HeaderKeyRecColumn
)

GO
GRANT SELECT ON  [dbo].[vfIMGetHeaderRecordSeq] TO [public]
GO
