SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLXA] as select a.* From bSLXA a
GO
GRANT SELECT ON  [dbo].[SLXA] TO [public]
GRANT INSERT ON  [dbo].[SLXA] TO [public]
GRANT DELETE ON  [dbo].[SLXA] TO [public]
GRANT UPDATE ON  [dbo].[SLXA] TO [public]
GRANT SELECT ON  [dbo].[SLXA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLXA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLXA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLXA] TO [Viewpoint]
GO
