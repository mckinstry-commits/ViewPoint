SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   proc [dbo].[vspPMProjectMasterTemplateVal]
/*************************************
 * Created By:	GP 7/13/2010
 * Modified by: AJW 10/7/2013 TFS-66175 Fix POCO to PURCHASECO
 *
 * Validates the template selected on PM Project Master Template tab
 * to ensure that it has corresponds to the correct document type and category.
 *
 * Pass:
 *	PM Document Type
 *  PM Document Template
 * Returns:
 *
 * Success returns:
 *	0 and Description from DocumentType
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@DocType bDocType, @Template bReportTitle, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @DocCategory varchar(10)

select @rcode = 0, @msg = ''


--Get Document Category
select @DocCategory = DocCategory from dbo.PMDT with (nolock) where DocType = @DocType

--Validate that the Template exists
if not exists (select top 1 1 from dbo.HQWD with (nolock) where TemplateName = @Template)
begin
	select @msg = 'The template entered does not exist in PM Document Templates.', @rcode = 1
	goto vspexit
end

--Validate that the Template exists by Template Type (Doc Category) in bHQWD
if not exists (select top 1 1 from dbo.HQWD with(nolock) where TemplateName = @Template and 
(    (TemplateType = @DocCategory) OR
	(@DocCategory = 'POCO' and TemplateType = 'PURCHASECO')
))
begin
	select @msg = 'The template entered is not assigned to the selected Document Type. Run PM Document Types form to view Document Type assignements.', @rcode = 1
	goto vspexit
end


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectMasterTemplateVal] TO [public]
GO
