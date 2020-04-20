SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[bspPRMPT11]    Script Date: 12/13/2007 15:22:31 ******/
CREATE  proc [dbo].[bspPRMPT11]
/********************************************************
* CREATED BY: 	CHS 05/12/11
* MODIFIED BY:  
*
* USAGE:
* 	Calculates Saipan (MP) Income Tax by calling Federal tax routine.
*
* INPUT PARAMETERS:
*	@prco		PR Company - used to lookup fed tax routine
*	@subjamt 	subject earnings
*	@ppds		# of pay pds per year
*	@status		filing status (S or M)
*	@exempts	# of exemptions
*
* OUTPUT PARAMETERS:
*	@amt		calculated Fed tax amount
*	@msg		error message if failure
*
* RETURN VALUE:
* 	0 	    	success
*	1 		failure
**********************************************************/
(@prco bCompany = 0, @calcbasis bDollar = 0, @ppds tinyint = 0, @filestatus char(1) = 'S', @regexempts tinyint = 0,
   	@calcamt bDollar = 0 output, @errmsg varchar(255) = null output)
	as
	set nocount on
  
	declare @rcode int, @nonresalienyn bYN, @dlcode bEDLCode, @routine varchar(10), @procname varchar(30)
  
	select @rcode = 0, @nonresalienyn = 'N'

	--lookup fed tax dedn code
	select @dlcode = TaxDedn from dbo.bPRFI with (nolock) where PRCo = @prco

	--lookup fed routine name
	select @routine = Routine
	from dbo.bPRDL with (nolock)
   	where PRCo = @prco and DLCode = @dlcode
	if @@rowcount = 0
		begin
		select @errmsg = 'Federal tax deduction code ' + convert(varchar(4),@dlcode) + ' not setup!', @rcode = 1
		goto bspexit
		end

	--lookup fed routine procedure name
	select @procname = null
	select @procname = ProcName from dbo.bPRRM with (nolock) where PRCo = @prco and Routine = @routine
	if @procname is null
		begin
		select @errmsg = 'Missing Routine procedure name for Federal tax deduction code ' + convert(varchar(4),@dlcode), @rcode = 1
		goto bspexit
		end

	--execute federal routine to compute tax amount
	exec @rcode = @procname @calcbasis, @ppds, @filestatus, @regexempts, @nonresalienyn, @calcamt output, @errmsg output


   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRMPT11] TO [public]
GO
