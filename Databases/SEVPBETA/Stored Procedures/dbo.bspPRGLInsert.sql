SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRGLInsert    Script Date: 8/28/99 9:35:32 AM ******/
    CREATE  procedure [dbo].[bspPRGLInsert]
    /***********************************************************
     * Created: GG 07/01/98
     * Modified: GG 07/01/98
     *           EN 6/6/01 - issue #11553 - ability to post hours to cross reference GL acct
     *           EN 7/17/01 - issue #14014
     *				EN 10/8/02 - issue 18877 change double quotes to single
     *
     * Called from various bspPRUpdateValGL.. procedures to insert or update
     * GL distributions in bPRGL prior to an update.
     *
     * Inputs:
     *   @prco   		PR Company
     *   @prgroup  		PR Group
     *   @prenddate		Pay Period Ending Date
     *   @mth		    Month
     *   @glco          GL Company
     *   @glacct        GL Account
     *   @employee      Employee #
   
     *   @payseq        Payment Sequence
     *   @amt           Amount - positive values are debits, negative values are credits
     *   @hours         Hours being posted to Cross Reference GL Acct
     *
     * Output:
     *   none
     *
     * Return Value:
     *   none
     *****************************************************/
        (@prco bCompany, @prgroup bGroup, @prenddate bDate, @mth bMonth, @glco bCompany,
         @glacct bGLAcct, @employee bEmployee, @payseq tinyint, @amt bDollar, @hours bHrs)
    as
    set nocount on
   
    if @glacct is null select @glacct = 'null'
   
    update bPRGL set Amt = Amt + @amt, Hours = Hours + @hours --issue #14014 - added ', Hours = Hours + @hours'
        where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Mth = @mth
            and GLCo = @glco and GLAcct = @glacct and Employee = @employee and PaySeq = @payseq
    if @@rowcount = 0
        begin
        insert bPRGL (PRCo, PRGroup, PREndDate, Mth, GLCo, GLAcct, Employee, PaySeq, Amt, OldAmt, Hours, OldHours)
        values (@prco, @prgroup, @prenddate, @mth, @glco, @glacct, @employee, @payseq, @amt, 0, @hours, 0)
        end
    return

GO
GRANT EXECUTE ON  [dbo].[bspPRGLInsert] TO [public]
GO
