SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPCUnlock    Script Date: 8/28/99 9:35:34 AM ******/
    CREATE  procedure [dbo].[bspPRPCUnlock]
    /***********************************************************
     * CREATED BY: GG 05/28/98
     * MODIFIED By : GG 05/28/98
     *              GG 08/26/99 - Remove entries from Ledger Update distribution tables
     *                  where all 'old' values equal 0.00
     *              EN 7/18/01 - issue #14014
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *				DAN SO 12/09/2009 - Issue #135173 - only the same user can unlock this Pay Period 
	 *				MB 11/09/2012  TK-19188 Payroll lines with GL Accounts not being removed preventing Work Order Scopes from being deleted
     *
     * USAGE:
     * Called from the Pay Period Update form to reset 'InUseBy' to null,
     * and clear update distributions tables with 0.00 'old' values.
     *
     * Pay Period is locked when selected using bspPRPCValforUpdate,
     * and unlocked when posted in bspPRUpdate, or with this procedure if
     * the Pay Period is changed.
     *
     * INPUT PARAMETERS
     *   PRCo   	PR Company
     *   PRGroup  	PR Group to validate
     *   PREndDate	Pay Period Ending Date
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs
     *
     * RETURN VALUE
     *   0         success
     *   1         failure
     *	 7		   Conditional Success	
     *****************************************************/
   
    	(@prco bCompany = null, @prgroup bGroup = null,
    	 @prenddate bDate = null, @msg varchar(60) = null output)
    as
   
    set nocount on
   
    declare @rcode int, @InUseBy bVPUserName
   
    select @rcode = 0
   
   
	-- ISSUE #135173 --
	SELECT @InUseBy = InUseBy
	  FROM bPRPC
	 WHERE PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   
	IF (@InUseBy IS NOT NULL) AND (@InUseBy <> SUSER_SNAME())
		BEGIN
			SELECT @msg = 'Cannot Unlock - Pay Period already in use by ' + @InUseBy, @rcode = 7 -- 7 = Conditional Success
			GOTO bspexit
		END


	update bPRPC set InUseBy = null
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
	if @@rowcount = 0
   
		begin
		select @msg = 'PR Group and Ending Date not on file!', @rcode = 1
		end
   
	-- clean up distribution tables.  If not removed bPRSQ entries will not be removed
	-- even if all timecards are deleted.
	-- remove entries from bPRJC interface table where 'old' values equal 0.00
	delete bPRJC
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and OldWorkUnits = 0 and OldHrs = 0 and OldAmt = 0 and OldJCUnits = 0
	-- remove entries from bPRRB interface table where 'old' values equal 0.00
	delete bPRRB
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and OldAmt = 0
	-- remove entries from bPRER interface table where 'old' values equal 0.00
	delete bPRER
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and OldTimeUnits = 0 and OldWorkUnits = 0 and OldRevenue = 0
	-- remove entries from bPREM interface table where 'old' values equal 0.00
	delete bPREM
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
		and OldHrs = 0 and OldAmt = 0
	-- remove entries from bPRGL interface table where 'old' values equal 0.00
	delete bPRGL
	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and OldAmt = 0 and OldHours = 0 --issue #14014

	--Delete the PRLedgerUpdateMonth records
	--This will cascade delete GLEntry and JCCostEntry
	--This will cascade null SMWorkCompleted
	DELETE dbo.vPRLedgerUpdateMonth
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Posted = 0
	
	--Once all WIP has been reversed and JCCostEntrys exist for SMWorkCompleted lines marked as deleted
	--then they can actually be deleted.
	DECLARE @PRLedgerUpdateMonthToDelete TABLE (PRLedgerUpdateMonthID bigint)
	
	DELETE vSMWorkCompleted
		OUTPUT DELETED.PRLedgerUpdateMonthID
			INTO @PRLedgerUpdateMonthToDelete
	FROM dbo.vPRLedgerUpdateMonth
		INNER JOIN dbo.vSMWorkCompleted ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vSMWorkCompleted.PRLedgerUpdateMonthID
		INNER JOIN dbo.vSMWorkOrder ON vSMWorkCompleted.SMCo = vSMWorkOrder.SMCo AND vSMWorkCompleted.WorkOrder = vSMWorkOrder.WorkOrder
		LEFT JOIN dbo.vSMWorkCompletedJCCostEntry ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedJCCostEntry.SMWorkCompletedID
		LEFT JOIN dbo.vSMWorkCompletedGLEntry ON vSMWorkCompleted.SMWorkCompletedID = vSMWorkCompletedGLEntry.SMWorkCompletedID
	WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate AND vSMWorkCompleted.IsDeleted = 1 AND vSMWorkCompleted.CostsCaptured = 1
		AND (vSMWorkOrder.Job IS NULL OR (vSMWorkCompleted.RevenueSMWIPGLEntryID IS NULL AND vSMWorkCompleted.RevenueJCWIPGLEntryID IS NULL AND vSMWorkCompletedJCCostEntry.SMWorkCompletedID IS NULL AND vSMWorkCompletedGLEntry.SMWorkCompletedID IS NULL))

	DELETE dbo.vPRLedgerUpdateMonth
	WHERE PRLedgerUpdateMonthID IN (SELECT PRLedgerUpdateMonthID FROM @PRLedgerUpdateMonthToDelete)

	DELETE dbo.vPRLedgerUpdateDistribution
	WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate AND Posted = 0
	
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPCUnlock] TO [public]
GO
