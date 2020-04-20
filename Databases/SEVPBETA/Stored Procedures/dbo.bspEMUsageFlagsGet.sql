SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMUsageFlagsGet    Script Date: 8/28/99 9:36:14 AM ******/
 CREATE       proc [dbo].[bspEMUsageFlagsGet]
 /*************************************
 *
 * Created:	12/21/98 bc
 * Modified:	05/06/99 bc - throws error msg now if no revcodes are set up by cat or equip
 *           		09/19/00 bc - added updatehrs to the output parameters
 * 		JM 10-22-02 - Ref Issue 19850 - Need to look first in EMRH for Rev Rate by Equip, then in EMHH for RR by Catgy 
 *		TV 02/11/04 - 23061 added isnulls
 *		TV 03/29/04 - 24167 Look in EMRH and EMRR for update hours override.
 *		TV 10/27/05 - 5x Issue 30196, Ws skipping the flags  (I don't see related 6x Issue, TJL 12/08/06)
 * Validates the revenue code and/or job inputs
 * Returns flags that are vital to maximum EMUsagePosting form performance.
 *
 * Pass:
 *	EMCo
 *	EMGroup
 *	Equipment
 *	Category
 *	Revenue Code
 *	EMTransType
 *	JCCo (optional)
 *	Job  (optional)
 *
 * Success returns:
 *	Post Work Units with Usage flag.  Which can be derived from several tables.
 *	Allow Posting Override.  Also a flag determined after a multi table search.
 *	Basis from EMRC
 *	HrsPerTimeUM from EMRC
 *	LockPhases
 *      	The descriptions for the valid revenue code and job
 *
 * Error returns:
 *	1 and error message
 **************************************/
 (@emco bCompany, @emgroup bGroup, @transtype varchar(10) = null,
  @equip bEquip = null, @category bCat = null, @revcode bRevCode = null, @jcco bCompany = null,
  @job bJob = null, @post_work_units bYN output, @allow_rate_oride bYN = null output,
  @rev_basis char(1) = null output, @hrfactor bHrs = null output, @lockphases bYN = null output, @rev_msg varchar(60) = null output,
  @job_msg varchar(60) = null output, @updatehrs bYN = null output, @msg varchar(255) output)
 as
 	set nocount on
 	declare @rcode int, @cnt int, @errmsg varchar(60)
 	declare @revtemp varchar(10)
 	select @rcode = 0, @cnt = 0
 
 
 if @emco is null
 	begin
 	select @msg = 'Invalid EM Company.', @rcode = 1
 	goto bspexit
 	end
 
 if @emgroup is null
 	begin
 	select @msg = 'Invalid EM Group.', @rcode = 1
 	goto bspexit
 	end
 
 if @transtype not in ('J','E','X','W')
 	begin
 	select @msg = 'Invalid transaction type.', @rcode = 1
 	goto bspexit
 	end
 
 if @equip is null
 	begin
 	select @msg = 'Please enter a piece of equipment prior to Rev Code or Job inputs.', @rcode = 1
 	goto bspexit
 	end
 
 /* find the revenue code basis */
 select @rev_basis = Basis, @hrfactor = HrsPerTimeUM, @rev_msg = Description, @updatehrs = UpdateHourMeter
 from bEMRC
 where EMGroup = @emgroup and RevCode = @revcode
 
 if @rev_basis is null
 	begin
 	select @msg = 'Revenue Code is invalid!', @rcode = 1
 	goto bspexit
 	end
 
 if @transtype = 'J'
 Begin
 
   /* Only drop down into the Job code once the job information has been filled out.
      Needed to put in the quote quote check because this routine is called in DDFI for both
      the revcode and job inputs, making the situation unique.  If they we not so co-dependent
      upon each other i would have passed in the value 'null' from the revcode DDFI for jcco and job */

   if @jcco is null or @job is null or @job = '' goto end_job_val--bspexit TV 10/27/05 30196
 
   exec @rcode = bspJCJMPostVal @jcco, @job, @lockphases = @lockphases output, @msg=@job_msg output
 
   if @rcode <> 0
     begin
     select @msg = @job_msg
     goto bspexit
     end
 
   /* Check to see if there is a template set up for this job */
   select @revtemp = min(RevTemplate)
   from bEMJT
   where EMCo = @emco and JCCo = @jcco and Job = @job
 
   if @revtemp is not null
 	begin
 	Select @allow_rate_oride = AllowOrideFlag
 	from bEMTE
 	where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
 
 	if @@rowcount = 0
 		begin
 		  Select @allow_rate_oride = AllowOrideFlag
 		  from bEMTC
 		  where EMCo = @emco and RevTemplate = @revtemp and Category = @category and EMGroup = @emgroup and RevCode = @revcode
 		  /* if cnt <> 0 then it was found in EMTC */
 		  if @@rowcount <> 0
 			begin
 			/* JM 10-22-02 - Ref Issue 19850 - Need to look first in EMRH for Rev Rate by Equip, then in EMHH for RR by Catgy */
 			select @post_work_units = PostWorkUnits, @updatehrs = UpdtHrMeter 
 			from bEMRH
 			where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
 			if @@rowcount = 0
 				begin
 				select @post_work_units = PostWorkUnits, @updatehrs = UpdtHrMeter
 			    from bEMRR
 				where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
 				goto bspexit
 				end
 			else
 				goto bspexit
 			end
 		end
 		/* found in EMTE */
 		else
 		  begin
 		  select @post_work_units = PostWorkUnits, @updatehrs = UpdtHrMeter
 		  from bEMRH
 		  where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
 		  goto bspexit
 		  end
 	end
end_job_val:
 End
 
 
 /* Either the trans type <> (J)ob or there is no template set up
    or there is no data below the template header */
 select 	@allow_rate_oride = AllowPostOride, @post_work_units = PostWorkUnits, @updatehrs = UpdtHrMeter
 from bEMRH
 where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
 
 if @@rowcount = 0
 	begin
 	select @allow_rate_oride = AllowPostOride, @post_work_units = PostWorkUnits, @updatehrs = UpdtHrMeter
 	from bEMRR
 	where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
 
 	if @@rowcount = 0
 	/* nothing set up in Cat or Equip revenue codes */
 		begin
 
 		  select @post_work_units = case @rev_basis when 'U' then 'Y' else 'N' end
 		  select @allow_rate_oride = UseRateOride
 		  from bEMCO
 		  where EMCo = @emco and EMGroup = @emgroup
 		  select @msg = 'Revenue code ' + isnull(@revcode,'') + ' is not set up in the category or equipment override forms', @rcode = 1
 		  goto bspexit
 		end
 	end
 
 bspexit:
 	if @rcode<>0 select @msg=isnull(@msg,'')
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMUsageFlagsGet] TO [public]
GO
