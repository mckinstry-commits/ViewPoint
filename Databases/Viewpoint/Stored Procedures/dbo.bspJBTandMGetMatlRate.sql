SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetMatlRate    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMGetMatlRate]
/**************************************************************************
* CREATED BY	: kb 9/4/00
* MODIFIED BY	: kb 12/28/00 issue #11435
*		kb 12/17/1 - issue #12377
*		TJL 09/13/02 - Issue #18542, Solution to 'Invalid Use of Null' during Material Validation.
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 03/23/04 - Issue #24048, Return and then Use correct ECM value from proper sources
*		TJL 06/11/04 - Issue #24809, Related to problem induced by Issue #24304. Set @matlrate = null
*		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
*		TJL 01/09/08 - Issue #124735, Correct MatlRate Default to LineSeq form for Template Matl Price Opt 'C' & 'L'
*
* USED IN:
*	bspJBTandMInit
*	bspJBTandMAddJCTrans
*
* USAGE:
*	The outputs @matlrate, @matlecm are ultimately used:
*		(@matlrate / @matlecm (1, 100, 1000)) * Units = Amount for Materials usage
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*	@matlrate	Material Rate value
*	@matlecm	E, C, M representing Facter by which Rate will be divided 
*
* RETURN VALUE
*   0         success
*   1         Failure
****************************************************************************************/

(@co bCompany, @source char(2), @template varchar(10), @templateseq int,
@jccdunitcost bUnitCost = null, @jccdecm bECM, @category varchar(10) = null,
@matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc,
@jcum bUM, @actualdate bDate, @effectivedate bDate, @matlrate bUnitCost output, 
@matlecm bECM output, @msg varchar(255) output)

as

set nocount on

declare @rcode int, @priceopt char(1), @overrideopt char(1), @overriderate bUnitCost,
@overrideprice bUnitCost, @overridecostopt char(1), @stdum bUM, @umconv bUnitCost,
@hqmuconvcost bUnitCost, @hqmucostecm bECM, @hqmtcost bUnitCost, @hqmtcostecm bECM,
@inmustdcost bUnitCost, @inmustdcostecm bECM,
@inmtlastcost bUnitCost, @inmtavgcost bUnitCost, @inmtstdcost bUnitCost,
@inmtlastecm bECM, @inmtavgecm bECM, @inmtstdecm bECM, @newoverrideprice bUnitCost 

select @rcode = 0, @matlrate = null, @matlecm = null

select @stdum = StdUM 
from bHQMT with (nolock) 
where MatlGroup = @matlgroup and Material = @material

/* PriceOpt 'C'ost, 'P'rice, or 'L'ocation */
select @priceopt = PriceOpt 
from bJBTS with (nolock) 
where JBCo = @co and Template = @template and Seq = @templateseq
   
/* Template ACTUAL PRICE (C)

  Use PostedUnitCost from JCCD unless an Override exists. All Sources w/Material
  includes MS, IN (includes MI & MO), MT will use PostedUnitCost for matlrate
  unless an override exists. 

  "CostOption" is not valid for this template Price Option setting. */
if @priceopt = 'C'
   	begin	/* Begin 'C' Opt */
   
	if @jccdunitcost is not null
		/* JC Transaction Processing:
		   @jccdunitcost will be 0.00 or some value when passed in via JC Trans processing 
		   procedures.  Rates and conversions are predetermined by forms posting to JCCD. */
		begin
		select @matlrate = @jccdunitcost, @matlecm = @jccdecm
		end
	else
		/* Manual Form (LineSeq) entry:
		   @jccdunitcost will be passed in as NULL from form.  We must determine proper
		   Price value to use.  "PRICE" has been verified correct here by Andrewk. */
		begin
   		if isnull(@stdum, '') <> isnull(@jcum, '')		--@jcum = Form UM passed in
   			begin
   			select @matlrate = Price, @matlecm = PriceECM  
   			from bHQMU with (nolock)
   			where MatlGroup = @matlgroup and Material = @material and UM = @jcum
   			if @@rowcount = 0 
				begin
   				select @matlrate = Price, @matlecm = PriceECM
   				from bHQMT with (nolock) 
   				where MatlGroup = @matlgroup and Material = @material
   				if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm, 'E')	
				end
   			end
   		else
   			/* UM (from Form) is a match to HQMT, therefore goto HQMT for rate information */
   			begin
   			select @matlrate = Price, @matlecm = PriceECM
   			from bHQMT with (nolock) 
   			where MatlGroup = @matlgroup and Material = @material
   			if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm, 'E')
   			end
		end

   	/* Check for material overrides settings on this template. */
   	select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,
   		@overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice	--There is no ECM in overrides, Use 'E'
   	From bJBMO with (nolock) 
   	where JBCo = @co and Template = @template and MatlGroup = @matlgroup
   		and Material = @material
   	if @@rowcount = 0 goto bspexit			--issue #12377, Override does not exist, Exit now.
   
   	-- APPLY OVERRIDES on C
   	/* If Override/Specific price exists, then reset @matlrate to be returned regardless of Price value. */	
   	if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01')
   		begin
   		if @newoverrideprice <> 0 select @matlrate = @newoverrideprice, @matlecm = 'E'
   		end
   	else
   		begin
   		if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'
   		end
   
   	/* Apply "Override Option" to the established Material Rate.  This Rate may come from:
		  1) JBMO Specific Price.

   	   	  2) JBMO Specific Price may be 0.00. If so, we will be using JCCD UnitCost 
   	   	     with the override option when a specific JC Trans is being processed. 
   
   		  3) On Manual form entry there is no JC Trans.  MatlRate will come from either
			 HQMU or HQMT Price values. */	
   	if @overrideopt = 'C' --cost plus
   		begin
   		select @matlrate = @matlrate + (@matlrate * @overriderate)
   		goto bspexit
   		end
   	if @overrideopt = 'P' --price less
   		begin
   		select @matlrate = @matlrate - (@matlrate * @overriderate)
   		goto bspexit
   		end
   	end	/* End 'C' Opt */
   
/* Template STD PRICE (P)

  This is a 'P'rice option and typically we are using "PRICE" rates from HQ unless an 
  override calls for a Cost option. 

  "CostOption" is not valid for this template Price Option setting.*/
if @priceopt = 'P'
   	begin	/* Begin 'P' Opt */
   	/* If PostedUM (from JCCD) is not the same as StandardUM from HQMT then any Price from HQMT 
   	   would be invalid.  We therefore need to go to a conversion table for the appropriate
   	   rate information rather than to HQMT. */
   	if isnull(@stdum,'') <> isnull(@jcum,'')
   		begin
   		select @matlrate = Price, @hqmuconvcost = Cost, @matlecm = PriceECM, @hqmucostecm = CostECM  
   		from bHQMU with (nolock)
   		where MatlGroup = @matlgroup and Material = @material and UM = @jcum
   		if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm,'E')
   		end
   	else
   	/* PostedUM (from JCCD) is a match to HQMT, therefore goto HQMT for rate information */
   		begin
   		select @matlrate = Price, @hqmtcost = Cost, @matlecm = PriceECM, @hqmtcostecm = CostECM
   		from bHQMT with (nolock) 
   		where MatlGroup = @matlgroup and Material = @material
   		if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm,'E')
   		end
   
   	/* Check for material overrides settings on this template. */
	select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,
       	@overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice	--There is no ECM in overrides, Use 'E'
	From bJBMO with (nolock) 
   	where JBCo = @co and Template = @template and MatlGroup = @matlgroup
       	and Material = @material
   	if @@rowcount = 0 goto bspexit			--Override does not exist, Exit now.
   
   	-- APPLY OVERRIDES on P
   	/* If Override/Specific price exists, then reset @matlrate to be returned */	
   	if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01')
   		begin
   		if @newoverrideprice <> 0 select @matlrate = @newoverrideprice, @matlecm = 'E'
   		end
   	else
   		begin
   		if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'
   		end
   
   
   	/* Apply Override ride Options to the appropriate Material Rate available. */ 
 	if @overrideopt = 'C' --cost plus
		/* This override calls for Cost values (not Price) which is why we saved them in 
		   variables above.  We will be reseting our outputs to these values now. 

		   This is kind of a side trip which will reset all the work done above. 
		   during a CostPlus override. */
     	begin
     	if isnull(@stdum,'') <> isnull(@jcum,'')
		/* PostedUM (from JCCD) is Not a match to HQMT, Use HQMU converted Cost values. */
         	begin
         	select @matlrate = isnull(@hqmuconvcost,isnull(@jccdunitcost,0)), 
				@matlecm = isnull(@hqmucostecm,isnull(@jccdecm,'E'))
         	end
     	else
		/* PostedUM (from JCCD) is a match to HQMT, therefore use HQMT Cost information */
        	begin
         	select @matlrate = isnull(@hqmtcost,isnull(@jccdunitcost,0)), 
				@matlecm = isnull(@hqmtcostecm,isnull(@jccdecm,'E'))
         	end
   
   		--if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'
   
   		/* We have the correct rate, do the CostPlus override conversion */
    	select @matlrate = @matlrate + (@matlrate * @overriderate)
    	goto bspexit
    	end
   
 	if @overrideopt = 'P' --price less
	/* If here, then @matlrate already represents the correct PRICE rate from either:
		1) HQMU, if StdUM <> jccdUM and converted Price is required.
		2) HQMT, if StdUM = jccdUM 
		3) JBMO, if Override Specific Price is to be use. 
		4) JCCD, direct from Cost Detail if no other values exist. */
    	begin
	-- @matlrate and @matlecm have been properly set previously above, simply use them
    	select @matlrate = @matlrate - (@matlrate * @overriderate)
    	goto bspexit
    	end
 	end		/* End 'P' Opt */
   
/* Template STD PRICE (L) 

  Get UnitCost from INMT otherwise get it from bHQMT.  However if PostedUM (@jcum) is 
  different than StandardUM then need price from INMU.  This value may also be overridden by an 
  Override table configuration.  If however, no UnitCost values exist anywhere then we
  will use PostUnitCost to avoid possibility of 0.00 value billed for Material 

  "CostOption" is valid for this template Price Option setting.*/
if @priceopt = 'L'
	begin	/* Begin 'L' Opt */
	/* If PostedUM (from JCCD) is not the same as StandardUM from HQMT then any Price from INMT 
	   or HQMT would be invalid.  We therefore need to go to conversion tables for the appropriate
	   rate information rather than to INMT and HQMT. */
	if isnull(@stdum,'') <> isnull(@jcum,'')		--@jcum might be Form UM value.
 		begin
 		select @matlrate = Price, @inmustdcost = StdCost, @matlecm = PriceECM, @inmustdcostecm = StdCostECM
		from bINMU with (nolock)
		where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material 
		and UM = @jcum
		if @@rowcount = 0
			begin
			select @matlrate = Price, @hqmuconvcost = Cost, @matlecm = PriceECM, @hqmucostecm = CostECM  
			from bHQMU with (nolock)
			where MatlGroup = @matlgroup and Material = @material and UM = @jcum
			if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm, 'E')	
			end		
 		end
	else
		/* PostedUM (from JCCD) is a match to HQMT, therefore goto INMT, HQMT for rate information */
		begin
		select @matlrate = StdPrice, @inmtlastcost = LastCost, @inmtavgcost = AvgCost, @inmtstdcost = StdCost,
			@matlecm = PriceECM, @inmtlastecm = LastECM, @inmtavgecm = AvgECM, @inmtstdecm = StdECM
		from bINMT with (nolock) 
		where INCo = @inco and Loc  = @loc and MatlGroup = @matlgroup
			and Material = @material
		if @@rowcount = 0
			begin
			select @matlrate = Price , @hqmtcost = Cost, @matlecm = PriceECM, @hqmtcostecm = CostECM
			from bHQMT with (nolock) 
			where MatlGroup = @matlgroup and Material = @material
			if @@rowcount = 0 select @matlrate = isnull(@jccdunitcost,0), @matlecm = isnull(@jccdecm,'E')
			end
		end
   
	/* Check for material overrides settings on this template. */
	select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,
   		@overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice		--There is no ECM in overrides, Use 'E'
	From bJBMO with (nolock) 
	where JBCo = @co and Template = @template and MatlGroup = @matlgroup and Material = @material
	if @@rowcount = 0 goto bspexit			--Override does not exist, Exit now.

	-- APPLY OVERRIDES on L
	/* If Override/Specific price exists, then reset @matlrate to be returned */
	if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01')
		begin
		if @newoverrideprice <> 0 select @matlrate = @newoverrideprice, @matlecm = 'E'
		end
	else
		begin
		if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'
		end
   
	/* Apply Override ride Options to the appropriate Material Rate available. */ 
	if @overrideopt = 'C' --cost plus
		/* This override calls for Cost values (not Price) which is why we saved them in 
		   variables above.  We will be reseting our outputs to these values now. 

		   This is kind of a side trip which will reset all the work done above. 
		   during a CostPlus override. */
		begin
		if isnull(@stdum,'') <> isnull(@jcum,'')
			/* PostedUM (from JCCD) is Not a match to HQMT, Use INMU, HQMU converted Cost values. */
			begin
			select @matlrate = isnull(@inmustdcost, isnull(@hqmuconvcost,isnull(@jccdunitcost,0))), 
				@matlecm = isnull(@inmustdcostecm, isnull(@hqmucostecm,isnull(@jccdecm,'E')))
			end
		else
			/* PostedUM (from JCCD) is a match to HQMT, therefore use INMT, HQMT Cost information */
			begin
			select @matlrate = isnull((case isnull(@overridecostopt,'') 
				when 'S' then @inmtstdcost
  				when 'A' then @inmtavgcost 
				when 'L' then @inmtlastcost
				when '' then @inmtstdcost end), isnull(@hqmtcost,isnull(@jccdunitcost,0))),
  				@matlecm = isnull((case isnull(@overridecostopt,'') 
					when 'S' then @inmtstdecm
  					when 'A' then @inmtavgecm 
					when 'L' then @inmtlastecm 
					when '' then @inmtstdecm end), isnull(@hqmtcostecm,isnull(@jccdecm,'E')))
			end
	   
		--if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'

		select @matlrate = @matlrate + (@matlrate * @overriderate)
		goto bspexit
		end
   
	if @overrideopt = 'P' --price less
		/* If here, then @matlrate already represents the correct PRICE rate from either:
			1) INMU or HQMU, if StdUM <> jccdUM and converted Price is required.
			2) INMT or HQMT, if StdUM = jccdUM 
			3) JBMO, if Override Specific Price is to be use. 
			4) JCCD, direct from Cost Detail if no other values exist. */
		begin
		select @matlrate = @matlrate - (@matlrate * @overriderate)
		goto bspexit
		end

 	end		/* End 'L' Opt */
   
bspexit:
if @matlrate is null select @rcode = 1, @msg = 'Material rate not found'	

return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetMatlRate] TO [public]
GO
