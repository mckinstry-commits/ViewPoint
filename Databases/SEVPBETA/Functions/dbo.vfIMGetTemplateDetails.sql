SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 4/23/10
-- Description:	Returns the IM Template Detail records with their related column name and overwrite and default settings
-- for a given import template and record type
-- =============================================
CREATE FUNCTION [dbo].[vfIMGetTemplateDetails]
(	
	@ImportTemplate VARCHAR(20), @RecordType VARCHAR(30)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT IMTD.Identifier AS Identifier, DDUD.ColumnName AS ColumnName, CASE WHEN IMTD.OverrideYN = 'Y' AND IMTD.DefaultValue = '[Bidtek]' THEN 1 ELSE 0 END AS UserOverwrite, CASE WHEN IMTD.DefaultValue = '[Bidtek]' THEN 1 ELSE 0 END AS UseDefault, ISNULL(sys.columns.is_nullable, 1) AS TableAllowsNull
	FROM IMTD
		INNER JOIN IMTR ON IMTD.ImportTemplate = IMTR.ImportTemplate AND IMTD.RecordType = IMTR.RecordType
		INNER JOIN DDUD ON IMTD.Identifier = DDUD.Identifier AND IMTR.Form = DDUD.Form
			LEFT JOIN sys.views ON DDUD.TableName = sys.views.Name
			LEFT JOIN sys.columns ON sys.views.object_id = sys.columns.object_id AND DDUD.ColumnName = sys.columns.Name
	WHERE IMTD.ImportTemplate = @ImportTemplate AND IMTD.RecordType = @RecordType
)

GO
GRANT SELECT ON  [dbo].[vfIMGetTemplateDetails] TO [public]
GO
