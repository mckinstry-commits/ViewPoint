SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRUpdateValGLCredits    Script Date: 8/28/99 9:36:35 AM ******/
   CREATE    procedure [dbo].[bspPRUpdateValGLCredits]
   /***********************************************************
    * Created: GG 06/30/98
    * Modified: GG 06/30/98
    *           EN 6/06/01 - issue #11553 - enhancement to interface hours to GL memo acccounts
    *				EN 12/09/03 - issue 23061  added isnull check, with (nolock), and dbo
	*				mh 06/05/09 - Issue 133911 - Corrected cursor to local fast forward.
	*				EN 5/6/2011 TK-04941/#140951 removed nolock which caused intermittent error
	*				EN/MV 9/18/2012 B-10153/TK-17826 added code to include potential payback/payback update amounts when determine
	*													amount to post to PRGL for D/L credit
	*				CHS	06/28/2013 TFS Bug 39054 fixing Schema changed error changed from FAST_FORWARD to STATIC.
    *
    * Called from the bspPRUpdateValGL procedure to validate and load
    * GL credit distributions into bPRGL for deductions and liabilities.
    * Posted to PR GL Co# in the month the paid.
    *
    * Errors are written to bPRUR unless fatal.
    *
    * Inputs:
    *   @prco   		PR Company
    *   @prgroup  		PR Group to validate
    *   @prenddate		Pay Period Ending Date
    *   @employee      Employee
    *   @payseq        Payment Seq
    *   @prglco        PR's GL Company
    *   @paidmth       Paid month for Employee/Pay Seq
    *
    * Output:
    *   @errmsg      error message if error occurs
    *
    * Return Value:
    *   0         success
    *   1         failure
    *****************************************************/
   
   	(@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null, @employee bEmployee = null,
        @payseq tinyint = null,  @prglco bCompany = null, @paidmth bMonth = null, @errmsg varchar(255) = null output)
   as
   
   set nocount on
   
DECLARE @DebugFlag bit
SET @DebugFlag=0  
   
   DECLARE @rcode int,			@errortext varchar(255),	@openEmplDLTotal tinyint,	@dltype char(1), 
		   @dlcode bEDLCode,	@amount bDollar,			@useover bYN,				@overamt bDollar, 
		   @glamt bDollar,		@glacct bGLAcct,			@overglacct bGLAcct,		@glhrs bHrs, 
		   @paybackamt bDollar,	@paybackoveramt bDollar,	@paybackoveryn bYN
   
   select @rcode = 0, @openEmplDLTotal = 0, @glhrs = 0
   
   -- create cursor to process credits for dedns and liabs
   DECLARE bcEmplDLTotal CURSOR LOCAL STATIC FOR
   SELECT EDLType, EDLCode,		Amount,			UseOver, 
		  OverAmt, PaybackAmt,	PaybackOverAmt, PaybackOverYN
   FROM dbo.bPRDT -- with (nolock) TK-04941 commented out nolock to resolve error
   WHERE PRCo = @prco AND 
		 PRGroup = @prgroup AND 
		 PREndDate = @prenddate AND 
		 Employee = @employee AND 
		 PaySeq = @payseq AND 
		 EDLType IN ('D','L')
   
   open bcEmplDLTotal
   select @openEmplDLTotal = 1
   
   -- loop through all Employee Dedn/Liab Totals
   next_EmplDLTotal:
       FETCH NEXT FROM bcEmplDLTotal INTO @dltype,	@dlcode,		@amount,			@useover, 
										  @overamt, @paybackamt,	@paybackoveramt,	@paybackoveryn
       if @@fetch_status = -1 goto bspexit
       if @@fetch_status <> 0 goto next_EmplDLTotal
   
       SELECT @glamt = (CASE @useover WHEN 'Y' THEN @overamt ELSE @amount END) +
					   (CASE @paybackoveryn WHEN 'Y' THEN @paybackoveramt ELSE @paybackamt END)
       if @glamt = 0 goto next_EmplDLTotal
   
       -- Dedn/Liab Credit based on DL Code - override by Employee
       select @glacct = null
       select @glacct = GLAcct
       from dbo.bPRDL with (nolock) where PRCo = @prco and DLCode = @dlcode
       if @@rowcount = 0
           begin
           select @errortext = 'Dedn/liab code ' + convert(varchar(6),@dlcode) + ' is not on file!'
           exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           if @rcode = 1 goto bspexit
           goto next_EmplDLTotal	-- skip this DL Code
           end
       -- check for Employee GL Account override
       select @overglacct = null
       select @overglacct = OverGLAcct
       from dbo.bPRED with (nolock)
       where PRCo = @prco and Employee = @employee and DLCode = @dlcode
       if @overglacct is not null select @glacct = @overglacct
   
       -- validate GL Account - subledger type must be null
       exec @rcode = bspGLACfPostable @prglco, @glacct, 'N', @errmsg output
       if @rcode = 1
           begin
           select @errortext = 'Dedn/Liab ' + convert(varchar(6),@dlcode) + ' Credit : ' + isnull(@errmsg,'')
           exec @rcode = bspPRURInsert @prco, @prgroup, @prenddate, @employee, @payseq, 0, @errortext, @errmsg output
           if @rcode = 1 goto bspexit
           end
       -- update GL distributions with a credit for dedn/liab amount - posted in Paid Month
       select @glamt = -(@glamt)
IF (@DebugFlag=1) PRINT 'bspPRUpdateValGLCredits CR1: GLCo='+Convert(varchar,@prglco)+' GLAcct='+@glacct+' GLAmt='+convert(varchar,@glamt)+' GLHrs='+convert(varchar,@glhrs)
       exec bspPRGLInsert @prco, @prgroup, @prenddate, @paidmth, @prglco, @glacct, @employee, @payseq, @glamt, @glhrs
       goto next_EmplDLTotal
   
   bspexit:     -- finished with dedn/liab credits
       if @openEmplDLTotal = 1
           begin
           close bcEmplDLTotal
           deallocate bcEmplDLTotal
           end
       --select @errmsg = @errmsg + char(13) + char(10) + '[bspPRUpdateValGLCredits]'
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUpdateValGLCredits] TO [public]
GO
