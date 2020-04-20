SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSI] as select a.* From bEMSI a
GO
GRANT SELECT ON  [dbo].[EMSI] TO [public]
GRANT INSERT ON  [dbo].[EMSI] TO [public]
GRANT DELETE ON  [dbo].[EMSI] TO [public]
GRANT UPDATE ON  [dbo].[EMSI] TO [public]
GO
