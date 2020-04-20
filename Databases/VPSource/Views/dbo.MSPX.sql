SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSPX] as select a.* From bMSPX a
GO
GRANT SELECT ON  [dbo].[MSPX] TO [public]
GRANT INSERT ON  [dbo].[MSPX] TO [public]
GRANT DELETE ON  [dbo].[MSPX] TO [public]
GRANT UPDATE ON  [dbo].[MSPX] TO [public]
GO
