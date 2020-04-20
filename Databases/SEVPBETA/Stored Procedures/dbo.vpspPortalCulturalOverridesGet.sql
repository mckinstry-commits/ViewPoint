SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vpspPortalCulturalOverridesGet]

AS

SET NOCOUNT ON;

SELECT DISTINCT v.Form, v.Seq, t.CultureID,
    ISNULL(ISNULL(ISNULL(c.CultureText, t.CultureText), d.Label), d.Description) AS 'FieldLabel',
    ISNULL(v.CustomGridColHeading, ISNULL(d.Label, ISNULL(c.CultureText, ISNULL(h.CultureText, GridColHeading)))) AS 'ColumnHeading',
	v.Datatype, d.Label As 'DataTypeLabel', d.TextID As 'DataTypeTextID', c.CultureText AS 'DateTypeCultureText', 
	LabelTextID, t.CultureText AS 'LabelCultureText', v.Description, 
	ColumnTextID, h.CultureText AS 'ColumnCultureText', GridColHeading, CustomGridColHeading
FROM DDFIShared v
INNER JOIN pPortalDataGridColumns p ON v.Form = p.Form AND v.Seq = p.Seq
LEFT OUTER JOIN DDDTShared d ON v.Datatype = d.Datatype
LEFT OUTER JOIN DDCTShared c ON d.TextID = c.TextID
LEFT OUTER JOIN DDCTShared t ON v.LabelTextID = t.TextID
LEFT OUTER JOIN DDCTShared h ON v.ColumnTextID = h.TextID

UNION 

SELECT DISTINCT v.Form, v.Seq, t.CultureID,
    ISNULL(ISNULL(ISNULL(c.CultureText, t.CultureText), d.Label), d.Description) AS 'FieldLabel',
    ISNULL(v.CustomGridColHeading, ISNULL(d.Label, ISNULL(c.CultureText, ISNULL(h.CultureText, GridColHeading)))) AS 'ColumnHeading',
	v.Datatype, d.Label As 'DataTypeLabel', d.TextID As 'DataTypeTextID', c.CultureText AS 'DateTypeCultureText', 
	LabelTextID, t.CultureText AS 'LabelCultureText', v.Description, 
	ColumnTextID, h.CultureText AS 'ColumnCultureText', GridColHeading, CustomGridColHeading
FROM DDFIShared v
INNER JOIN pPortalDetailsField p ON v.Form = p.Form AND v.Seq = p.Seq
LEFT OUTER JOIN DDDTShared d ON v.Datatype = d.Datatype
LEFT OUTER JOIN DDCTShared c ON d.TextID = c.TextID
LEFT OUTER JOIN DDCTShared t ON v.LabelTextID = t.TextID
LEFT OUTER JOIN DDCTShared h ON v.ColumnTextID = h.TextID AND t.CultureID = h.CultureID
GO
GRANT EXECUTE ON  [dbo].[vpspPortalCulturalOverridesGet] TO [VCSPortal]
GO
