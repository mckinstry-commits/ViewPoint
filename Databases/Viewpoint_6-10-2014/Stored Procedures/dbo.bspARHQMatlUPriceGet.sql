SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspARHQMatlUPriceGet    Script Date: 12/03/01 9:34:53 AM ******/
   CREATE   proc [dbo].[bspARHQMatlUPriceGet]
   /********************************************************
   * CREATED BY: 	TJL 12/03/01
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Retrieves the Standard Unit price for a Material from bHQMT
   *
   * INPUT PARAMETERS:
   *	HQ Material Group
   *	HQ Material
   *	HQ UM
   *	AR LineType
   * OUTPUT PARAMETERS:
   *	Unit price from HQMT or HQMU(if a different UM then the Standard
   *	ECM for that UM
   *	Error Message
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   **********************************************************/
   (@matlgroup bGroup=0, @material bMatl=null, @um bUM=null, @linetype varchar(1),
   @price bUnitCost=0 output, @ecm bECM=null output, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   declare @stdprice bUnitCost, @count integer
   
   if @matlgroup= 0
   	begin
   	select @msg = 'Missing HQ Material Group', @rcode = 1
   	goto bspexit
   	end
   
   select @count= count(*) from bHQUM where UM = @um
   if @count <=0
   	begin
   	select @msg = 'Not a valid unit of measure!', @rcode = 1
   	goto bspexit
   	end
   
   /* if the unit of measure is not 'LS' then the material may be left blank.
      Validation only occurs here for LineType 'Material'.
      -----------
      Also since 'Contract UM' is previously validated when setting up Contract
      Item and since UM and Material fields cannot be edited by user and are
      invisible when LineType is 'Contract', there is no need to validate 'Contract UM' here.
      -----------
      Likewise, since UM is always set to null for LineType 'Other',
      UM will not validate for LineType 'Other' */
   if @material is null and (@um <> 'LS' or @linetype = 'C') goto bspexit
   
   /* material must be present at this point to continue through the remainder of the validation */
   if @material is null
   	begin
   	select @msg = 'Missing HQ Material Code', @rcode = 1
   	goto bspexit
   	end
   
   /* This is run only for LineType 'Material', otherwise skipped */
   select @price= isNull(Price,0), @ecm=PriceECM from bHQMT
   where MatlGroup=@matlgroup and Material=@material and @um=StdUM
   
   if @@rowcount = 1 goto bspexit
   
   else
   	begin
         	select @rcode=0
         	select @price= isNull(Price,0), @ecm=PriceECM from bHQMU
         	where MatlGroup=@matlgroup and Material=@material and @um=UM
         	if @@rowcount=0 and (select count(*) from bHQMT where Material = @material and MatlGroup = @matlgroup) <>0
   		begin
   		select @msg = 'Invalid UM for this Material', @rcode=1
   		goto bspexit
   		end
      	end
   
   bspexit:
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARHQMatlUPriceGet] TO [public]
GO
