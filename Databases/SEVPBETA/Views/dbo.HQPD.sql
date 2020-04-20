SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQPD] as select a.* From bHQPD a

GO
GRANT SELECT ON  [dbo].[HQPD] TO [public]
GRANT INSERT ON  [dbo].[HQPD] TO [public]
GRANT DELETE ON  [dbo].[HQPD] TO [public]
GRANT UPDATE ON  [dbo].[HQPD] TO [public]
GO
