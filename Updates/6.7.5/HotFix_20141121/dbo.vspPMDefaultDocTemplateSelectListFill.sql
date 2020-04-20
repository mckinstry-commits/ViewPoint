IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vspPMDefaultDocTemplateSelectListFill]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[vspPMDefaultDocTemplateSelectListFill]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****************************************************************************/
CREATE  proc [dbo].[vspPMDefaultDocTemplateSelectListFill]
/****************************************************************************
 * Created By:	AJW - 6/5/13 TFS - 13608
 *
 * Modified By:	ScottP 08/09/2013 TFS-54471  Only return Active Templates
 *				AJW 11/6/13 TFS-66202 Check for Company Default Template
 *				AJW 11/6/13 TFS-66175 PURCHASECO in HQ POCO in PM
 *					return both SUB & SUBITEM when DocCat = 'SUB'
 *					return SUBITEM when DocCat = 'SUBITEM'
 *				AJW 12/9/2013 TFS 67985 Fixed Procedure to not return more than one default with SUB DocCat 
 *				SCOTTP 02/05/2014 TFS-70346 Return field stores the default the edit option checkbox in the SendDocument form
 *				AJW  02/14/2014 TFS-75074 Fix insert for @Templates
 *				SCOTTP 02/21/2014 TFS-74937 Merge C&S Edit Workflow modifications from 6.8
 *
 * USAGE:
 * Returns a resultset of PM default document template names for the template type.
 * Used in the PMDocSelection form to populate list view.
 *
 * INPUT PARAMETERS:
 * PMCo
 * Project
 * DocCat
 * DocType
 *
 * OUTPUT PARAMETERS:
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@pmco bCompany,@project bJob, @doccat varchar(10) = null, @doctype bDocType)
as
set nocount on

declare @Templates TABLE
( Template bReportTitle not null, DefaultYN bYN null, EditDocDefault bYN null)

--Special case for SUB combine SUBITEM templates combine the template list for those DocCategories

;with cte_ActiveTemplates (DocCategory,DocType,TemplateName,EditDocDefault) as
(
	select p.DocCategory,p.DocType,h.TemplateName,h.EditDocDefault
	from 
		HQWD h 
		join PMDT p on (p.DocCategory = h.TemplateType) or 
			(h.TemplateType = 'PURCHASECO' and p.DocCategory = 'POCO') or
			(h.TemplateType = 'SUBITEM' and p.DocCategory = 'SUB')
	where h.Active = 'Y' and p.Active = 'Y' and p.DocCategory <> 'PURCHASECO'
),
cte_DefaultProjectTemplates (PMCo,Project,DocCategory,DocType,TemplateName,DefaultYN,EditDocDefault) as
(
	select p1.PMCo,p1.Project,p1.DocCategory,p1.DocType,p1.DefaultTemplate,p1.DefaultYN,c1.EditDocDefault
	from PMProjectMasterTemplates p1 
		join cte_ActiveTemplates c1 on p1.DefaultTemplate = c1.TemplateName and p1.DocCategory = c1.DocCategory and 
		(p1.DocType = c1.DocType or p1.DocType is null)
),
cte_DefaultPMCoTemplate (PMCo,DocCategory,DocType,TemplateName,DefaultYN,EditDocDefault) as
(
	select c.PMCo,c1.DocCategory,c.DocType,c.DefaultTemplate,'Y',c1.EditDocDefault
	from PMCompanyTemplates c
		join cte_ActiveTemplates c1 on c.DefaultTemplate = c1.TemplateName and c.DocType = c1.DocType
),
-- determine the correct default template based on the following
-- Default Flagged if setup at the PMCo,Project,DocCategory,DocType [PMProjectMasterTemplates]
-- Default flagged if setup at the PMCo,Project,DocCategory, DocType is null [PMProjectMasterTemplates]
-- Default flagged if setup at the PMCo, DocType [PMCompanyTemplates]
cte_CoProjectTemplates (PMCo,Project,DocCategory,DocType,TemplateName,DefaultYN,DefaultYNLvl,EditDocDefault) as
(
	select p.PMCo,p.Project,p.DocCategory,p.DocType,p.TemplateName,p.DefaultYN,
		DefaultYNLvl = case when p.DocType is not null then 1 else 2 end,p.EditDocDefault 
	from cte_DefaultProjectTemplates p 
	union all
	select p.PMCo,p.Project,p.DocCategory,p.DocType,p.TemplateName,'Y',3,c.EditDocDefault
	from cte_DefaultPMCoTemplate c
	join cte_DefaultProjectTemplates p on c.PMCo = p.PMCo and c.TemplateName = p.TemplateName and c.DocCategory = p.DocCategory
)
INSERT @Templates(Template,DefaultYN,EditDocDefault)
select distinct
TemplateName, DefaultYN = case when DefaultYN = 'Y' and 
	exists(select 1	
		from cte_CoProjectTemplates t 
		where t.DefaultYN = 'Y' and t.PMCo = @pmco and t.Project = @project and t.DefaultYNLvl < a.DefaultYNLvl and
		a.DocCategory = t.DocCategory AND (t.DocType = @doctype OR t.DocType IS NULL)
		) then 'N' else DefaultYN end, EditDocDefault
from cte_CoProjectTemplates a
where a.PMCo = @pmco AND ( a.Project = @project or a.Project is null )
	 AND
	(	--special case for SUB & SUBITEM combine template list
		( @doccat = 'SUB' AND a.DocCategory in ('SUB','SUBITEM') AND (a.DocType = @doctype OR a.DocType IS NULL) ) 
			OR
		( 
			( a.DocCategory = @doccat or ( @doccat in ('POCO','PURCHASECO') and a.DocCategory in ('POCO','PURCHASECO') )) 
			AND (a.DocType = @doctype OR a.DocType IS NULL) )

	)

--delete any duplicates in case template is set to default at doctype but not at null
DELETE @Templates
	FROM @Templates t 
	WHERE DefaultYN='N' AND EXISTS(SELECT 1 FROM @Templates t1 where t1.Template=t.Template and t1.DefaultYN='Y')

IF NOT EXISTS(SELECT 1 FROM @Templates)
BEGIN
	-- special case HQ uses PURCHASECO PM uses POCO
	if @doccat = 'POCO' set @doccat = 'PURCHASECO'
	INSERT @Templates(Template,EditDocDefault)
	EXEC vspPMDocSelectListFill @doccat, 'Y'
	--set default from company if exists
	update @Templates set DefaultYN = 'Y'
	from @Templates t 
	join PMCompanyTemplates c on c.DefaultTemplate = t.Template
	where c.PMCo = @pmco and c.DocType = @doctype
	
END


SELECT * FROM @Templates


GO


