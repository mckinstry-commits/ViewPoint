SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMVG] as select a.* From bPMVG a

GO
GRANT SELECT ON  [dbo].[PMVG] TO [public]
GRANT INSERT ON  [dbo].[PMVG] TO [public]
GRANT DELETE ON  [dbo].[PMVG] TO [public]
GRANT UPDATE ON  [dbo].[PMVG] TO [public]
GRANT SELECT ON  [dbo].[PMVG] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMVG] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMVG] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMVG] TO [Viewpoint]
GO
