SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMUsePostingFlagsGet    Script Date: ******/
CREATE proc [dbo].[vspEMUsePostingFlagsGet]
/*************************************
*
* Created:	TJL 12/07/06 - Issue #27979, 6x Recode EMUsePosting.  Streamlined version of bspEMUsageFlagsGet
* Modified:	
*
* Called from Validation of the RevCode and/or Job inputs
* Returns flags that are vital to maximum EMUsagePosting form performance.
*
* Pass:
*	EMCo
*	EMGroup
*	Equipment
*	Category
*	Revenue Code
*	JCCo (optional)
*	Job  (optional)
*
* Success returns:
*	Post Work Units with Usage flag.  Which can be derived from several tables.
*	Allow Posting Override.  Also a flag determined after a multi table search.
*	Basis from EMRC
*	HrsPerTimeUM from EMRC
*
* Error returns:
*	1 and error message
**************************************/
(@emco bCompany, @emgroup bGroup,@equip bEquip = null, @category bCat = null, @revcode bRevCode = null, 
@jcco bCompany = null,@job bJob = null, @postworkunits bYN output, @allowrateoride bYN = null output,
@revbasis char(1) = null output, @hrfactor bHrs = null output,@updatehrs bYN = null output, @msg varchar(255) output)

as

set nocount on

declare @rcode int, @revtemp varchar(10)

select @rcode = 0
   
if @emco is null
begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto vspexit
end
if @emgroup is null
begin
	select @msg = 'Missing EM Group.', @rcode = 1
	goto vspexit
end
if @equip is null
begin
select @msg = 'Missing Equipment.', @rcode = 1
	goto vspexit
end
if @revcode is null
begin
	select @msg = 'Missing Revenue Code.', @rcode = 1
	goto vspexit
end
   
/*1.  Get Revenue Code setup info */
--Form EM Revenue Codes
select @revbasis = Basis, @hrfactor = HrsPerTimeUM, @updatehrs = UpdateHourMeter 
from dbo.EMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode

/****** Please Read  - See also vfEMPostWorkUnitsYN and vfEMAllowRateOverrideYN ******
The structure below may appear redundant.  It has been left this way (from 5x) to allow some
flexibility in the event that a specific combination requires a different outcome.  This 
validation is occurring in EMUsePosting under a variety of possible conditions.  (Values
exist or not depending on  add mode, change mode etc.)  The combinations are endless. 
There may be specific outcomes yet untested that may need to be adjusted and this structure
will allow it and minimize the possibility of breaking something.  DO NOT change the
structure unless you are absolutely sure and are willing to test countless conditions. */

/*2.  Verify JCCo and Job have values before checking 
Form: EM Job (Usage) Revenue Templates overrides by 2. Equipment and 1. Category
5.x  Job Rev Template Category records need to exist be Job Rev Template Equipment overrides could be entered*/
if @jcco is not null and isnull(@job,'') <> ''
begin
	/*3. If JCCo/Job exists in record, then check to see if the Job is using a Rev Template */
	--Form:  EM Job Templates
	select @revtemp = min(RevTemplate)	
	from dbo.EMJT with (nolock)
	where EMCo = @emco and JCCo = @jcco and Job = @job
	
	If isnull(@revtemp,'')<>''
	Begin 
		/*4. JCCo/Job RevTemplate exists.  Look for Rate Override Flag first in EMRevRateEquipTemplate
		and if not there, then go to the EMRevRateCatgyTemp file. */
		--Parent Form:  EM Revenue Template,  
		--Child/Related Form:  EM Rev Rate by Equipment Template
		select @allowrateoride = AllowOrideFlag	
		from dbo.EMTE with (nolock)
		where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
		and Equipment = @equip  and RevCode = @revcode
		if @@rowcount = 1
			begin
				/*When Revenue Template Equipment Override record exists, 
				get Revenue Code info from 1: Equipment (EMRH), 2: Category (EMRR)*/
				goto RevCodeInfoCategoryEquipment
			end
		else
			begin 
				/*5.  JCCo/Job RevTemplate Exists Look for Rate Override Flag first in EMRevRateCategoryTemplate
				***Rate Override Flag NOT found in EMRevRateEquipTemp file. */
				--Parent Form:  EM Revenue Template,  
				--Child/Related Form:  EM Rev Rate by Category Template
				select @allowrateoride = AllowOrideFlag
				from dbo.EMTC with (nolock)
				where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
				and Category = @category  and RevCode = @revcode
				if @@rowcount = 1
					begin
						/*When Revenue Template Equipment Override record exists, 
						get Revenue Code info from 1: Equipment (EMRH), 2: Category (EMRR)*/
						goto RevCodeInfoCategoryEquipment
					end
				else
					begin
						/*When no Revenue Template Category/Equipment override records exists*/
						goto NoRevenueTemplate
					end
			end
		
		RevCodeInfoCategoryEquipment:
		/*6. 1) Equipment Rev Template override exists get Rate Override Flag 
			  2) now get overrides from Equipment and Rev Code. */
		--Form: EM Rev Rates by Equipment
		select @postworkunits = PostWorkUnits, @updatehrs = UpdtHrMeter 
		from dbo.EMRH with (nolock)
		where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip  and RevCode = @revcode
		if @@rowcount = 1
			begin
				goto vspexit
			end
		else
			begin 
				/*7. If no Rev Rate by Equipment reord exists, deault to Equipment's Category Revenue Code/Rate record*/
				--Form EM Rev Rates by Category
				select @postworkunits = PostWorkUnits, @updatehrs = UpdtHrMeter
				from dbo.EMRR with (nolock)
				where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
				if @@rowcount = 1
					begin
						goto vspexit
					end
				else
					begin
						/*Return error when no Revenue Rates by Category and/or Equipment  records exists
						 Rate Override Flag NOT found in either EM Rev Rates by Equip (EMRH) or  EM Rev Rate Catgory (EMMR)
						Record will not be saved */
						select @msg = 'Revenue code ' + isnull(@revcode,'') + ' has not set up in EM Rev Rates by Category or Equipment  forms.', @rcode = 1
						goto vspexit
					end
			end
	End 
END

NoRevenueTemplate:
/*8. (1) the transtype is NOT (J)ob type 
	  (2) there is no Rev Template setup for Equipment or Category
	  (3) there is no data setup in either  EM Rev Rates by Equip (EMRH) or  EM Rev Rate Catgory (EMMR). */ 
select 	@allowrateoride = AllowPostOride, @postworkunits = PostWorkUnits, @updatehrs = UpdtHrMeter
from dbo.EMRH with (nolock) 
where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
if @@rowcount = 0
begin
	/* 9. Rate Override Flag and other info NOT found in EMRevRateEquip file above.  Check EMRevRateCatgy. */
   	select @allowrateoride = AllowPostOride, @postworkunits = PostWorkUnits, @updatehrs = UpdtHrMeter
   	from dbo.EMRR with (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and Category = @category  and RevCode = @revcode
   	if @@rowcount = 0
	begin
		/*Return error when no Revenue Rates by Category and/or Equipment  records exists
		Rate Override Flag NOT found in either EM Rev Rates by Equip (EMRH) or  EM Rev Rate Catgory (EMMR)
		Record will not be saved */
		select @msg = 'Revenue code ' + isnull(@revcode,'') + ' has not set up in EM Rev Rates by Category or Equipment  forms.', @rcode = 1
		goto vspexit
   	end
end

vspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingFlagsGet] TO [public]
GO
