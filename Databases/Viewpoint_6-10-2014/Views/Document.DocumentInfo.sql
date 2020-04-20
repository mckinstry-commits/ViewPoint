SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[DocumentInfo] 
AS 

SELECT doc.Title
, sndr.DisplayName
, doc.DueDate
, typ.DocumentTypeName
, doc.CreatedByUser As CreatedBy
, doc.KeyID
, doc.DocumentId
, doc.[State]
FROM [Document].[Document] doc
JOIN [Document].[DocumentType] typ
ON doc.DocumentTypeId=typ.DocumentTypeId 
JOIN [Document].[Sender] sndr
ON doc.SenderId=sndr.SenderId
GO
GRANT SELECT ON  [Document].[DocumentInfo] TO [public]
GRANT INSERT ON  [Document].[DocumentInfo] TO [public]
GRANT DELETE ON  [Document].[DocumentInfo] TO [public]
GRANT UPDATE ON  [Document].[DocumentInfo] TO [public]
GO
