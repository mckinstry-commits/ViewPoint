SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************************/
CREATE    proc [dbo].[vspPMPOCONumGet]
/***********************************************************
 * Created By:	GF 06/27/2011 - TK-06437
 * Modified By:	GP 7/28/2011 - TK-07143 changed bPO to varchar(30)
 *
 *
 * USAGE:
 * Gets the next PO Change Order Number from PMPOCO
 *
 * INPUT PARAMETERS
 * APCo, PO
 *
 * OUTPUT PARAMETERS
 *  POCONum   next sequential POCONum
 *  msg     description, or error message
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@APCo bCompany = NULL, @PO varchar(30) = NULL, 
 @POCONum SMALLINT = NULL OUTPUT, @msg varchar(255) output)
as
set nocount on

declare @rcode int

SET @rcode = 0

---- get next POCO Number
SELECT @POCONum = isnull(max(POCONum) + 1, 1)
FROM dbo.vPMPOCO
WHERE POCo = @APCo
	AND PO=@PO 
IF ISNULL(@POCONum,0) = 0 SET @POCONum = 1



bspexit:
	if @POCONum = 0 select @POCONum = null
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPOCONumGet] TO [public]
GO
