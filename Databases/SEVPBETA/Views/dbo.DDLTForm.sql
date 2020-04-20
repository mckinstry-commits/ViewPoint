SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   view [dbo].[DDLTForm] as select PrimaryTable as TableName, LinkedTable from vDDLT

GO
GRANT SELECT ON  [dbo].[DDLTForm] TO [public]
GRANT INSERT ON  [dbo].[DDLTForm] TO [public]
GRANT DELETE ON  [dbo].[DDLTForm] TO [public]
GRANT UPDATE ON  [dbo].[DDLTForm] TO [public]
GO
