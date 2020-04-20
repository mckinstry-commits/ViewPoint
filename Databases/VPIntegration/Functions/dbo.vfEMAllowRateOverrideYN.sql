SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfEMAllowRateOverrideYN]
(@emco bCompany = null, @emgroup bGroup = null, @equip bEquip = null, @category bCat = null, @revcode bRevCode = null,
	@jcco bCompany = null, @job bJob = null)
returns bYN
/***********************************************************
* CREATED BY	: TJL 12/06/06 - Issue #27979, 6x Recode EMUsePosting
* MODIFIED BY	
*
* USAGE:
* 	Returns Rate Override Flag based upon a specific priority.
*
*
* INPUT PARAMETERS:
*
*
* OUTPUT PARAMETERS:
*	AllowRateOverrideYN
*
*****************************************************/
as
begin

declare @allowrateorideyn bYN, @revtemp varchar(10)

select @allowrateorideyn = 'Y'

/****** Please Read  - See also vfEMPostWorkUnitsYN and vspEMUsePostingFlagsGet ******/
/* The structure below may appear redundant.  It has been left this way (from 5x) to allow some
   flexibility in the event that a specific combination requires a different outcome.  This 
   validation is occurring in EMUsePosting under a variety of possible conditions.  (Values
   exist or not depending on  add mode, change mode etc.)  The combinations are endless. 
   There may be specific outcomes yet untested that may need to be adjusted and this structure
   will allow it and minimize the possibility of breaking something.  DO NOT change the
   structure unless you are absolutely sure and are willing to test countless conditions. */

if @jcco is not null and @job is not null
	begin
	/* If JCCo/Job exists in record, check to see if there is a RevTemplate set up for this job. */
	select @revtemp = min(RevTemplate)
	from bEMJT with (nolock)
	where EMCo = @emco and JCCo = @jcco and Job = @job
   
	if @revtemp is not null
   		begin
		/* RevTemplate exists.  Look for Rate Override Flag first in EMRevRateEquipTemp file and 
		   if not there, then go to the EMRevRateCatgyTemp file. */
   		select @allowrateorideyn = AllowOrideFlag
   		from bEMTE with (nolock)
   		where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
			and Equipment = @equip  and RevCode = @revcode
   		if @@rowcount = 0
   			begin
			/* RevTemplate Exists but Rate Override Flag NOT found in EMRevRateEquipTemp file. */
   			select @allowrateorideyn = AllowOrideFlag
   			from bEMTC with (nolock)
   			where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
				and Category = @category  and RevCode = @revcode
			if @@rowcount = 0
				begin
				/* RevTemplate Exists but Rate Override Flag NOT found in EMRevRateCatgyTemp file. Continue on. */
				goto norevtemplate
				end
			else
				begin
				/* RevTemplate Exists and Rate Override Flag retrieved from EMRevRateCatgyTemp file. */
				goto exitfunction
				end
   			end
		else
			begin
			/* RevTemplate Exists and Rate Override Flag retrieved from EMRevRateEquipTemp file. */
			goto exitfunction
			end
   		end
	end		
   
norevtemplate:   
/* Either the transtype is NOT (J)ob type OR there is no Rev Template setup OR there is no data setup
  in either the EMRevRateEquipTemp file or the EMRevRateCatgyTemp file for a given RevTemplate. */
select @allowrateorideyn = AllowPostOride
from bEMRH with (nolock)
where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
if @@rowcount = 0
   	begin
	/* Rate Override Flag NOT found in EMRevRateEquip file above.  Check EMRevRateCatgy. */
   	select @allowrateorideyn = AllowPostOride
   	from bEMRR with (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
   	if @@rowcount = 0
   		begin
      	/* Rate Override Flag NOT found in either EMRevRateEquip file or EMRevRateCatgy file above. Check EMCO. */
		select @allowrateorideyn = UseRateOride
   		from bEMCO with (nolock)
   		where EMCo = @emco and EMGroup = @emgroup
   		end
   	end

exitfunction:
  			
return @allowrateorideyn
end

GO
GRANT EXECUTE ON  [dbo].[vfEMAllowRateOverrideYN] TO [public]
GO
