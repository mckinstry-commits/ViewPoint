SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspINLocValForFuelPosting]
/*************************************
* CREATED BY: JM 12/10/01
* Modified By: JM 12/11/01 - Ref Issue 14688 - Added calculation of TotalCost for update to bEMBF from form.
*		JM 12/26/01 - Added return of material so that if user enters a location which does not stock the
*			material on the form, it can be returned as null and will set the form material to null. If the location
*			entered does stock the material then just return it so there will be no effect.
*		JM 3/19/02 - Added @INLMTaxCodeFlag return param to allow front end to display warning only
*			when material is taxable but there is not TaxCode for the INCO/INLoc. This also allows normal failure
*			for standard non-valid inputs.
*		JM - 3/20/02 - Added @gloffsetacct output param - Ref Issue 12679
*		JM 4/16/02 - Removed return of GLOffsetAcct
*  		GF 10/01/2002 - Issue #18627 - using wrong pricing option from INCO. Should use equip option.
*		JM 10-22-02 - Reinstated return of GLOffsetAcct - could not find issue supporting the removal on 4-16-02.
*		JM 12-29-02 - Ref Issue 19800 - Replaced @msg with @errmsg in call to bspGLACfPostable so that the 
*			Desc or the @gloffsetacct won't overwrite the Desc pulled for the INLoc already stored in @msg.
*		GG 3/21/05 - #27012 - corrected hierarchy of search for IN GL Account
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE (REMARKS only)
*
* Validates IN Location for a Material Code and returns TaxCode from INLM if material is taxable in HQMT
*
* Pass:
*   INCo - Inventory Company
*   Loc - Location to be Validated
*   Material = Material validate at the Location
*
* Success returns:
*   Description of Location
*   TaxCode if taxable in HQMT
*   Material (see not above in 12/26 modification)
*   INLMTaxCodeFlag = '0' for success (Material taxable in HQMT and a TaxCode exists in INLM for INCo/Loc)
*			'1' for failure (no TaxCode in INLM)
*
* Error returns:
*	1 and error message
**************************************/
(@inco bCompany = null, @loc bLoc, @materialin bMatl, @activeopt bYN, @matlgroup bGroup,
@emco bCompany=null, @equipment bEquip, @materialout bMatl output, @taxcode bTaxCode output,
@unitprice bUnitCost output, @INLMTaxCodeFlag char(1) output, @gloffsetacct bGLAcct output,
@msg varchar(255) output)
as
set nocount on
 
declare @active bYN, @numrows int, @rcode int, @EMEP_HQMatl bMatl, @invpriceopt tinyint,
	@avgcost bUnitCost, @lastcost bUnitCost, @stdcost bUnitCost, @stdprice bUnitCost,
	@inglco bCompany, @overridegloffsetacct bGLAcct, @errmsg varchar(255),
	@matl bMatl
     
set @rcode = 0
-- default this flag to success and reset to failure only if material is sent in from form
set @INLMTaxCodeFlag = 0 

if @inco is null
 	begin
 	select @msg = 'Missing IN Company', @rcode = 1
 	goto bspexit
 	end

if @loc is null
 	begin
 	select @msg = 'Missing IN Location', @rcode = 1
 	goto bspexit
 	end

if @emco is null
 	begin
 	select @msg = 'Missing EM Company', @rcode = 1
 	goto bspexit
 	end

if @equipment is null
 	begin
 	select @msg = 'Missing Equipment', @rcode = 1
 	goto bspexit
 	end
     
-- validate the location
select @msg = INLM.Description, @active = INLM.Active 
from dbo.INLM with (nolock) where INCo = @inco and Loc = @loc
if @@rowcount = 0
 	begin
 	select @msg='Not a valid IN Location', @rcode=1
 	goto bspexit
 	end

if @activeopt = 'Y' and @active = 'N'
 	begin
 	select @msg = 'Not an active Location', @rcode=1
 	goto bspexit
 	end
     
-- if material sent in from form, return it and TaxCode as null if it isn't stocked at this location; 
-- if it is, return it back to the form and also return the TaxCode from INLM  if it's taxable in HQMT.
-- If the TaxCode doesn't exist in INLM and the Material is taxable, return INLMTaxCodeFlag = 1
-- so the form can display a warning only (ref Issue 16434).
if isnull(@materialin,'') <> ''
 	begin
 	-- Translate @materialin to EMEP.HQMatl if there
 	select @EMEP_HQMatl=HQMatl from dbo.EMEP with (nolock)
	where EMCo = @emco and Equipment = @equipment and PartNo = @materialin
	if @@rowcount = 0 or isnull(@EMEP_HQMatl,'') = '' set @EMEP_HQMatl = null

	-- set @matl equal @EMEP_HQMatl when not null else @materialin
	set @matl = isnull(@EMEP_HQMatl, @materialin)
 	-- Get the price for the material in INMT for the location if it exists
 	select @avgcost = AvgCost, @lastcost = LastCost, @stdcost = StdCost, @stdprice = StdPrice 
 	from dbo.INMT with (nolock)
 	where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @matl
 	--and Material = case when @EMEP_HQMatl is null then @materialin else @EMEP_HQMatl end
 	--select @numrows = @@rowcount
	if @@rowcount = 0
     	-- if @numrows = 0
		begin
		-- a valid loc but matl not stocked there so blank out the material on the form
		set @materialout = null
   		set @taxcode = null
		-- get unit price from HQMT

		select @unitprice = Price from dbo.HQMT with (nolock) 
   		where MatlGroup = @matlgroup and Material = @matl
   		--and Material = case when @EMEP_HQMatl is null then @materialin else @EMEP_HQMatl end
		end
	else
		begin
 		-- a valid loc and matl stocked there so return the form's mal back
 		set @materialout = @materialin
 		-- now get the inv price opt from INCO
		select @invpriceopt = EquipPriceOpt from dbo.INCO with (nolock) where INCo = @inco
 		select @unitprice = case @invpriceopt
 				when 1 then @avgcost
 				when 2 then @lastcost
 				when 3 then @stdcost
 				when 4 then @stdprice
 				end

		-- get TaxCode if taxable
		set @taxcode = null
		if exists(select 1 from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @matl and Taxable = 'Y')
			begin
			select @taxcode=TaxCode from dbo.INLM with (nolock) where INCo=@inco and Loc=@loc
			if @@rowcount = 0 or isnull(@taxcode,'') = '' set @INLMTaxCodeFlag=1
			end

		/*
 			if (select Taxable from bHQMT with (nolock) where MatlGroup = @matlgroup 
 				and Material = case when @EMEP_HQMatl is null then @materialin else @EMEP_HQMatl end) = 'Y'
 				begin
 				select @taxcode = TaxCode from bINLM with (nolock) where INCo = @inco and Loc = @loc
 				if isnull(@taxcode,'') = '' set @INLMTaxCodeFlag = 1
 				end
 			else
 				-- set TaxCode to null
 				set @taxcode = null
		*/
		end
	end
     
-- Get OffsetGLAcct = EquipSalesGLAcct from INLC or INLS or INLM or error.
-- #27012 - corrected hierarchy of serach for IN GL Account
select @gloffsetacct = null
select @gloffsetacct = EquipSalesGLAcct
from dbo.INLC with (nolock) 
where INCo = @inco and Loc = @loc  and Co = @emco and MatlGroup = @matlgroup 
	and Category = (select Category from dbo.HQMT with (nolock) where MatlGroup = @matlgroup and Material = @materialin)
if @gloffsetacct is null
	select @gloffsetacct = EquipSalesGLAcct
	from dbo.INLS with (nolock)
	where INCo = @inco and Loc = @loc and Co = @emco
	if @gloffsetacct is null
		select @gloffsetacct = EquipSalesGLAcct
		from dbo.INLM with (nolock)
		where INCo = @inco and Loc = @loc
		if @gloffsetacct is null
 			begin
 			select @msg = 'Missing GL Account for Inventory Sales to Equip!', @rcode = 1
 			goto bspexit
 			end
     
-- Validate the GLOffsetAcct as postable
select @inglco = GLCo from dbo.INCO with (nolock) where INCo = @inco
-- JM 12-29-02 - Ref Issue 19800 - Replaced @msg with @errmsg in call to bspGLACfPostable so that the Desc or the
-- @gloffsetacct won't overwrite the Desc pulled for the INLoc already stored in @msg.
exec @rcode = bspGLACfPostable @inglco, @gloffsetacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @msg = 'GLOffsetAcct: ' + @errmsg, @rcode = 1
	goto bspexit
	end	
   
   
bspexit:
--if @rcode<>0 select @msg
return @rcode
SET QUOTED_IDENTIFIER ON


GO
GRANT EXECUTE ON  [dbo].[bspINLocValForFuelPosting] TO [public]
GO
