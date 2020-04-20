SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBTMEffectiveDates]
   /***********************************************************
   * CREATED BY:	TJL 01/31/05 - Issue #17896
   * MODIFIED By : TJL 02/16/05 - Issue #27135, Error when JBTMBillLines form first opens if EffectDates are Null
   *
   * USAGE:
   *
   * INPUT PARAMETERS
   *   JBCo		JB Co to validate against
   *	Template	Template in use for JBTMBill
   *
   * OUTPUT PARAMETERS
   *   @msg      error message if error occurs otherwise Description of Contract
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   @jbco bCompany = 0, @template varchar(10), @laboreffectivedate bDate output, @equipeffectivedate bDate output,
   	@matleffectivedate bDate output, @msg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int
   select @rcode = 0
   
   if @jbco is null
   	begin
   	select @msg = 'Missing JB Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @template is null
   	begin
   	select @msg = 'Missing template!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get Effective Dates for this Template */
   select @laboreffectivedate = isnull(LaborEffectiveDate, '1900-01-01'), @equipeffectivedate = isnull(EquipEffectiveDate, '1900-01-01'),
   	@matleffectivedate = isnull(MatlEffectiveDate, '1900-01-01')
   from bJBTM with (Nolock)
   where JBCo = @jbco and Template = @template
   if @@rowcount = 0
   	begin
   	select @msg = 'Template not on file. Cannot retrieve Rate Effective Dates.', @rcode = 1
   	goto bspexit
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTMEffectiveDates] TO [public]
GO
