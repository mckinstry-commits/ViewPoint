SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRDH] as select a.* From bPRDH a

GO
GRANT SELECT ON  [dbo].[PRDH] TO [public]
GRANT INSERT ON  [dbo].[PRDH] TO [public]
GRANT DELETE ON  [dbo].[PRDH] TO [public]
GRANT UPDATE ON  [dbo].[PRDH] TO [public]
GO
