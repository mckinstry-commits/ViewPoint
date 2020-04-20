SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUpdatePost    Script Date: 8/28/99 9:35:41 AM ******/
   CREATE PROCEDURE [dbo].[bspPRUpdatePost]
   /***********************************************************
    * CREATED BY: GG 05/28/98
    * MODIFIED By : GG 05/28/98
    *				GG 07/30/01 - added call to bspPRPCUnlock - #14133
    *				EN 10/9/02 - issue 18877 change double quotes to single
    *				DAN SO 08/25/09 - Issue #135173 - make sure batch is InUse by current user
	*				EN 3/30/2010 #137126 provide appropriate error message when SQL error 16943 is trapped in bspPRUpdatePostAccums
    *
    * USAGE:
    * Called from the Pay Period Update form to perform updates to
    * JC, EM, GL, CM, PR Payment History, and Employee Accums.
    *
    * INPUT PARAMETERS
    *   @prco   		PR Company
    *   @prgroup  		PR Group to validate
    *   @prenddate		Pay Period Ending Date
    *   @postdate		Posting Date used for transaction detail
    *   @upsmjc		    Update SM JC flag - Y,N
    *   @upem		    Update EM flag - Y,N
    *   @upgl		    Update GL flag - Y,N
    *
    * OUTPUT PARAMETERS
    *   @errmsg        error message if error occurs
    *
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   	(@prco bCompany, @prgroup bGroup, @prenddate bDate, @postdate bDate,
   	@upsmjc bYN, @upem bYN, @upgl bYN, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @status tinyint, @InUseBy as bVPUserName
   
   select @rcode = 0
   
   -- get Pay Period status
   select @status = Status, @InUseBy = InUseBy
   from bPRPC
   where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
   if @@rowcount = 0
       begin
       select @errmsg = 'Invalid Pay Period!',@rcode = 1
       goto bspexit
       end

	-- ISSUE #135173 --
	IF ISNULL(@InUseBy,'') <> SUSER_SNAME()
   		BEGIN
   			SELECT @errmsg = 'Pay Period is not locked by current user!', @rcode = 1
   			GOTO bspexit
   		END
   
   --In order to handle SM and JC WIP for SM timecards the work completed needs to be associated with the pay period
   --This also prevents the work completed from being deleted so that any JC or GL reversing can be done.
   UPDATE vPRLedgerUpdateMonth
   SET Posted = 1
   FROM dbo.vPRLedgerUpdateMonth
		INNER JOIN dbo.vSMWorkCompleted ON vPRLedgerUpdateMonth.PRLedgerUpdateMonthID = vSMWorkCompleted.PRLedgerUpdateMonthID
   WHERE vPRLedgerUpdateMonth.PRCo = @prco AND vPRLedgerUpdateMonth.PRGroup = @prgroup AND vPRLedgerUpdateMonth.PREndDate = @prenddate AND vPRLedgerUpdateMonth.Posted = 0
   
   if @upsmjc = 'Y'
       begin
       --It is important that the SM sproc get called first because both SM and JC updates are driven off of
       --the PRPC JCInterface flag which is updated in bspPRUpdatePostJC
       exec @rcode = vspPRUpdatePostSM @prco, @prgroup, @prenddate, @postdate, @status, @errmsg output
       if @rcode = 1
           begin
           select @errmsg = 'Unable to complete SM Cost update!' + @errmsg, @rcode = 1
           goto bspexit
           end
       
       exec @rcode = bspPRUpdatePostJC @prco, @prgroup, @prenddate, @postdate, @status, @errmsg output
       if @rcode = 1
           begin
           select @errmsg = 'Unable to complete JC and EM Revenue update!', @rcode = 1
           goto bspexit
           end
       end
   
   if @upem = 'Y'
       begin
       exec @rcode = bspPRUpdatePostEM @prco, @prgroup, @prenddate, @postdate, @status, @errmsg output
       if @rcode = 1
           begin
           select @errmsg = 'Unable to complete EM Cost update!', @rcode = 1
           goto bspexit
           end
       end
   
   if @upgl = 'Y'
       begin
       exec @rcode = bspPRUpdatePostGL @prco, @prgroup, @prenddate, @postdate, @status, @errmsg output
       if @rcode = 1
           begin
		   --#137126 provide appropriate message to fit the circumstance
		   if @errmsg = 'SQL ERROR #16943 trapped in bspPRUpdatePostAccums'
				select @errmsg = 'Update interrupted due to possible payroll processing in progress.  Retry after determining that processing is complete.'
		   else
				select @errmsg = 'Unable to complete GL, CM, Employee Accumulations update!'
           goto bspexit
           end
       end

	BEGIN TRY
		--Updating the vPRLedgerUpdateDistribution to posted should cause a fk exception
		--if any distribution records are still pointing to the vPRLedgerUpdateDistribution.
		--This allows for cascade deleting when clearing batches during validation and
		--validating  that all distributions were processed as expected.
		UPDATE dbo.vPRLedgerUpdateDistribution
		SET Posted = 1
		WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate
		
		DELETE dbo.vPRLedgerUpdateDistribution
		WHERE PRCo = @prco AND PRGroup = @prgroup AND PREndDate = @prenddate
	END TRY
	BEGIN CATCH
		SET @errmsg = 'Not all updates were posted. - ' + ERROR_MESSAGE()
		RETURN 1
	END CATCH
   
   -- after successful update, unlock Pay Period
   exec @rcode = bspPRPCUnlock @prco, @prgroup, @prenddate, @errmsg output
   	
   bspexit:
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdatePost]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdatePost] TO [public]
GO
