SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udOffering] as select a.* From budOffering a
GO
GRANT SELECT ON  [dbo].[udOffering] TO [public]
GRANT INSERT ON  [dbo].[udOffering] TO [public]
GRANT DELETE ON  [dbo].[udOffering] TO [public]
GRANT UPDATE ON  [dbo].[udOffering] TO [public]
GO
