SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMPayTypeVal]
	/******************************************************
	* CREATED BY:  Mark H 
	* MODIFIED By: Mark H 10/29/2010 - Added check for inactive Pay Type
	*			   Mark H 1/23/2011 - Added EarnCode output param
	*
	* Usage:  Validates Pay Type against SMPayType
	*	
	*
	* Input params:
	*	
	*	@SMCo - SM Company
	*	@PayType - Pay Type
	*	
	*
	* Output params:
	*	@Msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@SMCo bCompany, @PayType varchar(10), @EarnCode bEDLCode output, @Msg varchar(100) output)
	as 
	set nocount on

	DECLARE @Active bYN
	
	SELECT @Active = 'N'
	
	IF @SMCo is null
	BEGIN
		SELECT @Msg = 'Missing SM Company.'
		RETURN 1
	END
	
	IF @PayType is null
	BEGIN
		SELECT @Msg = 'Missing Pay Type.'
		RETURN 1
	END
	
	SELECT @Msg = [Description], @Active = [Active], @EarnCode = EarnCode
	FROM dbo.SMPayType
	WHERE SMCo = @SMCo AND PayType = @PayType 
	
	IF @@rowcount = 0
	BEGIN
		SET @Msg = 'Pay Type has not been setup.'
		RETURN 1
	END

	IF @Active = 'N'
	BEGIN
		SET @Msg = 'Pay Type is not active.'	
		RETURN 1
	END
	
	RETURN 0
 




GO
GRANT EXECUTE ON  [dbo].[vspSMPayTypeVal] TO [public]
GO
