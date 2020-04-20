SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQET] as select a.* From bHQET a
GO
GRANT SELECT ON  [dbo].[HQET] TO [public]
GRANT INSERT ON  [dbo].[HQET] TO [public]
GRANT DELETE ON  [dbo].[HQET] TO [public]
GRANT UPDATE ON  [dbo].[HQET] TO [public]
GO
