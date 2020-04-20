SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPMDocTemplateCopy ******/
CREATE  procedure [dbo].[vspPMDefaultResponseFieldsFromStdObject]
/*******************************************************************************
 * Created By:	GPT 05/11/2011 
 * Modified By:	
 *
 * Defaults in response field records to template from stdobject for 
 * that sepecific templatetype
 *
 * Pass In
 * template		    target template to populate
 * templatetype		Destination template to copy into
 *
 * RETURN PARAMS
 * msg           Error Message, or Success message
 *
 * Returns
 * 0 on success
 * -1 on error
 ********************************************************************************/
(@template bReportTitle, @templatetype varchar(10), @msg varchar(255) output)
AS
SET NOCOUNT ON
DECLARE @rcode INT, @sourcetemplate bReportTitle

SELECT @rcode = 0

IF NOT EXISTS ( SELECT TOP 1 1 FROM dbo.HQWD WHERE TemplateType = @templatetype and StdObject = 'Y')
BEGIN
	select @msg = 'No StdObject from which to default response fields in PM Document Templates.', @rcode = 1
	set @rcode = 1
	GOTO vspexit
END

SELECT @sourcetemplate = TemplateName from dbo.HQWD WHERE TemplateType = @templatetype AND StdObject = 'Y'

INSERT INTO dbo.HQDocTemplateResponseField (
		[TemplateName],
		[Seq],
		[DocObject],
		[ColumnName],
		[ResponseFieldName],
		[Caption],
		[ControlType],
		[ResponseValues],
		[Bookmark],
		[ResponseOrder],
		[Visible],
		[ReadOnly])
SELECT  @template as [TemplateName],
		[Seq],
		[DocObject],
      	[ColumnName],
		[ResponseFieldName],
        [Caption],
		[ControlType],
		[ResponseValues],
		[Bookmark],
		[ResponseOrder],
		[Visible],
		[ReadOnly] FROM dbo.HQDocTemplateResponseField WHERE TemplateName = @sourcetemplate

vspexit:
	SELECT @msg = isnull(@msg,'')
  	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMDefaultResponseFieldsFromStdObject] TO [public]
GO
