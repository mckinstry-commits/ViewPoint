SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPREmployeeInfoGet    Script Date: 8/28/99 9:33:19 AM ******/
   CREATE     proc [dbo].[bspPREmployeeInfoGet]
   /***********************************************************
    * CREATED BY: kb
    * MODIFIED By : kb 1/22/98
    * 				 kb 1/26/98
    *				GG 11/13/01 - #15262 - remove input/output params for totals
    *				 EN 2/26/02 - issue 16349 - default outputs other than last updated jcco/job/crew to null to save code in timecards form
    *				EN 3/2/04 - issue 20564  return employee shift
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * Usage:
    *	Called by PR Timecard Entry program to return Employee related info after validation
    *
    * Input params:
    *	@prco			PR company
    *	@empl			Employee number
    * 
    * Output params:
    *	@prdept			Employee default PR Department
    *	@crew			Employee default Crew 
    *	@usestate		Y = Use Employee States, N = Use Job States
    *	@insstate		Employee default Insurance State
    *	@taxstate		Employee default Tax State
    *	@uselocal		Y = Use Employee Local, N = Use Job Local 
    *	@local			Employee default Local code
    *	@unempstate		Employee default Unemployment State
    *	@craft			Employee default Craft
    *	@cert			Employee default Certified flag (Y/N)
    *	@inscode		Employee default Insurance code
    *	@glco			Employee default GL Company #
    *	@emprate		Employee default pay rate
    *	@class			Employee default Class
    *	@jcco			Employee default JC Company # - last posted
    *	@job			Employee default Job - last posted
    *	@salaryamt		Employee default salary amount
    *	@earncode		Employee default earnings code
    *	@useins			Y = Use Employee default Insurance code, N = Use Job Insurance code
    *	@shift			Employee default shift
    *	@msg			Error message
    *
    * Return code:
    *	0 = success, 1 = failure
     ************************************************************/ 
   	(@prco bCompany = null, @empl bEmployee = null, @prdept bDept = null output, @crew varchar(10) output, 
    	@usestate bYN = null output, @insstate varchar(4) = null output, @taxstate varchar(4) = null output, 
   	@uselocal bYN = null output, @local bLocalCode = null output, @unempstate varchar(4) = null output, 
    	@craft bCraft = null output, @cert bYN = null output, @inscode bInsCode = null output, @glco bCompany = null output, 
    	@emprate bUnitCost = null output, @class bClass = null output, @jcco bCompany output, 
    	@job bJob output, @salaryamt bDollar = null output, @earncode bEDLCode = null output, 
    	@useins bYN = null output, @shift tinyint = null output, @msg varchar(60) output)
   
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0
    	
   -- validate Employee and get default values 
   select @prdept = PRDept, @crew = Crew, @usestate = UseState, @insstate = InsState, @taxstate = TaxState, 
   	@uselocal = UseLocal, @useins = UseIns, @local = LocalCode, @unempstate = UnempState, 
    	@craft = Craft, @cert = CertYN, @inscode = InsCode, @glco = GLCo, @emprate = HrlyRate,
   	@class = Class, @jcco = JCCo, @job = Job, @salaryamt = SalaryAmt, @earncode = EarnCode,
   	@shift = Shift
   from PREH
   where PRCo = @prco and Employee = @empl 
   if @@rowcount = 0
   	begin
    	select @msg = 'Not a valid Employee', @rcode = 1
    	goto bspexit
    	end
    
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPREmployeeInfoGet] TO [public]
GO
