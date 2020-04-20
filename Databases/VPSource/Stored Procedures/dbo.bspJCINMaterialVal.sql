SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspJCINMaterialVal]
/*****************************************************************************
* Created By: danf 02/27/2000
* Modified danf 08/24/2000
*          danf 03/27/2002 Corrected Offset account
*			TV - 23061 added isnulls
*			DANF - Issue 29654 Miscellanous material assume taxable.
*			CHS 1/15/08 issue #121623
*			CHS 05/22/2009 	- issue #129478
*			CHS 09/10/2009	- issue #135474
*			CHS 01/04/2010	- issue #137306
*
* validates Material
*
* Pass:
*	Material, MaterialGroup, INCO, Loc
*
* Success returns:
*	stdum, stdunitcost, stdecm, salum, salunitcost, salecm,
*   mphase, mcosttype, taxgroup, taxcode
*
* Error returns:
*	1 and error message
*******************************************************************************/
   	(@material bMatl = null, @matlgrp bGroup = null, @inco bCompany = null, @loc bLoc = null,
       @stdum bUM output, @stdunitcost bUnitCost output, @stdecm bECM output,
       @salum bUM output, @salunitcost bUnitCost output, @salecm bECM output,
       @mphase bPhase output, @mcosttype bJCCType output, @taxable bYN output,
       @jobsalesacct bGLAcct output, @onhand bUnits output, @available bUnits output,
       @jcco bCompany, @valid bYN output, @msg varchar(60) output)
   as
   	set nocount on
   	declare @rcode int, @stocked bYN,
                @jobprice as tinyint, @jobrate as bRate,
               @lastcost bUnitCost, @lastcostecm bECM,
               @avgcost bUnitCost, @avgcostecm bECM,
               @stdprice bUnitCost, @stdpriceecm bECM,
               @inlsjobsalesacct bGLAcct, @inlcjobsalesacct bGLAcct,
               @jccomiscmatacct bGLAcct, @categoryacct bGLAcct,
               @category varchar(10), @validmat bYN, @active bYN
   
   	select @rcode = 0
   	-- #129478
	-- if @material is null
   if isnull(@material, '') = ''
       begin
       select @msg='Missing Material', @rcode=1
       goto bspexit
       end
   
   select @valid = 'Y'
   
   	-- #129478
	-- if @matlgrp is null
   if isnull(@matlgrp, '') = ''
       begin
       select @msg='Missing Material Group', @rcode=1
       goto bspexit
       end
   
   
     select @validmat = ValidateMaterial, @jccomiscmatacct = GLMiscMatAcct
     from bJCCO
     where @jcco = JCCo
   
   --check whether material exists in HQMT
	-- #129478
	-- If @loc = null
   If isnull(@loc, '') = '' 
     begin
		 select @jobsalesacct = @jccomiscmatacct
		 select @msg=Description, @stdum=StdUM, @stdunitcost=Cost, @stdecm=CostECM,
				@salum=SalesUM, @salunitcost=Price, @salecm= PriceECM,
				@mphase=MatlPhase, @mcosttype=MatlJCCostType,
				@taxable = Taxable, @category = Category
		 from bHQMT
		 where Material=@material and MatlGroup=@matlgrp
		 IF @@rowcount =0
			begin
				select @msg = 'Miscellanous Material'
				select @valid = 'N'
				-- Issue 29654 Non Validate Materials or Miscellanous Materials default as taxable.
				select @taxable = 'Y'
				if @validmat = 'Y' select @rcode = 1
				goto bspexit
			end

			select @categoryacct=GLAcct
			from bHQMC
			where Category=@category and MatlGroup=@matlgrp
			If @@rowcount <> 0
			Begin
				if @categoryacct is not null   select @jobsalesacct = @categoryacct
				goto bspexit
			end
		end
   else
     begin
   
		select @msg=Description, @stdum=StdUM,
				@salum=SalesUM,  @salecm= PriceECM,
				@mphase=MatlPhase, @mcosttype=MatlJCCostType,
				@stocked  = Stocked, @taxable = Taxable,
				@category = Category
		from bHQMT
		where Material=@material and MatlGroup=@matlgrp
		if @@rowcount = 0
			begin
				select @msg='Not set up in HQ Material ', @rcode=1
				goto bspexit
			end
   
		if @stocked = 'N'
			begin
				select @msg='Material is not flag as a stocked Item.', @rcode=1
				goto bspexit
			end
   
		select @jobprice=JobPriceOpt
		from bINCO
		where INCo=@inco
		if @@rowcount = 0
			begin
				select @msg='Missing Inventory Company.', @rcode=1
				goto bspexit
			end

	 -- issue #135474
     select @lastcost=LastCost, @lastcostecm=LastECM,

            @avgcost=AvgCost, @avgcostecm=AvgECM,
            @stdunitcost=StdCost, @stdecm=StdECM,
            @stdprice=StdPrice, @stdpriceecm=PriceECM,
            @jobrate=JobRate, @onhand=OnHand,
            @available = OnHand - Alloc,
			@active = Active

     from bINMT
     where INCo= @inco and Loc=@loc and Material=@material and MatlGroup=@matlgrp
     if @@rowcount = 0
       begin
       select @msg='Not set up in IN Materials', @rcode=1
       goto bspexit
       end
	if @active = 'N'
        begin
        select @msg = 'Must be an active Material.', @rcode = 1
        goto bspexit
        end
   
    -- select @salum=@stdum
   
     If @jobprice = 1
       begin
       select  @salunitcost=@avgcost+(@avgcost*@jobrate), @salecm=@avgcostecm
       end
   
     If @jobprice = 2
       begin
       select  @salunitcost=@lastcost+(@lastcost*@jobrate), @salecm=@lastcostecm
       end
   
      If @jobprice = 3
       begin
       select  @salunitcost=@stdunitcost+(@stdunitcost*@jobrate), @salecm=@stdecm
       end
   
      If @jobprice = 4
       begin
       select  @salunitcost=@stdprice-(@stdprice*@jobrate), @salecm=@stdpriceecm
       end
   
   -- get jobsales acct
   select  @jobsalesacct = JobSalesGLAcct
   from bINLM
   where INCo = @inco and Loc = @loc
   
   -- validate Location compant over ride - set override accounts
   
   select @inlsjobsalesacct = JobSalesGLAcct
   from bINLS
   where INCo = @inco and Loc = @loc and Co = @jcco
   if @@rowcount <> 0
       begin
       if @inlsjobsalesacct is not null select @jobsalesacct = @inlsjobsalesacct
       end
   
   -- validate Location company over ride - set override accounts
   select @inlcjobsalesacct = JobSalesGLAcct
   from bINLC
   where INCo = @inco and Loc = @loc and Co = @jcco and MatlGroup = @matlgrp and Category = @category
   if @@rowcount <> 0
       begin
       if @inlcjobsalesacct is not null select @jobsalesacct = @inlcjobsalesacct
       end
   
     end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCINMaterialVal] TO [public]
GO
