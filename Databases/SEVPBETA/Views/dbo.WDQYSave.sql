SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQYSave] as select a.* From bWDQYSave a
GO
GRANT SELECT ON  [dbo].[WDQYSave] TO [public]
GRANT INSERT ON  [dbo].[WDQYSave] TO [public]
GRANT DELETE ON  [dbo].[WDQYSave] TO [public]
GRANT UPDATE ON  [dbo].[WDQYSave] TO [public]
GO
