SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	CREATE  procedure [dbo].[vspSMSessionChangeBillingFlag]
	/******************************************************
	* CREATED BY:  EricV 
	* MODIFIED By: 
	*
	* Usage:  Change the value of the Prebilling flag in the vSMSession table
	*	
	*
	* Input params:
	*	
	*	@SMSessionID	- SM Session ID
	*	@Prebilling     - Prebilling Flag
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMSessionID int, @Prebilling bit, @msg varchar(100)=NULL output
   	
	AS 
	SET NOCOUNT ON

	-- Check to see if the session is locked.
	DECLARE @UserName varchar(128), @IsLocked bit, @CurrentPrebilling bit
	exec vspSMCheckSession @SMSessionID, @IsLocked OUTPUT, @UserName OUTPUT, @CurrentPrebilling OUTPUT
	
	IF (@IsLocked = 1)
	BEGIN
		SET @msg = 'Session is currently locked by '+@UserName
		RETURN 1
	END
	
	BEGIN TRY
		--Get rid of the actual session
		UPDATE dbo.SMSession SET Prebilling = @Prebilling WHERE SMSessionID = @SMSessionID
	END TRY
	BEGIN CATCH
		SET @msg = ERROR_MESSAGE();
		RETURN 1
	END CATCH
	
	RETURN 0
	

GO
GRANT EXECUTE ON  [dbo].[vspSMSessionChangeBillingFlag] TO [public]
GO
