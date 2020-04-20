SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE view [dbo].[HQCompanyProcess] as select a.* from dbo.vHQCompanyProcess a





GO
GRANT SELECT ON  [dbo].[HQCompanyProcess] TO [public]
GRANT INSERT ON  [dbo].[HQCompanyProcess] TO [public]
GRANT DELETE ON  [dbo].[HQCompanyProcess] TO [public]
GRANT UPDATE ON  [dbo].[HQCompanyProcess] TO [public]
GRANT SELECT ON  [dbo].[HQCompanyProcess] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQCompanyProcess] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQCompanyProcess] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQCompanyProcess] TO [Viewpoint]
GO
