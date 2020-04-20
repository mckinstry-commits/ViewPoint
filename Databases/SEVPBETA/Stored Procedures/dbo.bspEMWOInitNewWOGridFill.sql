SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMWOInitNewWOGridFill    Script Date: 3/1/2002 10:47:30 AM ******/
   
   CREATE       proc [dbo].[bspEMWOInitNewWOGridFill]
    /*******************************************************************
     * CREATED: 11/18/98 JM
     * LAST MODIFIED: TV 02/11/04 - 23061 added isnulls 
     *					TRL 03/20/08 27172 added PRC to display output
     *					TRL 02/05/10 Issue 138584  update Description Col to 60
	 *
     * USAGE: Called by EMWOInit form to report the new Work Orders
     *		created in a series for a set of Equipment.
     *
     * INPUT PARAMS:
     *	@emco		Controlling EM Company
     *	@beginningwo	First EMWH.WorkOrder for which Items/Parts
     *			were initialized
     *	@endingwo	Last EMWH.WorkOrder for which Items/Parts
     *			were initialized
     *
     * OUTPUT PARAMS:
    
     *	@rcode		Return code; 0 = success, 1 = failure
     *	@errmsg		Error message; # copied if success,
     *			error message if failure
     ********************************************************************/
    (@emco bCompany = null, @autoinitsessionid varchar(30) = null, --@beginningwo bWO = null, @endingwo bWO = null, 
    @errmsg varchar(255) output)
    
    as
    
    set nocount on
    
    declare @rcode integer
    
    select @rcode = 0
    
    /* Verify required parameters passed. */
    if @emco is null
    	begin
    	select @errmsg = 'Missing EM Company!', @rcode = 1
     	goto bspexit
    	end
   if @autoinitsessionid is null
    	begin
    	select @errmsg = 'Missing AutoInitSessionIDr!', @rcode = 1
    	goto bspexit
    	end
   /* if @beginningwo is null
    	begin
    	select @errmsg = 'Missing Beginning Work Order!', @rcode = 1
    	goto bspexit
    	end
    if @endingwo is null
    	begin
    	select @errmsg = 'Missing Ending Work Order!', @rcode = 1
    	goto bspexit
    	end*/
    																																																		
    /* Return recordset to VB */
    select WorkOrder, Description, Equipment, Shop,PRCo /*27172*/, Mechanic, InvLoc, DateDue, DateSched
    from dbo.EMWH with(nolock)
    where EMCo = @emco and AutoInitSessionID = @autoinitsessionid
   -- where EMCo = @emco and WorkOrder >= @beginningwo and WorkOrder <= @endingwo 
    
    bspexit:
    	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	--+ char(13) + char(10) + '[bspEMWOInitNewWOGridFill]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMWOInitNewWOGridFill] TO [public]
GO
