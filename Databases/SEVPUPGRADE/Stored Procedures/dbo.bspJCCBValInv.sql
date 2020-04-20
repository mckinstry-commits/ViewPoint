SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspJCCBValInv    Script Date: 8/28/99 9:36:01 AM ******/
CREATE procedure [dbo].[bspJCCBValInv]
/*********************************************
* Created: DANF 03/20/00
* Modified DANF 08/15/00 Corrected the Inventory override accounts and Avg unit cost.
*          DANF 11/15/01 Added Cost Method over ride by location and category
*          DANF 09/05/02 17738 Added Phase Group as parameter & bspJCCAGlacctDflt
*			GG 02/02/04 - #20538 - split GL units flag
*			TV - 23061 added isnulls
*			GF 01/28/2010 - issue #136649 the tax accrual account must exist in the from and to GL Companies.
*
* Usage:
*  Called from the JC Transaction Batch validation procedure (bspJCCBVal)
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
*  @taxcode            Tax Code
*  @jcglco             JC GL company
*  @taxgroup           Tax Group
*  @phasegroup         PhaseGroup
*  @phase              Phase
*  @jcctype            cost type
*  @job                Job
*  @jcco               JC Company
*  @transacct          Transaction Account
*
* Output:
*  @stdum              Standard unit of measure
*  @stdunits           Units expressed in std unit of measure
*  @costmth            Cost method (1 = Average, 2 = Last, 3 = Standard)
*  @fixedunitcost      Fixed Unit Cost based on Cost Method
*  @fixedecm           E = Each, C = Hundred, M = Thousand
*  @burdenyn           Burdened unit cost flag
*  @taxglacct          Tax GL Account - used with unburdened unit costs
*  @taxaccturalacct    Tax
*  @miscglacct         Freight/Misc GL Account - used with unburdened unit costs
*  @costvarianceglacct Cost Variance GL Account - used with fixed unit costs
*  @inglco             IN GL Company
*  @taxphase           Tax Phase
*  @taxct              Tax cost type
*  @inglunits          IN GL Sales Units update to GL
*  @jobsalesacct       IN Job Sales Account
*  @cogsacct           IN Cost of Goods Sold Account
*  @inventoryacct      IN Inventory Account
*  @jobsalesqtyacct    IN Job Sales Quanity Account
*  @msg                Error message
*
* Return:
*  0                   success
*  1                   error
*************************************************/
   
       @mth bMonth, @inco bCompany, @loc bLoc, @matlgroup bGroup, @material bMatl, @um bUM, @units bUnits, @taxcode bTaxCode,
       @jcglco bCompany, @taxgroup bGroup, @phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @job bJob, @jcco bCompany, @transacct bGLAcct,
       @stdum bUM output, @stdunits bUnits output, @stdunitcost bUnitCost output, @stdecm bECM output,
       @inpstunitcost bUnitCost output, @taxglacct bGLAcct output, @taxaccuralacct bGLAcct output,
       @miscglacct bGLAcct output, @costvarglacct bGLAcct output, @inglco bCompany output, @taxphase bPhase output,
       @taxct bJCCType output, @inglunits bYN output, @jobsalesacct bGLAcct output, @cogsacct bGLAcct output,
       @inventoryacct bGLAcct output, @jobsalesqtyacct bGLAcct output, @msg varchar(255) output
   
   as
   
   set nocount on
   
   declare @rcode int, @umconv bUnitCost, @active bYN,
           @lastunitcost bUnitCost, @lastecm bECM,
           @avgunitcost bUnitCost, @avgecm bECM,
           @inlsjobsalesacct bGLAcct, @inlsjobsalesqtyacct bGLAcct,
           @inlcjobsalesacct bGLAcct, @inlcjobsalesqtyacct bGLAcct,
           @category varchar(10), @inlccogsacct bGLAcct,
           @costmth tinyint, @inlcinventoryacct bGLAcct,
           @accttype char(1), @subtype char(1),
           @incostmth tinyint, @lmcostmth tinyint, @locostmth tinyint
   
   select @rcode = 0, @stdunits = 0, @inpstunitcost = 0 , @stdunitcost = 0
   
   -- validate IN Co#
   select @inglco = GLCo, @incostmth = CostMethod
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
          @jobsalesacct = JobSalesGLAcct, @cogsacct = CostGLAcct, @inventoryacct = InvGLAcct,
          @jobsalesqtyacct = JobQtyGLAcct
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
   exec @rcode = bspHQStdUMGet @matlgroup, @material, @um, @umconv output, @stdum output, @msg output
   if @rcode <> 0 goto bspexit
   
   -- validate Location and Material - get override GL Accounts
   select @active = Active, @lastunitcost = LastCost, @lastecm=LastECM,
           @avgunitcost=AvgCost, @avgecm=AvgECM,
           @stdunitcost=StdCost, @stdecm=StdECM,
           @inglunits=GLSaleUnits
   from bINMT
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
   if @@rowcount = 0
       begin
       select @msg = 'Material: ' + isnull(@material,'') + ' is not stocked at Location: ' + isnull(@loc,''), @rcode = 1
       goto bspexit
       end
   if @active = 'N'
       begin
       select @msg = 'Location: ' + isnull(@loc,'') + ' Material: ' + isnull(@material,'') + ' is Inactive!', @rcode = 1
       goto bspexit
       end
   
   
   -- Find Cost Method by location and category 
   select @locostmth = CostMethod
   from bINLO
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Category = @category
   
   
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
   
   if @umconv <> 0
      begin
       select @stdunits = @units * @umconv
       select @inpstunitcost = @stdunitcost * @umconv
      end
   
   ValAcct:
   
    -- validate 'posted to' GL Co and Expense Month
    exec @rcode = bspHQBatchMonthVal @inglco, @mth, 'JC',@msg output
    if @rcode <> 0 goto bspexit
   
   -- validate Location compant over ride - set override accounts
   select @inlsjobsalesacct = JobSalesGLAcct, @inlsjobsalesqtyacct = JobQtyGLAcct
   from bINLS
   where INCo = @inco and Loc = @loc and Co = @jcco
   if @@rowcount <> 0
       begin
       if @inlsjobsalesacct is not null select @jobsalesacct = @inlsjobsalesacct
       if @inlsjobsalesqtyacct is not null select @jobsalesqtyacct = @inlsjobsalesqtyacct
       end
   
   -- validate Location company over ride - set override accounts
   select @inlcjobsalesacct = JobSalesGLAcct, @inlcjobsalesqtyacct = JobQtyGLAcct
   from bINLC
   where INCo = @inco and Loc = @loc and Co = @jcco and MatlGroup = @matlgroup and Category = @category
   if @@rowcount <> 0
       begin
       if @inlcjobsalesacct is not null select @jobsalesacct = @inlcjobsalesacct
       if @inlcjobsalesqtyacct is not null select @jobsalesqtyacct = @inlcjobsalesqtyacct
       end
   
   -- validate Location category over ride - set override accounts
   select @inlccogsacct = CostGLAcct, @inlcinventoryacct = InvGLAcct
   from bINLO
   where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Category = @category
   if @@rowcount <> 0
       begin
       if @inlccogsacct is not null select @cogsacct = @inlccogsacct
       if @inlcinventoryacct is not null select @inventoryacct = @inlcinventoryacct
       end
   
   -- validate Job Sales Account
   exec @rcode = bspGLACfPostable @inglco, @jobsalesacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN Job Sales GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   -- validate Cost Of Goods Sold Account
   exec @rcode = bspGLACfPostable @inglco, @cogsacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN Cost Of Goods Sold GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   -- validate Inventory Account
   exec @rcode = bspGLACfPostable @inglco, @inventoryacct, 'I', @msg output
   if @rcode <> 0
   begin
    select @msg = 'IN Inventory GL Account: ' + isnull(@msg,''), @rcode = 1
     goto bspexit
    end
   
   -- validate Job Sales Qty Account
   if @inglunits = 'N' select @jobsalesqtyacct = Null
   if @inglunits = 'Y'
    begin
    if @jobsalesqtyacct is null
       begin
         select @msg = 'Missing Job Sale Quanity Account for Loc : ' + isnull(@loc,'') + ' Material : ' + isnull(@material,'') + isnull(@msg,''), @rcode = 1
         goto bspexit
       end
    select @accttype = AcctType, @subtype = SubType, @active = Active, @msg=Description
    from bGLAC
    where GLCo = @inglco and GLAcct = @jobsalesqtyacct
    if @@rowcount = 0
      	begin
   	select @msg = 'Job Sale Quantiy Account: ' + isnull(@jobsalesqtyacct,'') + ' not found!', @rcode = 1
      	goto bspexit
     	end
    if @accttype <> 'M'
      	begin
       select @msg = 'Job Sale Quanity Account: ' + isnull(@jobsalesqtyacct,'') + ' must be Memo Account!', @rcode=1
       goto bspexit
     	end
    if @active = 'N'
      	begin
       select @msg = 'Job Sale Quanity Account: ' + isnull(@jobsalesqtyacct,'') + ' is inactive!', @rcode = 1
       goto bspexit
     	end
   
   /*if @chksubtype is not null and @subtype is not null
   	begin
   	if @subtype <> @chksubtype
           begin
         	select @msg = 'GL Account: ' + @glacct + ' is Subledger Type: ' + @subtype + '.  Must be ' + @chksubtype + 'or Blank!'
   	select @rcode = 1
         	goto bspexit
       	end
   	end*/
   
    end
   
   
   
taxcode:
   
if @taxcode is not null
	begin
	select @taxaccuralacct = GLAcct, @taxphase = Phase, @taxct = JCCostType
	from bHQTX
	where TaxGroup = @taxgroup and TaxCode = @taxcode
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Tax Code:' + isnull(@taxcode,'') + ' Tax Group ' + isnull(convert(varchar(3),@taxgroup),''), @rcode = 1
		goto bspexit
		end
		
	---- validate Tax Account
	if @taxaccuralacct is null
		begin
		select @msg = 'Missing Tax GL Account for Tax code : ' + isnull(@taxcode,''), @rcode = 1
		goto bspexit
		end
	
	--- verify tax accrual account in JC GLCompany
	exec @rcode = bspGLACfPostable @jcglco, @taxaccuralacct, 'P', @msg output
	If @rcode <> 0
		begin
		select @msg = 'Tax Accural GL Account:' + isnull(@taxaccuralacct,'') + ' -   ' + isnull(@msg,''), @rcode = 1
		goto bspexit
		end
		
	--- verify tax accrual account in IN to company #136649
	if @jcglco <> @inglco
		begin
		exec @rcode = bspGLACfPostable @inglco, @taxaccuralacct, 'P', @msg output
		if @rcode <> 0
			begin
			select @msg = 'Tax Accural GL Account:' + isnull(@taxaccuralacct,'') + ' -   ' + isnull(@msg,''), @rcode = 1
			goto bspexit
			end
		end
		
	-- Tax Phase and Cost Type
	-- use 'posted' phase and cost type unless overridden by tax code
	if @taxphase is null select @taxphase = @phase
	if @taxct is null select @taxct = @jcctype
	select @taxglacct = @transacct     -- default is 'posted' account

	if @taxphase <> @phase or @taxct <> @jcctype
		begin
		-- get GL Account for Tax Expense
		exec @rcode = bspJCCAGlacctDflt @jcco, @job, @phasegroup, @taxphase, @taxct, 'J', @taxglacct output, @msg output
		if @rcode <> 0
			begin
			select @msg = 'Tax: ' + @msg, @rcode = 1
			goto bspexit
			end
		-- validate Tax Account
		exec @rcode = bspGLACfPostable @jcglco, @taxglacct , 'J', @msg output
		If @rcode <> 0
			begin
			select @msg = 'Tax Expense for Job ' + isnull(@job,'') + ' Phase ' + isnull(@taxphase,'') + ' cost type ' + isnull(convert(varchar(3),@taxct),'') + ' ' + isnull(@msg,''), @rcode = 1
			goto bspexit
			end
		end
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCCBValInv] TO [public]
GO
