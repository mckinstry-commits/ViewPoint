SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[CompanyImages] as select a.* From vCompanyImages a
GO
GRANT SELECT ON  [dbo].[CompanyImages] TO [public]
GRANT INSERT ON  [dbo].[CompanyImages] TO [public]
GRANT DELETE ON  [dbo].[CompanyImages] TO [public]
GRANT UPDATE ON  [dbo].[CompanyImages] TO [public]
GRANT SELECT ON  [dbo].[CompanyImages] TO [Viewpoint]
GRANT INSERT ON  [dbo].[CompanyImages] TO [Viewpoint]
GRANT DELETE ON  [dbo].[CompanyImages] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[CompanyImages] TO [Viewpoint]
GO
