SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  procedure [dbo].[vspSMChangeScopeOnHold]
	/******************************************************
	* CREATED BY:	AaronL
	* MODIFIED By:	
	*	
	*
	* Input params:
	*
	*	@ScopeID - Key ID of Scope
	*	@OnHold - Is scope to be placed on hold
	*	
	*
	* Output params:
	*	@msg		error message.
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	(@ScopeID int, @OnHold bYN, @msg varchar(100) OUTPUT)
	
AS
BEGIN
	SET NOCOUNT ON
	
	IF @ScopeID IS NULL
	BEGIN
		SET @msg = 'Missing ScopeID.'
		RETURN 1
	END
	
	IF @OnHold IS NULL
	BEGIN
		SET @msg = 'Missing On Hold'
		RETURN 1
	END

	if(@OnHold = 'Y')
	begin
		UPDATE SMWorkOrderScope
		Set OnHold = @OnHold
		WHERE SMWorkOrderScopeID = @ScopeID
	end
	else
	begin
		UPDATE SMWorkOrderScope
		Set OnHold = @OnHold, HoldReason = null, FollowUpDate = null
		WHERE SMWorkOrderScopeID = @ScopeID
	end
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMChangeScopeOnHold] TO [public]
GO
