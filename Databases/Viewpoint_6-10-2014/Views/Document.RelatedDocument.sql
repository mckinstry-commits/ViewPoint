SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[RelatedDocument]
	AS SELECT * FROM Document.[vRelatedDocument]
GO
GRANT SELECT ON  [Document].[RelatedDocument] TO [public]
GRANT INSERT ON  [Document].[RelatedDocument] TO [public]
GRANT DELETE ON  [Document].[RelatedDocument] TO [public]
GRANT UPDATE ON  [Document].[RelatedDocument] TO [public]
GO
