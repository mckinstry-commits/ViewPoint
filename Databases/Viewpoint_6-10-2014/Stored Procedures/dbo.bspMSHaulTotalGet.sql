SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE   proc [dbo].[bspMSHaulTotalGet]
/********************************************************
 * Created By:	GF 12/15/2000
 * Modified By: GF 01/06/2000
 *				GF 08/04/2004 - issue #25295 allow delete flag was not being set properly
 *
 *
 * USAGE:
 * 	Retrieves totals for an MS Haul Transaction and a Y/N
 *   flag whether there are any Haul Lines.
 *
 * INPUT PARAMETERS:
 *   @msco       MS Co#
 *   @mth		Batch month
 *   @batchid	Batch Id
 *   @batchseq	Batch Seq
 *	@haultrans	MS Haul Trans
 *   @saledate   Haul Sale Date
 *   @haultype   Hauler Type
 *   @vendgroup  VendorGroup
 *   @haulvendor Haul Vendor
 *   @truck      Haul Vendor Truck
 *   @driver     Haul Vendor Truck Driver
 *   @emco       EM CO#
 *   @emgroup    EM Group
 *   @equipment  EM Equipment
 *   @prco       PR CO#
 *   @employee   Employee
 *
 * OUTPUT PARAMETERS:
 * @hours			Total Haul Hours
 * @loads			Total Haul Loads
 * @tickets			Total Haul # of tickets
 * @haulchg			Total Haul Charge
 * @paytotal		Total Haul Pay
 * @revenue			Total Haul Revenue
 * @lineflag		Haul Line Flag (YN)
 * @msg				Error message
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
 @haultrans bTrans = null, @saledate bDate = null, @haultype char(1) = null,
 @vendorgroup bGroup = null, @haulvendor bVendor = null, @truck varchar(10) = null,
 @driver bDesc = null, @emco bCompany = null, @emgroup bGroup = null, @equipment bEquip = null,
 @prco bCompany = null, @employee bEmployee = null, @hours bHrs = 0 output, @loads int = 0 output,
 @tickets int = 0 output, @haultotal bDollar = 0 output, @paytotal bDollar = 0 output,
 @revtotal bDollar = 0 output, @lineflag bYN = 'N' output, @allowdelete bYN = 'Y' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @hours2 bHrs, @loads2 int, @haultotal2 bDollar, @paytotal2 bDollar,
		@revtotal2 bDollar, @validcnt int

select @rcode = 0, @hours = 0, @loads = 0, @tickets = 0, @haultotal = 0, @revtotal = 0,
		@paytotal = 0, @hours2 = 0, @loads2 = 0, @haultotal2 = 0, @paytotal2 = 0,
		@revtotal2 = 0, @lineflag = 'N', @allowdelete = 'Y'

if @msco is null or @mth is null or @batchid is null or @batchseq is null goto bspexit

---- get existing values from MSTD for HaulTrans
if @haultrans is not null
	begin
	select @hours = isnull(sum(Hours),0), @loads = isnull(sum(Loads),0),
			@haultotal = isnull(sum(HaulTotal),0),
			@paytotal = isnull(sum(PayTotal),0),
			@revtotal = isnull(sum(RevTotal),0)
	from MSTD with (nolock) where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans

	---- get changed values from MSLB for existing HaulTrans lines
	select @hours2 = isnull(sum(Hours - OldHours),0),
              @loads2 = isnull(sum(Loads - OldLoads),0),
              @paytotal2 = isnull(sum(PayTotal - OldPayTotal),0),
              @haultotal2 = isnull(sum(HaulTotal - OldHaulTotal),0),
              @revtotal2 = isnull(sum(RevTotal - OldRevTotal),0)
	from MSLB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
	and BatchTransType = 'C'

	---- combine existing values
	select @hours = @hours + @hours2, @loads = @loads + @loads2,
              @haultotal = @haultotal + @haultotal2, @paytotal = @paytotal + @paytotal2,
              @revtotal = @revtotal + @revtotal2
	select @hours2 = 0 , @loads2 = 0, @haultotal2 = 0, @paytotal2 = 0,@revtotal2 = 0
	end

---- get values from MSLB for new HaulTrans lines
select @hours2 = isnull(sum(Hours),0), @loads2 = isnull(sum(Loads),0),
          @haultotal2 = isnull(sum(HaulTotal),0), @paytotal2 = isnull(sum(PayTotal),0),
          @revtotal2 = isnull(sum(RevTotal),0)
from MSLB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
and BatchTransType = 'A'

---- accumulate new and changed values
select @hours = @hours + @hours2, @loads = @loads + @loads2,
		@haultotal = @haultotal + @haultotal2,
		@paytotal = @paytotal + @paytotal2,
		@revtotal = isnull(@revtotal,0) + isnull(@revtotal2,0)
select @hours2 = 0, @loads2 = 0, @haultotal2 = 0, @paytotal2 = 0, @revtotal2 = 0

---- get values from MSLB for deleted HaulTrans lines
select @hours2 = isnull(sum(Hours),0), @loads2 = isnull(sum(Loads),0),
          @haultotal2 = isnull(sum(HaulTotal),0), @paytotal2 = isnull(sum(PayTotal),0),
          @revtotal2 = isnull(sum(RevTotal),0)
from MSLB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
and BatchTransType = 'D'

---- subtract out deleted values
select @hours = @hours - @hours2, @loads = @loads - @loads2,
		@haultotal = @haultotal - @haultotal2, @paytotal = @paytotal - @paytotal2,
		@revtotal = isnull(@revtotal,0) - isnull(@revtotal2,0)

if @driver is not null
	begin
	select @driver = UPPER(RTRIM(@driver))
	end

---- count number of tickets in MSTD for the Haul transaction - Haul Type (H)
if @haultype = 'H'
	begin
	select @validcnt=count(*) from MSTD with (nolock) 
	where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='H' and SaleDate=@saledate
	and isnull(VendorGroup,'')=isnull(@vendorgroup,'') and isnull(HaulVendor,'')=isnull(@haulvendor,'')
	and isnull(Truck,'')=isnull(@truck,'') and UPPER(isnull(Driver,''))=isnull(@driver,'')
	and VerifyHaul = 'Y'
	if @validcnt <> 0 select @tickets=@validcnt
	end

if @haultype = 'E'
	begin
	select @validcnt=count(*) from MSTD with (nolock) 
	where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='E' and SaleDate=@saledate
	and isnull(EMCo,'')=isnull(@emco,'') and isnull(Equipment,'')=isnull(@equipment,'')
	and isnull(PRCo,'')=isnull(@prco,'') and isnull(Employee,'')=isnull(@employee,'')
	and VerifyHaul = 'Y'
	if @validcnt <> 0 select @tickets=@validcnt
	end

---- look for Haul lines for this Haul Transaction
select @lineflag = 'N'
---- check MSLB table
if exists(select 1 from MSLB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq)
	begin
	select @lineflag = 'Y'
	end
---- check MSTD table
if @haultrans is not null and exists(select 1 from MSTD with (nolock) where MSCo=@msco and Mth=@mth and HaulTrans=@haultrans)
	begin
	select @lineflag = 'Y'
	end

---- look for Haul lines for this Haul Transaction that have been invoiced to AR or AP
select @allowdelete = 'Y'
---- check MSLB table
---- issue #25295 wrap OldMSInv or OldAPRef in parenthesis
if exists(select 1 from MSLB with (nolock) where Co=@msco and Mth=@mth and BatchId=@batchid
				and BatchSeq=@batchseq and (OldMSInv is not null or OldAPRef is not null))
	begin
	select @allowdelete = 'N'
	end
---- check bMSTD table
if @haultrans is not null and exists(select 1 from MSTD with (nolock) where MSCo=@msco and Mth=@mth
				and HaulTrans=@haultrans and (MSInv is not null or APRef is not null))
	begin
	select @allowdelete = 'N'
	end




bspexit:
   	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulTotalGet] TO [public]
GO
