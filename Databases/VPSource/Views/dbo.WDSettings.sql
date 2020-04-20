SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDSettings] as select a.* From bWDSettings a
GO
GRANT SELECT ON  [dbo].[WDSettings] TO [public]
GRANT INSERT ON  [dbo].[WDSettings] TO [public]
GRANT DELETE ON  [dbo].[WDSettings] TO [public]
GRANT UPDATE ON  [dbo].[WDSettings] TO [public]
GO
