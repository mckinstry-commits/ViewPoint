SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetEquipRate    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMGetEquipRate]
   /***********************************************************
   * CREATED BY	: kb 5/10/00
   * MODIFIED BY	: kb 4/12/01 - added error if no equip rate found
   *		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL	01/22/04 - Issue #23561, Correct the Sequence in which bJBER is evaluated
   *		TJL 06/11/04 - Issue #24809, Related to problem induced by Issue #24304. Set @equiprate = null
   *		TJL 08/10/04 - Issue #25341, EMGroup Not valid when JBER Rate not based upon specific Equip or RevCode
   *		TJL 12/07/04 - Issue #26392, EMGroup only valid when JBER Rate is based upon a specific RevCode (RevCode not null)
   *		TJL 01/10/05 - Issue #17896, Add EffectiveDate to JBTM and NewRate/NewSpecificPrice to JBLR, JBLO, JBER, JBMO
   *
   * USED IN:
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany, /*@jccdmth bMonth, @jccdtrans bTrans,*/ @source char(2), 
   	@template varchar(10), @category varchar(10) = null, @emco bCompany = null, 
   	@emgroup bGroup = null, @equip bEquip = null, @revcode bRevCode = null,
   	@actualdate bDate, @effectivedate bDate, @rateopt char(1) output, @equiprate bUnitCost output, 
   	@HrsPerTimeUM bHrs output, @msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @overriderate bUnitCost, @overriderateopt char(1), @newequiprate bUnitCost
   
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
   where JBCo = @co and Template = @template and EMCo = @emco /*and EMGroup = @emgroup*/ and EquipCategory = @category 
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
   where JBCo = @co and Template = @template and EMCo = @emco /*and EMGroup = @emgroup*/ and EquipCategory = @category 
   	and Equipment is null 
   	and RevCode is null
   if @@rowcount <> 0 goto bspexit
   
   bspexit:
   select @HrsPerTimeUM = HrsPerTimeUM 
   from bEMRC with (nolock) 
   where EMGroup = @emgroup and RevCode = @revcode
   
   /* Determine whether to use OldRate or NewRate */
   if isnull(@actualdate, '1900-01-01') >= isnull(@effectivedate, '1900-01-01') select @equiprate = isnull(@newequiprate, @equiprate)
   if @equiprate is null select @rcode = 1, @msg = 'Equip rate not found'
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetEquipRate] TO [public]
GO
