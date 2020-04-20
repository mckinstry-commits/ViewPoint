SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Cost_Inventory    Script Date: 3/20/2002 10:27:35 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspEMVal_Cost_Inventory    Script Date: 8/28/99 9:36:01 AM ******/
   
   CREATE     procedure [dbo].[bspEMVal_Cost_Inventory]
   /*********************************************
    * Created: DANF 03/20/00
    * Modified: DANF 08/15/00 - Correction to selecting the override GL accounts
   *                  DANF 08/29/00 - Added check for unit of measure conversion.
    *           DANF 01/30/02 - Added Location Category override for the cost method in Inventory
    *			TV 02/11/04 - 23061 added isnulls
    *			TV 09/26/05 Cost to IN not following Location Master Cost Method, uses INCO only
    * Usage:
    *  Called from the EM Transaction Batch validation procedure (bspEMVal_Cost_EMIN_Inserts and bspEMVal_Cost_EMGL_Inserts)
    *  to validate Inventory information.
    *
    * Input:
    *  @mth                Expense Month
    *  @inco               IN Co#
    *  @loc                Location
    *  @matlgroup          Material Group
    *  @material           Material
    *  @um                 Posted unit of measure
    *  @units              Posted units
    *  @emglco             EM GL company
    *  @costcode           CostCode
    *  @emctype            Cost Type
    *  @equip              Equip
    *  @emco               EM Company
    *
    * Output:
    *  @stdum              Standard unit of measure
    *  @stdunits           Units expressed in std unit of measure
    *  @stdunitcost        Unit cost expressed in std unit of measure
    *  @stdecm             Standard ECM
    *  @fixedunitcost      Fixed Unit Cost based on Cost Method
    *  @fixedecm           E = Each, C = Hundred, M = Thousand
    *  @burdenyn           Burdened unit cost flag
    *  @costvarianceglacct Cost Variance GL Account - used with fixed unit costs
    *  @inglco             IN GL Company
    *  @equipsalesacct     IN equip Sales Account
    *  @cogsacct           IN Cost of Goods Sold Account
    *  @inventoryacct      IN Inventory Account
    *  @msg                Error message
    *
    * Return:
    *  0                   success
    *  1                   error
    *************************************************/
   
       @mth bMonth, @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits,
       @emglco bCompany, @costCode bCostCode, @emctype bEMCType, @equip bEquip, @emco bCompany,
       @stdum bUM output, @stdunits bUnits output, @stdunitcost bUnitCost output, @stdecm bECM output,
       @inpstunitcost bUnitCost output, @costvarglacct bGLAcct output,
       @inglco bCompany output, @equipsalesacct bGLAcct output, @cogsacct bGLAcct output,
       @inventoryacct bGLAcct output, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @active bYN,
           @lastunitcost bUnitCost, @lastecm bECM,
           @avgunitcost bUnitCost, @avgecm bECM,
           @inlsequipsalesacct bGLAcct, @inlsequipsalesqtyacct bGLAcct,
           @inlcequipsalesacct bGLAcct, @inlcequipsalesqtyacct bGLAcct,
           @category varchar(10), @inlccogsacct bGLAcct,
           @costmth tinyint, @inlcinventoryacct bGLAcct,
           @accttype char(1), @subtype char(1),
           @incostmth tinyint, @lmcostmth tinyint, @locostmth tinyint,
           @burdencost bYN, @inmatlgroup bGroup
   
   select @rcode = 0, @stdunits = 0, @inpstunitcost = 0 , @stdunitcost = 0
   
   -- validate IN Co#
   select @inmatlgroup = MatlGroup
   from bHQCO where HQCo = @inco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid HQ Co#!', @rcode = 1
       goto bspexit
       end
   
   
   -- validate IN Co#
   select @inglco = GLCo, @incostmth = CostMethod, @burdencost = BurdenCost
   from bINCO where INCo = @inco
   if @@rowcount = 0
       begin
       select @msg = 'Invalid IN Co#!', @rcode = 1
       goto bspexit
       end
   
   -- validate material HQMT
   select @category = Category
   from bHQMT where Material = @material and MatlGroup = @matlgroup
   if @@rowcount = 0
       begin
       select @msg = 'Invalid Material!', @rcode = 1
       goto bspexit
       end
   
   -- validate Location - get default GL Accounts
   select @active = Active, @costvarglacct = CostVarGLAcct, @lmcostmth = CostMethod,
          @equipsalesacct = EquipSalesGLAcct, @cogsacct = CostGLAcct, @inventoryacct = InvGLAcct
   from bINLM
   where INCo = @inco and Loc = @loc
   if @@rowcount = 0
       begin
    select @msg = 'Location: ' + isnull(@loc,'') + ' is invalid!', @rcode = 1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + isnull(@loc,'') + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = dbo.bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0
      begin
         select @rcode = 1
         goto bspexit
      end
   
   -- validate Location and Material - get override GL Accounts
   select @active = Active, @lastunitcost = LastCost, @lastecm=LastECM,
           @avgunitcost=AvgCost, @avgecm=AvgECM,
           @stdunitcost=StdCost, @stdecm=StdECM
   from bINMT
   where INCo = @inco and Loc = @loc and MatlGroup = @inmatlgroup and Material = @material
   if @@rowcount = 0
       begin
       select @msg = 'Material: ' + isnull(@material,'') + ' is not stocked at Location: ' + @loc, @rcode = 1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + isnull(@loc,'') + ' Material: ' + isnull(@material,'') + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   
   
   -- TV 09/26/05 Cost to IN not following Location Master Cost Method, uses INCO only
   select @locostmth = CostMethod
   from bINLO
   where INCo = @inco and Loc = @loc and MatlGroup = @inmatlgroup and Category = @category
   
   /*select @lmcostmth = CostMethod
   from bINLO
   where INCo = @inco and Loc = @loc and MatlGroup = @inmatlgroup and Category = @category
   if @@rowcount = 0
      begin
        select @costmth = @lmcostmth
      end
   else
      begin
        select @costmth = @locostmth
      end*/
   
   --if @costmth is null or @costmth = 0 select @costmth = @incostmth
   select @costmth = 0, @costmth = @locostmth
   if @costmth is null or @costmth = 0 select @costmth = @lmcostmth
   if @costmth is null or @costmth = 0 select @costmth = @incostmth
   
   select @stdunitcost = CASE @costmth
           WHEN 1 THEN @avgunitcost
        	WHEN 2 THEN @lastunitcost
        	WHEN 3 THEN @stdunitcost
         	ELSE 0
           END
   
   select @stdecm = CASE @costmth
           WHEN 1 THEN @avgecm
        	WHEN 2 THEN @lastecm
        	WHEN 3 THEN @stdecm
         	ELSE 'E'
           END
   
   -- if std unit of measure equals posted unit of measure, set IN units equal to posted
   if @stdum = @um
       begin
       select @stdunits = @units
       select @inpstunitcost = @stdunitcost
       goto ValAcct
       end
   
   IF @stdum <> @um and @umconv =0
      begin
        select @msg = 'No Unit of Measure conversion set up between ' + isnull(@um,'') + ' and ' + isnull(@stdum,'') + '.'
        select @rcode = 1
        goto bspexit
      end
   
   if @umconv <> 0
      begin
       select @stdunits = @units * @umconv
       select @inpstunitcost = @stdunitcost * @umconv
      end
   
   ValAcct:
   
    -- validate 'posted to' GL Co and Expense Month
    exec @rcode = bspHQBatchMonthVal @inglco, @mth, 'EM',@msg output
    if @rcode <> 0 goto bspexit
   
   -- validate Location compant over ride - set override accounts
   select @inlsequipsalesacct = EquipSalesGLAcct
   from bINLS
   where INCo = @inco and Loc = @loc and Co = @emco
   if @@rowcount <> 0
       begin
       if @inlsequipsalesacct is not null select @equipsalesacct = @inlsequipsalesacct
       end
   
   -- validate Location company over ride - set override accounts
   select @inlcequipsalesacct = EquipSalesGLAcct
   from bINLC
   where INCo = @inco and Loc = @loc and Co = @emco and MatlGroup = @inmatlgroup and Category = @category
   if @@rowcount <> 0
       begin
       if @inlcequipsalesacct is not null select @equipsalesacct = @inlcequipsalesacct
       end
   
   -- validate Location category over ride - set override accounts
   select @inlccogsacct = CostGLAcct, @inlcinventoryacct = InvGLAcct
   from bINLO
   where INCo = @inco and Loc = @loc and MatlGroup = @inmatlgroup and Category = @category
   if @@rowcount <> 0
       begin
       if @inlccogsacct is not null select @cogsacct = @inlccogsacct
       if @inlcinventoryacct is not null select @inventoryacct = @inlcinventoryacct
       end
   
   -- validate equip Sales Account
   exec @rcode = dbo.bspGLACfPostable @inglco, @equipsalesacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN equip Sales GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   -- validate Cost Of Goods Sold Account
   exec @rcode = dbo.bspGLACfPostable @inglco, @cogsacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN Cost Of Goods Sold GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   -- validate Inventory Account
   exec @rcode = dbo.bspGLACfPostable @inglco, @inventoryacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN Inventory GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Cost_Inventory] TO [public]
GO
