SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspSMWorkOrderCompleteEquipVal]
   
/***********************************************************
* CREATED BY:  TRL  11/05/2010
* MODIFIED By : JVH 3/11/11
*				JG 01/20/2012 - TK-11897 - Returning the JC Cost Type
* USAGE:	
*
* INPUT PARAMETERS
*	@SMCo		SM Company
*	@EMCo		EM Company
*	@Equipment		Equipment to be validated
*
* OUTPUT PARAMETERS
*	ret val		EMEM column
*	-------		-----------
*	@RevCode 	Default RevCode
*	@msg			Description or Error msg if error
**********************************************************/
(@SMCo dbo.bCompany,
@EMCo bCompany, 
@Equipment bEquip, 
@Job dbo.bJob,
@SMCostType SMALLINT,
@RevCode bRevCode = NULL OUTPUT, 
@Category bCat = NULL OUTPUT, 
@JCCostType dbo.bJCCType = NULL OUTPUT,
@msg varchar(255) OUTPUT)
   
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int, @Status char(1), @Type char(1)

	--Validation of required parameters happens in vspEMEquipChangeInProgressVal
	   
	-- Return if Equipment Change in progress for New Equipment Code, 126196.
	EXEC @rcode = dbo.vspEMEquipChangeInProgressVal @emco = @EMCo, @equip = @Equipment, @msg = @msg OUTPUT
	IF @rcode <> 0 RETURN @rcode

	--Already verified that the equipment exists in vspEMEquipChangeInProgressVal
	--Get equipment informaiton
	SELECT @RevCode = RevenueCode, @Status = [Status], @Type = [Type], @Category = Category
	FROM dbo.EMEM 
	WHERE EMCo = @EMCo and Equipment = @Equipment
	IF (@@ROWCOUNT = 0)
	BEGIN
		SET @msg = 'Invalid Equipment.'
		RETURN 1
	END

	--InActive Equipment can't be used'
	IF @Status <> 'A' and @Status <> 'D'
	BEGIN
		SET @msg = 'Equipment may not be InActive.'
		RETURN 1
	END
	 
	--Componets are attached to Equipment and can't be used in this form'   
	IF @Type = 'C'
	BEGIN 
		SET @msg = 'Invalid entry.  Cannot be a component!'
		RETURN 1
	END 

	--TK-11897
    EXEC	@rcode = vspSMJCCostTypeDefaultVal 
			@SMCo = @SMCo
			, @Job = @Job
			, @LineType = 1 -- Equip
			, @Equipment = @Equipment
			, @SMCostType = @SMCostType
			, @JCCostType = @JCCostType OUTPUT
			, @msg = @msg OUTPUT
    
    RETURN @rcode
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderCompleteEquipVal] TO [public]
GO
