SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREquipValUsage    Script Date: 8/28/99 9:34:27 AM ******/
   CREATE   procedure [dbo].[bspPREquipValUsage]
   
     /***********************************************************
      * CREATED BY: EN 10/6/99
      * MODIFIED By : EN 10/6/99
      *               EN 2/21/00 - return error if @jobflag = 'Y' and @jobposted (if provided) <> @job
      *               EN 6/2/00 - include equipment description in return params
      *               EN 6/5/01 - issue #13648 - allow equipment with status of 'down'
      *				EN 10/8/02 - issue 18877 change double quotes to single
      *				EN 2/17/04 - issue 23788 clarify the "Missing usage cost type" message
	  *				TRL 08/13/2008 - 126196 rewrote stored proc for Equipment Change val (DanSo)
      *
      * USAGE:
      *	Validates EMEM.Equipment and returns flags needed for EM Usage form interface,
      *	If equipment needs to be active send flag @checkactive = 'Y' and the status must be 'A'.
      *    (Used in Timecard posting.  Works same as bspEMEquipValUsage except for extra validation for usage cost type.)
      *
      * INPUT PARAMETERS
      *	@emco		EM Company
      *	@equip		Equipment to be validated
      * 	@checkactive send in a 'Y' or 'N'
      *    @jccoposted JC company posted (optional)
      *    @jobposted  Job posted (optional)
      *
      * OUTPUT PARAMETERS
      *	ret val		EMEM column
      *	-------		-----------
      *	@category	Category
      *	@odoreading 	OdoReading
      *	@hrreading 	HourReading
      *	@jcco 		JCCo
      *	@job 		Job
      *	@jcct		Cost type
      *	@phasegrp 	PhaseGrp
      *	@postcosttocomp PostCostToComp
      *	@jobflag	Restrict to current job from EMCM
      *	@prco		PRCo
      *	@employee	Operator from EMEM
      * 	@class		used for payroll purposes
      *    @equipdesc  Equipment description
      *	@errmsg		Description or Error msg if error
       **********************************************************/
   
     (@emco bCompany, @equip bEquip,  @checkactive bYN, @jccoposted bCompany = null, @jobposted bJob = null,
      @category varchar(23) = null output,
      @odoreading bHrs = null output, @hrreading bHrs = null output, @jcco bCompany = null output, @job bJob = null output,
      @usgcosttype bJCCType = null output,  @phasegrp bGroup = null output, @postcosttocomp bYN = null output,
      @jobflag bYN = null output, @prco bCompany = null output, @employee bEmployee = null output,
      @revcode bRevCode = null output, @class bClass = null output, @equipdesc bDesc = null output, @errmsg varchar(255) output)
   
     as
     set nocount on
     declare @rcode int, @msg varchar(60), @status char(1), @type char(1)
     select @rcode = 0
   
       if @emco is null
     	begin
   
     	select @errmsg = 'Missing EM Company!', @rcode = 1
     	goto bspexit
     	end
   
     if @equip is null
     	begin
     	select @errmsg = 'Missing Equipment!', @rcode = 1
     	goto bspexit
     	end
   
   
     /* validate equipment and retrieve emem flags */
     exec @rcode = bspEMEquipValWithInfo @emco, @equip, @type=@type output, @category=@category output,
     	@odoreading=@odoreading output,	@hrreading=@hrreading output, @jcco=@jcco output, @job=@job output,
     	@usgcosttype=@usgcosttype output, @phasegrp=@phasegrp output, @postcosttocomp = @postcosttocomp output, @msg=@errmsg output
     if @rcode <> 0 goto bspexit
   
     if @usgcosttype is null
         begin
         select @errmsg = 'Must assign usage cost type in Equipment Master', @rcode = 1
         goto bspexit
         end
   
	--Return if Equipment Change in progress for New Equipment Code - 126196
	exec @rcode = vspEMEquipChangeInProgressVal @emco, @equip, @errmsg output
	If @rcode = 1
	begin
		  goto bspexit
	end

     select @prco = PRCo, @equipdesc = Description, @employee = Operator, @status = Status, @revcode = RevenueCode
     from EMEM
     where EMCo = @emco and Equipment = @equip
   

     if @checkactive='Y'
     	begin
     	if @status not in ('A', 'D')
   
     		begin
     		select @errmsg = 'Equipment must not be inactive', @rcode = 1
     		goto bspexit
     		end
     	end
   
    if @type = 'C'
     begin
     select @errmsg = 'Invalid entry.  Cannot be a component!', @rcode = 1
     goto bspexit
     end
   
     /* Snag a flag. DDFI is going to validate this category for us anyway. */
     exec @rcode = bspEMCategoryVal @emco, @category, @jobflag output, @msg=@msg output
     if @rcode <> 0
     	begin
     	/* the category is displayed in a label so if there is an error, display it in the same place */
     	select @category = @msg
     	goto bspexit
     	end
   
     if @jobflag = 'Y' and @jccoposted is not null and @jobposted is not null
     and (@jccoposted <> @jcco or @jobposted <> @job)
       begin
       select @errmsg = 'Must post to the Job Cost company and job assigned to this piece of equipment!', @rcode = 1
       goto bspexit
       end
   
     select @class = PRClass
     	from EMCM
     	where EMCo = @emco and Category = @category
   
   bspexit:
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREquipValUsage] TO [public]
GO
