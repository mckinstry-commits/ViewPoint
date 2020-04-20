SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************/
CREATE procedure [dbo].[vspPMRecordRelatedFormsAvailable]
/************************************************************************
* Created By:	GF 11/30/2010 
* Modified By:
*
* Return table name based on input string
*
* Inputs
*	@FormName	- Form Name
*
* Outputs
*	@rcode		- 0 = successfull - 1 = error
*	@msg		- Table name or error
*
*************************************************************************/
(@FormName NVARCHAR(128) = NULL, @msg varchar(255) output)

--with execute as 'viewpointcs'

AS
SET NOCOUNT ON

DECLARE @rcode	INT

SET @rcode = 1
SET @msg = ''

---- if no form no possible related forms
IF ISNULL(@FormName,'') = '' GOTO vspExit
	
---- check vDDFormRelated for related forms
IF EXISTS(SELECT TOP 1 1 FROM dbo.vDDFormRelated WHERE Form = @FormName)
	BEGIN
	SET @rcode = 0
	GOTO vspExit
	END
	


vspExit:
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelatedFormsAvailable] TO [public]
GO
