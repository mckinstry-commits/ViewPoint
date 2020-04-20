SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[vspPMProjectTemplateDefaults]
/*************************************
* Created By:	TRL 05/13/2013 User Story 13608 Define templates b Project
* Modified By:	AJW 10/7/2013 TFS - 66175 support POCO/PURCHASECO SUB/SUBITEM
*
* Purpose:  Repturn data for Project Distribution Defaults
*
*	
* INPUT:PMCo,Project, DocCategory, DocType
* 
*
* OUTPUT: PMCo,Project, DocCategory,DocType,DefaultTemplate,DefaultYN,KeyID 
* 
* Success returns:
* 0
*
* Error returns:
*
**************************************/
(@PMCo bCompany, @Project bProject, @DocumentCategory varchar(10), @errmsg varchar(255) output
)
AS
SET NOCOUNT ON

IF @PMCo IS NULL
BEGIN
	SELECT @errmsg = 'PMCo can not be null'
	RETURN 1
END

IF @Project IS NULL
BEGIN
	SELECT @errmsg = 'Project can not be null'
	RETURN 1
END

IF @DocumentCategory IS NULL
BEGIN
	SELECT @errmsg = 'Document Category can not be null'
	RETURN 1
END


-- PM uses POCO and HQ uses PURCHASECO so you'll see some exceptions to handle those
SELECT  case when y.TemplateType = 'PURCHASECO' then 'POCO' else 
case when y.TemplateType = 'SUBITEM' then 'SUB' else y.TemplateType end end AS [DocCat], coalesce(w.DocType, z.DocType) AS [DocType],
	y.TemplateName AS [Template],y.Location, y.FileName,
CASE WHEN w.DefaultYN = 'Y' THEN 'true' ELSE 'false' END AS  [DefaultYN],
CASE WHEN w.Project IS NULL THEN 'false' ELSE 'true' END AS [Assigned], w.KeyID
FROM dbo.HQWD y
LEFT JOIN dbo.PMDT z  on (z.DocCategory = y.TemplateType) or 
	(z.DocCategory = 'POCO' and y.TemplateType = 'PURCHASECO') or
	(y.TemplateType = 'SUBITEM' and z.DocCategory = 'SUB') 
LEFT JOIN (SELECT x.* FROM dbo.PMProjectMasterTemplates x WHERE x.DocCategory = @DocumentCategory and PMCo=@PMCo and Project = @Project) 
			AS w ON z.DocCategory = w.DocCategory and z.DocType = w.DocType and y.TemplateName = w.DefaultTemplate
WHERE y.Active = 'Y' and 
( y.TemplateType = @DocumentCategory or
 (@DocumentCategory in ('POCO','PURCHASECO') and z.DocCategory = 'POCO') or
 (@DocumentCategory in ('SUB','SUBITEM') and y.TemplateType in ('SUB','SUBITEM') )
 )


UNION 

SELECT case when a.TemplateType = 'PURCHASECO' then 'POCO' else 
case when a.TemplateType = 'SUBITEM' then 'SUB' else a.TemplateType end end AS [DocCat],
null AS [DocType], a.TemplateName AS [Template],a.Location, a.FileName,
CASE WHEN c.DefaultYN = 'Y' THEN 'true' ELSE 'false' END AS  [DefaultYN],
CASE WHEN c.Project IS NULL THEN 'false' ELSE 'true' END AS [Assigned], c.KeyID 
FROM dbo.HQWD a
LEFT JOIN (SELECT b.* FROM dbo.PMProjectMasterTemplates b WHERE PMCo=@PMCo and Project = @Project and DocType is null) 
	AS c ON a.TemplateName = c.DefaultTemplate and (a.TemplateType = c.DocCategory or 
	(a.TemplateType = 'PURCHASECO' and c.DocCategory = 'POCO') or 
	(a.TemplateType = 'SUBITEM' and c.DocCategory = 'SUB') )
WHERE a.Active = 'Y' and 
( a.TemplateType = @DocumentCategory or
 (@DocumentCategory in ('POCO','PURCHASECO') and a.TemplateType = 'PURCHASECO') or
 (@DocumentCategory in ('SUB','SUBITEM') and a.TemplateType in ('SUB','SUBITEM') )
)


RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspPMProjectTemplateDefaults] TO [public]
GO
