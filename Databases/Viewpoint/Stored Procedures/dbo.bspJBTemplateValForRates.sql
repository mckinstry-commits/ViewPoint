SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBTemplateValForRates]
/**********************************************************************************************
 * CREATED BY: kb 9/15/00
 * MODIFIED By:  TJL 01/13/06 - Issue #28224, Return EffectiveDate back to all Rate setup forms.
 *		TJL 04/24/06 - Issue #28215, 6x Rewrite.  Remove "Template not using Rates" error.
 *
 * USAGE:
 *
 * INPUT PARAMETERS
 *   JBCo      JB Co to validate against
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description of Contract
 * RETURN VALUE
 *   0         success
 *   1         Failure
 ***********************************************************************************************/
   
@jbco bCompany = 0, @template varchar(10), @source varchar(2), @rateeffectivedate bDate = null output,
	@msg varchar(255) output

as
set nocount on
   
declare @rcode int, @laborrateopt char(1), @laborrateoveryn bYN,
	@equiprateopt char(1), @laborcatyn bYN , @equipcatyn bYN,
	@matlcatyn bYN, @miscdistyn bYN, @laborrateeffdate bDate, @equiprateeffdate bDate,
	@matlrateeffdate bDate
   
select @rcode = 0

/* Standard Template Validation - If Template does not exist, user may not create Rate table entries. */  
exec @rcode = bspJBTemplateVal @jbco, @template, @laborrateopt output,
	@laborrateoveryn output, @equiprateopt output, @laborcatyn output, @equipcatyn output,
	@matlcatyn output, @miscdistyn output, @msg output

if @rcode = 0
	/* Template is valid. */
	begin
	/* If Template does not allow use of Rates, user may not setup Rate table entries. */
--	if @source in ('L','LO')and @laborrateopt <> 'R'
--	   begin
--	   select @msg = 'Template does not allow labor rates.', @rcode =1
--	   goto bspexit
--	   end
--	if @source = 'LO' and @laborrateoveryn='N'
--	   begin
--	   select @msg = 'Template does not allow labor rate overrides.', @rcode = 1
--	   goto bspexit
--	   end
--	if @source = 'E' and @equiprateopt not in ('T','R')
--	   begin
--	   select @msg = 'Template does not allow equip rates.', @rcode =1
--	   goto bspexit
--	   end

	/* The Template selected by user validates OK.  Go ahead and retrieve New Rate EffectiveDate
	   relative to this form.  Decided to place code in this routine (instead of bspJBTemplateVal)
	   since this routine has limited use by only the four Rate setup forms. */
	select @laborrateeffdate = LaborEffectiveDate, @equiprateeffdate = EquipEffectiveDate,
		@matlrateeffdate = MatlEffectiveDate
	from bJBTM with (nolock)
	where JBCo = @jbco and Template = @template
	if isnull(@@rowcount, 0) <> 0
		begin
		if @source in ('L', 'LO') select @rateeffectivedate = @laborrateeffdate
		if @source in ('E') select @rateeffectivedate = @equiprateeffdate
		if @source in ('M') select @rateeffectivedate = @matlrateeffdate
		end
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTemplateValForRates] TO [public]
GO
