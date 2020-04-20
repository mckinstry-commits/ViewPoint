SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMUC] as select a.* From bPMUC a

GO
GRANT SELECT ON  [dbo].[PMUC] TO [public]
GRANT INSERT ON  [dbo].[PMUC] TO [public]
GRANT DELETE ON  [dbo].[PMUC] TO [public]
GRANT UPDATE ON  [dbo].[PMUC] TO [public]
GRANT SELECT ON  [dbo].[PMUC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMUC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMUC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMUC] TO [Viewpoint]
GO
