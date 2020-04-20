SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRevCodeTempVal    Script Date: 8/28/99 9:32:43 AM ******/
CREATE proc [dbo].[bspEMRevCodeTempVal]
   
/******************************************************
* Created By:  bc  08/28/98
* Modified by: bc  05/09/00    added output parameter AllowPostOride
*		TV 02/11/04 - 23061 added isnulls
*		TJL 11/08/06 - Issue #27973, 6x Rewrite.  Add check to EMRH.AllowPostOverride before using EMRH.Rate
*
* Usage:
* Validates Revenue code from EMRC.
* and returns flag and default information
*
*
* Input Parameters
*
*	EMCo		Need company to retreive Allow posting override flag
* 	EMGroup		EM group for this company
*	Revtemplate	EM template
*	Category	Null if being called from the equipment template
*	Equipment	Null if being called from the category template
*	RevCode		Revenue code to validate
*
* Output Parameters
*	UseRateOride	From EMCo
*	std_rate	taken from EMRR for category rev codes or EMRC for equipment temp rev codes
*	units		defaulted from EMRC
*	@msg		The RevCode description.  Error message when appropriate.
*
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(@emco bCompany, @EMGroup bGroup, @template varchar(10), @catgy bCat = null, @equip bEquip = null,
@RevCode bRevCode, @UseRateOride bYN output, @std_rate bDollar output, @units int output,
@allowpostoride bYN output, @msg varchar(255) output)
   
as
set nocount on
declare @rcode int, @emrhrate bDollar, @emrrrate bDollar, @emrhoriderateyn bYN
select @rcode = 0, @std_rate = 0, @emrhrate = 0, @emrrrate = 0
select @UseRateOride = 'Y', @allowpostoride = 'N', @emrhoriderateyn = 'N'
   
if @emco is null
	begin
	select @msg= 'Missing Company.', @rcode = 1
	goto bspexit
	end

if @RevCode is null
	begin
	select @msg= 'Missing Revenue Code.', @rcode = 1
	goto bspexit
	end

/* Get misc values. */
select @UseRateOride = UseRateOride		--AllowPosting Flag
from bEMCO with (nolock)
where EMCo = @emco

/* Validate existence of RevCode. */
select @msg= Description, @units = HrsPerTimeUM
from bEMRC with (nolock)
where EMGroup = @EMGroup and RevCode = @RevCode
if @@rowcount = 0
	begin
	select @msg = 'Revenue Code not set up.', @rcode = 1
	goto bspexit
	end

/* Rate By Category */   
if @catgy is not null
   	begin
   	select @emrrrate = Rate
   	from bEMRR with (nolock)
   	where EMCo = @emco and EMGroup = @EMGroup and Category = @catgy and RevCode = @RevCode
   	if @@rowcount = 0
   		begin
   		select @msg = 'Revenue Code not set up in Rev Rate by Catgy form.', @rcode = 1
   		goto bspexit
   		end

	select @std_rate = @emrrrate
	goto bspexit
   	end
   
/* Rate By Equipment */
if @equip is not null
   	begin
   	select @catgy = Category
   	from bEMEM with (nolock)
   	where EMCo = @emco and Equipment = @equip
   
   	select @emrhrate = Rate, @allowpostoride = AllowPostOride, @emrhoriderateyn = ORideRate
   	from bEMRH with (nolock)
   	where EMCo = @emco and EMGroup = @EMGroup and Equipment = @equip and RevCode = @RevCode
   	if @@rowcount = 0
   		begin
		/* There are no Records in EMRH.  Only option is to use Rate from EMRR if present. */
   	    select @emrrrate = Rate, @allowpostoride = AllowPostOride
   	    from bEMRR	with (nolock)
   	    where EMCo = @emco and EMGroup = @EMGroup and Category = @catgy and RevCode = @RevCode
        if @@rowcount = 0
			begin
   			select @msg = 'Revenue code not set up in Rev Rate by Catgy form.  Category: ' + @catgy, @rcode = 1
			select @std_rate = 0
   			goto bspexit
   			end

		select @std_rate = @emrrrate
		goto bspexit
		end
	else
		begin
		/* EMRH rate does exist but further evaluation is necessary. */
		if @emrhoriderateyn = 'Y'
			begin
			/* OK to use EMRH rate. */
			select @std_rate = @emrhrate
			goto bspexit
			end
		else
			begin
			/* Not OK to use EMRH rate.  Go get EMRR rate if present. */
   			select @emrrrate = Rate, @allowpostoride = AllowPostOride
   			from bEMRR	with (nolock)
   			where EMCo = @emco and EMGroup = @EMGroup and Category = @catgy and RevCode = @RevCode
			if @@rowcount = 0
				begin
   				select @msg = 'Revenue code not set up in Rev Rate by Catgy form.  Category: ' + @catgy, @rcode = 1
				select @std_rate = 0
   				goto bspexit
   				end
	
			select @std_rate = @emrrrate
			goto bspexit
			end
		end
	end
   
bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRevCodeTempVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevCodeTempVal] TO [public]
GO
