SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDQPSave] as select a.* From bWDQPSave a
GO
GRANT SELECT ON  [dbo].[WDQPSave] TO [public]
GRANT INSERT ON  [dbo].[WDQPSave] TO [public]
GRANT DELETE ON  [dbo].[WDQPSave] TO [public]
GRANT UPDATE ON  [dbo].[WDQPSave] TO [public]
GO
