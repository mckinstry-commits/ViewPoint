SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udPIFOffering] as select a.* From budPIFOffering a
GO
GRANT SELECT ON  [dbo].[udPIFOffering] TO [public]
GRANT INSERT ON  [dbo].[udPIFOffering] TO [public]
GRANT DELETE ON  [dbo].[udPIFOffering] TO [public]
GRANT UPDATE ON  [dbo].[udPIFOffering] TO [public]
GO
