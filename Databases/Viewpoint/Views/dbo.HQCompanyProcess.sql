SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





create view [dbo].[HQCompanyProcess] as select a.* from dbo.vHQCompanyProcess a





GO
GRANT SELECT ON  [dbo].[HQCompanyProcess] TO [public]
GRANT INSERT ON  [dbo].[HQCompanyProcess] TO [public]
GRANT DELETE ON  [dbo].[HQCompanyProcess] TO [public]
GRANT UPDATE ON  [dbo].[HQCompanyProcess] TO [public]
GO
