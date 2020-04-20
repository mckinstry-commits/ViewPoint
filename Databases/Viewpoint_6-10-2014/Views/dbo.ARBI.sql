SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBI] as select a.* From bARBI a
GO
GRANT SELECT ON  [dbo].[ARBI] TO [public]
GRANT INSERT ON  [dbo].[ARBI] TO [public]
GRANT DELETE ON  [dbo].[ARBI] TO [public]
GRANT UPDATE ON  [dbo].[ARBI] TO [public]
GRANT SELECT ON  [dbo].[ARBI] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARBI] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARBI] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARBI] TO [Viewpoint]
GO
