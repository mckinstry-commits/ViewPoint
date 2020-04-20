SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQPO] as select a.* From bHQPO a

GO
GRANT SELECT ON  [dbo].[HQPO] TO [public]
GRANT INSERT ON  [dbo].[HQPO] TO [public]
GRANT DELETE ON  [dbo].[HQPO] TO [public]
GRANT UPDATE ON  [dbo].[HQPO] TO [public]
GO
