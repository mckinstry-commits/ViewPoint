SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMSubcontractCO] as select a.* From vPMSubcontractCO a
GO
GRANT SELECT ON  [dbo].[PMSubcontractCO] TO [public]
GRANT INSERT ON  [dbo].[PMSubcontractCO] TO [public]
GRANT DELETE ON  [dbo].[PMSubcontractCO] TO [public]
GRANT UPDATE ON  [dbo].[PMSubcontractCO] TO [public]
GRANT SELECT ON  [dbo].[PMSubcontractCO] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMSubcontractCO] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMSubcontractCO] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMSubcontractCO] TO [Viewpoint]
GO
