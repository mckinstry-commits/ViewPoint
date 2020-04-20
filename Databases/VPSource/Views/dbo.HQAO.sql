SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQAO] as select a.* From bHQAO a

GO
GRANT SELECT ON  [dbo].[HQAO] TO [public]
GRANT INSERT ON  [dbo].[HQAO] TO [public]
GRANT DELETE ON  [dbo].[HQAO] TO [public]
GRANT UPDATE ON  [dbo].[HQAO] TO [public]
GO
