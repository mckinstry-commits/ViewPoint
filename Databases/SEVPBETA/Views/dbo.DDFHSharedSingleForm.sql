SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/************************************************************************
* CREATED:	AR 12/23/2010    
* MODIFIED:	
*
* Purpose:	The ISNULL around form causes an index scan so creating a view
			that uses a union so an index seek can be performed

* returns 1 and error msg if failed
*
*************************************************************************/


CREATE VIEW [dbo].[DDFHSharedSingleForm]
AS
SELECT
	c.Form AS Form, 
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
--covers c and d and c only
FROM         dbo.vDDFHc AS c LEFT JOIN
                      dbo.vDDFH AS d ON d.Form = c.Form
UNION ALL

SELECT  d.Form AS Form,
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
-- covers d when there is no c, completing a full-outer join		
FROM    dbo.vDDFH AS d 
			LEFT JOIN dbo.vDDFHc AS c ON d.Form = c.Form
WHERE c.Form IS NULL



GO
GRANT SELECT ON  [dbo].[DDFHSharedSingleForm] TO [public]
GRANT INSERT ON  [dbo].[DDFHSharedSingleForm] TO [public]
GRANT DELETE ON  [dbo].[DDFHSharedSingleForm] TO [public]
GRANT UPDATE ON  [dbo].[DDFHSharedSingleForm] TO [public]
GO
