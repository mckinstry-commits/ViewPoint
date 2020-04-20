SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRCrewEmplVal    Script Date: 8/28/99 9:33:19 AM ******/
    CREATE           proc [dbo].[bspPRCrewEmplVal]
    
    /***********************************************************
     * CREATED BY: EN 2/25/03
     * MODIFIED By :	EN	7/25/03 issue 21953 - re-add ability to set up employee multiple times in crew
	 *					MH  1/16/08 Issue 126856 - Crew's PR Group must be passed in.   
	 *					MH  1/31/09 Issue 123591 - Bring in EMCo, EMGroup and Equipment from PREC
     *
     * Usage:
     *	Used to validate employees being assigned to a crew by either Sort Name or number.
     *	Verifies that employee's PR Group matches that of crew if crew's group is set.
     *  Otherwise crew group default's from returned employee PR Group (ie. typically 
     *  first employee assigned to the crew).
     *
     * Input params:
     *	@prco		PR company
     *	@empl		Employee sort name or number
     *	@crewprgroup	PR Group shared by all empl's in crew
     *	@crew		Crew code
     *	@prcwseq	bPRCW Entry Sequence
     *
     * Output params:
     *	@emplout	Employee number
     *	@prgroup	Employee PR Group
	 *  @empEMCo	Employee EM Company from PREH
	 *  @empEMGroup Employee EM Group from PREH (M.B.U.)
	 *  @empEquip	Employee EM Equipment from PREH
     *	@msg		Employee Name or error message
     *
     * Return code:
     *	0 = success, 1 = failure
     ************************************************************/
    
	(@prco bCompany, @empl varchar(15), @crewprgroup bGroup, @crew varchar(10)=null, @prcwseq smallint,
     @emplout bEmployee=null output, @prgroup bGroup output, @empEMCo bCompany output, 
	 @empEMGroup bGroup output, @empEquip bEquip output, @msg varchar(60) output)
    
    as
    set nocount on
    
    declare @rcode int, @errmsg varchar(60), @lastname varchar(30), @firstname varchar(30)
    
    select @rcode = 0
    
    /* check required input params */
    
    if @empl is null
    	begin
    	select @msg = 'Missing Employee.', @rcode = 1
    	goto bspexit
    	end

	if @crewprgroup is null
	begin
		select @msg = 'Missing Crew PR Group.', @rcode = 1
		goto bspexit
	end
    
    exec @rcode = bspPREmplVal @prco, @empl, 'Y', @emplout=@emplout output, @lastname=@lastname output,
    	@firstname=@firstname output, @msg=@msg output
    if @rcode = 1 goto bspexit
   
   -- issue 21953 - re-add ability to set up employee multiple times in crew 
   -- --Check for duplicate employee entry in Crew
   -- if exists (select * from bPRCW where PRCo=@prco and Crew=@crew and Seq<>@prcwseq and Employee=@emplout)
   -- 	begin
   -- 	select @msg = 'Employee already set up in crew.', @rcode = 1
   -- 	goto bspexit
   -- 	end
    
    --Employee's PR Group must match Crew's PR Group
    select @prgroup=p.PRGroup, @empEMCo = p.EMCo, @empEMGroup = p.EMGroup, @empEquip = p.Equipment 
	from dbo.PREH p (nolock) where p.PRCo=@prco and p.Employee=@emplout
    
    --if @crewprgroup is not null and exists (select * from PRCW where PRCo=@prco and Crew=@crew)
--    	begin
    	if @prgroup<>@crewprgroup
    	begin
    		select @msg = 'PR Group does not match crew PR Group.', @rcode = 1
    		goto bspexit
    	end
--    	end
    
    
    bspexit:
    
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRCrewEmplVal] TO [public]
GO
