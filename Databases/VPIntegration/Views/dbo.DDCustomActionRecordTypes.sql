SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[DDCustomActionRecordTypes] AS SELECT * FROM [vDDCustomActionRecordTypes]
GO
GRANT SELECT ON  [dbo].[DDCustomActionRecordTypes] TO [public]
GRANT INSERT ON  [dbo].[DDCustomActionRecordTypes] TO [public]
GRANT DELETE ON  [dbo].[DDCustomActionRecordTypes] TO [public]
GRANT UPDATE ON  [dbo].[DDCustomActionRecordTypes] TO [public]
GO
