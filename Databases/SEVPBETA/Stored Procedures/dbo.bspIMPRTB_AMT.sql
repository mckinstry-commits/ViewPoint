SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspIMPRTB_AMT]
/********************************************************
* CREATED BY: 	DANF 05/16/00
* MODIFIED BY:    DANF 05/11/01 - corrected to is nullssss.
*		CC 10/17/08 - Adjusted when earn method is 'A' and distributed earnings = 'Y'
*		CC 02/05/09 Issue 132058 - Prevent divide by 0 error if Pay Period Hours is 0
*		TJL 08/10/10 - Issue #140781, Minor adjustment when Earning Method ='A' and Rate = 0.00 set Amount = 0.00
*		
* USAGE:
* 	Retrieves PR AMOUNT FROM PREH
*
* INPUT PARAMETERS:
*	PR Company
*   PR Employee
*
* OUTPUT PARAMETERS:
*	AMOUNT from bPREH
*	Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
   
(@prco bCompany = 0, 
@employee bEmployee, 
@Earncode bEDLCode, 
@Hours bHrs, 
@PRGroup bGroup,
@PREndDate bDate,
@Rate bUnitCost output, 
@amt bDollar output, 
@msg varchar(60) output) as

set nocount on
declare @rcode int, @salamt bDollar, @salearn bEDLCode, @method  char(1), @IsDistributedEarnings bYN, @PayPeriodHours bHrs
select @rcode = 0

if @prco = 0
	begin
	select @msg = 'Missing PR Company#!', @rcode = 1
	goto bspexit
	end

--Can be (Hours * Employee/CraftClass Rate)
--Can also be (Hours * Earn Method = 'A' Rate) based on Pay Period Hours
If isnull(@Hours,0)<>0 and  isnull(@Rate,0) <> 0
	begin
	select @amt = @Hours * @Rate
	goto bspexit
	end
 
--Past this point we are primarily dealing with Earn Method = 'A'  
select @method = Method, @IsDistributedEarnings = IncldSalaryDist
from bPREC
where PRCo = @prco and EarnCode = @Earncode

select @salamt = SalaryAmt, @salearn = EarnCode
from bPREH
where PRCo = @prco and Employee = @employee
if @@rowcount = 0
	begin
	select @msg = 'Employee is not on File.', @rcode=1, @employee=0, @amt = null
	goto bspexit
	end

SELECT @PayPeriodHours = Hrs FROM PRPC WHERE PRCo = @prco AND PRGroup = @PRGroup and PREndDate = @PREndDate

If @method ='A' and isnull(@amt,0) = 0  and isnull(@salamt,0) <> 0 and @Earncode = @salearn and isnull(@PayPeriodHours,0)<>0
	begin
	select @amt = @salamt, @Rate = @salamt / @PayPeriodHours
	end

--This seems redundant but would have to be carefully evaluated and compared to the above statement
--and then carefully tested if removed or adjusted.
If @method = 'A' and isnull(@amt,0) = 0 select @amt = @salamt
if isnull(@PayPeriodHours,0)<>0 select @Rate = @amt / @PayPeriodHours

--Based on Earn Code "Include in Salary Distribution Calculations" setting
IF ISNULL(@method,'') ='A' AND (ISNULL(@IsDistributedEarnings, 'N') = 'Y' OR ISNULL(@Rate, 0)= 0) 
	BEGIN
	SELECT @amt = 0, @Rate = 0
	END

bspexit:
if @rcode<>0 select @msg=isnull(@msg,'Amount') + char(13) + char(10) + '[bspIMPRTB_AMT]'
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspIMPRTB_AMT] TO [public]
GO
