SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[WDJBTableColumns] as select a.* From vWDJBTableColumns a

GO
GRANT SELECT ON  [dbo].[WDJBTableColumns] TO [public]
GRANT INSERT ON  [dbo].[WDJBTableColumns] TO [public]
GRANT DELETE ON  [dbo].[WDJBTableColumns] TO [public]
GRANT UPDATE ON  [dbo].[WDJBTableColumns] TO [public]
GO
