SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  10/15/2008
* Description:	Validates a given template
*
*	Inputs:
*	@TemplateName		The name of the template to validate
*
*	Outputs:
*	@Msg		error message
*	
*	Returns:
*	@rcode		0 = success, 1 = invalid template
*
*****************************************************/
CREATE PROCEDURE dbo.vspVPValidateTemplate
	-- Add the parameters for the stored procedure here
	@TemplateName VARCHAR(20),
	@Msg VARCHAR(255) = null OUTPUT
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rcode int;
	SELECT @rcode = 0;

	IF NOT EXISTS(SELECT TOP 1 1 
					FROM VPCanvasSettingsTemplate
					WHERE TemplateName = @TemplateName)
		SELECT @rcode = 1;

	IF @rcode = 1
		SELECT @Msg = 'Invalid template name.'
	RETURN @rcode 
END
GO
GRANT EXECUTE ON  [dbo].[vspVPValidateTemplate] TO [public]
GO
