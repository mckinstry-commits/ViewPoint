SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POJM] as select a.* From bPOJM a

GO
GRANT SELECT ON  [dbo].[POJM] TO [public]
GRANT INSERT ON  [dbo].[POJM] TO [public]
GRANT DELETE ON  [dbo].[POJM] TO [public]
GRANT UPDATE ON  [dbo].[POJM] TO [public]
GO
