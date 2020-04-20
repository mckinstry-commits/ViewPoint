SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRProcessGetBasisPreTax    Script Date: 8/28/99 9:35:37 AM ******/
CREATE procedure [dbo].[vspPRProcessGetBasisPreTax]
/***********************************************************
* MODIFIED BY:  MV  10/07/2013 - TFS-57069
*
* USAGE:
* Calculates earning code basis amounts for pretax deductions
* Called FROM bspPRProcessGetBasis for State, Local and Insurance codes
*		to calculate prorated amounts for state, local and insurance pretax deductions.
* 
* INPUT PARAMETERS
*   @PRCo          PR Company
*   @PRGroup       PR Group
*   @PREndDate     Pay Period ending date
*   @Employee      Employee
*   @PaySeq        Payment Sequence
*   @Method        DL calculation method
*   @DLCode        DL code
*   @DLType        DL code type (D)
*	@PreTaxCode	   Pretax DL Code
*   @CalcCategory  DL code calculation category
* 
* OUTPUT PARAMETERS
*   @PreTaxBasis   pretax basis amount for dlcode being worked on
*   @TotalBasis    basis amount for all earnings for this employee that have the pretax code
*   @ErrMsg  	    error message IF something went wrong
* 
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
@PRCo bCompany,
@PRGroup bGroup,
@PREndDate bDate,
@Employee bEmployee,
@PaySeq  tinyint,
@Method varchar(10),
@DLCode bEDLCode, 
@DLType char(1), 
@PreTaxCode bEDLCode,
@CalcCategory varchar(1), 
@StateTaxDednCode bEDLCode = NULL,
@CalcDiff bYN = NULL,
--@basedon bYN = NULL, -- U for Unemp State and T for Tax State
@PreTaxBasis bDollar output, 
@TotalBasis bDollar output,
@ErrMsg varchar(255) output
   
AS
SET NOCOUNT ON

SELECT @PreTaxBasis = 0, @TotalBasis = 0

	
IF @CalcCategory = 'S'
BEGIN
	-- Get PreTax Basis: Based on one line in PRTH so this works for both Dedns and Liabs
	SELECT @PreTaxBasis = CASE @Method
							WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
							END
	FROM dbo.PRTH t
	JOIN dbo.PRSI s on t.PRCo = s.PRCo and t.TaxState= s.State 
		AND s.TaxDedn = CASE ISNULL(@CalcDiff, 'N') WHEN 'Y' THEN ISNULL(@StateTaxDednCode,@DLCode) ELSE @DLCode END
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = s.TaxDedn and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 

		SELECT @TotalBasis = CASE @Method
								WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
	END
		FROM dbo.PRTH t
	JOIN dbo.PRSI s on t.PRCo = s.PRCo and t.TaxState= s.State 
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = s.TaxDedn and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 
END
ElSE IF @CalcCategory = 'L'
BEGIN
	SELECT @PreTaxBasis =	CASE @Method
								WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
							END
	FROM dbo.PRTH t
	JOIN dbo.PRLI l on t.PRCo = l.PRCo and t.LocalCode= l.LocalCode and l.TaxDedn = @DLCode
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = l.TaxDedn and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 
		
		SELECT @TotalBasis = CASE @Method
							 WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
	END
							FROM dbo.PRTH t
	JOIN dbo.PRLI l on t.PRCo = l.PRCo and t.LocalCode= l.LocalCode
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = l.TaxDedn and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 
	
END
ELSE IF @CalcCategory = 'I'
BEGIN
	SELECT @PreTaxBasis =	CASE @Method
								WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
							END
	FROM dbo.PRTH t
	JOIN dbo.PRIN l on t.PRCo = l.PRCo and t.InsState = l.State and t.InsCode = l.InsCode
	JOIN dbo.PRID i on l.PRCo = i.PRCo and l.State = i.State and l.InsCode = i.InsCode and i.DLCode = @DLCode
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = i.DLCode and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 
		
	SELECT @TotalBasis = CASE @Method
								WHEN 'D' THEN COUNT(DISTINCT t.PostDate)
								WHEN 'F' THEN ISNULL(SUM(t.Hours),0.00)
								WHEN 'H' THEN ISNULL(SUM(t.Hours),0.00)						
								ELSE ISNULL(SUM(t.Amt),0.00)
							END
	FROM dbo.PRTH t
	JOIN dbo.PRIN l on t.PRCo = l.PRCo and t.InsState = l.State and t.InsCode = l.InsCode
	JOIN dbo.PRID i on l.PRCo = i.PRCo and l.State = i.State and l.InsCode = i.InsCode 
	JOIN dbo.PRDB b on t.PRCo=b.PRCo and b.DLCode = i.DLCode and b.EDLType = 'D' and b.EDLCode = @PreTaxCode
	JOIN dbo.PRDB b2 on t.PRCo = b2.PRCo and b2.DLCode = @PreTaxCode and b2.EDLType = 'E' and b2.EDLCode = t.EarnCode
	WHERE t.PRCo = @PRCo and t.Employee = @Employee and t.PRGroup = @PRGroup and t.PREndDate = @PREndDate and t.PaySeq = @PaySeq
		and b2.SubjectOnly = 'N' 
		
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[vspPRProcessGetBasisPreTax] TO [public]
GO
