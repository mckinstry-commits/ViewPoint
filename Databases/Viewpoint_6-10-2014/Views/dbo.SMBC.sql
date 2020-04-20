SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMBC] as select a.* From vSMBC a
GO
GRANT SELECT ON  [dbo].[SMBC] TO [public]
GRANT INSERT ON  [dbo].[SMBC] TO [public]
GRANT DELETE ON  [dbo].[SMBC] TO [public]
GRANT UPDATE ON  [dbo].[SMBC] TO [public]
GRANT SELECT ON  [dbo].[SMBC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMBC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMBC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMBC] TO [Viewpoint]
GO
