SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMMiscellaneousBatch] as select a.* From vSMMiscellaneousBatch a




GO
GRANT SELECT ON  [dbo].[SMMiscellaneousBatch] TO [public]
GRANT INSERT ON  [dbo].[SMMiscellaneousBatch] TO [public]
GRANT DELETE ON  [dbo].[SMMiscellaneousBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMMiscellaneousBatch] TO [public]
GO
