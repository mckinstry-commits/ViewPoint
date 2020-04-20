SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMTA] as select a.* From bIMTA a

GO
GRANT SELECT ON  [dbo].[IMTA] TO [public]
GRANT INSERT ON  [dbo].[IMTA] TO [public]
GRANT DELETE ON  [dbo].[IMTA] TO [public]
GRANT UPDATE ON  [dbo].[IMTA] TO [public]
GRANT SELECT ON  [dbo].[IMTA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMTA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMTA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMTA] TO [Viewpoint]
GO
