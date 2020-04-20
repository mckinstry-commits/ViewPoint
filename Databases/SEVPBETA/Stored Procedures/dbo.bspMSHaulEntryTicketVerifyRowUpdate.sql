SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE proc [dbo].[bspMSHaulEntryTicketVerifyRowUpdate]
/********************************************************
 * Created By:   GF 08/02/2007
 * Modified By:
 *
 * USAGE: Called from MS HaulEntryTics to update a MSTD.VerifyHaul for 
 * a single MSTD.MSTrans.
 *
 * INPUT PARAMETERS:
 * @msco		MS Complany
 * @mth			MSTD Batch month
 * @mstrans		MSTD Transaction
 * @verifyhaul	Verify haul flag Y/N
 *
 *
 *
 * OUTPUT PARAMETERS:
 *	@msg		Error message
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@msco bCompany, @mth bMonth, @mstrans bTrans, @verifyhaul bYN,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @msco is null or @mth is null or @mstrans is null or @verifyhaul is null
	begin
	goto bspexit
	end


---- update MSTD.VerifyHaul for transaction
update MSTD set VerifyHaul=@verifyhaul
where MSCo=@msco and Mth=@mth and MSTrans=@mstrans and VerifyHaul <> @verifyhaul




bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulEntryTicketVerifyRowUpdate] TO [public]
GO
