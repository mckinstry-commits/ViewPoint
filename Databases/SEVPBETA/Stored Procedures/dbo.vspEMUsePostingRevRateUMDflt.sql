SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspEMUsePostingRevRateUMDflt    Script Date:  ******/
CREATE proc [dbo].[vspEMUsePostingRevRateUMDflt]
/*************************************
*
* Created:	TJL 12/12/06 - Issue #27979, 6x Recode EMUsePosting form.  Based upon 5x proc bspEMRevRateUMDflt
* Modified: 
*
*
* Called from Validation of the RevCode and/or Job inputs
* Determines default revenue Rate and Time/Work UMs for maximum EMUsagePosting form performance.
*
* Pass:
*	EMCo
*	EMGroup
*	Equipment
*	EMTransType
*	Category
*	Revenue Code
*	JCCo
*	Job
*
* Success returns:
*	Rate from EMRC or the revenue override tables
*	TimeUM from EMRC or EMCO
*	WorkUM from EMRC or the revenue override tables
*
* Error returns:
*	1 and error message
**************************************/
(@emco bCompany, @emgroup bGroup,
	@equip bEquip = null, @category bCat = null, @revcode bRevCode = null, @jcco bCompany = null,
    @job bJob = null, @rate bDollar output, @timeum bUM output, @workum bUM = null output,
	@msg varchar(255) output)
  
as
set nocount on
   
declare @rcode int, @revtemp varchar(10), @discount bPct, @emrcworkum bUM, @typeflag char(1), @oriderate bYN
   
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
   
/* Find the base value for the units of measure */
select @timeum = null
select @timeum = TimeUM, @emrcworkum = WorkUM
from EMRC with (nolock)
where EMGroup = @emgroup and RevCode = @revcode
   
/* If TimeUm is null then the rev code is unit based but we still need the TimeUM so snag it from EMCo */
If @timeum is null
	begin
	select @timeum = HoursUM
	from EMCO with (nolock)
	where EMCo = @emco
	if @timeum is null
		begin
		select @msg = 'Hours unit of measure is not set up in company form.', @rcode = 1
		goto vspexit
		end
	end
   
if @jcco is not null and @job is not null
	begin
	/* If JCCo/Job exists in record, check to see if there is a RevTemplate set up for this job. */   
	select @revtemp = RevTemplate
	from EMJT with (nolock)
	where EMCo = @emco and JCCo = @jcco and Job = @job
   
	if @revtemp is not null
		begin
		select @typeflag = TypeFlag
		from EMTH with (nolock)
		where EMCo = @emco and RevTemplate = @revtemp
   
		/* RevTemplate exists.  Look for Rate and Discount value first in EMRevRateEquipTemp file and 
		   if not there, then go to the EMRevRateCatgyTemp file. */
   		select @rate = Rate, @discount = DiscFromStdRate
   		from EMTE with (nolock)
   		where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
			and Equipment = @equip  and RevCode = @revcode
   		if @@rowcount = 0
   			begin
			/* RevTemplate Exists but Rate and Discount value NOT found in EMRevRateEquipTemp file. */
   			select @rate = Rate, @discount = DiscFromStdRate
   			from EMTC with (nolock)
   			where EMCo = @emco and EMGroup = @emgroup and RevTemplate = @revtemp 
				and Category = @category and RevCode = @revcode
   			if @@rowcount = 0
				begin
				/* RevTemplate Exists but Rate and Discount value NOT found in EMRevRateCatgyTemp file. Continue on. */
				goto norevtemplate
				end
			end
   
		/* We've got a Rate to work with from RevTemplate files.  Now check for any discounts or overrides of
		   the rate and grab the UM if it is here.  If we do drop down into this section then the only place 
		   to go afterwards is vspexit. */
		if @typeflag = 'P'
			begin
			select @rate = Rate, @workum = WorkUM
			from EMRH with (nolock)
			where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip  and RevCode = @revcode and ORideRate = 'Y'
			if @@rowcount = 0
				begin
   				select @rate = Rate, @workum = WorkUM
   				from EMRR with (nolock)
   				where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
				if @@rowcount = 0
					begin
					select @msg = 'Revenue code ' + isnull(@revcode,'') + ' invalid for category ' + isnull(@category,''), @rcode = 1
					goto vspexit
					end
        		else 
					/* Dound in EMRR */
					begin
					select @rate = @rate * @discount
					end
				end
			else 
				/* Found in EMRH */
				begin
				select @rate = @rate * @discount
				end
			end
   
		/* For Over ride type templates, keep the rate that was found in either the equip or catgy template table
		   but still go back to the base equip and catgy tables in search of a UM */
		if @typeflag = 'O'
			begin
			select @workum = WorkUM
			from EMRH with (nolock)
			where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
			if @@rowcount = 0
				begin
				select @workum = WorkUM
				from EMRR with (nolock)
				where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
				if @@rowcount = 0
					begin
   					select @msg = 'Revenue code ' + isnull(@revcode,'') + ' invalid for category ' + isnull(@category,''), @rcode = 1
   					goto vspexit
   					end
				end
			end

		/* Skip over the norevtemplate code */
		goto vspexit
		end 
	end

norevtemplate:
/* Either the transtype is NOT (J)ob type OR there is no Rev Template setup OR there is no data setup
  in either the EMRevRateEquipTemp file or the EMRevRateCatgyTemp file for a given RevTemplate. */ 
select @oriderate = null
select 	@oriderate = ORideRate, @workum = WorkUM
from EMRH with (nolock)
where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
if @oriderate is not null
	begin
	if @oriderate = 'Y'
		begin
		select @rate = Rate
		from EMRH with (nolock)
		where EMCo = @emco and EMGroup = @emgroup and Equipment = @equip and RevCode = @revcode
		end
	if @oriderate = 'N'
		begin
		select @category = Category
		from EMEM with (nolock)
		where EMCo = @emco and Equipment = @equip
   
		select @rate = Rate
		from EMRR with (nolock)
		where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
		end
     end
else
	/* @oriderate = null meaning no record is in EMRH */
   	begin
   	select 	@rate = Rate, @workum = WorkUM
   	from EMRR with (nolock)
   	where EMCo = @emco and EMGroup = @emgroup and Category = @category and RevCode = @revcode
   	if @@rowcount = 0
		/* Nothing set up in Catgy or Equip revenue codes */
		begin
		/* No overrides exist for this revenue code. */
		-- select @rate = 0, @workum = @emrcworkum
		select @msg = 'Revenue code ' + isnull(@revcode,'') + ' is not set up for category ' + isnull(@category,''), @rcode = 1
		goto vspexit
		end
	end
   
vspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMUsePostingRevRateUMDflt] TO [public]
GO
