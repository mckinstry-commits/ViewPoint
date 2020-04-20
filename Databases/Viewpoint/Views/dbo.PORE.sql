SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PORE] as select a.* From bPORE a

GO
GRANT SELECT ON  [dbo].[PORE] TO [public]
GRANT INSERT ON  [dbo].[PORE] TO [public]
GRANT DELETE ON  [dbo].[PORE] TO [public]
GRANT UPDATE ON  [dbo].[PORE] TO [public]
GO
