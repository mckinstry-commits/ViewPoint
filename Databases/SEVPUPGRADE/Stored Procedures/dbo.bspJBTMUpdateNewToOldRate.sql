SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTMUpdateEffectiveDate Script Date: 01/10/05 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTMUpdateNewToOldRate]
   /********************************************************************************************************
   * CREATED BY:	TJL 01/14/05 - Issue #17896, Update JBLR, JBLO, JBER, JBMO NewRate to OldRate
   * MODIFIED BY:  TJL 09/28/06 - Issue #28221, 6X recode.  Add space between SpecificPrice in errmsg
   *
   *
   * USED IN:
   *	JBTemplateLaborRates Form
   *	JBTemplateLaborRateOver Form
   *	JBTemplateEquipRates Form
   *	JBTempMatOverrides Form
   *
   * USAGE:
   *	Called in each of these forms from a File/Menu option.  When called it will copy NewRates
   *	from its respective table to OldRate column in same table and will leave the NewRate
   *	value as it was.  Users do this in preparation of entering a new EffectiveDate and New Rates.
   *
   *
   * INPUT PARAMETERS
   *	@jbco			JB Company
   *	@template		JB Template
   *	@ratetype		Rate Type:  Labor, Equip, Matl
   *	
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *********************************************************************************************************/
    
   (@jbco bCompany, @template varchar(10), @ratetype char(1), @msg varchar(275) output)
   
   as
   
   set nocount on
   
   declare	@rcode int
   
   select @rcode = 0
   
   if @jbco is null
   	begin
   	select @msg = 'JB Company missing.', @rcode = 1
   	goto bspexit
   	end
   if @template is null
   	begin
   	select @msg = 'Template missing.', @rcode = 1
   	goto bspexit
   	end
   if @ratetype is null
   	begin
   	select @msg = 'Rate Type missing, cannot determine table to update.', @rcode = 1
   	goto bspexit
   	end
   
   /* Begin update */
   /* Labor: Update Labor Rates New To Old. */
   if @ratetype = 'L'
   	begin
   	update bJBLR
   	set Rate = NewRate
   	where JBCo = @jbco and Template = @template
   	if @@rowcount = 0
   		begin
   		select @msg = 'New Labor Rates were not copied to Old Rates.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   /* Labor Overrides:  Update LaborOverride Rates New To Old. */
   if @ratetype = 'O'
   	begin
   	update bJBLO
   	set Rate = NewRate
   	where JBCo = @jbco and Template = @template
   	if @@rowcount = 0
   		begin
   		select @msg = 'New Labor Rate Overrides were not copied to Old Rates.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   /* Equipment: Update Equip Rates New to Old. */
   if @ratetype = 'E'
   	begin
   	update bJBER
   	set Rate = NewRate
   	where JBCo = @jbco and Template = @template
   	if @@rowcount = 0
   		begin
   		select @msg = 'New Equipment Rates were not copied to Old Rates.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   /* Material: Update Material Rates New to Old. */
   if @ratetype = 'M'
   	begin
   	update bJBMO
   	set SpecificPrice = NewSpecificPrice
   	where JBCo = @jbco and Template = @template
   	if @@rowcount = 0
   		begin
   		select @msg = 'New Specific Price was not copied to Old Specific Price.', @rcode = 1
   		goto bspexit
   		end
   	end
   
   bspexit:
   
   if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[bspJBTMUpdateNewToOldRate]'
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTMUpdateNewToOldRate] TO [public]
GO
