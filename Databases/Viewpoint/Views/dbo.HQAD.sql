SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAD] as select a.* From bHQAD a

GO
GRANT SELECT ON  [dbo].[HQAD] TO [public]
GRANT INSERT ON  [dbo].[HQAD] TO [public]
GRANT DELETE ON  [dbo].[HQAD] TO [public]
GRANT UPDATE ON  [dbo].[HQAD] TO [public]
GO
