SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSHH] as select a.* From bMSHH a
GO
GRANT SELECT ON  [dbo].[MSHH] TO [public]
GRANT INSERT ON  [dbo].[MSHH] TO [public]
GRANT DELETE ON  [dbo].[MSHH] TO [public]
GRANT UPDATE ON  [dbo].[MSHH] TO [public]
GO
