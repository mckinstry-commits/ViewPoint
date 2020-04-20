SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INTB] as select a.* From bINTB a
GO
GRANT SELECT ON  [dbo].[INTB] TO [public]
GRANT INSERT ON  [dbo].[INTB] TO [public]
GRANT DELETE ON  [dbo].[INTB] TO [public]
GRANT UPDATE ON  [dbo].[INTB] TO [public]
GRANT SELECT ON  [dbo].[INTB] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INTB] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INTB] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INTB] TO [Viewpoint]
GO
