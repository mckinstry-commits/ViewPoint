SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

	CREATE  procedure [dbo].[vspSMPayTypeValforTimecards]
	/******************************************************
	* CREATED BY:  MarkH TK-12387  
	* MODIFIED By: 
	*
	* Usage:	Validates SM Pay Type and returns Earnings Code and SM JC Cost Type
	*			if applicable.
	*	
	*
	* Input params:
	*	@SMCo - SM Company
	*	@PayType - SM Pay Type
	*	@Job - Job value acts as a control to determine if an SM JC Cost Type will be looked for and returned
	*	@LaborCode - Value used to determine what SM JC Cost Type to return
	*	@SMCostType - Value used to determine what SM JC Cost Type to return
	*
	* Output params:
	*	@EarnCode - Earnings Code associated with Pay
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany = NULL, 
   	@PayType varchar(10) = NULL, 
   	@Job bJob = NULL, 
   	@LaborCode VARCHAR(15) = NULL, 
   	@SMCostType SMALLINT = NULL,
   	@EarnCode bEDLCode OUTPUT, 
   	@JCCostType bJCCType OUTPUT, 
   	@msg varchar(100)OUTPUT)

	as 
	set nocount on
	
	DECLARE @rcode tinyint
	SET @rcode = 0
	
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

	
	RETURN 0


GO
GRANT EXECUTE ON  [dbo].[vspSMPayTypeValforTimecards] TO [public]
GO
