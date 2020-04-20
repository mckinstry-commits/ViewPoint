SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPPartFormChangedParameters
AS
SELECT     KeyID, ColumnName, Name, SqlType, ParameterValue, ViewName, FormChangedID, ParameterOrder
FROM         dbo.vVPPartFormChangedParameters


GO
GRANT SELECT ON  [dbo].[VPPartFormChangedParameters] TO [public]
GRANT INSERT ON  [dbo].[VPPartFormChangedParameters] TO [public]
GRANT DELETE ON  [dbo].[VPPartFormChangedParameters] TO [public]
GRANT UPDATE ON  [dbo].[VPPartFormChangedParameters] TO [public]
GO
