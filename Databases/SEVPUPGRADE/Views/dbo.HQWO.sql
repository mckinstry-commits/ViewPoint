SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQWO] as select a.* From bHQWO a

GO
GRANT SELECT ON  [dbo].[HQWO] TO [public]
GRANT INSERT ON  [dbo].[HQWO] TO [public]
GRANT DELETE ON  [dbo].[HQWO] TO [public]
GRANT UPDATE ON  [dbo].[HQWO] TO [public]
GO
