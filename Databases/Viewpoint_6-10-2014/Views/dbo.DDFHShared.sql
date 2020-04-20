SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DDFHShared]
AS
SELECT
ISNULL(c.Form, d.Form) AS Form, 
ISNULL(c.Title, d.Title) AS Title, 
ISNULL(c.FormType, d.FormType) AS FormType, 
ISNULL(c.ShowOnMenu, d.ShowOnMenu) AS ShowOnMenu, 
ISNULL(c.IconKey, d.IconKey) AS IconKey, 
ISNULL(c.ViewName, d.ViewName) AS ViewName, 
ISNULL(c.JoinClause, d.JoinClause) AS JoinClause, 
ISNULL(c.WhereClause, d.WhereClause) AS WhereClause, 
ISNULL(c.AssemblyName, d.AssemblyName) AS AssemblyName, 
ISNULL(c.FormClassName, d.FormClassName) AS FormClassName, 
ISNULL(c.ProgressClip, d.ProgressClip) AS ProgressClip, 
ISNULL(c.FormNumber, d.FormNumber) AS FormNumber,
d.HelpFile,
d.HelpKeyword, 
ISNULL(c.NotesTab, d.NotesTab) AS NotesTab, 
ISNULL(c.FormattedNotesTab, d.FormattedNotesTab) AS FormattedNotesTab, 
ISNULL(c.LoadProc, d.LoadProc) AS LoadProc, 
ISNULL(c.LoadParams, d.LoadParams) AS LoadParams, 
ISNULL(c.PostedTable, d.PostedTable) AS PostedTable, 
ISNULL(c.AllowAttachments, d.AllowAttachments) AS AllowAttachments, 
ISNULL(c.Version, d.Version) AS Version, 
ISNULL(c.Mod, d.Mod) AS Mod, 
ISNULL(d.HasProgressIndicator, 'N') AS HasProgressIndicator, 
ISNULL(c.CoColumn, d.CoColumn) AS CoColumn, 
d.BatchProcessForm, 
ISNULL(c.OrderByClause, d.OrderByClause) AS OrderByClause, 
CASE WHEN d .Form IS NULL THEN 'Y' ELSE 'N' END AS Custom, 
ISNULL(c.DefaultTabPage, d.DefaultTabPage) AS DefaultTabPage, 
ISNULL(d.LicLevel, 1) AS LicLevel, 
ISNULL(d.AllowCustomFields, 'Y') AS AllowCustomFields, 
d.CustomFieldTable, 
ISNULL(c.SecurityForm, d.SecurityForm) AS SecurityForm, 
ISNULL(c.DetailFormSecurity, 'N') AS DetailFormSecurity, 
COALESCE (d.V5xForm, c.Form, d.Form) AS V5xForm, 
d.QueryView, 
d.TitleID, 
COALESCE(c.ShowFormProperties, d.ShowFormProperties, 'Y') AS ShowFormProperties, 
COALESCE(c.ShowFieldProperties, d.ShowFieldProperties, 'Y') AS ShowFieldProperties, 
c.DefaultAttachmentTypeID, 
d.AlwayInheritAddUpdateDelete,
d.CustomFieldView

FROM         dbo.vDDFHc AS c FULL OUTER JOIN
                      dbo.vDDFH AS d ON d.Form = c.Form;

GO
GRANT SELECT ON  [dbo].[DDFHShared] TO [public]
GRANT INSERT ON  [dbo].[DDFHShared] TO [public]
GRANT DELETE ON  [dbo].[DDFHShared] TO [public]
GRANT UPDATE ON  [dbo].[DDFHShared] TO [public]
GRANT SELECT ON  [dbo].[DDFHShared] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFHShared] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFHShared] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFHShared] TO [Viewpoint]
GO
