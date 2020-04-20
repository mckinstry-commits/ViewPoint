SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMBC] as select a.* From bEMBC a
GO
GRANT SELECT ON  [dbo].[EMBC] TO [public]
GRANT INSERT ON  [dbo].[EMBC] TO [public]
GRANT DELETE ON  [dbo].[EMBC] TO [public]
GRANT UPDATE ON  [dbo].[EMBC] TO [public]
GRANT SELECT ON  [dbo].[EMBC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMBC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMBC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMBC] TO [Viewpoint]
GO
