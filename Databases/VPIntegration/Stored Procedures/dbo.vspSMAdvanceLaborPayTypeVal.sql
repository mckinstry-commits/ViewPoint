SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMAdvanceLaborPayTypeVal]
	/******************************************************
	* CREATED BY:  Mark H 
	* MODIFIED By: Mark H 12/02/10 removed restriction that Call type only 
	*				rate had to be specified before use in Call Type/Pay Type combination
	*				MarkH 01/23/2011 - Added EarnCode output param to vspSMPayTypeVal call
	*
	* Usage:  Validates the Pay Type and if appropriate the Call Type
	*			Pay Type combination.  
	*
	*		1 - Only allow one Call Type/Pay Type combination for a 
	*			Rate Template.
	*	
	*
	* Input params:
	*	
	*		@SMCo - SM Company
	*		@PayType - Pay Type
	*		@CallType - Call Type
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, @RateTemplate varchar(10), @Seq int, @PayType varchar(10), @CallType varchar(10), @msg varchar(500) output
	as 
	set nocount on

	DECLARE @rcode int, @EarnCode bEDLCode

	IF @SMCo is null
	BEGIN
		SELECT @msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @RateTemplate is null
	BEGIN
		SELECT @msg = 'Missing Rate Template.'
		RETURN 1
	END
	
	IF @PayType is null
	BEGIN
		SELECT @msg = 'Missing Pay Type.'
		RETURN 1
	END
	
	--We do not allow the addition of a Pay Type that is not active.  What happens if we have a Pay Type
	--on a Rate scheme that has been changed to inactive but is still on the scheme.  Do we allow the rate
	--to be changed?
	EXEC @rcode = vspSMPayTypeVal @SMCo, @PayType, @EarnCode output, @msg output
	
	IF @rcode <> 0
	BEGIN
		RETURN 1
	END
	
	--Assuming Call Types is a valid value
	IF @CallType is not null
	BEGIN
		IF EXISTS(SELECT 1 FROM SMAdvancedLaborRate 
		WHERE SMCo = @SMCo and RateTemplate = @RateTemplate and CallType = @CallType and PayType = @PayType
		and Seq <> @Seq)
		BEGIN
			SELECT @msg = 'Call Type: ' + @CallType + ' and Pay Type: ' + @PayType + ' have already been defined for Template.' 
			RETURN 1		
		END
	END
	





GO
GRANT EXECUTE ON  [dbo].[vspSMAdvanceLaborPayTypeVal] TO [public]
GO
