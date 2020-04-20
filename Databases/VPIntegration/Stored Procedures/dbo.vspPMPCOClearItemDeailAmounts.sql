SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE PROCEDURE [dbo].[vspPMPCOClearItemDeailAmounts] 
/*****************************************************************
* Created By:	JG 05/18/2011 TK-04940
* Modified By:	
*
*
*
*	Usage: Used to reset PMOL items when SL and PO is unchecked.
*
*
*	Pass in: 
*	@PMCo 		- PM Company
*	@Project 	- PM Project
*	@PCOType	- PCO type
*	@PCO		- PCO
*	@EstImpact	- Impact Estimate
*	@SLImpact	- Impact SL
*	@POImpact	- Impact PO
*
*	output:
*
*	returns:
*		@rcode
*
*****************************************************************/
(@PMCo bCompany = null, @Project bJob = null, @PCOType bDocType = null, @PCO bPCO = null,
 @EstImpact char(1) = NULL, @SLImpact char(1) = NULL, @POImpact char(1) = NULL, @msg varchar(255) output)
as
set nocount on
   
declare @rcode int

set @rcode = 0

---- flag must not be null
if @EstImpact is null
	begin
	select @msg = 'Impact Estimate flag may not be null.', @rcode = 1
	goto bspexit
	end
   
---- flag must not be null
if @SLImpact is null
	begin
	select @msg = 'Impact SL flag may not be null.', @rcode = 1
	goto bspexit
	end
	
---- flag must not be null
if @POImpact is null
	begin
	select @msg = 'Impact PO flag may not be null.', @rcode = 1
	goto bspexit
	end
	

IF @EstImpact = 'Y' GOTO slpo

---- when estimate type is not checked there must be no PMOL detail records for any PCO items
---- TK-04940 - When impact estimate is unchecked, reset all amounts to 0
if exists(select TOP 1 1 from dbo.PMOL where PMCo=@PMCo and Project=@Project and PCOType=@PCOType and PCO=@PCO)
BEGIN

	---- TK-04940 - Set all Estimate amounts to 0 for all items
	UPDATE dbo.bPMOL
	SET EstCost = 0
	WHERE PMCo = @PMCo
	AND Project = @Project
	AND PCOType = @PCOType
	AND PCO = @PCO
	
END


slpo:
IF @SLImpact = 'Y' OR @POImpact = 'Y' GOTO bspexit

----When impact PO and SL are uncheck, reset all
if exists(select TOP 1 1 from dbo.PMOL where PMCo=@PMCo and Project=@Project and PCOType=@PCOType and PCO=@PCO)
BEGIN
	
	----Set all Purchase amounts to 0 for all items
	UPDATE dbo.bPMOL
	SET PurchaseAmt = 0
	WHERE PMCo = @PMCo
	AND Project = @Project
	AND PCOType = @PCOType
	AND PCO = @PCO
	
END
	
bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMPCOClearItemDeailAmounts] TO [public]
GO
