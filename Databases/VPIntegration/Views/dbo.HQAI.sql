SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAI] as select a.* From bHQAI a
GO
GRANT SELECT ON  [dbo].[HQAI] TO [public]
GRANT INSERT ON  [dbo].[HQAI] TO [public]
GRANT DELETE ON  [dbo].[HQAI] TO [public]
GRANT UPDATE ON  [dbo].[HQAI] TO [public]
GO
