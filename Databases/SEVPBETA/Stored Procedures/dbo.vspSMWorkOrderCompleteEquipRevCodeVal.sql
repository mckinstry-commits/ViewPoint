SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspSMWorkOrderCompleteEquipRevCodeVal]
/***********************************************************
* CREATED BY:	TRL 11/05/2010
* MODIFIED By:	ECV 11/17/2010 Added Revenue UM output parameter
				JJB 12/9/10 - Fixed the rev rate logic and cleanup
				JVH 3/11/11 - Simplified some of the logic
*
*
* USAGE:
*	Validates RevCode
*	Calls vspEMUsePostingFlagsGet for other values
*	Calls vspEMUsePostingRevRateUMDflt for other values
*
*
* INPUT PARAMETERS
*
*
* OUTPUT PARAMETERS
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(	
	@SMCo bCompany,
	@WorkOrder int,
	@Scope int,
	@EMCo bCompany,
	@Equipment bEquip,
	@EMGroup bGroup,
	@RevCode bRevCode,
	@Basis char(1) = NULL OUTPUT,
	@Rate bDollar = NULL OUTPUT,
	@PostWorkUnits bYN = NULL OUTPUT,
	@TimeUM bUM = NULL OUTPUT,
	@WorkUM bUM = NULL OUTPUT,
	@msg varchar(255) OUTPUT
)	
AS 

SET NOCOUNT ON

	-- Validation
	IF @EMCo IS NULL
	BEGIN 
		SELECT @msg = 'Missing EM Company.'
		RETURN 1
	END
	
	IF @Equipment IS NULL OR @Equipment =''
	BEGIN 
		SELECT @msg = 'Missing Equipment.'
		RETURN 1
	END 

	IF @RevCode IS NULL OR @RevCode =''
	BEGIN 
		SELECT @msg = 'Missing Revenue Code.'
		RETURN 1
	END

	IF @EMGroup IS NULL
	BEGIN 
		SELECT @msg = 'Missing EM Group.'
		RETURN 1
	END 

	SELECT @msg = [Description]
	FROM dbo.EMRC
	WHERE EMGroup = @EMGroup AND RevCode = @RevCode
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Revenue Code doesn''t exist.'
		RETURN 1
	END

	SELECT @Basis = Basis, @Rate = Rate, @PostWorkUnits = PostWorkUnits, @TimeUM = TimeUM, @WorkUM = WorkUM
	FROM dbo.vfEMEquipmentRevCodeSetup(@EMCo, @Equipment, @EMGroup, @RevCode)
	WHERE CategorySetupExists = 'Y' OR EquipmentSetupExists = 'Y'
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'Revenue Code has not been set up in EM Rev Rates by Category or Equipment forms.'
		RETURN 1
	END

	RETURN 0



GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderCompleteEquipRevCodeVal] TO [public]
GO
