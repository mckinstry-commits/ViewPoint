SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQFSave] as select a.* From bWDQFSave a
GO
GRANT SELECT ON  [dbo].[WDQFSave] TO [public]
GRANT INSERT ON  [dbo].[WDQFSave] TO [public]
GRANT DELETE ON  [dbo].[WDQFSave] TO [public]
GRANT UPDATE ON  [dbo].[WDQFSave] TO [public]
GO
