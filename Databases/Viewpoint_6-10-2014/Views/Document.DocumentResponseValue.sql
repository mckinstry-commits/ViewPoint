SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentResponseValue]
AS
SELECT DocumentResponse.KeyID AS [Id],
      CAST(ResponseTable.Responses.query('local-name(.)') AS VARCHAR(50)) AS FieldName, 
	  ResponseTable.Responses.value('.', 'varchar(max)') AS ResponseValue,
	  ParticipantId,
	  DocumentId,
	  DocumentResponseId,
	  Processed
FROM Document.DocumentResponse
CROSS APPLY Response.nodes('/*/*') as ResponseTable(Responses)
GO
GRANT SELECT ON  [Document].[DocumentResponseValue] TO [public]
GRANT INSERT ON  [Document].[DocumentResponseValue] TO [public]
GRANT DELETE ON  [Document].[DocumentResponseValue] TO [public]
GRANT UPDATE ON  [Document].[DocumentResponseValue] TO [public]
GO
