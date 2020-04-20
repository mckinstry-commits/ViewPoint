SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[SecondaryIdentifierType]
	AS SELECT * FROM Document.[vSecondaryIdentifierType]
GO
GRANT SELECT ON  [Document].[SecondaryIdentifierType] TO [public]
GRANT INSERT ON  [Document].[SecondaryIdentifierType] TO [public]
GRANT DELETE ON  [Document].[SecondaryIdentifierType] TO [public]
GRANT UPDATE ON  [Document].[SecondaryIdentifierType] TO [public]
GO
