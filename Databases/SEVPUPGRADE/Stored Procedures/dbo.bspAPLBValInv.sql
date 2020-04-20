SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPLBValInv    Script Date: 8/28/99 9:36:01 AM ******/
   
   CREATE    procedure [dbo].[bspAPLBValInv]
   /*********************************************
    * Created: GG 6/25/99
    * Modified: GR 1/29/00
    * Modified: GR 6/13/00 fixed to return the output params correctly
    *			GG 06/26/00 - changed to return fixed unit cost based on std u/m, fixed cost option lookup
    *          kb 10/11/1 - issue #14894
    *          kb 10/28/2 - issue #18878 - fix double quotes
    *			ES 03/11/04 - #23061 isnull wrapping
    *			MV 08/16/05 - #29558 - return AvgECM from bINMT
    *			MV 08/24/05 - #29644 - get INMU conversion factor if override exists.
	*			MV 11/05/08 - #130877 - default INCO misc glacct, tax glacct for non burdened gl distributions
	*				if Location override or location master glaccts are null
    *
    * Usage:
    *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
    *  to validate Inventory information.
    *
    * Input:
    *  @inco               IN Co#
    *  @loc                Location
    *  @matlgroup          Material Group
    *  @material           Material
    *  @um                 Posted unit of measure
    *  @units              Posted units
    *
    * Output:
    *  @stdum              Standard unit of measure
    *  @stdunits           Units expressed in std unit of measure
    *  @costopt            Cost option (1 = Average, 2 = Last, 3 = Std)
    *  @fixedunitcost      Fixed Unit Cost
    *  @fixedecm           E = Each, C = Hundred, M = Thousand
    *  @burdenyn           Burdened unit cost flag
    *  @taxglacct          Tax GL Account - used with unburdened unit costs
    *  @miscglacct         Freight/Misc GL Account - used with unburdened unit costs
    *  @varianceglacct     Cost Variance GL Account - used with fixed unit costs
    *  @msg                Error message
    *
    * Return:
    *  0                   success
    *  1                   error
    *************************************************/
   
       @inco bCompany = null, @loc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
       @um bUM = null, @units bUnits = 0, @stdum bUM = null output, @stdunits bUnits = 0 output,
       @costopt tinyint = null output, @fixedunitcost bUnitCost = 0 output, @fixedecm bECM = null output,
       @burdenyn bYN = null output, @taxglacct bGLAcct = null output, @miscglacct bGLAcct = null output,
       @costvarglacct bGLAcct = null output, @avgecm bECM = null output, @msg varchar(255) = null output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @active bYN, @cocostopt int, @loccostopt int,
   @loctaxglacct bGLAcct, @locmiscglacct bGLAcct, @loccostvarglacct bGLAcct, @category varchar(10),
	@incomiscglacct bGLAcct,@incotaxglacct bGLAcct
   
   select @rcode = 0, @stdunits = 0, @costopt = 0
   
   -- validate IN Co#
   select @burdenyn = BurdenCost, @cocostopt = CostMethod,@incomiscglacct = MiscGLAcct, @incotaxglacct = TaxGLAcct
   from bINCO where INCo = @inco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid IN Co#!', @rcode = 1
       goto bspexit
       end
   
   --get Material Category
   select @category = Category
   from bHQMT
   where MatlGroup = @matlgroup and Material = @material
   
   -- validate Location - get default GL Accounts
   select @active = Active, @loccostopt = CostMethod, @loctaxglacct = TaxGLAcct,
   @locmiscglacct = MiscGLAcct, @loccostvarglacct = CostVarGLAcct
   from bINLM
   where INCo = @inco and Loc = @loc
   if @@rowcount = 0
       begin
       select @msg = 'Location: ' + isnull(@loc, '') + ' is invalid!', @rcode = 1 --#23061
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + isnull(@loc, '') + ' is Inactive!', @rcode = 1 --#23061
       goto bspexit
       end
   
   select @costopt=null, @taxglacct=null, @miscglacct=null, @costvarglacct=null
   --get override GL Accounts from Location override
   select @costopt = CostMethod, @taxglacct = TaxGLAcct, @miscglacct = MiscGLAcct, @costvarglacct = CostVarGLAcct
   from bINLO
   where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Category=@category
   if isnull(@costopt,0) = 0
       begin
       select @costopt = @loccostopt
       if isnull(@costopt,0) = 0 select @costopt = @cocostopt
       end
   
	select @taxglacct = isnull(isnull(@taxglacct,@loctaxglacct),@incotaxglacct)
--   select @taxglacct=isnull(@taxglacct,@loctaxglacct)
	select @miscglacct = isnull(isnull(@miscglacct,@locmiscglacct),@incomiscglacct)
--   select @miscglacct=isnull(@miscglacct,@locmiscglacct)
	select @costvarglacct=isnull(@costvarglacct,@loccostvarglacct)
   
	select @stdum=null, @fixedunitcost=0
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- validate Location Material
   select @active = Active, @fixedunitcost = StdCost, @fixedecm = StdECM, @avgecm = isnull(AvgECM,'E')
   from bINMT
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
       begin
       select @msg = 'Material: ' + isnull(@material, '') + ' is not stocked at Location: ' + isnull(@loc, ''), @rcode = 1  --#23061
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + isnull(@loc, '') + ' Material: ' + isnull(@material, '') + ' is Inactive!', @rcode = 1  --#23061
       goto bspexit
       end
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @um
       begin
       select @stdunits = @units
       goto bspexit
       end
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #29644
    if @stdum <> @um
   	  begin
   	  select @umconv = Conversion
   	  from bINMU with (nolock)
   	  where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup
   	      and Material = @material and UM = @um
   	  end
   if @umconv <> 0 select @stdunits = @units * @umconv
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPLBValInv] TO [public]
GO
