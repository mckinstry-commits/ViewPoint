SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Stored Procedure dbo.vspPOItemLineTaxCalcs  ******/

CREATE procedure [dbo].[vspPOItemLineTaxCodeVal]
/************************************************************************
 * Created By:	GF 08/11/2011 TK-07438 TK-07439 TK-07440
 * Modified By:	DAN SO 04/23/2012 TK-14139 - Need to validate for SM Jobs
 *
 *
 *
 *
 * PURPOSE:
 * Validates the tax code for PO Item Lines. If the item type is
 * 1 - Job OR 6 - SMWO then the tax phase and tax cost type is validated also.
 * Called from PO Item Line insert, update, and delete triggers currently.
 *
 * INPUT:
 * @PostToCo
 * @Job
 * @PhaseGroup
 * @Phase
 * @JCCType
 * @ItemType
 * @TaxGroup
 * @TaxType
 * @TaxCode
 *
 * OUTPUT:
 * @TaxPhase
 * @TaxCT
 * @TaxJCUM
 *
 * RETURNS:
 *	0 - Success 
 *	1 - Failure
 *
 *************************************************************************/
(@PostToCo bCompany = NULL, @Job bJob = NULL, @PhaseGroup bGroup = NULL, 
 @Phase bPhase = NULL, @JCCType bJCCType = NULL, @ItemType TINYINT = NULL,
 @TaxGroup bGroup = NULL, @TaxType TINYINT = NULL, @TaxCode bTaxCode = NULL,
 @TaxPhase bPhase = NULL OUTPUT, @TaxCT bJCCType = NULL OUTPUT,
 @TaxJCUM bUM = NULL OUTPUT, @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON


declare @rcode INT
		
---- inititalize variables
SET @rcode = 0
SET @TaxPhase = NULL
SET @TaxCT = NULL
SET @TaxJCUM = NULL

---- validate tax code and get tax phase / cost type
EXEC @rcode = dbo.bspPOTaxCodeVal @TaxGroup, @TaxCode, @TaxType, @TaxPhase OUTPUT, @TaxCT OUTPUT, @ErrMsg OUTPUT
IF @rcode <> 0
	BEGIN
	SELECT @ErrMsg = ISNULL(@ErrMsg, ''), @rcode = 1
	GOTO vspexit
	END

---- validate Tax Phase if Job Type
if (@ItemType = 1) OR (@ItemType = 6 AND @Job IS NOT NULL)	-- TK-14139 --
	BEGIN
	IF @TaxPhase IS NULL SET @TaxPhase = @Phase
	IF @TaxCT IS NULL SET @TaxCT = @JCCType

	---- validate Tax phase and Tax Cost Type
	EXEC @rcode = dbo.bspJobTypeVal @PostToCo, @PhaseGroup, @Job, @TaxPhase, @TaxCT, @TaxJCUM OUTPUT, @ErrMsg OUTPUT
	IF @rcode <> 0
		BEGIN
		SELECT @ErrMsg = ISNULL(@ErrMsg,''), @rcode = 1
		GOTO vspexit
		END
	END

		




vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineTaxCodeVal] TO [public]
GO
