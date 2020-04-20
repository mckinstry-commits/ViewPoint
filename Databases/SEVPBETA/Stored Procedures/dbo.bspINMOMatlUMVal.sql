SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINMOMatlUMVal]
 /***************************************************************************
 * Created By:	GG 03/12/02
 * Modified:	RM 09/10/2002 - Pull Alternate Unit price if alternate UM is used.
 *				RM 10/21/2002 - Alternate UM query was not joining on INCo
 *				GF 09/01/2005 - issue #29683 not using INLM markup when job markup is zero.
 *				GF 02/16/2010 - issue #138069 - default ecm needs to consider price option.
 *
 *
 *
 * Used to validate a material's unit of measure.  Must be standard u/m
 * or setup as an alternative u/m at the location specified.
 *
 * Inputs:
 *	@inco			IN Company
 *	@loc			Location
 *	@material		Material
 *	@matlgroup		Material Group
 *	@um				Unit of Measure to validate
 *
 * Outputs:
 *	@conv			Conversion factor
 *	@cost			Standard unit cost
 *	@costecm		Unit cost E/C/M
 *	@price			Standard unit price
 *	@priceecm		Unit price E/C/M
 *	@msg			Unit of measure description or error message
 *
 * Returns:
 *	@rcode			0 = success, 1 = error
 *
 *****************************************************************************/
(@inco bCompany = null, @loc bLoc = null, @material bMatl = null, @matlgroup bGroup = null,
 @um bUM = null,@jcco bCompany = null,@job bJob = null, @conv bUnitCost = null output,
 @ecm bECM = null output ,@defaultunitprice bUnitCost = null output, @msg varchar(255) output)
as
set nocount on
     
declare @rcode int, @cost bUnitCost ,@costecm bECM , @price bUnitCost, @priceecm bECM, @stdum bUM,
		@jobpriceopt tinyint, @discrate bRate, @defaultecm bECM ----#138069

select @rcode = 0, @conv = 1
    
    -- get U/M description
    select @msg = Description from bHQUM with (nolock) where UM = @um
    if @@rowcount = 0
     	begin
     	select @msg = 'Unit of measure not setup in HQ.', @rcode = 1
     	goto bspexit
     	end
    
    -- validate material in HQ Materials
    select @stdum = StdUM
    from bHQMT with (nolock)
    where MatlGroup = @matlgroup and Material = @material
    if @@rowcount = 0
     	begin
     	select @msg = 'Invalid HQ Material.', @rcode = 1
     	goto bspexit
     	end
    
    -- validate in Location Materials
    if @stdum = @um
     	begin
     	select @cost = StdCost, @costecm = StdECM, @price = StdPrice, @priceecm = PriceECM
     	from bINMT with (nolock)
     	where INCo = @inco and Loc = @loc and Material = @material and MatlGroup = @matlgroup
     	if @@rowcount=0
     		begin
     		select @msg = 'Invalid Inventory Material ', @rcode = 1
     		goto bspexit
     		end
     	end
    else
     	begin	
     	select @conv = Conversion, @cost = StdCost, @costecm = StdCostECM, @price = Price, @priceecm = PriceECM
     	from bINMU with (Nolock)
     	where INCo = @inco and Loc = @loc and Material = @material and MatlGroup = @matlgroup and UM = @um
     	if @@rowcount = 0
     		begin
     		select @msg = 'Not a valid Unit of Measure: ' + isnull(@um,'') + ' for this material: ' + isnull(@material,'') + ' at the Location: ' + isnull(@loc,'') + '.', @rcode = 1
     		goto bspexit
     		end
     	end
    
select @ecm=@priceecm
--get job sales price option from IN Company
select @jobpriceopt=JobPriceOpt from bINCO with (nolock) where INCo=@inco

--get Mark Up rate from JCJM, if 0, then set to null so that it will use value from INMT
select @discrate = MarkUpDiscRate from JCJM with (nolock) where JCCo=@jcco and Job=@job
-- -- -- changed below to set to null issue #29683
if isnull(@discrate,0) = 0 select @discrate = null
----#138069
set @defaultecm = null

if @stdum = @um
	begin
	Select @defaultunitprice = 
		case @jobpriceopt when 1 then i.AvgCost + (i.AvgCost * isnull(@discrate,i.JobRate))
						  when 2 then i.LastCost + (i.LastCost * isnull(@discrate,i.JobRate))
						  when 3 then i.StdCost + (i.StdCost * isnull(@discrate,i.JobRate))
						  when 4 then i.StdPrice - (i.StdPrice * isnull(@discrate,i.JobRate)) end,
		----#138069
		@defaultecm = case @jobpriceopt when 1 then i.AvgECM
										when 2 then i.LastECM
										when 3 then i.StdECM
										when 4 then i.PriceECM
										end
	from INMT i with (nolock)
	join HQMT h with (nolock) on i.MatlGroup = h.MatlGroup and i.Material = h.Material 
	where i.INCo = @inco and i.Loc = @loc and i.Material = @material and i.Active = 'Y'
	end
else
	begin
	Select @defaultunitprice =
		case @jobpriceopt when 1 then (i.AvgCost*@conv) + ((i.AvgCost*@conv) * isnull(@discrate,i.JobRate))
						  when 2 then u.LastCost + (u.LastCost  * isnull(@discrate,i.JobRate))
						  when 3 then u.StdCost + (u.StdCost * isnull(@discrate,i.JobRate))
						  when 4 then u.Price - (u.Price * isnull(@discrate,i.JobRate)) end,
		----#138069
		@defaultecm = case @jobpriceopt when 1 then i.AvgECM
										when 2 then i.LastECM
										when 3 then i.StdECM
										when 4 then i.PriceECM
										end	  
	from INMT i with (nolock)
	join INMU u with (Nolock) on i.INCo=u.INCo and i.Loc = u.Loc and i.MatlGroup = u.MatlGroup and i.Material = u.Material
	where i.INCo = @inco and i.Loc = @loc and i.Material = @material and u.UM=@um
	end

if @defaultunitprice is null set @defaultunitprice = 0
---- #138069
if @defaultecm is not null set @ecm = @defaultecm
    
     
bspexit:
-- 	if @rcode <> 0 select @msg
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOMatlUMVal] TO [public]
GO
