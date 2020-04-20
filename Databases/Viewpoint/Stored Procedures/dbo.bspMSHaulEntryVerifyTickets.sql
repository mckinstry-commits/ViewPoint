SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************/
CREATE proc [dbo].[bspMSHaulEntryVerifyTickets]
/********************************************************
 * Created By:   GF 01/08/2001
 * Modified By:
 *
 * USAGE:
 * 	Called from MS HaulEntryLines to verify all tickets or none.
 *
 * INPUT PARAMETERS:
 *   @msco       MS Co#
 *   @mth		Batch month
 *   @ticketopt  Verify ticket option (0-verify all, 1-none)
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
 *	@msg		Error message
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 **********************************************************/
(@msco bCompany = null, @mth bMonth = null, @ticketopt int = null, @saledate bDate = null,
 @haultype char(1) = null, @vendorgroup bGroup = null, @haulvendor bVendor = null,
 @truck varchar(10) = null, @driver bDesc = null, @emco bCompany = null, @emgroup bGroup = null,
 @equipment bEquip = null, @prco bCompany = null, @employee bEmployee = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int

select @rcode = 0

if @driver is not null
	begin
	select @driver = UPPER(RTRIM(@driver))
	end

---- section one - verify tickets option (0) set VerifyHaul = 'Y' - by hauler type
if @ticketopt = 0
       begin
       if @haultype = 'H'
           begin
           update bMSTD set VerifyHaul = 'Y'
           where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='H' and SaleDate=@saledate
           and isnull(VendorGroup,'')=isnull(@vendorgroup,'') and isnull(HaulVendor,'')=isnull(@haulvendor,'')
           and isnull(Truck,'')=isnull(@truck,'') and UPPER(isnull(Driver,''))=isnull(@driver,'')
           and VerifyHaul <> 'Y'
           end
       if @haultype = 'E'
           begin
           update bMSTD set VerifyHaul = 'Y'
           where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='E' and SaleDate=@saledate
           and isnull(EMCo,'')=isnull(@emco,'') and isnull(Equipment,'')=isnull(@equipment,'')
           and isnull(PRCo,'')=isnull(@prco,'') and isnull(Employee,'')=isnull(@employee,'')
           and VerifyHaul <> 'Y'
           end
       end
   
   -- section one - verify tickets option (1) set VerifyHaul = 'N' - by hauler type
   if @ticketopt = 1
       begin
       if @haultype = 'H'
           begin
           update bMSTD set VerifyHaul = 'N'
           where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='H' and SaleDate=@saledate
           and isnull(VendorGroup,'')=isnull(@vendorgroup,'') and isnull(HaulVendor,'')=isnull(@haulvendor,'')
           and isnull(Truck,'')=isnull(@truck,'') and UPPER(isnull(Driver,''))=isnull(@driver,'')
           and VerifyHaul <> 'N'
           end
       if @haultype = 'E'
           begin
           update bMSTD set VerifyHaul = 'N'
           where MSCo=@msco and Mth=@mth and HaulTrans is null and HaulerType='E' and SaleDate=@saledate
           and isnull(EMCo,'')=isnull(@emco,'') and isnull(Equipment,'')=isnull(@equipment,'')
           and isnull(PRCo,'')=isnull(@prco,'') and isnull(Employee,'')=isnull(@employee,'')
           and VerifyHaul <> 'N'
           end
       end
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulEntryVerifyTickets] TO [public]
GO
