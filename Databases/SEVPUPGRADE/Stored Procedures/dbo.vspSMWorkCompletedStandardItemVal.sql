SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


	CREATE  procedure [dbo].[vspSMWorkCompletedStandardItemVal]
	/******************************************************
	* CREATED BY:	Lane G 07/12/11
	* MODIFIED By:	MarkH 08/20/11 - TK-07482 - Removed MiscellaneousType
	*
	* Usage:  Validates a Work Completed Standard Item
	*	
	*
	* Input params:
	*
	*	@SMCo         - SM Company
	*	@StandardItem - Standard Item
	*	
	* Output params:
	*
	*	@CostRate     - Cost rate of Standard Item.
	*	@msg		  - Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany, @StandardItem varchar(20), @CostRate bUnitCost OUTPUT, @SMCostType smallint = NULL OUTPUT, @msg varchar(100) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON

	SET @msg = 
  		CASE WHEN @SMCo IS NULL THEN 'Missing SM Company.'
  			 WHEN @StandardItem IS NULL THEN 'Missing Standard Item.'
		END
	
	IF @msg IS NOT NULL
	BEGIN	
		RETURN 1
	END

	SET @msg = 'Standard Item not on file.'

	SELECT 
		@msg = [Description], 
		@CostRate = CASE WHEN CostRate=0 THEN NULL ELSE CostRate END,
		@SMCostType = SMCostType
	FROM dbo.SMStandardItem
	WHERE SMCo = @SMCo and StandardItem = @StandardItem
	IF @@rowcount = 0
	BEGIN
		SELECT @msg = 'Standard Item does not exist in SMStandardItem.'
		RETURN 1
	END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedStandardItemVal] TO [public]
GO
