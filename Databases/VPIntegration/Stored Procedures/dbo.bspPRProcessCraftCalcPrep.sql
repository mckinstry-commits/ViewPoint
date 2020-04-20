SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE          procedure [dbo].[bspPRProcessCraftCalcPrep]
/***********************************************************
* CREATED:  MV	11/02/10 - #140541
* MODIFIED:	
*
* USAGE:
* Gets required information and loads PRPE for a select Employee,Pay Seq and Pretax DL Code
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
        @dlcode bEDLCode, @craft bCraft, @class bClass,@template smallint,@effectdate bDate OUTPUT,
        @oldcaplimit bDollar OUTPUT,@newcaplimit bDollar OUTPUT,@recipopt char(1) OUTPUT,
        @jobcraft bCraft OUTPUT, @errmsg varchar(255) OUTPUT
    
     AS
	 SET NOCOUNT ON
     DECLARE @rcode INT
     SELECT @rcode = 0
    
    BEGIN
         -- clear Process Earnings
         DELETE dbo.bPRPE WHERE VPUserName = SUSER_SNAME()
    
         -- load Process Earnings with all earnings posted to this Craft/Class/Template for 
         INSERT dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt)   	
         	SELECT SUSER_SNAME(), h.PostSeq, h.PostDate, h.EarnCode, e.Factor, e.IncldLiabDist, h.Hours, h.Rate, h.Amt 
             FROM dbo.bPRTH h
             LEFT JOIN dbo.bJCJM j ON h.JCCo = j.JCCo AND h.Job = j.Job
             JOIN dbo.bPREC e ON e.PRCo = h.PRCo AND e.EarnCode = h.EarnCode
             JOIN dbo.bPRDB d ON d.PRCo=e.PRCo AND d.EDLCode=e.EarnCode AND d.EDLType='E'
             WHERE h.PRCo = @prco AND h.PRGroup = @prgroup AND h.PREndDate = @prenddate
                 AND h.Employee = @employee AND h.PaySeq = @payseq
                 AND h.Craft = @craft AND h.Class = @class
                 AND d.DLCode=@dlcode
                 AND ((j.CraftTemplate = @template) or (h.Job IS NULL AND @template IS NULL)
                 OR (j.CraftTemplate IS NULL AND @template IS NULL))
    
         INSERT dbo.bPRPE ( VPUserName, PostSeq, PostDate, EarnCode, Factor, IncldLiabDist, Hours, Rate, Amt) 	
             SELECT SUSER_SNAME(), a.PostSeq, t.PostDate, a.EarnCode, e.Factor, e.IncldLiabDist, 0, a.Rate, a.Amt 
             FROM dbo.bPRTA a with (nolock)
             JOIN dbo.bPRTH t ON t.PRCo = a.PRCo AND t.PRGroup = a.PRGroup AND t.PREndDate = a.PREndDate
                 AND t.Employee = a.Employee AND t.PaySeq = a.PaySeq AND t.PostSeq = a.PostSeq
             LEFT JOIN dbo.bJCJM j with (nolock) ON t.JCCo = j.JCCo AND t.Job = j.Job
             JOIN dbo.bPREC e with (nolock) ON e.PRCo = a.PRCo AND e.EarnCode = a.EarnCode
             JOIN dbo.bPRDB d ON d.PRCo=e.PRCo AND d.EDLCode=e.EarnCode AND d.EDLType='E'
             WHERE a.PRCo = @prco AND a.PRGroup = @prgroup AND a.PREndDate = @prenddate
                 AND a.Employee = @employee AND a.PaySeq = @payseq
                 AND t.Craft = @craft AND t.Class = @class
                 AND d.DLCode=@dlcode
                 AND ((j.CraftTemplate = @template) OR (t.Job IS NULL AND @template IS NULL)
                 OR (j.CraftTemplate IS NULL AND @template IS NULL))
    
         -- get Craft/Class/Template info
         SELECT @effectdate = EffectiveDate 
         FROM dbo.bPRCM
         WHERE PRCo = @prco AND Craft = @craft
         IF @@ROWCOUNT = 0
             BEGIN
             SELECT @errmsg = 'Missing Craft ' + @craft + '.  Cannot process!', @rcode = 1
             GOTO bspexit
             END
         -- check for Template override
         SELECT @effectdate = EffectiveDate
         FROM dbo.bPRCT 
         WHERE PRCo = @prco AND Craft = @craft AND Template = @template AND OverEffectDate = 'Y'
    
         -- get Craft/Class Capped Code limits
         SELECT @oldcaplimit = OldCapLimit, @newcaplimit = NewCapLimit
         FROM dbo.bPRCC with (nolock)
         WHERE PRCo = @prco AND Craft = @craft AND Class = @class
         IF @@ROWCOUNT = 0
             BEGIN
             SELECT @errmsg = 'Missing Craft/Class ' + @craft + '/' + @class + '.  Cannot process!', @rcode = 1
             GOTO bspexit
             END
         -- check for Template override
         SELECT @oldcaplimit = OldCapLimit, @newcaplimit = NewCapLimit
         FROM dbo.bPRTC 
         WHERE PRCo = @prco AND Craft = @craft AND Class = @class AND Template = @template AND OverCapLimit = 'Y'
    
         -- set Reciprocal Craft defaults
         SELECT @recipopt = 'N', @jobcraft = null
         -- check for Template override
         SELECT @recipopt = RecipOpt, @jobcraft = JobCraft
         FROM dbo.bPRCT with (nolock)
         WHERE PRCo = @prco AND Craft = @craft AND Template = @template
    
     bspexit:
    
    END
     	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRProcessCraftCalcPrep] TO [public]
GO
