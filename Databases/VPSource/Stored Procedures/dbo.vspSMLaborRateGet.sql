SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMLaborRateGet]
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By:  Mark H 01/23/2011	- Added EarnCode output parameter vspSMPayTypeVal call
	*				JB 07/11/2011		- Modified SP to support Labor pricing overrides
	*               ECV 07/18/2011		- Added Craft and Class to input parameters.
	*				JG 01/20/2012		- TK-11897 - Returning the JC Cost Type
	*
	* Usage:
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/

   	(@SMCo bCompany, 
   	@Technician varchar(15), 
   	@PayType varchar(10), 
   	@Job bJob = NULL,
   	@LaborCode VARCHAR(15) = NULL,
   	@SMCostType SMALLINT = NULL,
   	@LaborCostRate bUnitCost OUTPUT, 
   	@JCCostType AS dbo.bJCCType OUTPUT,
   	@msg varchar(100) OUTPUT)
   	   	
	AS 
	SET	NOCOUNT ON

	DECLARE @CostMethod tinyint, @Factor bDollar, @TechRate bUnitCost, @EarnCode bEDLCode, @rcode int

	IF @SMCo is null
	BEGIN
		SELECT @msg = 'Missing SM Company.'
		RETURN 1
	END

	IF @PayType is null
	BEGIN
		SELECT @msg = 'Missing Pay Type.'
		RETURN 1
	END

	EXEC @rcode = vspSMPayTypeVal @SMCo, @PayType, @EarnCode output, @msg output
	if @rcode = 1
	BEGIN
		RETURN 1
	END
	
	-- Determine Labor Cost Rate
	SELECT @CostMethod = CostMethod, @Factor = Factor FROM SMPayType WHERE SMCo = @SMCo and PayType = @PayType
	
	IF @CostMethod = 0
	BEGIN
		SELECT @TechRate = isnull(Rate,0) FROM SMTechnician where SMCo = @SMCo and Technician = @Technician
		
		SELECT @LaborCostRate = @TechRate * isnull(@Factor,1)
	END

	IF @CostMethod = 1
	BEGIN
		SELECT @LaborCostRate = @Factor
	END

	--TK-11897
	EXEC	@rcode = vspSMJCCostTypeDefaultVal 
			@SMCo = @SMCo
			, @Job = @Job
			, @LineType = 2 -- Labor
			, @PayType = @PayType
			, @LaborCode = @LaborCode
			, @SMCostType = @SMCostType
			, @JCCostType = @JCCostType OUTPUT
			, @msg = @msg OUTPUT
    
    RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSMLaborRateGet] TO [public]
GO
