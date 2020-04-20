SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	  Mike Brewer
-- Create date: 8/25/09
-- Modified:    
-- Description: The month used to store Original Contract 
--and Estimate values has changed from JCCM Start Month to 
--JCCI Start Month.  Many JC Reports rely on JCCM Start Month 
--when aggregating and reporting cost and/or revenue values.  
--“JC Contract Master Start Month Exception Report” will help 
--identify contract items affected by the change, by listing 
--Contract Items where JCCM Start Month is different than JCCI 
--Start Month.  Other data listed in the report include Contract, 
--Contract Status, Contract Closed Month and Original Amounts 
--(Dollars and Units).
-- =============================================
CREATE PROCEDURE [dbo].[brptJCStartMthExcep]
--	
(@JCCo bCompany, 
@BeginContract bContract ='', 
@EndContract bContract= 'zzzzzzzzz', 
@BeginDate bDate = '01/01/51', 
@EndDate bDate)


AS
BEGIN

SET NOCOUNT ON;
--JC Contract Master Start Month Exception Report

Select
JCCI.JCCo, 
LTRIM(RTRIM(JCCM.Contract)) as 'Contract',
LTRIM(RTRIM(JCCM.Description)) as 'Description', 
case JCCM.ContractStatus
	when 1 then 'Open'
	when 2 then 'Soft Close'
	when 3 then 'Hard Close'
else '' end as 'ContractStatus',
JCCM.StartMonth as 'ContractStartMonth',
JCCM.MonthClosed,
LTRIM(RTRIM(JCCI.Item)) as 'Item',
LTRIM(RTRIM(JCCI.Description)) as 'Description',
JCCI.StartMonth as 'ItemStartMonth',
isnull(JCCI.OrigContractUnits, 0) as 'OrigContractUnits', 
isnull(JCCI.OrigContractAmt,0) as 'OrigContractAmt',
cast(HQCO.HQCo as varchar) + '   ' + HQCO.Name as 'Name'
FROM   JCCM  
INNER JOIN JCCI  
	ON JCCM.JCCo=JCCI.JCCo 
	AND JCCM.Contract=JCCI.Contract 
INNER JOIN HQCO  
	ON JCCM.JCCo=HQCO.HQCo 
WHERE  JCCI.JCCo=@JCCo
and (JCCM.Contract>=@BeginContract and JCCM.Contract<=@EndContract)
and JCCM.StartMonth <> JCCI.StartMonth
and (JCCM.StartMonth >= @BeginDate or JCCI.StartMonth >= @BeginDate)
and (JCCM.StartMonth <= @EndDate   or JCCI.StartMonth <= @EndDate)

END





GO
GRANT EXECUTE ON  [dbo].[brptJCStartMthExcep] TO [public]
GO
