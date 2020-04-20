SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE proc [dbo].[bspMSHaulEntryTicBatchVal]
/********************************************************
 * Created By:   GF 01/08/2001
 * Modified By:
 *
 * USAGE: Called from MS HaulEntryTickets to validate MSHB Batch and Sequence.
 * Returns batch header information needed to find MSTD tickets for this batch
 * sequence.
 *
 * INPUT PARAMETERS:
 * @msco		MS Company
 * @mth			MSHB Batch month
 * @batchid		MSHB Batch Id
 * @batchseq	MSHB Batch Seq
 *
 *
 * OUTPUT PARAMETERS:
 * @saledate
 * @haultype
 * @vendorgroup
 * @haulvendor
 * @truck
 * @driver
 * @emco
 * @emgroup
 * @equipment
 * @prco
 * @employee
 *
 *	@msg		Error message
 *
 * RETURN VALUE:
 * 	0 Success
 *	1 & message Failure
 *
 **********************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
 @saledate bDate = null output,@haultype char(1) = null output, @vendorgroup bGroup = null output,
 @haulvendor bVendor = null output, @truck varchar(10) = null output, @driver bDesc = null output,
 @emco bCompany = null output, @emgroup bGroup = null output, @equipment bEquip = null output,
 @prco bCompany = null output, @employee bEmployee = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0

---- validate MSHB batch record
select @saledate=SaleDate, @haultype=HaulerType, @vendorgroup=VendorGroup, @haulvendor=HaulVendor,
		@truck=Truck, @driver=Driver, @emco=EMCo, @emgroup=EMGroup, @equipment=Equipment,
		@prco=PRCo, @employee=Employee
from MSHB where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
if @@rowcount = 0
	begin
	select @msg = 'Invalid MSHB batch sequence.', @rcode = 1
	goto bspexit
	end
   





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulEntryTicBatchVal] TO [public]
GO
