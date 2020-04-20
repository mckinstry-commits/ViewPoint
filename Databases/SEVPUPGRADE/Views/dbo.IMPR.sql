SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMPR] as select a.* From bIMPR a

GO
GRANT SELECT ON  [dbo].[IMPR] TO [public]
GRANT INSERT ON  [dbo].[IMPR] TO [public]
GRANT DELETE ON  [dbo].[IMPR] TO [public]
GRANT UPDATE ON  [dbo].[IMPR] TO [public]
GO
