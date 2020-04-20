SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMAdvancedLaborRateDetailRecVal]
	/******************************************************
	* CREATED BY:	Mark H 
	* MODIFIED By: 
	*
	* Usage:  Called from Insert or Update of Advanced Labor Rate record 
	*		provide a sanity check. 
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
   
   	(@SMCo bCompany, @RateTemplate varchar(10), @Seq int, @CallType varchar(10),
   	@PayType varchar(10), @LaborRate bUnitCost, @msg varchar(100) output)
   	
	as 
	set nocount on

	IF (@Seq is not null and @CallType is null and @PayType is null and @LaborRate is not null)
	BEGIN
		SELECT @msg = 'Labor rate cannot be specified without a Call Type or a Pay Type.'
		RETURN 1
	END
	
	IF (@CallType is not null and @PayType is null)
	BEGIN
		IF EXISTS(SELECT 1 FROM SMAdvancedLaborRate WHERE CallType = @CallType
		and PayType is null and Seq <> @Seq and SMCo = @SMCo and RateTemplate = @RateTemplate)
		BEGIN
			SELECT @msg = 'Labor rate has already been defined in this Template for Call Type: ' + @CallType
			RETURN 1
		END
	END
	
	IF (@CallType is null and @PayType is not null)
	BEGIN
		IF EXISTS(SELECT 1 from SMAdvancedLaborRate WHERE CallType is null 
		and PayType = @PayType and Seq <> @Seq and SMCo = @SMCo and RateTemplate = @RateTemplate)
		BEGIN
			SELECT @msg = 'Labor rate has already been defined in this Template for Pay Type: ' + @PayType
			RETURN 1
		END
	END
	
	IF (@CallType is not null and @PayType is not null)	
	BEGIN
		IF EXISTS(SELECT 1 FROM SMAdvancedLaborRate WHERE CallType = @CallType 
		and PayType = @PayType and Seq <> @Seq and SMCo = @SMCo and RateTemplate = @RateTemplate)
		BEGIN
			SELECT @msg = 'Call Type: ' + @CallType + ' and Pay Type: ' + @PayType + ' have already been defined for this Template.'
			RETURN 1
		END
	END


GO
GRANT EXECUTE ON  [dbo].[vspSMAdvancedLaborRateDetailRecVal] TO [public]
GO
