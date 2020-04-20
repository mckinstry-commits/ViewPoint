SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRevRateUMDflt    Script Date: 8/28/99 9:36:14 AM ******/
   CREATE    proc [dbo].[bspEMRevRateUMDflt]
   /*************************************
   *
   * Created:	1/20/98 bc
   * Modified: 07/02/01 bc - RevTemplates.  do not use the standard rate in EMRH (Equipment) for Percentage templates
   *                                        if EMRH.ORideRate = 'N'.  Go get the std rate out of EMRR (Category)
   *			TV 02/11/04 - 23061 added isnulls
   *
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
   (@emco bCompany, @emgroup bGroup, @transtype char(1) = null, @equip bEquip = null,
    @category bCat = null, @revcode bRevCode = null, @jcco bCompany = null,
    @job bJob = null, @rate bDollar output, @time_um bUM output, @work_um bUM = null output,
    @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @errmsg varchar(60)
   declare @revtemp varchar(10), @discount bPct, @emrc_workum bUM, @typeflag char(1), @oriderate bYN
   
   select @rcode = 0
   
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
   
   /* find the base value for the units of measure */
   select @time_um = null
   select @time_um = TimeUM, @emrc_workum = WorkUM, @msg = Description
   from bEMRC
   where EMGroup = @emgroup and RevCode = @revcode
   
   /*if TimeUm is null then the rev code is unit based but we still need the TimeUM so snag it from EMCo */
   If @time_um is null
         	Begin
         	  select @time_um = HoursUM
         	  from bEMCO
         	  where EMCo = @emco
   
         	if @time_um is null
             begin
               select @msg = 'Hours unit of measure is not set up in company form.', @rcode = 1
               goto bspexit
             end
          End
   
   if @transtype = 'J'
   Begin
   
   /* This bsp should not be called from vb if the type = J and JCCo or Job is null
      but keep this check available just in case */
   If @jcco is null or @job is null or @job = '' goto bspexit
   
   /* Check to see if there is a template set up for this job */
   select @revtemp = RevTemplate
   from bEMJT
   where EMCo = @emco and JCCo = @jcco and Job = @job
   
   if @revtemp is null goto NoJob
     else
       Begin
   	select @typeflag = TypeFlag
   	from bEMTH
   	where EMCo = @emco and RevTemplate = @revtemp
   
   	/* check the equip template for a corresponding record */
   	Select @rate = Rate, @discount = DiscFromStdRate
   	from bEMTE
   	where EMCo = @emco and RevTemplate = @revtemp and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
   
   	if @@rowcount = 0
   		begin
   		/* check the catgy template for a corresponding record */
   		Select @rate = Rate, @discount = DiscFromStdRate
   		from bEMTC
   		where EMCo = @emco and RevTemplate = @revtemp and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   
   		/* no records exist under the template for the passed in job */
   		if @@rowcount = 0 goto NoJob
   		end
       End
   
   /* Check for any discounts or overrides of the rate and grab the UM if it is here.
      If we do drop down into this section then the only place to go afterwards is bspexit. */
   if @typeflag = 'P'
     Begin
   
     select @rate = Rate, @work_um = WorkUM
     from bEMRH
     where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode and ORideRate = 'Y'
   
     if @@rowcount = 0
   
       begin
   	select @rate = Rate, @work_um = WorkUM
   	from bEMRR
   	where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   
   	if @@rowcount = 0
   		begin
   		select @msg = 'Revenue code ' + isnull(@revcode,'') + ' invalid for category ' + isnull(@category,''), @rcode = 1
   		goto bspexit
   		end
   	    /* found in EMRR */
        	else select @rate = @rate * @discount
       end
    /* found in EMRH */
       else select @rate = @rate * @discount
     End
   
   /* For Over ride type templates, keep the rate that was found in either the equip or catgy template table
      but still go back to the base equip and catgy tables in search of a UM */
   if @typeflag = 'O'
     Begin
     select @work_um = WorkUM
     from bEMRH
     where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
   
     if @@rowcount = 0
       begin
   	select @work_um = WorkUM
   	from bEMRR
   	where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   
   	if @@rowcount = 0
   	  begin
   	  select @msg = 'Revenue code ' + isnull(@revcode,'') + ' invalid for category ' + isnull(@category,''), @rcode = 1
   	  goto bspexit
   	  end
       end
     End
     /* skip over the NoJob code */
     goto bspexit
   /* end Job type entries */
   END
   
   /* Either the trans type <> (J)ob or there is not template set up
      or there is no data below the template header */
   NoJob:
   select @oriderate = null
   select 	@oriderate = ORideRate, @work_um = WorkUM
   from bEMRH
   where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
   
   if @oriderate is not null
     begin
     if @oriderate = 'Y'
       begin
       select @rate = Rate
       from bEMRH
       where EMCo = @emco and Equipment = @equip and EMGroup = @emgroup and RevCode = @revcode
       end
     if @oriderate = 'N'
       begin
       select @category = Category
       from bEMEM
       where EMCo = @emco and Equipment = @equip
   
       select @rate = Rate
       from bEMRR
       where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
       end
     end
     else
     	/* @oriderate = null meaning no record is in EMRH */
   	begin
   	select 	@rate = Rate, @work_um = WorkUM
   	from bEMRR
   	where EMCo = @emco and Category = @category and EMGroup = @emgroup and RevCode = @revcode
   
   	if @@rowcount = 0
   	  /* nothing set up in Catgy or Equip revenue codes */
   	  begin
   	  /* no overrides exist for this revenue code. */
   	  -- select @rate = 0, @work_um = @emrc_workum
         select @msg = 'Revenue code ' + isnull(@revcode,'') + ' is not set up for category ' + isnull(@category,''), @rcode = 1
		 goto bspexit
   	  end
   	end
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRevRateUMDflt]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevRateUMDflt] TO [public]
GO
