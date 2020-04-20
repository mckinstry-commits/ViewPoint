SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INTG] as select a.* From bINTG a
GO
GRANT SELECT ON  [dbo].[INTG] TO [public]
GRANT INSERT ON  [dbo].[INTG] TO [public]
GRANT DELETE ON  [dbo].[INTG] TO [public]
GRANT UPDATE ON  [dbo].[INTG] TO [public]
GRANT SELECT ON  [dbo].[INTG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INTG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INTG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INTG] TO [Viewpoint]
GO
