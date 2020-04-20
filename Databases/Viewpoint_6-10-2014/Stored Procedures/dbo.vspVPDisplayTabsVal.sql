SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************
* Created: Chris G 4/15/11 (B-02317)
* Modified: ScottP 04/08/13 (TFS-38555) Setup Message to Group Description
*
* Validates the Tabs tab in VAVPDisplayProfile form.
*
* Inputs:
*	@GroupID
*	@TemplateName
*	@NavigationID
*	
* Outputs:
*	@msg			error message
*
* Return code:
*	0 = success, 1 = failure
*
**************************************/
CREATE PROCEDURE [dbo].[vspVPDisplayTabsVal]
	@GroupID int, @TemplateName varchar(20), @NavigationID int, @msg varchar(60) output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @GroupDesc varchar(50)
	
    IF @GroupID IS NOT NULL
    BEGIN
		SELECT @GroupDesc = [Description] FROM VPCanvasTemplateGroup WHERE KeyID = @GroupID
		IF @GroupDesc IS NULL
		BEGIN
			SET @msg = 'Work Center not found.'
			RETURN 1
		END
		
		IF @TemplateName IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 1 FROM VPCanvasSettingsTemplate WHERE TemplateName = @TemplateName AND GroupID = @GroupID)
			BEGIN
				SET @msg = 'Template Name not found or not allowed with the Work Center.'
				RETURN 1
			END
		END
    END
    
    IF @NavigationID IS NOT NULL
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 1 FROM VPDisplayTabNavigation WHERE KeyID = @NavigationID AND TemplateName = @TemplateName)
		BEGIN
			SET @msg = 'The Navigation ID not found or not allowed with the Template Name.'
			RETURN 1
		END
	END
	
	SET @msg = @GroupDesc
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspVPDisplayTabsVal] TO [public]
GO
