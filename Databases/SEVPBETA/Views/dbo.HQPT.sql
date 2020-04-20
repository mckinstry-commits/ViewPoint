SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQPT] as select a.* From bHQPT a
GO
GRANT SELECT ON  [dbo].[HQPT] TO [public]
GRANT INSERT ON  [dbo].[HQPT] TO [public]
GRANT DELETE ON  [dbo].[HQPT] TO [public]
GRANT UPDATE ON  [dbo].[HQPT] TO [public]
GO
