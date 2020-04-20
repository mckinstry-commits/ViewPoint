SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************************/
CREATE  proc [dbo].[vspPMDocGetDefaultTemplate]
/****************************************************************************
 * Created By:	GP 7/12/2010
 * Modified By:	GF 03/19/2011 TK-02607
 *				GP 11/27/2012 TK-19173 - Provide default for TRANSMIT
 *
 *
 *
 * USAGE:
 * Returns the default template (if there is one) for the specific
 * PMCo, Project, and DocType from the PM Project Master.
 *
 * INPUT PARAMETERS:
 * PMCo
 * Project
 * DocType
 *
 * OUTPUT PARAMETERS:
 * DefaultTemplate
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1		and Failure Message
 *
 *****************************************************************************/
(@PMCo bCompany = null, @Project bJob = null, @DocType bDocType = null, 
 @DocCategory VARCHAR(10) = NULL, @DefaultTemplate bReportTitle output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int
set @rcode = 0

---- SUBCO category does not have a document type, used first one found
IF @DocCategory = 'SUBCO'
	BEGIN
	SELECT TOP 1 @DefaultTemplate = a.DefaultTemplate
	FROM dbo.PMProjectMasterTemplates a
	JOIN dbo.PMDT b ON b.DocType = a.DocType
	WHERE a.PMCo = @PMCo and a.Project = @Project
	AND b.DocCategory = @DocCategory
	GROUP BY a.PMCo, a.Project, a.DocType, a.DefaultTemplate
	END
	
---- ISSUE category may not have a document type, if none then used first one found
IF @DocCategory = 'ISSUE' AND @DocType IS NULL
	BEGIN
	SELECT TOP 1 @DefaultTemplate = a.DefaultTemplate
	FROM dbo.PMProjectMasterTemplates a
	JOIN dbo.PMDT b ON b.DocType = a.DocType
	WHERE a.PMCo = @PMCo and a.Project = @Project
	AND b.DocCategory = @DocCategory
	GROUP BY a.PMCo, a.Project, a.DocType, a.DefaultTemplate
	END
	
-- Transmittals don't have document types, thus no defaults are allowed. Will default the first template.
IF @DocCategory = 'TRANSMIT'
BEGIN
	SELECT TOP 1 @DefaultTemplate = TemplateName FROM dbo.HQWD WHERE TemplateType = 'TRANSMIT'
END	
	
---- for all others
select @DefaultTemplate = DefaultTemplate 
from dbo.PMProjectMasterTemplates 
where PMCo = @PMCo and Project = @Project and DocType = @DocType



vspexit:
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspPMDocGetDefaultTemplate] TO [public]
GO
