SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[POHB] as select a.* From bPOHB a
GO
GRANT SELECT ON  [dbo].[POHB] TO [public]
GRANT INSERT ON  [dbo].[POHB] TO [public]
GRANT DELETE ON  [dbo].[POHB] TO [public]
GRANT UPDATE ON  [dbo].[POHB] TO [public]
GO
