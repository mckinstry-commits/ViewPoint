SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQSM] as select a.* From bHQSM a

GO
GRANT SELECT ON  [dbo].[HQSM] TO [public]
GRANT INSERT ON  [dbo].[HQSM] TO [public]
GRANT DELETE ON  [dbo].[HQSM] TO [public]
GRANT UPDATE ON  [dbo].[HQSM] TO [public]
GO
