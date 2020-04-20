SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Document].[Company]
	AS SELECT * FROM Document.vCompany
GO
GRANT SELECT ON  [Document].[Company] TO [public]
GRANT INSERT ON  [Document].[Company] TO [public]
GRANT DELETE ON  [Document].[Company] TO [public]
GRANT UPDATE ON  [Document].[Company] TO [public]
GO
