SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udProjOffering] as select a.* From budProjOffering a
GO
GRANT SELECT ON  [dbo].[udProjOffering] TO [public]
GRANT INSERT ON  [dbo].[udProjOffering] TO [public]
GRANT DELETE ON  [dbo].[udProjOffering] TO [public]
GRANT UPDATE ON  [dbo].[udProjOffering] TO [public]
GO
