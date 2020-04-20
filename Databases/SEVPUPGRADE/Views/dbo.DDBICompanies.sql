SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDBICompanies
AS
SELECT     dbo.vDDBICompanies.*
FROM         dbo.vDDBICompanies

GO
GRANT SELECT ON  [dbo].[DDBICompanies] TO [public]
GRANT INSERT ON  [dbo].[DDBICompanies] TO [public]
GRANT DELETE ON  [dbo].[DDBICompanies] TO [public]
GRANT UPDATE ON  [dbo].[DDBICompanies] TO [public]
GO
