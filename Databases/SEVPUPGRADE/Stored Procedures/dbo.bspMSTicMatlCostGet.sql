SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************************/
CREATE    procedure [dbo].[bspMSTicMatlCostGet]
/*********************************************
 *  Created By:  GF 07/18/2000
 *  Modified By: GG 01/24/01 - initialized output parameters to null
 *				 GG 03/06/01 - fixed total cost calculation to use ECM factor
 *               GF 06/25/01 - case statement for costing had avg and last reversed.
 *               GF 08/13/01 - if material not stocked at from location, exit but don't through error.
 *				 GG 07/05/05 - #28942 - check for bINLO Cost Method override
 *
 *  Usage:
 *  Called from the MS TicEntry form to calculate Material Cost Total
 *
 *  Input:
 *  @msco               IN Co#
 *  @fromloc            From Location
 *  @matlgroup          Material Group
 *  @material           Material
 *  @um                 Posted unit of measure
 *  @units              Posted units
 *
 *  Output:
 *  @matlcosttotal      Material Cost Total
 *  @msg                Error message
 *
 * Return:
 *  0                   success
 *  1                   error
 *************************************************/
(@msco bCompany = null, @fromloc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
 @um bUM = null, @units bUnits = null, @matlcosttotal bDollar = null output,
 @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @umconv bUnitCost, @active bYN, @lastunitcost bUnitCost, @lastecm bECM,
		@avgunitcost bUnitCost, @avgecm bECM, @costmthd tinyint, @incostmthd tinyint,
		@loccostmthd tinyint, @stdum bUM, @stdunits bUnits, @stdecm bECM, @stdunitcost bUnitCost,
		@inpstunitcost bUnitCost, @factor smallint, @category varchar(10), @catcostmthd tinyint

select @rcode = 0, @matlcosttotal = 0

---- validate IN Co#
select @incostmthd=CostMethod from dbo.INCO with (nolock) where INCo=@msco
if @@rowcount = 0
	begin
	select @msg = 'Invalid IN Company', @rcode = 1
	goto bspexit
	end

---- validate Location
select @loccostmthd=CostMethod from dbo.INLM with (nolock) where INCo=@msco and Loc=@fromloc
if @@rowcount = 0
	begin
	select @msg = 'Invalid From Location', @rcode = 1
	goto bspexit
	end

---- #28942 - get Material Category and check for optional Category Cost Method override
select @category = Category from dbo.HQMT (nolock)
where MatlGroup = @matlgroup and Material = @material
if @@rowcount <> 0
   	begin
   	select @catcostmthd = CostMethod from dbo.INLO (nolock)
   	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @category
   	end

---- get U/M conversion factor
select @umconv=Conversion from dbo.INMU with (nolock) 
where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@um
if @@rowcount = 0
	begin
	exec @rcode = bspHQStdUMGet @matlgroup,@material,@um,@umconv output,@stdum output,@msg output
	if @rcode <> 0 goto bspexit
	end

---- validate Location and Material
select @lastunitcost=LastCost, @lastecm=LastECM, @avgunitcost=AvgCost,
		@avgecm=AvgECM, @stdunitcost=StdCost, @stdecm=StdECM
from INMT with (nolock) where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
	begin
       ----select @msg = 'Material is not stocked at the from location', @rcode = 1
	goto bspexit
	end

set @costmthd = @catcostmthd		-- #28942 - default to Category Cost Method 
if isnull(@costmthd,0) = 0 set @costmthd = @loccostmthd	-- use Location Cost Method
if isnull(@costmthd,0) = 0 set @costmthd = @incostmthd	-- use Company Cost Method

select @stdunitcost = CASE @costmthd
			WHEN 1 THEN @avgunitcost
			WHEN 2 THEN @lastunitcost
        	WHEN 3 THEN @stdunitcost
         	ELSE 0 END

select @stdecm = CASE @costmthd
			WHEN 1 THEN @avgecm
			WHEN 2 THEN @lastecm
        	WHEN 3 THEN @stdecm
         	ELSE 'E' END

---- if std unit of measure equals posted unit of measure, set IN units equal to posted
if @stdum = @um
	begin
	select @stdunits=@units
	end
else
	begin
	if @umconv = 0
		begin
		select @stdunits = 0
		end
	else
		begin
		select @stdunits = @units * @umconv
		end
	end

---- calculate Material Cost Total
select @factor = case @stdecm when 'M' then 1000 when 'C' then 100 else 1 end
select @matlcosttotal = (@stdunits * @stdunitcost) / @factor




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlCostGet] TO [public]
GO
