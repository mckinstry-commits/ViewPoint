SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDTables] AS SELECT * FROM vDDTables

GO
GRANT SELECT ON  [dbo].[DDTables] TO [public]
GRANT INSERT ON  [dbo].[DDTables] TO [public]
GRANT DELETE ON  [dbo].[DDTables] TO [public]
GRANT UPDATE ON  [dbo].[DDTables] TO [public]
GO
