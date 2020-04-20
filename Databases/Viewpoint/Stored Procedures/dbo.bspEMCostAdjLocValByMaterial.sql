SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspEMCostAdjLocValByMaterial]
   /*************************************
   * CREATED BY: DANF 06/06/00
   * Modified By: JM 6/19/01 - Added translation of @material to EMEP.HQMatl if appropriate.
   *	JM 6/20/01 - Added exit from procedure if @material = ''. This is necessary for 
   *	EMWOEdit form since the Material column in the grid is a key field and will always 
   *	be converted from null to '', and since this column is after the invloc column it comes
   *	in as a '' rather than a null, incorrectly triggering a validation error. Note that for that
   *	form this procedure will be run again when the record is saved and the requirement
   *	for the Material will be enforced by its key status.
   *	JM 3/19/02 - Added @INLMTaxCodeFlag return param to allow front end to display warning only
   *	when material is taxable but there is not TaxCode for the INCO/INLoc. This also allows normal failure
   *	for standard non-valid inputs.
   *		TV 02/11/04 - 23061 added isnulls
   *		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
			AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
   *
   * Validates IN Location for a Material Code and returns Equipment Sales Account
   *
   * Pass:
   *   INCo - Inventory Company
   *   Loc - Location to be Validated
   *   Material = Material validate at the Location
   *
   * Success returns:
   *   Description of Location
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@inco bCompany = null,
   	@loc bLoc,
   	@material bMatl,
   	@activeopt bYN,
   	@matlgroup bGroup,
   	@emco bCompany,
   	@equipment bEquip,
   	@equipsalesacct bGLAcct output,
   	@unitprice bUnitCost output,
   	@INLMTaxCodeFlag char(1) output,
   	@msg varchar(100) output)
   as
   
   set nocount on
   
   declare @active bYN,
   	@category varchar(10),
   	@numrows int,
   	@inlcequipsalesacct bGLAcct,
   	@inlsequipsalesacct bGLAcct,
   	@stdum bUM,
   	@equipprice bUnitCost,
   	@lastcost bUnitCost,
   	@equiprate bUnitCost,
   	@inequiprate bUnitCost,
   	@avgcost bUnitCost,
   	@stdprice bUnitCost,
   	@stdunitcost bUnitCost,
   	@salecm bECM,
   	@lastcostecm bECM,
   	@avgcostecm bECM,
   	@stdecm bECM,
   	@stdpriceecm bECM,
   	@salunitcost bUnitCost,
   	@matfile bYN,
   	@rcode int,
   	@inmatlgroup bGroup,
   	@EMEP_HQMatl bMatl,
   	@taxable bYN
   
   select @rcode = 0, @unitprice = 0, @matfile = 'N', @INLMTaxCodeFlag = 0
   
   if @loc is null
   	begin
   	goto bspexit
   	end
   
   if @inco is null
   	begin
   	select @msg='Missing Inventory Company', @rcode=1
   	goto bspexit
   	end
   
   select @inmatlgroup = MatlGroup from bHQCO where HQCo = @inco
   
   select @msg = bINLM.Description, @active = bINLM.Active from bINLM where bINLM.INCo = @inco and bINLM.Loc = @loc
   
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg='Invalid inventory Location', @rcode=1
   	goto bspexit
   	end
   
   if @active = 'N'
   	begin
   	select @msg='Inventory Location is not active', @rcode=1
   	goto bspexit
   	end
   
   if @material is null goto bspexit
   if @material = '' goto bspexit
   
   /* Translate @material to EMEP.HQMatl if there */
   select @EMEP_HQMatl = HQMatl from bEMEP where EMCo = @emco and Equipment = @equipment and PartNo = @material
   
   /* If Material is in bHQMT, read Description, Category, Price and StdUM there. */
   select @matfile = 'N'
   select @category=Category from bHQMT where MatlGroup = @matlgroup and Material = case when @EMEP_HQMatl is null then @material else @EMEP_HQMatl end
   
   If @@rowcount <> 0 select @matfile = 'Y'
   
   /* If Material found in bHQMT read GLOffsetAcct = bHQMC.GLAcct by bHQMT.Category. */
   if @matfile = 'Y' select @equipsalesacct = GLAcct from bHQMC where MatlGroup = @matlgroup and Category = @category
   
   /* If Material not found in bHQMT read GLOffsetAcct = bEMCO.MatlMiscGLAcct. */
   if @matfile = 'N' select @equipsalesacct = MatlMiscGLAcct from bEMCO where EMCo = @emco
	-- #142278   
   SELECT   @msg = bINLM.[Description],
            @active = bINLM.Active,
            @equipsalesacct = EquipSalesGLAcct
   FROM     dbo.bINLM
            JOIN dbo.bINMT ON bINMT.INCo = bINLM.INCo
								AND bINMT.Loc = bINLM.Loc
   WHERE    bINLM.INCo = @inco
            AND bINLM.Loc = @loc
            AND bINMT.MatlGroup = @inmatlgroup
            AND bINMT.Material = ISNULL(@EMEP_HQMatl,@material)
       
   select @numrows = @@rowcount
   if @numrows = 0
   	begin
   	select @msg='Not a valid Location for this Material', @rcode=1
   	goto bspexit
   	end
   
   if @activeopt = 'Y' and @active = 'N'
   	begin
   	select @msg = 'Not an active Location', @rcode=1
   	goto bspexit
   	end
   
   -- validate Location company over ride - set override accounts
   select @inlsequipsalesacct = EquipSalesGLAcct
   from bINLS
   where INCo = @inco and Loc = @loc and Co = @emco
   if @@rowcount = 0 if @inlsequipsalesacct is not null select @equipsalesacct = @inlsequipsalesacct
   
   -- validate Location company over ride - set override accounts
   select @inlcequipsalesacct = EquipSalesGLAcct 
   from bINLC
   where INCo = @inco and Loc = @loc and Co = @emco and MatlGroup = @inmatlgroup and Category = @category
   if @@rowcount = 0 if @inlcequipsalesacct is not null select @equipsalesacct = @inlcequipsalesacct
   
   --check whether material exists in HQMT
   If @loc is not null
   	begin
   	select @stdum=StdUM, @salecm= PriceECM, @category = Category, @taxable = Taxable from bHQMT
   	where Material=case when @EMEP_HQMatl is null then @material else @EMEP_HQMatl end and MatlGroup=@matlgroup
   	if @@rowcount = 0
   		begin
   		select @msg='Not set up in HQ Material', @rcode=1
   		goto bspexit
   		end
   
   	if @taxable = 'Y'
   		begin
   		if not exists(select TaxCode from bINLM where INCo = @inco and Loc = @loc)
   			select @INLMTaxCodeFlag = 1
   		end
   
     select @equipprice=EquipPriceOpt
     from bINCO
     where INCo=@inco
     if @@rowcount = 0
       begin
       select @msg='Missing Inventory Company.', @rcode=1
       goto bspexit
       end
   
     select @lastcost=LastCost, @lastcostecm=LastECM,
            @avgcost=AvgCost, @avgcostecm=AvgECM,
            @stdunitcost=StdCost, @stdecm=StdECM,
            @stdprice=StdPrice, @stdpriceecm=PriceECM,
            @inequiprate=EquipRate
     from bINMT
     where INCo= @inco and Loc=@loc and Material=case when @EMEP_HQMatl is null then @material else @EMEP_HQMatl end and MatlGroup=@inmatlgroup
     if @@rowcount = 0
       begin
       select @msg='Not set up in IN Materials', @rcode=1
       goto bspexit
       end
   
     select @equiprate =0
   
     if @inequiprate <>0  select @equiprate = @inequiprate
   
     If @equipprice = 1
       begin
       select  @unitprice=@avgcost+(@avgcost*@equiprate), @salecm=@avgcostecm
       end
   
     If @equipprice = 2
       begin
       select  @unitprice=@lastcost+(@lastcost*@equiprate), @salecm=@lastcostecm
       end
   
      If @equipprice = 3
       begin
       select  @unitprice=@stdunitcost+(@stdunitcost*@equiprate), @salecm=@stdecm
       end
   
      If @equipprice = 4
       begin
       select  @unitprice=@stdprice-(@stdprice*@equiprate), @salecm=@stdpriceecm
       end
   
    end
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')		--+ char(13) + char(10) + '[bspEMCostAdjLocValByMaterial]'
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspEMCostAdjLocValByMaterial] TO [public]
GO
