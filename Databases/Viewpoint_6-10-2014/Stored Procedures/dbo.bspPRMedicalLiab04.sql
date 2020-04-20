SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPRMedicalLiab04]
   /********************************************************
   * CREATED BY:   GG 10/13/04
   * MODIFIED BY:	
   *
   * USAGE:
   * 	Custom routine to calculate Medical liability (#25661 - Meadow Valley).
   *
   *	Called from bspPRProcessEmpl, must be processed after employee based Medical deduction
   *
   *	Medical liability = Employee limit - Medical deduction
   *	If result is < 0 then use 0.00
   *
   *	Reads Medical deduction code from MiscAmt1 in bPRRM
   *
   *
   * INPUT PARAMETERS:
   *	@prco	 	  	PR Company
   *	@prgroup		PR Group
   *	@prenddate		PR Ending Date
   *	@employee		Employee
   *	@payseq			Pay sequence
   *	@limit			Medical liability pay period limit
   *	@routine		PR routine linked to this liability
   *
   * OUTPUT PARAMETERS:
   *	@calcamt	  calculated deduction amount
   *	@errmsg		  error message if failure
   *
   * RETURN VALUE:
   * 	0 	    success
   *	1 		failure
   **********************************************************/
   (@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
    @limit bDollar, @routine varchar(10), @calcamt bDollar = 0 output, @errmsg varchar(255) = null output)
     
   as
   set nocount on
     
   declare @rcode int, @procname varchar(30), @meddedn bEDLCode, @amt1 bDollar
     
   select @rcode = 0, @amt1 = 0, @meddedn = 0, @procname = 'bspPRMedicalLiab04'
   
   
   -- get medical deduction code from Routine master MiscAmt1
   select @meddedn = MiscAmt1
   from dbo.bPRRM (nolock)
   where PRCo = @prco and Routine = @routine
   
   -- get medical deduction amount
   if @meddedn <> 0
   	begin
   	select @amt1 = case UseOver when 'Y' then OverAmt else Amount end
   	from dbo.bPRDT (nolock)
   	where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate and Employee = @employee
   		and PaySeq = @payseq and EDLType = 'D' and EDLCode = @meddedn	-- medical deduction code
   	end
   
   -- calculate amount
   select @calcamt = @limit - @amt1 
   if @calcamt < 0 select @calcamt = 0	-- if result is less than zero, return 0
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMedicalLiab04] TO [public]
GO
