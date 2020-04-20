SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDAssemblyDependencySelect] 
/******************************************************************************
* Created: Paul Wiegardt 2012-10-17
*
* Select dependent assemblies by assembly
*
* Inputs:
*	@assembly: The parent assembly name
*
* Output:
*	The assemblies the parent assembly depends on
*	@errmsg		Error message
*
* Return code:
*	@rcode	0 = success, 1 = failure
*
*******************************************************************************
* Modified:
*******************************************************************************/
(
    @assembly varchar(256) = null,
    
    @errmsg varchar(512) OUTPUT
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 0

	BEGIN TRY 
		SELECT
			Assembly
		,	DependentAssembly
		FROM vDDAssemblyDependency
		WHERE (@assembly is null) or Assembly = @assembly -- if @assembly is null then select all
	END TRY
	BEGIN CATCH
		SELECT @errmsg = ERROR_MESSAGE()
		SELECT @rcode = 1
		RAISERROR (@errmsg, 15, 1)
	END CATCH
	 
	RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspDDAssemblyDependencySelect] TO [public]
GO
