SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[RelatedVDocsToV6]
	AS SELECT  dvtr.DocumentId,
		pmrr.LinkTableName AS V6TableName,
		pmrr.LINKID AS V6KeyID,
		pmrr.RECID AS AssociatedKeyV6KeyID,
		pmrr.RecTableName AS AssociatedTableName,
		dvtrAssociated.DocumentId AS AssociatedDocumentId	
FROM Document.vDocumentV6TableRow dvtr
	JOIN dbo.vPMRelateRecord pmrr ON pmrr.LinkTableName = dvtr.TableName AND pmrr.LINKID = dvtr.TableKeyId
	LEFT JOIN Document.vDocumentV6TableRow dvtrAssociated ON pmrr.RecTableName = dvtr.TableName AND pmrr.RECID = dvtr.TableKeyId
GO
GRANT SELECT ON  [Document].[RelatedVDocsToV6] TO [public]
GRANT INSERT ON  [Document].[RelatedVDocsToV6] TO [public]
GRANT DELETE ON  [Document].[RelatedVDocsToV6] TO [public]
GRANT UPDATE ON  [Document].[RelatedVDocsToV6] TO [public]
GO
