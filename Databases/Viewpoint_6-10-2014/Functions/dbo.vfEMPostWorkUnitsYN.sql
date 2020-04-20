SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[vfEMPostWorkUnitsYN]
(@emco bCompany = null, @emgroup bGroup = null, @equip bEquip = null, @category bCat = null, @revcode bRevCode = null,
	@jcco bCompany = null, @job bJob = null)
returns bYN
/***********************************************************
* CREATED BY	: TJL 12/06/06 - Issue #27979, 6x Recode EMUsePosting
* MODIFIED BY	
*
* USAGE:
* 	Returns PostWorksUnits Flag based upon a specific priority.
*
*
* INPUT PARAMETERS:
*
*
* OUTPUT PARAMETERS:
*	PostWorkUnitsYN
*
*****************************************************/
as
begin

declare @postworkunitsyn bYN, @allowrateorideyn bYN, @revtemp varchar(10), @revbasis char(1)

select @postworkunitsyn = 'Y'

/* Find the revenue code basis. */
select @revbasis = Basis
from EMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode

/****** Please Read  - See also vfEMAllowRateOverrideYN and vspEMUsePostingFlagsGet ******/
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
		/* RevTemplate exists. */
   		select @allowrateorideyn = AllowOrideFlag
   		from bEMTE with (nolock)
   		where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
			and Equipment = @equip  and RevCode = @revcode
   		if @@rowcount = 0
   			begin
			/* RevTemplate Exists but its NOT an EMRevRateEquip Template.  Check for EMRevRateCatgy Template.*/
   			select @allowrateorideyn = AllowOrideFlag
   			from bEMTC with (nolock)
   			where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
				and Category = @category  and RevCode = @revcode
			if @@rowcount = 0
				begin
				/* RevTemplate Exists but its NOT an EMRevRateCatgy Template. Continue on. */
				goto norevtemplate
				end
			else
				begin
				/* RevTemplate Exists and found to be an EMRevRateCatgy Template.  Get additional info. */
   				select @postworkunitsyn = PostWorkUnits 
   				from bEMRH with (nolock)
   				where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
   				if @@rowcount = 0
   					begin
   					select @postworkunitsyn = PostWorkUnits
   					from bEMRR with (nolock)
   					where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
   					goto exitfunction
   					end
   				else
					begin
   					goto exitfunction
					end
   				end
   			end
		else
			begin
			/* RevTemplate Exists and found to be an EMRevRateEquip Template.  Get additional info. */
			select @postworkunitsyn = PostWorkUnits 
			from bEMRH with (nolock)
			where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
			if @@rowcount = 0
				begin
				select @postworkunitsyn = PostWorkUnits
				from bEMRR with (nolock)
				where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
				goto exitfunction
				end
			else
				begin
				goto exitfunction
				end
			end
   		end
	end		
   
norevtemplate:   
/* Either the transtype is NOT (J)ob type OR there is no Rev Template setup OR there is no data setup
  in either the EMRevRateEquipTemp file or the EMRevRateCatgyTemp file for a given RevTemplate. */
select @postworkunitsyn = PostWorkUnits
from bEMRH with (nolock)
where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
if @@rowcount = 0
   	begin
	/* PostWorksUnits Flag NOT found in EMRevRateEquip file above.  Check EMRevRateCatgy. */
   	select @postworkunitsyn = PostWorkUnits
   	from bEMRR with (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
   	if @@rowcount = 0
   		begin
      	/* PostWorksUnits Flag NOT found in either EMRevRateEquip file or EMRevRateCatgy file above. */
		select @postworkunitsyn = case @revbasis when 'U' then 'Y' else 'N' end
   		end
   	end

exitfunction:
  			
return @postworkunitsyn
end

GO
GRANT EXECUTE ON  [dbo].[vfEMPostWorkUnitsYN] TO [public]
GO
