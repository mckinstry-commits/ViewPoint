SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE          procedure [dbo].[bspPRProcessEmplCalcPrep]
/***********************************************************
* CREATED:  MV	11/03/10 - #140541
* MODIFIED:	
*
* USAGE:
* Loads PRPE for a select Employee,Pay Seq and Pretax DL Code for
* Employee pretax code processing
* Called from bspPRProcess 'Pre Tax Processing' procedure.
*
* INPUT PARAMETERS
*   @prco	    PR Company
*   @prgroup	PR Group
*   @prenddate	PR Ending Date
*   @employee	Employee to process
*   @payseq	Payment Sequence #
*	@dlcode		Pre Tax DL Code
*	@craft/@class/@template  PRTH    
*
* OUTPUT PARAMETERS
*   @errmsg  	Error message if something went wrong
*	@effectdate 
*   @oldcaplimit
*	@newcaplimit
*	@recipopt 
*   @jobcraft  
*
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
    
     	@prco bCompany, @prgroup bGroup, @prenddate bDate, @employee bEmployee, @payseq tinyint,
        @dlcode bEDLCode
    
     AS
	 SET NOCOUNT ON
     DECLARE @rcode INT
     SELECT @rcode = 0
    
         -- clear Process Earnings
         DELETE dbo.bPRPE WHERE VPUserName = SUSER_SNAME()
    
         -- load Process Earnings with all earnings posted to this Employee and Pay Seq for this dlcode
         INSERT dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt)   	
         	SELECT SUSER_SNAME(), h.PostSeq, h.PostDate, h.EarnCode, e.Factor, e.IncldLiabDist, h.Hours, h.Rate, h.Amt 
             FROM dbo.bPRTH h
             JOIN dbo.bPREC e ON e.PRCo = h.PRCo AND e.EarnCode = h.EarnCode
             JOIN dbo.bPRDB d ON d.PRCo=e.PRCo AND d.EDLCode=e.EarnCode AND d.EDLType='E'
             WHERE h.PRCo = @prco AND h.PRGroup = @prgroup AND h.PREndDate = @prenddate
                 AND h.Employee = @employee AND h.PaySeq = @payseq
                 AND d.DLCode=@dlcode
                 
    
         INSERT dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) 	
             SELECT SUSER_SNAME(), a.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt 
             FROM dbo.bPRTA a with (nolock)
             JOIN dbo.bPRTH t ON t.PRCo = a.PRCo AND t.PRGroup = a.PRGroup AND t.PREndDate = a.PREndDate
                 AND t.Employee = a.Employee AND t.PaySeq = a.PaySeq AND t.PostSeq = a.PostSeq
             JOIN dbo.bPREC e with (nolock) ON e.PRCo = a.PRCo AND e.EarnCode = a.EarnCode
             JOIN dbo.bPRDB d ON d.PRCo=e.PRCo AND d.EDLCode=e.EarnCode AND d.EDLType='E'
             WHERE a.PRCo = @prco AND a.PRGroup = @prgroup AND a.PREndDate = @prenddate
                 AND a.Employee = @employee AND a.PaySeq = @payseq
                 AND d.DLCode=@dlcode
    
     bspexit:
    
     	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPRProcessEmplCalcPrep] TO [public]
GO
