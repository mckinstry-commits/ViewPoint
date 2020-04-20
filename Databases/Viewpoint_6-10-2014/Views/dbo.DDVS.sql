SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDVS
AS
SELECT     LicenseLevel, UseAppRole, AppRolePassword, Version, DaysToKeepLogHistory, MaxLookupRows, MaxFilterRows, LoginMessage, LoginMessageActive, 
                      AnalysisServer, CubesProcessed, ShowMyViewpoint, OLAPJobName, OLAPDatabaseName,
                      ServicePack, FrameworkFilePath, OrganizationID, AllowExportPrintRPRun, TaxUpdate, NumberOfWorkCenterTabs,
					  FourProjectsUserName,
					  FourProjectsPassword,
					  FourProjectsEnterpriseName,
					  FourProjectsEnterpriseId,
					  FourProjectsApplicationId,
					  FourProjectsBaseUrl,
					  SendViaSmtp
FROM         dbo.vDDVS
GO
GRANT SELECT ON  [dbo].[DDVS] TO [public]
GRANT INSERT ON  [dbo].[DDVS] TO [public]
GRANT DELETE ON  [dbo].[DDVS] TO [public]
GRANT UPDATE ON  [dbo].[DDVS] TO [public]
GRANT SELECT ON  [dbo].[DDVS] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDVS] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDVS] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDVS] TO [Viewpoint]
GO