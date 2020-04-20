SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   FUNCTION    [dbo].[vf_rptJBMatlRate]  
/************************************************************************
* CREATED:	
* MODIFIED:	AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables
*
* Purpose:

* returns 1 and error msg if failed
*
*************************************************************************/  
  (@co bCompany,  @template varchar(10),@templateseq int, @category varchar(10),@jbidsource char(2),@phasegrp bGroup,  
 @jcctype bJCCType, @jctranstype varchar(2),   
    @jccdunitcost bUnitCost, @jccdecm bECM,   
    @matlgroup bGroup, @material bMatl, @inco bCompany, @loc bLoc,  
    @jcum bUM, @actualdate bDate, @effectivedate bDate)  
  
RETURNS numeric(12,5)  
AS  
BEGIN  
  
   --#142350 - renaming @MatlRate
	DECLARE @rcode int,
			@priceopt char(1),
			@overrideopt char(1),
			@overriderate bUnitCost,
			@overrideprice bUnitCost,
			@overridecostopt char(1),
			@stdum bUM,
			@umconv bUnitCost,
			@hqmuconvcost bUnitCost,
			@hqmucostecm bECM,
			@hqmtcost bUnitCost,
			@hqmtcostecm bECM,
			@inmustdcost bUnitCost,
			@inmustdcostecm bECM,
			@inmtlastcost bUnitCost,
			@inmtavgcost bUnitCost,
			@inmtstdcost bUnitCost,
			@inmtlastecm bECM,
			@inmtavgecm bECM,
			@inmtstdecm bECM,
			@newoverrideprice bUnitCost,
			@matlrate bUnitCost,
			@matlecm bECM,
			@MaterialRate numeric(12, 5)  
	 
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
    begin /* Begin 'C' Opt */  
    /* Begin with an initial value from JC Detail */  
    select @matlrate = @jccdunitcost, @matlecm = @jccdecm  
     
    /* Check for material overrides settings on this template. */  
    select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,  
     @overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice --There is no ECM in overrides, Use 'E'  
    From bJBMO with (nolock)   
    where JBCo = @co and Template = @template and MatlGroup = @matlgroup  
     and Material = @material  
    if @@rowcount = 0 goto bspexit   --issue #12377, Override does not exist, Exit now.  
     
    -- APPLY OVERRIDES on C  
    /* If Override/Specific price exists, then reset @matlrate to be returned */   
    if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01')  
     begin  
     if @newoverrideprice <> 0 select @matlrate = @newoverrideprice, @matlecm = 'E'  
     end  
    else  
     begin  
     if @overrideprice <> 0 select @matlrate = @overrideprice, @matlecm = 'E'  
     end  
     
    /* Apply Override ride Options to the appropriate Material Rate available.  
          1) JBMO Specific Price may be 0.00. If so, we will be using JCCD UnitCost   
             with the override option instead.   
     
       2) In this scenario, there is no distinction between Cost and Price.    
       Therefore, Override options get applied to the same Rate value. */   
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
    end /* End 'C' Opt */  
     
   /* Template STD PRICE (P)  
     
      This is a 'P'rice option and typically we are using "PRICE" rates from HQ unless an   
      override calls for a Cost option.   
     
      "CostOption" is not valid for this template Price Option setting.*/  
   if @priceopt = 'P'  
    begin /* Begin 'P' Opt */  
    /* If PostedUM (from JCCD) is not the same as StandardUM from HQMT then any Price from HQMT   
       would be invalid.  We therefore need to go to a conversion table for the appropriate  
       rate information rather than to HQMT. */  
    if @stdum <> @jcum  
     begin  
     select @matlrate = Price, @hqmuconvcost = Cost, @matlecm = PriceECM, @hqmucostecm = CostECM    
     from bHQMU with (nolock)  
     where MatlGroup = @matlgroup and Material = @material and UM = @jcum  
     if @@rowcount = 0 select @matlrate = @jccdunitcost, @matlecm = @jccdecm  
     end  
    else  
    /* PostedUM (from JCCD) is a match to HQMT, therefore goto HQMT for rate information */  
     begin  
     select @matlrate = Price, @hqmtcost = Cost, @matlecm = PriceECM, @hqmtcostecm = CostECM  
     from bHQMT with (nolock)   
     where MatlGroup = @matlgroup and Material = @material  
     if @@rowcount = 0 select @matlrate = @jccdunitcost, @matlecm = @jccdecm  
     end  
     
    /* Check for material overrides settings on this template. */  
      select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,  
        @overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice --There is no ECM in overrides, Use 'E'  
       From bJBMO with (nolock)   
    where JBCo = @co and Template = @template and MatlGroup = @matlgroup  
        and Material = @material  
    if @@rowcount = 0 goto bspexit   --Override does not exist, Exit now.  
     
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
          if @stdum <> @jcum  
      /* PostedUM (from JCCD) is Not a match to HQMT, Use HQMU converted Cost values. */  
              begin  
              select @matlrate = isnull(@hqmuconvcost,@jccdunitcost), @matlecm = isnull(@hqmucostecm,@jccdecm)  
              end  
          else  
      /* PostedUM (from JCCD) is a match to HQMT, therefore use HQMT Cost information */  
             begin  
              select @matlrate = isnull(@hqmtcost,@jccdunitcost), @matlecm = isnull(@hqmtcostecm,@jccdecm)  
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
      end  /* End 'P' Opt */  
     
   /* Template STD PRICE (L)   
     
      Get UnitCost from INMT otherwise get it from bHQMT.  However if PostedUM (@jcum) is   
      different than StandardUM then need price from INUM.  This value may also be overridden by an   
      Override table configuration.  If however, no UnitCost values exist anywhere then we  
      will use PostUnitCost to avoid possibility of 0.00 value billed for Material   
     
      "CostOption" is valid for this template Price Option setting.*/  
   if @priceopt = 'L'  
      begin /* Begin 'L' Opt */  
    /* If PostedUM (from JCCD) is not the same as StandardUM from HQMT then any Price from INMT   
       or HQMT would be invalid.  We therefore need to go to conversion tables for the appropriate  
       rate information rather than to INMT and HQMT. */  
      if @stdum <> @jcum  
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
      if @@rowcount = 0 select @matlrate = @jccdunitcost, @matlecm = @jccdecm   
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
      if @@rowcount = 0 select @matlrate = @jccdunitcost, @matlecm = @jccdecm  
      end  
     end  
     
    /* Check for material overrides settings on this template. */  
      select @overrideopt = OverrideOpt, @overriderate = Rate, @overrideprice = SpecificPrice,  
        @overridecostopt = CostOpt, @newoverrideprice = NewSpecificPrice  --There is no ECM in overrides, Use 'E'  
       From bJBMO with (nolock)   
    where JBCo = @co and Template = @template and MatlGroup = @matlgroup and Material = @material  
    if @@rowcount = 0 goto bspexit   --Override does not exist, Exit now.  
     
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
         if @stdum <> @jcum  
      /* PostedUM (from JCCD) is Not a match to HQMT, Use INMU, HQMU converted Cost values. */  
           begin  
      select @matlrate = isnull(@inmustdcost, isnull(@hqmuconvcost,@jccdunitcost)),   
       @matlecm = isnull(@inmustdcostecm, isnull(@hqmucostecm,@jccdecm))  
           end  
     else  
      /* PostedUM (from JCCD) is a match to HQMT, therefore use INMT, HQMT Cost information */  
      begin  
          select @matlrate = isnull((case isnull(@overridecostopt,'')   
        when 'S' then @inmtstdcost  
              when 'A' then @inmtavgcost   
        when 'L' then @inmtlastcost end), isnull(@hqmtcost,@jccdunitcost)),  
             @matlecm = isnull((case isnull(@overridecostopt,'')   
        when 'S' then @inmtstdecm  
              when 'A' then @inmtavgecm   
        when 'L' then @inmtlastecm end), isnull(@hqmtcostecm,@jccdecm))  
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
     
      end  /* End 'L' Opt */  
     
   bspexit:  
 select @MaterialRate= @matlrate-- left(convert(varchar(10),@matlrate)+ '0000000000' ,10)   
   return @MaterialRate  
  
 END  

GO
GRANT EXECUTE ON  [dbo].[vf_rptJBMatlRate] TO [public]
GO
