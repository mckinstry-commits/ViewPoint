SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  3/17/2008
* Description:	This procedure extracts, re-orders, and re-inserts tasks/steps in a Viewpoint Template
* MODIFIED By : JVH 6/24/2009 Issue #130980 Increase @Template to VARCHAR(60)
*	Inputs:
*	@Company		Not used
*	@Template		Template to do reordering on
*	@Renumber		Comma delimited list of current numbers
*	@RenumberTo		Comma delimited list of numbers to be shifted to
*	@Task			Optional indicating what task the steps are to be renumbered for
*	@Type			Step/Task
*
*	Outputs:
*		@msg		return error message if any
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFReorderVPTemplate]
	-- Add the parameters for the stored procedure here
	@Company bCompany = null,
	@Template varchar(60) = null,
	@Renumber varchar(max) = null,
	@RenumberTo varchar(max) = null,
	@Task int = null,
	@Type varchar(4),
	@msg varchar(256) = null OUTPUT
AS
BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @rcode int
	DECLARE @OldList TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   )
	DECLARE @NewList TABLE(KeyID int IDENTITY,
						   Names VARCHAR(150)
						   )

INSERT INTO @OldList SELECT Names FROM [dbo].[vfTableFromArray](@Renumber)
INSERT INTO @NewList SELECT Names FROM [dbo].[vfTableFromArray](@RenumberTo)
IF @Type = 'task'
BEGIN

	BEGIN TRY

		BEGIN TRANSACTION

		UPDATE vWFVPTemplateSteps SET Task = CAST(n.Names as int)
		FROM vWFVPTemplateSteps s, @NewList n, @OldList o
		WHERE s.Task = o.Names AND n.KeyID = o.KeyID AND s.Template = @Template

		UPDATE vWFVPTemplateTasks SET Task = CAST(n.Names as int)
		FROM vWFVPTemplateTasks t, @NewList n, @OldList o
		WHERE t.Task = o.Names AND n.KeyID = o.KeyID AND t.Template = @Template
	
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SELECT @msg = left('Error Number: ' + cast(ERROR_NUMBER() as varchar(max)) + ' Line: '+ cast(ERROR_LINE() as varchar(max)) + ' Message: ' + ERROR_MESSAGE(),255)
		SET @rcode = 1
		RETURN @rcode 
	END CATCH

	IF @@TRANCOUNT > 0
		    COMMIT TRANSACTION;
		SET @rcode = 0
		RETURN @rcode 
END

IF @Type = 'step'
BEGIN
	BEGIN TRY

		BEGIN TRANSACTION

		UPDATE vWFVPTemplateSteps SET Step = CAST(n.Names as int)
		FROM vWFVPTemplateSteps s, @NewList n, @OldList o
		WHERE s.Step = o.Names AND n.KeyID = o.KeyID AND s.Template = @Template AND s.Task = @Task

	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;
		SELECT @msg = left('Error Number: ' + cast(ERROR_NUMBER() as varchar(max)) + ' Line: '+ cast(ERROR_LINE() as varchar(max)) + ' Message: ' + ERROR_MESSAGE(),255)
		SET @rcode = 1
		RETURN @rcode 
	END CATCH

	IF @@TRANCOUNT > 0
		COMMIT TRANSACTION;
	SET @rcode = 0
	RETURN @rcode 
END -- step

END
GO
GRANT EXECUTE ON  [dbo].[vspWFReorderVPTemplate] TO [public]
GO
