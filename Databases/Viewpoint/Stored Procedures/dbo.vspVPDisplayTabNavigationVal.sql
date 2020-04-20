SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***************************************
* Created: Chris G 4/15/11 (B-02317)
* Modified: 
*
* Validates the VAVPDisplayTabNavigation form.
*
* Inputs:
*	@lookup		Lookup name from DDLH
*	
* Outputs:
*	@lookup			Lookup used on forms
*	@msg			error message
*
* Return code:
*	0 = success, 1 = failure
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPDisplayTabNavigationVal]
	@TemplateName as varchar(20), @msg varchar(60) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF NOT EXISTS (SELECT TOP 1 1 FROM VPCanvasTreeItemsTemplate WHERE TemplateName = @TemplateName)
	BEGIN
		SET @msg = 'Template does exist or does not contain any navigation items.'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVPDisplayTabNavigationVal] TO [public]
GO
