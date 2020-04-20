SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPDisplayGridParameters
AS
SELECT     ParameterValue, SqlType, Name, GridConfigurationId, ParamterId
FROM         dbo.vVPDisplayGridParameters

GO
GRANT SELECT ON  [dbo].[VPDisplayGridParameters] TO [public]
GRANT INSERT ON  [dbo].[VPDisplayGridParameters] TO [public]
GRANT DELETE ON  [dbo].[VPDisplayGridParameters] TO [public]
GRANT UPDATE ON  [dbo].[VPDisplayGridParameters] TO [public]
GO
