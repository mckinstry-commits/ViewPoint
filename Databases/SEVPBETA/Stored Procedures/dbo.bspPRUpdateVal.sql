SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUpdateVal    Script Date: 8/28/99 9:35:41 AM ******/
   CREATE PROCEDURE [dbo].[bspPRUpdateVal]
   /***********************************************************
    * CREATED BY: GG 05/28/98
    * MODIFIED By : GG 07/21/98
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
    *
    * USAGE:
    * Called from the Pay Period Update form to load and validate
    * JC, EM, and GL prior to an update.
    *
    * Errors are written to bPRUR unless fatal.
    *
    * INPUT PARAMETERS
    *   @prco   		PR Company
    *   @prgroup  		PR Group to validate
    *   @prenddate		Pay Period Ending Date
    *   @upsmjc		Update SM JC flag - Y,N
    *   @upem		Update EM flag - Y,N
    *   @upgl		Update GL flag - Y,N
    *
    * OUTPUT PARAMETERS
    *   @errmsg      error message if error occurs
    *
    * RETURN VALUE
    *   0         success
    *   1         fatal error, or errors exist in bPRUR
    *****************************************************/
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
   	 @upsmjc bYN = 'N', @upem bYN = 'N', @upgl bYN = 'N', @errmsg varchar(255) = null output)
   as
   
   set nocount on
   
   declare @rcode int
   
   -- Pay Period variables
   declare @beginmth bMonth, @endmth bMonth, @cutoffdate bDate, @status tinyint, @inuseby bVPUserName, @PRLedgerUpdateDistributionID bigint
   select @rcode = 0
   -- get Pay Period info
   select @beginmth = BeginMth, @endmth = EndMth, @cutoffdate = CutoffDate,
   	@status = Status, @inuseby = InUseBy
   from dbo.bPRPC with (nolock)
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Missing Pay Period.  Cannot continue.', @rcode = 1
   	goto bspexit
   	end
   if @inuseby is null
   	begin
   	select @errmsg = 'Pay Period has not been locked!', @rcode = 1
   	goto bspexit
   	end
   if @inuseby <> SUSER_SNAME()
   	begin
   	select @errmsg = 'Pay Period is already in use by ' + isnull(@inuseby,''), @rcode = 1
   	goto bspexit
   	end
   -- clear PR Update Error table
   delete dbo.bPRUR
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
   	--Delete distributions to cascade delete any distributions not posted.
	DELETE dbo.vPRLedgerUpdateDistribution
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate
   
	--Delete the PRLedgerUpdateMonth records
	--This will cascade delete GLEntry and JCCostEntry
	--This will cascade null SMWorkCompleted
	DELETE dbo.vPRLedgerUpdateMonth
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Posted = 0

	INSERT dbo.vPRLedgerUpdateDistribution (PRCo, PRGroup, PREndDate)
	VALUES (@prco, @prgroup, @prenddate)

	SET @PRLedgerUpdateDistributionID = SCOPE_IDENTITY()

   if @upsmjc = 'Y'
   	begin
   	-- Service Management validation
    exec @rcode = vspPRUpdateValSM  @prco, @prgroup, @prenddate, @beginmth, @endmth, @cutoffdate, @status, @errmsg output
   	if @rcode <> 0 goto bspexit
   	
	-- Job Cost / Equipment Revenue validation
   	exec @rcode = bspPRUpdateValJC @prco, @prgroup, @prenddate, @beginmth, @endmth, @cutoffdate, @errmsg output
   	if @rcode <> 0 goto bspexit
   	
	end
   	
   -- Equipment Cost validation
   if @upem = 'Y'
   	begin
   	exec @rcode = bspPRUpdateValEMCost @prco, @prgroup, @prenddate, @beginmth, @endmth, @cutoffdate, @errmsg output
   	if @rcode <> 0 goto bspexit
   	end

   -- General Ledger / Cash Mgmt / Payment History / Employee Accumulation validation
   if @upgl = 'Y'
   	begin
       exec @rcode = bspPRUpdateValGL @prco, @prgroup, @prenddate, @beginmth, @endmth, @cutoffdate, @status, @PRLedgerUpdateDistributionID, @errmsg output
   	if @rcode <> 0 goto bspexit
   	end
   -- check PR Update Errors for validation errors
   if exists(select * from dbo.bPRUR with (nolock) where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate)
   	begin
   	select @errmsg = 'Validation process completed, but errors were found!', @rcode = 1
   	end
   bspexit:
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdateVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateVal] TO [public]
GO
