SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJCCostTypeValForAPBurden]
/***********************************************************
* CREATED BY:		CHS 02/21/2012
* MODIFIED By:
* USAGE:
*
* INPUT PARAMETERS
*   APCo      JB Co to validate against
*
*
* OUTPUT PARAMETERS
*   @msg      error message IF error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
@APCo bCompany, @CostType varchar(10), @CostTypeOut bJCCType output, @Description bItemDesc output, @msg varchar(255) output
   
	AS
	SET NOCOUNT ON

	DECLARE @RCode int, @PhaseGroup bGroup

	SELECT @RCode = 0
   
   
	IF @APCo is null
		BEGIN
		SELECT @msg = 'Missing AP Company!', @RCode = 1
		RETURN @RCode
		END

	SELECT @PhaseGroup = PhaseGroup
	FROM HQCO
	WHERE HQCo = @APCo
   
   
	/* IF @CostType is numeric then try to find*/
	IF isnumeric(@CostType) = 1
		BEGIN
		SELECT @CostTypeOut = CostType, @Description = Abbreviation, @msg = Description
		FROM JCCT
		WHERE PhaseGroup = @PhaseGroup and CostType = convert(int,convert(float, @CostType))
		END
   
	/* IF not numeric or not found try to find as Sort Name */
	IF @@rowcount = 0
		BEGIN
		SELECT @CostTypeOut = CostType, @Description = Abbreviation, @msg = Description
		FROM JCCT
		WHERE PhaseGroup = @PhaseGroup and CostType=(SELECT min(j.CostType)
		FROM bJCCT j
		WHERE j.PhaseGroup=@PhaseGroup and j.Abbreviation like @CostType + '%')
		
		IF @@rowcount = 0
			BEGIN
			SELECT @msg = 'JC Cost Type not on file!', @RCode = 1
			RETURN @RCode
			END
			
		END
   

GO
GRANT EXECUTE ON  [dbo].[vspJCCostTypeValForAPBurden] TO [public]
GO
