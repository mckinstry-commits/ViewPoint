SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  FUNCTION    [dbo].[vf_rptJBEquipRate]
  	(@co bCompany, 
   	@template varchar(10), @category varchar(10) = null, @emco bCompany = null, 
   	@emgroup bGroup = null, @equip bEquip = null, @revcode bRevCode = null,
   	@actualdate bDate, @effectivedate bDate)

RETURNS char(12)
AS
BEGIN

   
   declare @rcode int, @overriderate bUnitCost, @overriderateopt char(1), @newequiprate bUnitCost,@RateAndOpt char(20),
	@rateopt char(1), @equiprate bUnitCost, 
   	@HrsPerTimeUM bHrs 
   
   select @rcode = 0, @equiprate = null, @newequiprate = null, @rateopt = null
   
   /* Determine Equipment Rate and Rate Opt.  
      @co, @template, @emco, @emgroup (bEMCO), @category (bEMEM) will never be NULL */
   select @equiprate = Rate, @newequiprate = NewRate, @rateopt = RateOpt 
   from bJBER with (nolock)				-- EMGroup only valid when Rate based on a specific RevCode 
   where JBCo = @co and Template = @template and EMCo = @emco and EMGroup = @emgroup and EquipCategory = @category	--Required
   	and Equipment = @equip  
   	and RevCode = @revcode
   if @@rowcount <> 0 goto bspexit
   
   select @equiprate = Rate, @newequiprate = NewRate, @rateopt = RateOpt 
   from bJBER with (nolock)				-- EMGroup only valid when Rate based on a specific RevCode 
   where JBCo = @co and Template = @template and EMCo = @emco  and EquipCategory = @category 
   	and Equipment = @equip 
   	and RevCode is null
   if @@rowcount <> 0 goto bspexit
   
   select @equiprate = Rate, @newequiprate = NewRate, @rateopt = RateOpt 
   from bJBER with (nolock)				-- EMGroup only valid when Rate based on a specific RevCode 
   where JBCo = @co and Template = @template and EMCo = @emco and EMGroup = @emgroup and EquipCategory = @category
   	and Equipment is null  
   	and RevCode = @revcode
   if @@rowcount <> 0 goto bspexit
   
   select @equiprate = Rate, @newequiprate = NewRate, @rateopt = RateOpt 
   from bJBER with (nolock)				-- EMGroup only valid when Rate based on a specific RevCode 
   where JBCo = @co and Template = @template and EMCo = @emco and EquipCategory = @category 
   	and Equipment is null 
   	and RevCode is null
   if @@rowcount <> 0 goto bspexit
   
   bspexit:
   select @HrsPerTimeUM = HrsPerTimeUM 
   from bEMRC with (nolock) 
   where EMGroup = @emgroup and RevCode = @revcode
   
   /* Determine whether to use OldRate or NewRate */
   if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01') select @equiprate = isnull(@newequiprate, @equiprate)

select @RateAndOpt=left(convert(varchar(10),@equiprate)+ '0000000000' ,10) + ' ' +@rateopt
--------------------------------------------------------------------------------------------------------------------------------------------------
   RETURN( @RateAndOpt)

END

GO
GRANT EXECUTE ON  [dbo].[vf_rptJBEquipRate] TO [public]
GO
