SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRAC] as select a.* From bHRAC a

GO
GRANT SELECT ON  [dbo].[HRAC] TO [public]
GRANT INSERT ON  [dbo].[HRAC] TO [public]
GRANT DELETE ON  [dbo].[HRAC] TO [public]
GRANT UPDATE ON  [dbo].[HRAC] TO [public]
GO
