SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPORBExpValInv    Script Date: 8/28/99 9:36:01 AM ******/
   
   CREATE   procedure [dbo].[bspPORBExpValInv]
   /*********************************************
    * Created: DANF 04/23/01
    * Modified:	MV 03/16/05 - #28451 - check for conversion factor in bINMU when @um <> @stdum 
    *				MV 08/16/05 = #29558 - return AvgECM from bINMT
    *				DC 09/04/08 - #128289 - PO International Sales Tax
    *
    * Usage:
    *  Called from the PO Receiving Batch validation procedure (bspPORBVal)
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
	@incotaxglacct bGLAcct  --DC #128289
   
   select @rcode = 0, @stdunits = 0, @costopt = 0
   
   -- validate IN Co# - get default GL Accounts
   select @burdenyn = BurdenCost, @cocostopt = CostMethod,
			@incotaxglacct = TaxGLAcct  --DC #128289
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
       select @msg = 'Location: ' + @loc + ' is invalid!', @rcode = 1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + @loc + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   
   --get override GL Accounts from Location override
   select @costopt = CostMethod, @taxglacct = TaxGLAcct, @miscglacct = MiscGLAcct, @costvarglacct = CostVarGLAcct
   from bINLO
   where INCo=@inco and Loc=@loc and MatlGroup=@matlgroup and Category=@category
   if isnull(@costopt,0) = 0
       begin
       select @costopt = @loccostopt
       if isnull(@costopt,0) = 0 select @costopt = @cocostopt
       end
   
   select @taxglacct=isnull(@taxglacct,isnull(@loctaxglacct,@incotaxglacct))  --DC #128289
   select @miscglacct=isnull(@miscglacct,@locmiscglacct)
   select @costvarglacct=isnull(@costvarglacct,@loccostvarglacct)
   
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- validate Location Material
   select @active = Active, @fixedunitcost = StdCost, @fixedecm = StdECM, @avgecm = isnull(AvgECM,'E')
   from bINMT
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
       begin
       select @msg = 'Material: ' + @material + ' is not stocked at Location: ' + @loc, @rcode = 1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + @loc + ' Material: ' + @material + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @um
       begin
       select @stdunits = @units
       goto bspexit
       end
   -- get conversion factor from bINMU if exists, overrides bHQMU -- #28451
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
GRANT EXECUTE ON  [dbo].[bspPORBExpValInv] TO [public]
GO
