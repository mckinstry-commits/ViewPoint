SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Mike Brewer
-- Create date: 7/8/2010
-- Description:	This procedure is used by Michigan
-- subreport the Schedule A Form 940 report
-- it returns Total taxable FUTA wages paid
-- in Michigan 
--
-- changes:	
--huyh - #141007 rename EarnCode to EDLCode 
--		and filter by EDLType = 'E' reviewed by charleyw
--	Charley #126535 12/8/2010 
--      Added Indiana and South Carolina processing
--  Charley #143020 02/22/2011
--	    Changed processing to select based FUTA wages by Tax State 
--		rather than unemployment date.  Use the paid date(PRSQ.PaidMth)
--		rather than PREndDate so wages are in the correct tax year. Limit
--		the FUTA wages to #employees * 7000 dollars.
-- Charley #143631 03/18/2011
--      Change TaxState to UnempState and added code to ensure
--      the maximun credit amount per employee is 7000 dollars.
--
-- GG - #143631 - 3/24/2011 - Cleanup - modified to calculate state credits based on employee accums
--
-- =============================================
CREATE PROCEDURE [dbo].[vrptPRForm940ScedAPart2]
(@PRCo bCompany, @Year int)

--For testing purposes uncomment the following parameters 
--and comment out the production parameters 
--(@PRCo bCompany =1
--, @Year int = 2010)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @FUTACode bEDLCode

--determine FUTA code
select @FUTACode = FUTALiab from PRFI
where PRCo = @PRCo

--Create table varibale to hold year-to-date unemployment wages by employee and state
DECLARE @FUTACredits TABLE (Amt Numeric(12,2), Employee bEmployee, [State] varchar(4))

-- Get year-to-date unemployment wages for each employee by state
-- Assumes FUTA basis earnings codes match SUTA basis earnings codes
-- Amounts are pulled from employee accums to handle new sites (i.e. no detail) as well as year-end corrections
INSERT INTO @FUTACredits
SELECT SUM(e.SubjectAmt),e.Employee, s.[State]
FROM PREA e
JOIN PRSI s ON s.PRCo = e.PRCo AND s.SUTALiab = e.EDLCode AND e.EDLType = 'L'
WHERE e.PRCo = @PRCo
 AND DATEPART(yyyy,e.Mth) = @Year
GROUP BY e.Employee, s.[State]

--Apply FUTA wage limit to state unemployment subject earnings
UPDATE @FUTACredits
SET Amt = 7000	-- hardcoded $7000 annual FUTA subject earnings limit
WHERE Amt > 7000

-- ****** This section changes annually *******
--Returns total eligible FUTA wages for states allowed a credit reduction and the amount of reduction on the Schedule A (Form 940).
SELECT 
	 sum (CASE WHEN [State] ='IN' THEN isnull(Amt,0.00) Else 0 End)  as '2a'
	,(sum (CASE WHEN [State] ='IN' THEN isnull(Amt,0.00) Else 0 End)) * .003  as '2b'
	,sum (CASE WHEN [State] ='MI' THEN isnull(Amt,0.00) Else 0 End)  as '2c'
	,(sum (CASE WHEN [State] ='MI' THEN isnull(Amt,0.00) Else 0 End)) * .006  as '2d'
	,sum (CASE WHEN [State] ='SC' THEN isnull(Amt,0.00) Else 0 End)  as '2e'
	,(sum (CASE WHEN [State] ='SC' THEN isnull(Amt,0.00) Else 0 End)) * .003  as '2f'
FROM @FUTACredits
END


----determine EarnCodes related to FUTA
--declare @EarnCodeTable table (EarnCode bEDLCode)
-- insert into @EarnCodeTable

--select EDLCode from PRDB
--	where DLCode = @FUTACode
--	and PRCo = @PRCo
--	and EDLType = 'E'
	
----Select all employee payment transactions(PRTH and PRTA)regardless 
----of what state they worked in.
--DECLARE @EmployeeTotalPay TABLE (Amt Numeric(12,2), PREndDate bDate, Employee bEmployee,UnempState varchar(4),TableName varchar(4) )
--INSERT INTO @EmployeeTotalPay

--	SELECT
--	PRTH.Amt as Amt, PRTH.PREndDate, PRTH.Employee, PRTH.UnempState, 'PRTH'
--	FROM PRSQ PRSQ
--	INNER JOIN PRTH  PRTH  --Timecard Header
--		ON 	PRSQ.PRCo = PRTH.PRCo AND PRSQ.PRGroup = PRTH.PRGroup AND PRSQ.PREndDate = PRTH.PREndDate
--		AND PRSQ.Employee = PRTH.Employee AND PRSQ.PaySeq = PRTH.PaySeq
--	WHERE PRTH.PRCo = @PRCo
--	and DatePart(YYYY,PRSQ.PaidMth) = @Year
--	and PRTH.EarnCode in (SELECT EarnCode FROM @EarnCodeTable)
	
--	Union All
	
--	SELECT
--	PRTA.Amt as  Amt, PRTA.PREndDate, PRTA.Employee, PRTH.UnempState as UnempState, 'PRTA'
--	FROM PRTA PRTA --Timecard Addons
--	INNER JOIN PRTH PRTH --Timecard Header
--		ON  PRTH.PRCo = PRTA.PRCo AND PRTH.PRGroup = PRTA.PRGroup AND PRTH.PREndDate = PRTA.PREndDate
--		AND PRTH.Employee = PRTA.Employee AND PRTH.PaySeq = PRTA.PaySeq	AND PRTH.PostSeq = PRTA.PostSeq
--	INNER JOIN PRSQ PRSQ
--			ON 	PRSQ.PRCo = PRTA.PRCo AND PRSQ.PRGroup = PRTA.PRGroup AND PRSQ.PREndDate = PRTA.PREndDate
--		AND PRSQ.Employee = PRTA.Employee AND PRSQ.PaySeq = PRTA.PaySeq

--	WHERE PRTA.PRCo = @PRCo
--	and DatePart(YYYY,PRSQ.PaidMth) = @Year
--	and PRTA.EarnCode in 
--		(select EarnCode from @EarnCodeTable)

----DEBUG uncomment to display table	
----SELECT '@EmployeeTotalPay',* FROM @EmployeeTotalPay

----Calculate the state wages for each employee 
--DECLARE @EmployeeByStatePay TABLE (Amt Numeric(12,2), Employee bEmployee,UnempState varchar(4) )
--INSERT INTO @EmployeeByStatePay
--	SELECT 
--	 SUM (Amt) as Amt
--	,Employee
--	,UnempState
--	FROM @EmployeeTotalPay
--	GROUP BY	Employee  ,UnempState 
----DEBUG uncomment to display table	
----SELECT '@EmployeeByStatePay',* FROM @EmployeeByStatePay
	
----Limit the state wages for each employee to a maximun of 7000 
--DECLARE @EmployeeByStatePay7000 TABLE (Amt Numeric(12,2), Employee bEmployee,UnempState varchar(4) )
--INSERT INTO @EmployeeByStatePay7000
--	SELECT 
--	 Amt = CASE  WHEN Amt > 7000 THEN 7000 ELSE Amt END
--	,Employee
--	,UnempState
--	FROM @EmployeeByStatePay 
----DEBUG uncomment to display table	
----SELECT '@EmployeeByStatePay7000',* FROM @EmployeeByStatePay7000


----Count the number of employees in each state and calculate the total state wage for FUTA liability
--DECLARE @EmployeeStatePay TABLE (EmployeeCount int,FUTAUnempStateAmt decimal(12,2),UnempState varchar(4))
--INSERT INTO @EmployeeStatePay
--	SELECT
--	COUNT(*) as EmployeeCount
--	,SUM(Amt) as FUTAUnempStateAmt
--	,UnempState
--	FROM @EmployeeByStatePay7000
--	GROUP BY	UnempState
	
----DEBUG uncomment to display table	
----SELECT '@EmployeeStatePay',* FROM @EmployeeStatePay

----Calculate the FUTA wages for states allowed a credit reduction and the amount of reduction on the Schedule A (Form 940).
--select 
-- sum (CASE WHEN UnempState ='IN' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)  as '2a'
--,(sum (CASE WHEN UnempState ='IN' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)) * .003  as '2b'
--,sum (CASE WHEN UnempState ='MI' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)  as '2c'
--,(sum (CASE WHEN UnempState ='MI' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)) * .006  as '2d'
--,sum (CASE WHEN UnempState ='SC' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)  as '2e'
--,(sum (CASE WHEN UnempState ='SC' THEN isnull(FUTAUnempStateAmt,0.00) Else 0 End)) * .003  as '2f'
--from 
--@EmployeeStatePay

--END



GO
GRANT EXECUTE ON  [dbo].[vrptPRForm940ScedAPart2] TO [public]
GO
