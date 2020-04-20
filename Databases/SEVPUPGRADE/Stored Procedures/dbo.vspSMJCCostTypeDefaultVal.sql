SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMJCCostTypeDefaultVal] 
/***********************************************
* Created:	JG 01/20/12 - TK-11897
* Modified: JG 02/07/12 - TK-11897 - Flipping the way defaults work.
*				TL 07/19/121 TK-16537 - Changed  Equipment/Material selection

* Used to get the default JC Cost Type based on parameters.
*
* Inputs:
*	@SMCo			SM Company
*	@LineType		Either Equipment, Labor, Material or Misc
*	@Job			JC Job value - returns NULL JCCostType if NULL
*	@LaborCode		SM Labor Code value
*	@PayType		SM Pay Type value
*	@SMCostType		SM Cost Type value
*	@Equipment		Equipment value
*	@MatlGroup		Material Group
*	@Material		Material value
*	@JCCostType		Parameter default value
* 
************************************************/
(
 @SMCo dbo.bCompany = NULL,
 @Job dbo.bJob = NULL,
 @LineType TINYINT = NULL,
 @LaborCode VARCHAR(15) = NULL,
 @PayType VARCHAR(10) = NULL,
 @SMCostType SMALLINT = NULL,
 @Equipment dbo.bEquip = NULL,
 @MatlGroup dbo.bGroup = NULL,
 @Material bMatl = NULL,
 @JCCostType dbo.bJCCType OUTPUT,
 @msg VARCHAR(255) OUTPUT
)
AS 
SET nocount ON

DECLARE @rcode INT 

SELECT  @rcode = 0

/*JC Cost Type Hiearchy
1. Equipment, SM Cost Type, PayType, 
2. Material, SM Cost Type,PayType
3. Labor Code, SM Cost Type,PayType
*/

IF ISNULL(@Job,'') = ''
BEGIN
	RETURN 0
END


IF @LaborCode IS NOT NULL
BEGIN
	SELECT @JCCostType = ISNULL(JCCostType, @JCCostType) FROM dbo.SMLaborCode WHERE SMCo = @SMCo AND LaborCode = @LaborCode	

	--Exit if JC Cost Type Exists
	IF @JCCostType IS NOT NULL
	BEGIN
		RETURN 0
	END
END

IF @SMCostType IS NOT NULL
BEGIN
	SELECT @JCCostType = JCCostType	FROM dbo.SMCostType	WHERE SMCo = @SMCo AND SMCostType = @SMCostType

	--Exit if JC Cost Type Exists
	IF @JCCostType IS NOT NULL
	BEGIN
		RETURN 0
	END
END

IF @PayType IS NOT NULL 
BEGIN
	SELECT @JCCostType = PREC.JCCostType
	FROM dbo.SMPayType
	INNER JOIN SMCO ON SMCO.SMCo = SMPayType.SMCo
	INNER	JOIN dbo.PREC ON PREC.EarnCode = SMPayType.EarnCode 	AND PREC.PRCo = SMCO.PRCo
	WHERE SMPayType.SMCo = @SMCo AND SMPayType.PayType = @PayType
END	

IF @Equipment IS NOT NULL
BEGIN
	-- Get the JC Cost Type from EM Equipment
	SELECT @JCCostType = UsageCostType 
	FROM dbo.EMEM
	INNER JOIN dbo.SMCO ON SMCO.EMCo = EMEM.EMCo
	WHERE SMCO.SMCo = @SMCo	AND Equipment = @Equipment 
END	

IF @Material IS NOT NULL AND @MatlGroup IS NOT NULL
BEGIN
	SELECT @JCCostType = MatlJCCostType FROM dbo.HQMT WHERE MatlGroup = @MatlGroup AND Material = @Material
END

vcsexit:

RETURN @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSMJCCostTypeDefaultVal] TO [public]
GO
