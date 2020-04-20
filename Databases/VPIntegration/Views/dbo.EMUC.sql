SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMUC] as select a.* From bEMUC a

GO
GRANT SELECT ON  [dbo].[EMUC] TO [public]
GRANT INSERT ON  [dbo].[EMUC] TO [public]
GRANT DELETE ON  [dbo].[EMUC] TO [public]
GRANT UPDATE ON  [dbo].[EMUC] TO [public]
GO
