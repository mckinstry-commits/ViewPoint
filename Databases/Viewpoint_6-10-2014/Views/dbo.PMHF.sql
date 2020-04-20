SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMHF] as select a.* From bPMHF a

GO
GRANT SELECT ON  [dbo].[PMHF] TO [public]
GRANT INSERT ON  [dbo].[PMHF] TO [public]
GRANT DELETE ON  [dbo].[PMHF] TO [public]
GRANT UPDATE ON  [dbo].[PMHF] TO [public]
GRANT SELECT ON  [dbo].[PMHF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMHF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMHF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMHF] TO [Viewpoint]
GO
