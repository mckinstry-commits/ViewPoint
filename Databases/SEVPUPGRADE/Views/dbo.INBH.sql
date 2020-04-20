SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INBH] as select a.* From bINBH a

GO
GRANT SELECT ON  [dbo].[INBH] TO [public]
GRANT INSERT ON  [dbo].[INBH] TO [public]
GRANT DELETE ON  [dbo].[INBH] TO [public]
GRANT UPDATE ON  [dbo].[INBH] TO [public]
GO
