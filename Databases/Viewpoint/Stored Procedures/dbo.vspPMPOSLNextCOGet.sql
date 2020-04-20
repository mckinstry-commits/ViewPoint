SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************/
create  proc [dbo].[vspPMPOSLNextCOGet]
/*************************************
 * Created By:	GF 06/10/2011 TK-00000
 * Modified by:
 *
 * called from PM Common Routines to return the next change order number
 * for SubCO or POCONum. Both the PO and SL Change Order forms will use
 * this procedure to get next CO number when New is specified in the key
 * field.
 *
 * Pass:
 * COType		Either PO or SL to know what type of CO to get next for
 * Company		SL/PO Company
 * POSL			Purchase Order or Subcontract
 *
 * OUTPUT PARAMETERS
 * CONum		next change order number for the PO or SL
 * msg			description, or error message
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 **************************************/
(@COType VARCHAR(2) = NULL, @Company bCompany = NULL, @POSL VARCHAR(30) = NULL,
 @CONum SMALLINT = NULL OUTPUT, @msg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode INT

SET @rcode = 0
SET @CONum = -1

---- missing data exit
IF @COType IS NULL OR @Company IS NULL OR @POSL IS NULL GOTO vspexit


------------------------
-- GET NEXT CO Number --
------------------------
---- 'PO' purchase order	
IF @COType = 'PO'
	BEGIN
	---- get next POCO Number
	SELECT @CONum = isnull(max(POCONum) + 1, 1)
	FROM dbo.PMPOCO
	WHERE POCo = @Company
		AND PO=@POSL
	IF ISNULL(@CONum,0) = 0 SET @CONum = 1
	END

---- 'SL' subcontract
IF @COType = 'SL'
	BEGIN
	---- get next SubCO Number
	SELECT @CONum = isnull(max(SubCO) + 1, 1)
	FROM dbo.PMSubcontractCO
	WHERE SLCo = @Company
		AND SL = @POSL 
	END




vspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOSLNextCOGet] TO [public]
GO
