SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMOZ] as select a.* From bPMOZ a

GO
GRANT SELECT ON  [dbo].[PMOZ] TO [public]
GRANT INSERT ON  [dbo].[PMOZ] TO [public]
GRANT DELETE ON  [dbo].[PMOZ] TO [public]
GRANT UPDATE ON  [dbo].[PMOZ] TO [public]
GRANT SELECT ON  [dbo].[PMOZ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMOZ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMOZ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMOZ] TO [Viewpoint]
GO
