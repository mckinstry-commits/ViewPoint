SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*Where DetailFormSecurity <> 'Y'*/
CREATE VIEW dbo.vDDFHSecurable
AS
SELECT     TOP (100) PERCENT ISNULL(m.Mod, f.Mod) AS Mod, f.Form, f.Title, f.FormType, f.ShowOnMenu, f.IconKey, f.ViewName, f.JoinClause, f.WhereClause, f.AssemblyName, 
                      f.FormClassName, f.ProgressClip, f.FormNumber, f.HelpFile, f.HelpKeyword, f.NotesTab, f.LoadProc, f.LoadParams, f.PostedTable, f.AllowAttachments, f.Version, 
                      f.HasProgressIndicator, f.CoColumn, f.BatchProcessForm, f.OrderByClause, f.DefaultTabPage, f.LicLevel, f.AllowCustomFields, f.CustomFieldTable, f.SecurityForm, 
                      f.TitleID, f.AlwayInheritAddUpdateDelete
FROM         dbo.DDFHShared AS f LEFT OUTER JOIN
                      dbo.DDMF AS m ON f.Form = m.Form
WHERE     (f.Form = f.SecurityForm) AND (f.Title <> 'VP Main Menu') AND (f.Form NOT IN ('VPLogOn', 'frmLogViewer', 'StdLogon', 'frmWeb', 'StdUserConfigEntry')) OR
                      (f.Form NOT IN ('VPLogOn', 'frmLogViewer', 'StdLogon', 'frmWeb')) AND (f.Title <> 'VP Main Menu') AND (f.DetailFormSecurity = 'Y')

GO
GRANT SELECT ON  [dbo].[vDDFHSecurable] TO [public]
GRANT INSERT ON  [dbo].[vDDFHSecurable] TO [public]
GRANT DELETE ON  [dbo].[vDDFHSecurable] TO [public]
GRANT UPDATE ON  [dbo].[vDDFHSecurable] TO [public]
GO
