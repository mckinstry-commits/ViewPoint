SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJBTableLayout] as select a.* From vWDJBTableLayout a

GO
GRANT SELECT ON  [dbo].[WDJBTableLayout] TO [public]
GRANT INSERT ON  [dbo].[WDJBTableLayout] TO [public]
GRANT DELETE ON  [dbo].[WDJBTableLayout] TO [public]
GRANT UPDATE ON  [dbo].[WDJBTableLayout] TO [public]
GO
