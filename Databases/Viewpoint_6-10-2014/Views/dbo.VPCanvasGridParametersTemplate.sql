SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.VPCanvasGridParametersTemplate
AS
SELECT     ParamterId, GridConfigurationId, Name, SqlType, ParameterValue
FROM         dbo.vVPCanvasGridParametersTemplate

GO
GRANT SELECT ON  [dbo].[VPCanvasGridParametersTemplate] TO [public]
GRANT INSERT ON  [dbo].[VPCanvasGridParametersTemplate] TO [public]
GRANT DELETE ON  [dbo].[VPCanvasGridParametersTemplate] TO [public]
GRANT UPDATE ON  [dbo].[VPCanvasGridParametersTemplate] TO [public]
GRANT SELECT ON  [dbo].[VPCanvasGridParametersTemplate] TO [Viewpoint]
GRANT INSERT ON  [dbo].[VPCanvasGridParametersTemplate] TO [Viewpoint]
GRANT DELETE ON  [dbo].[VPCanvasGridParametersTemplate] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[VPCanvasGridParametersTemplate] TO [Viewpoint]
GO
