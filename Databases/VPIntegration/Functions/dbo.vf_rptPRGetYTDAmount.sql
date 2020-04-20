SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[vf_rptPRGetYTDAmount] 
/*********************************************************** 
* 
* 
* Inputs:    @PRCo int 
*            @Employee int 
*            @EDLType varchar(255) 
*            @EDLCode int 
*            @PREndDate smalldatetime  
*            @PaySeq tinyint 
*            @PaidMth bMonth 
* 
* Returns:   Year-To-Date Amount 
* 
* This function returns the calculated ytd amt as accums + net 
* from current and earlier Pay Pds - old from later Pay Pds. The 
* logic is based on stored proc dbo.bspPRCheckProcess.
* 
* 
* Maintenance Log: HH 03/12/2012 initial version D-04661
*					MV 08/09/2012 B-10562/TK-16945 Arrears/Payback
* 
*****************************************************/ 
(
	@PRCo      bCompany = NULL, 
	@Employee  bEmployee = NULL, 
	@EDLType   CHAR = NULL, 
	@EDLCode   bEDLCode = NULL, 
	@PREndDate bDate = NULL, 
	@PaySeq    TINYINT = NULL, 
	@PaidMth   bMonth = NULL
) 
RETURNS bDollar 
AS 
  BEGIN 
      
      --set @PRCo = 1 
      --set @Employee = 1 
      --set @EDLType = 'E' 
      --set @EDLCode = 1 
      --set @PREndDate = '2011-06-30' 
      --set @PaySeq = 1 
      --set @PaidMth = '2011-06-30' 
      
      DECLARE @a1 bDollar, 
			  @a2 bDollar, 
			  @a3 bDollar, 
			  @a4 bDollar, 
			  @amt bDollar,
			  @PaybackAmt bDollar 
      
      DECLARE @mthvalue   TINYINT, 
              @yearendmth TINYINT, 
              @yearvalue  INT 
      
      DECLARE @accumbeginmth SMALLDATETIME, 
			  @accumendmth SMALLDATETIME 
      
      DECLARE @DefaultCountry VARCHAR(255) 

      SELECT @DefaultCountry = DefaultCountry 
      FROM   HQCO 
      WHERE  HQCo = @PRCo 

      IF @DefaultCountry = 'AU' 
        BEGIN 
            SET @yearendmth = 6 
        END 
      ELSE 
        SET @yearendmth = 12 

      -- determine month and year values from input month   
      SELECT @mthvalue = Datepart(MONTH, @PaidMth), 
             @yearvalue = Datepart(YEAR, @PaidMth) 

      -- increment year if month value comes after year ending month 
      IF @mthvalue > @yearendmth 
        SELECT @yearvalue = @yearvalue + 1 

      -- compute beginning and ending months for the year 
      SELECT @accumendmth = CONVERT(VARCHAR, @yearendmth) + '/1/' + 
                                   CONVERT(VARCHAR, @yearvalue) 

	  -- beginning month is 11 months earlier 
      SELECT @accumbeginmth = Dateadd(MONTH, -11, @accumendmth) 
      
      -- get YTD amounts from Employee Accums to pull prior amounts and adjustments
      SELECT @a1 = Isnull(SUM(Amount), 0) 
      FROM   dbo.bPREA WITH (nolock) 
      WHERE  PRCo = @PRCo 
             AND Employee = @Employee 
             AND Mth BETWEEN @accumbeginmth AND @accumendmth 
             AND EDLType = @EDLType 
             AND EDLCode = @EDLCode 

	  -- get current amounts from current and earlier Pay Periods where Final Accum update has not been run
      SELECT @a2 = 
					(
						ISNULL(SUM(CASE d.UseOver WHEN 'Y' THEN d.OverAmt ELSE d.Amount END), 0)
					)
				+ 
					(
						ISNULL(SUM(CASE WHEN d.PaybackOverYN='Y' THEN d.PaybackOverAmt ELSE d.PaybackAmt END),0)
					)
      FROM   dbo.bPRDT d WITH (nolock) 
             JOIN dbo.bPRSQ s WITH (nolock) 
               ON s.PRCo = d.PRCo 
                  AND s.PRGroup = d.PRGroup 
                  AND s.PREndDate = d.PREndDate 
                  AND s.Employee = d.Employee 
                  AND s.PaySeq = d.PaySeq 
             JOIN dbo.bPRPC c WITH (nolock) 
               ON c.PRCo = d.PRCo 
                  AND c.PRGroup = d.PRGroup 
                  AND c.PREndDate = d.PREndDate 
      WHERE  d.PRCo = @PRCo 
             AND d.Employee = @Employee 
             AND d.EDLType = @EDLType 
             AND d.EDLCode = @EDLCode 
             AND ( ( d.PREndDate < @PREndDate ) 
                    OR ( d.PREndDate = @PREndDate 
                         AND d.PaySeq <= @PaySeq ) ) 
             AND ( ( s.PaidMth IS NULL 
                     AND c.MultiMth = 'N' 
                     AND c.BeginMth BETWEEN @accumbeginmth AND @accumendmth ) 
                    OR ( s.PaidMth IS NULL 
                         AND c.MultiMth = 'Y' 
                         AND c.EndMth BETWEEN @accumbeginmth AND @accumendmth ) 
                    OR ( s.PaidMth BETWEEN @accumbeginmth AND @accumendmth ) ) 
             AND c.GLInterface = 'N' 

	  -- get old amounts from current and earlier Pay Periods where Final Accum update has not been run
      SELECT @a3 = 
					(
						ISNULL(SUM(OldAmt), 0)
					)
				 +  
					(
						ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0)
					)
      FROM   dbo.bPRDT d WITH (nolock) 
             JOIN dbo.bPRPC c WITH (nolock) 
               ON c.PRCo = d.PRCo 
                  AND c.PRGroup = d.PRGroup 
                  AND c.PREndDate = d.PREndDate 
      WHERE  d.PRCo = @PRCo 
             AND d.Employee = @Employee 
             AND d.EDLType = @EDLType 
             AND d.EDLCode = @EDLCode 
             AND ( ( d.PREndDate < @PREndDate ) 
                    OR ( d.PREndDate = @PREndDate 
                         AND d.PaySeq <= @PaySeq ) ) 
             AND d.OldMth BETWEEN @accumbeginmth AND @accumendmth 
             AND c.GLInterface = 'N' 

	  -- get old amount from later Pay Periods - need to back out of accums
      SELECT @a4 = 
					(
						ISNULL(SUM(OldAmt), 0)
					)
				 +  
					(
						ISNULL(SUM(CASE WHEN PaybackOverYN='Y' THEN PaybackOverAmt ELSE PaybackAmt END),0)
					)	 
      FROM   dbo.bPRDT WITH (nolock) 
      WHERE  PRCo = @PRCo 
             AND Employee = @Employee 
             AND EDLType = @EDLType 
             AND EDLCode = @EDLCode 
             AND ( ( PREndDate > @PREndDate ) 
                    OR ( PREndDate = @PREndDate 
                         AND PaySeq > @PaySeq ) ) 
             AND OldMth BETWEEN @accumbeginmth AND @accumendmth 

	  -- calculate ytd amt as accums + net from current and earlier Pay Pds - old from later Pay Pds
      SELECT @amt = @a1 + ( @a2 - @a3 ) - @a4 

BSPEXIT: 

      RETURN @amt 
  END 
GO
GRANT EXECUTE ON  [dbo].[vf_rptPRGetYTDAmount] TO [public]
GO
