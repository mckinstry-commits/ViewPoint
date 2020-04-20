SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

	CREATE  procedure [dbo].[vspSMStandardItemVal]
	/******************************************************
	* CREATED BY:	Eric V 
	* MODIFIED By: 
	*
	* Usage:  Validates a Standard Item
	*	
	*
	* Input params:
	*
	*	@SMCo         - SM Company
	*	@StandardItem - Standard Item
	*	@MustExist    - Flag to control validation behavior
	*	
	*
	* Output params:
	*
	*	@CostRate     - Cost rate of Standard Item.
	*   @BillableRate - Billable rate of Standard Item.
	*	@msg		  - Work Scope description or error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
	
	/*************************************************************
	-- Testing harness
	BEGIN TRANSACTION
	DECLARE @SMCo bCompany, @WorkScope varchar(20), @MustExist bYN, @CostRate bRate, @BillableRate bRate, @msg varchar(100), @rcode int

	INSERT SMStandardItem (SMCo, StandardItem, Description, CostRate, BillableRate, Notes) VALUES (0, 'TEST1.1', 'Testing Step 1.1', 45.5, 99.9, 'Test Notes')

	SELECT 'Testing existing entry with MustExist=Y' Test	
	SELECT @SMCo=0, @StandardItem='TEST1.1', @MustExist='Y'
	EXECUTE @rcode = vspSMStandardItemVal @SMCo, @StandardItem, @MustExist, @CostRate OUTPUT, @BillableRate OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=0 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @CostRate [CostRate], @BillableRate [BillableRate], @msg [msg]
	
	SELECT 'Testing missing entry with MustExist=Y' Test	
	SELECT @SMCo=0, @StandardItem='TEST1.2', @MustExist='Y'
	EXECUTE @rcode = vspSMStandardItemVal @SMCo, @StandardItem, @MustExist, @CostRate OUTPUT, @BillableRate OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=1 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @CostRate [CostRate], @BillableRate [BillableRate], @msg [msg]
	
	SELECT 'Testing missing entry with MustExist=N' Test	
	SELECT @SMCo=0, @StandardItem='TEST1.2', @MustExist='N'
	EXECUTE @rcode = vspSMStandardItemVal @SMCo, @StandardItem, @MustExist, @CostRate OUTPUT, @BillableRate OUTPUT, @msg OUTPUT
	SELECT CASE WHEN @rcode=0 THEN 'PASSED' ELSE 'FAILED' END AS Results, @rcode 'Return code', @CostRate [CostRate], @BillableRate [BillableRate], @msg [msg]
	
	ROLLBACK TRANSACTION
	***************************************************************/
	

   
   	(@SMCo bCompany, @StandardItem varchar(20), @MustExist bYN, @CostRate bUnitCost OUTPUT, @BillableRate bUnitCost OUTPUT, @SMCostType smallint = NULL OUTPUT, @msg varchar(100) OUTPUT)
	
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
		@BillableRate = BillableRate,
		@SMCostType = SMCostType
	FROM dbo.SMStandardItem
	WHERE SMCo = @SMCo and StandardItem = @StandardItem
	IF @@rowcount = 0 AND @MustExist = 'Y'
	BEGIN
		SELECT @msg = 'Standard Item does not exist in SMStandardItem.'
		RETURN 1
	END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMStandardItemVal] TO [public]
GO
