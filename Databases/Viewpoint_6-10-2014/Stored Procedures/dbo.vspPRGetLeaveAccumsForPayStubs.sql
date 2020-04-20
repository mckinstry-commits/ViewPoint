SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspPRGetLeaveAccumsForPayStubs]
/***********************************************************
* Created: EN 1/17/2013 - D-06530/#142769/TK-20813 Created to normalize common code used by 3 other stored procedure
* Modified:	
*
* USAGE:
* Determines leave accumulations for PR check and direct deposit stubs and adds this info to bPRSX.
* Used by stored procedures vspPRDirectDepositStubProcess, bspPRCheckProcess and bspPRCheckStubLoad.
*
* INPUT PARAMETERS
*   @prco				PR Company #
*   @prgroup			PR Group
*   @employee  			Employee number
*   @periodenddate		Pay Period End Date
*   @yearbeginmth		First month in current year ... used for determining employee accumulations in PREA
*   @payseq				Payment Seq #
*              
* OUTPUT PARAMETERS
*   @msg      		error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
*******************************************************************/
(@prco bCompany = NULL, 
 @prgroup bGroup = NULL,
 @employee bEmployee = NULL, 
 @periodenddate bDate = NULL,
 @yearbeginmth bMonth = NULL, 
 @payseq tinyint = NULL,
 @msg varchar(255) OUTPUT)
	 
AS
SET NOCOUNT ON

DECLARE @PeriodBeginDate bDate,
		@LeaveCode bLeaveCode,
		@Description varchar(30), 
		@AvailableBalance bDollar, 
		@PayPdUsage bDollar, 
		@YTDUsage bDollar

-- validate input parameters
IF  @prco IS NULL OR 
    @prgroup IS NULL OR
    @employee IS NULL OR
    @periodenddate IS NULL OR
    @yearbeginmth IS NULL OR
    @payseq IS NULL
BEGIN
	SELECT @msg = 'Must provide PR Co#, PR Group, Employee, PR End Date, Year Begin Month, and payment sequence number.'
	RETURN 1
END

-- get Beginning Date
SELECT @PeriodBeginDate = BeginDate
FROM dbo.bPRPC WITH (NOLOCK)
WHERE PRCo = @prco 
	  AND PRGroup = @prgroup 
	  AND PREndDate = @periodenddate
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Missing PR Control entry for this Pay Period!'
	RETURN 1
END
		
-- initialize a cursor for Leave Code info
DECLARE bcLeaveCodes CURSOR FOR
SELECT l.LeaveCode, l.Description, e.AvailBal
FROM dbo.bPRLV l WITH (NOLOCK)
JOIN dbo.bPRGV g WITH (NOLOCK) ON l.PRCo = g.PRCo AND l.LeaveCode = g.LeaveCode
JOIN dbo.bPREL e WITH (NOLOCK) ON l.PRCo = e.PRCo AND l.LeaveCode = e.LeaveCode
WHERE l.PRCo = @prco 
	  AND g.PRGroup = @prgroup 
	  AND e.Employee = @employee

OPEN bcLeaveCodes

-- get first cursor item
FETCH NEXT FROM bcLeaveCodes INTO @LeaveCode, @Description, @AvailableBalance

-- loop through cursor
WHILE @@fetch_status = 0
BEGIN
	SELECT @PayPdUsage = 0, @YTDUsage = 0
 
	-- get current period usage amount
	SELECT @PayPdUsage = ISNULL(SUM(Amt),0)
	FROM dbo.bPRLH WITH (NOLOCK)
	WHERE PRCo = @prco
		  AND Employee = @employee
		  AND LeaveCode = @LeaveCode
		  AND [Type] = 'U'
		  AND ActDate BETWEEN @PeriodBeginDate AND @periodenddate

	-- get YTD usage amount
	SELECT @YTDUsage = ISNULL(SUM(Amt),0)
	FROM dbo.bPRLH WITH (NOLOCK)
	WHERE PRCo = @prco 
		  AND Employee = @employee 
		  AND LeaveCode = @LeaveCode 
		  AND [Type] = 'U' 
		  AND ActDate BETWEEN @yearbeginmth AND @periodenddate
		
	-- insert Leave Code info into check stub detail
	INSERT dbo.bPRSX 
		(PRCo,			PRGroup,	PREndDate,		Employee,		PaySeq,		[Type], 
		 Code,			Rate,		[Description],	Amt1,			Amt2,		Amt3)
	VALUES
		(@prco,			@prgroup,	@periodenddate,	@employee,		@payseq,	'V', 
		 @LeaveCode,	0,			@Description,	@PayPdUsage,	@YTDUsage,	@AvailableBalance)

	-- get next cursor item
	FETCH NEXT FROM bcLeaveCodes INTO @LeaveCode, @Description, @AvailableBalance

END

-- cursor cleanup
CLOSE bcLeaveCodes
DEALLOCATE bcLeaveCodes
 

RETURN 0    
GO
GRANT EXECUTE ON  [dbo].[vspPRGetLeaveAccumsForPayStubs] TO [public]
GO
