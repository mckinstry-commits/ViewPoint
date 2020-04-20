SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspMSHaulMatlVal]
   /*************************************
    * Created By:   GF 12/09/2000
    * Modified By:
    *
    * USAGE:   Validate material and unit of measure entered in MS HaulEntry
    *
    *
    * INPUT PARAMETERS
    *  MS Company, MatlGroup, Material, MatlVendor, FromLoc, LocGroup, MatlUM
    *
    * OUTPUT PARAMETERS
    *  SalesUM
    *  PayDiscType
    *  PayDiscRate
    *  Haul Phase
    *  Haul CostType
    *  HaulCode
    *  @msg      error message if error occurs, otherwise description from HQMT
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *
    **************************************/
(@msco bCompany = null, @umval bYN = 'N', @matlgroup bGroup = null, @material bMatl = null,
 @matlvendor bVendor = null, @fromloc bLoc = null, @matlum bUM = null, @salesum bUM output,
 @paydisctype char(1) output, @paydiscrate bUnitCost output, @haulphase bPhase output,
 @haulct bJCCType output, @haulcode bHaulCode output, @taxable bYN = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @umdesc bDesc, @stocked bYN, @hqstdum bUM

select @rcode = 0

if @msco is null
       begin
       select @msg = 'Missing MS Company', @rcode = 1
       goto bspexit
       end

if @matlgroup is null
   	begin
   	select @msg = 'Missing Material Group', @rcode = 1
   	goto bspexit
   	end

if @material is null
       begin
       select @salesum = null, @paydisctype = null, @paydiscrate = null, @haulphase = null,
              @haulct = null,  @haulcode = null, @taxable = 'N'
       goto bspexit
       end
   
   if @fromloc is null
   	begin
   	select @msg = 'Missing IN From Location', @rcode = 1
   	goto bspexit
   	end
   
   -- validate Material UM if needed
   if @umval = 'Y'
       begin
       if @matlum is null
           begin
           select @msg = 'Missing Unit of measure', @rcode = 1
           goto bspexit
           end
       select @umdesc=Description from bHQUM where UM=@matlum
       if @@rowcount = 0
           begin
           select @msg = 'Unit of measure not on file', @rcode =1
           end
       end
   
select @msg=Description, @paydisctype=PayDiscType, @paydiscrate=PayDiscRate,
          @haulphase=HaulPhase, @haulct=HaulJCCostType, @haulcode=HaulCode,
          @stocked=Stocked, @hqstdum=StdUM, @salesum=SalesUM, @taxable=Taxable
from HQMT where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
	if @umval = 'N'
		begin
		select @msg = 'Material not on file.', @rcode = 1
		goto bspexit
		end
	else
		begin
   		select @msg = 'Material not on file for UM.', @rcode = 1
		goto bspexit
		end
	end
else
	if @umval ='N'
           begin
           select @paydiscrate=PayDiscRate
           from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@salesum
           end
       else
           if @matlum <> @hqstdum
               begin
               select @paydiscrate=PayDiscRate
               from bHQMU where MatlGroup=@matlgroup and Material=@material and UM=@matlum
               if @@rowcount = 0
                   begin
                   select @msg = 'UM must be either standard UM or set up in HQMU.', @rcode = 1
                   goto bspexit
                   end
               end
   
   if @umval = 'N' and @matlum is null select @matlum=@salesum
   
   if @matlvendor is null and @stocked = 'N'
       begin
       select @msg = 'This material must be a stocked material.', @rcode = 1
       goto bspexit
       end
   
   if @matlvendor is null and @umval = 'N'
       begin
       select @validcnt=count(*) from bINMT
       where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
       if @validcnt = 0
           begin
           select @msg = 'Material is not set up for the IN Sales Location', @rcode = 1
           goto bspexit
           end
       end
   
   if @matlvendor is null and @umval = 'Y' and @matlum <> @hqstdum
       begin
       select @validcnt=count(*) from bINMU
       where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material and UM=@matlum
       if @validcnt = 0
           begin
           select @msg = 'Material UM is not set up for the IN Sales Location', @rcode = 1
           goto bspexit
           end
       end
   
   if @umval = 'Y' and @rcode = 0 select @msg = @umdesc





bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulMatlVal] TO [public]
GO
