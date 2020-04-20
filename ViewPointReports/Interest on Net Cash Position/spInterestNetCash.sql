use Viewpoint
go

if exists (select 1 from sysobjects where type='P' and name='spInterestNetCash')
begin
	print 'DROP PROCEDURE spInterestNetCash'
	DROP PROCEDURE spInterestNetCash
end
go

print 'CREATE PROCEDURE spInterestNetCash'
go

CREATE PROCEDURE dbo.spInterestNetCash 
(
	@AsOf bMonth = NULL
,	@Co	  bCompany = 0
,	@Contract	bContract = null
)
AS

/*
2014.11.17 - LWO - Altered to exclude test companies and to honor company parameter being passed in (allowing null)

*/
SET NOCOUNT ON

DECLARE @ncpd_rate	bRate
DECLARE @ncpc_rate	bRate

IF @AsOf IS NULL SET @AsOf = DATEADD(mm, DATEDIFF(mm,0,getdate()), 0);

--2014.11.18 - LWO - Altered to ensure we get the most recent rate based on effective date
SELECT top 1 @ncpd_rate=Rate FROM udCompanyRates (NOLOCK) WHERE Co=@Co AND RateType='NCPD' AND EffectiveDate <= @AsOf ORDER BY EffectiveDate desc
SELECT top 1 @ncpc_rate=Rate FROM udCompanyRates (NOLOCK) WHERE Co=@Co AND RateType='NCPC' AND EffectiveDate <= @AsOf ORDER BY EffectiveDate desc


SELECT 
	CAST(hqco.HQCo AS VARCHAR(5)) + ' - ' + hqco.Name AS Company
,	ncp.Contract
,	jcmp.Name AS [Point of Contact]
,	glpi.Description AS [GL Department]  --   ADD GLDepartmentName from GLPI Part 3
,	(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END)) AS [Total JTD Cash Paid Out] --AS ActualCost 
,	SUM(ncp.ReceivedAmt) AS [Total JTD Cash Collected] --AS ActualReceived
,	SUM(ncp.ReceivedAmt)-(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END)) AS [Total JTD Net Cash Position] -- AS NetCashPosition 
/*
	Interest Rates defined by company as UD table associated to bHQCO [udCompanyRates] storing the debit/credit interest rates
	for each company individually by Financial Reporting period ( GLFY/GLFP )
*/
,	CASE
		WHEN (SUM(ncp.ReceivedAmt)-(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END))) <= 0 
		THEN CAST(((SUM(ncp.ReceivedAmt)-(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END))) * (NCPD.Rate/12)) AS DECIMAL(18,2))
		WHEN (SUM(ncp.ReceivedAmt)-(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END))) >= 0 
		THEN CAST(((SUM(ncp.ReceivedAmt)-(SUM(ncp.ActualCost)-SUM(CASE WHEN ncp.RecType=3 then ncp.APOpenAmt ELSE 0 END))) * (NCPC.Rate/12)) AS DECIMAL(18,2))
		ELSE 0
	END AS [Current Month Interest (Cost) / Earning] --Interest
,	NCPD.Rate*100 AS NCPDRate
,	NCPC.Rate*100 AS NCPCRate
FROM 
	JCCM jccm (NOLOCK) JOIN
	JCCI jcci (NOLOCK) ON
		jcci.JCCo=jccm.JCCo
	AND jcci.Contract=jccm.Contract
	AND jcci.udRevType<>'N' 
	AND jccm.ContractStatus<>3 JOIN
	brvJCWIPCashFlow ncp (NOLOCK) ON
	--brvJCContStat ncp (NOLOCK) ON
		ncp.JCCo=jccm.JCCo
	AND ncp.Contract=jccm.Contract 
	AND COALESCE(ncp.Item, (select top 1 Item from JCCI where JCCo=ncp.JCCo AND Contract=ncp.Contract and udRevType<>'N'))=jcci.Item JOIN
	JCDM jcdm (NOLOCK) ON
		jccm.JCCo=jcdm.JCCo AND 
		jccm.Department=jcdm.Department JOIN
	GLPI glpi (NOLOCK) ON 
		jcdm.GLCo = glpi.GLCo 
	AND SUBSTRING(jcdm.ClosedRevAcct,10,4) = glpi.Instance JOIN
	JCMP jcmp (NOLOCK) ON 
		jccm.udPOC = jcmp.ProjectMgr 
	-- 2014.11.18 - LWO - Corrected Join to use jcmp.JCCo instead of jcmp.udPRCo
	AND jccm.JCCo=jcmp.JCCo  
	JOIN (SELECT * FROM vwudCompanyRates  WHERE EffectiveDate <= @AsOf AND RateType='NCPD') AS NCPD ON NCPD.Co = ncp.JCCo 
	JOIN (SELECT * FROM vwudCompanyRates  WHERE EffectiveDate <= @AsOf AND RateType='NCPC') AS NCPC ON NCPC.Co = ncp.JCCo 
	JOIN HQCO hqco (NOLOCK) ON hqco.HQCo=ncp.JCCo and hqco.udTESTCo<>'Y'
WHERE 
	ncp.Mth < @AsOf 
  AND ( ncp.PaidMth >= @AsOf)
  AND ( ncp.JCCo=@Co or @Co = 0)
  AND ( ncp.Contract=@Contract or @Contract is null)
GROUP BY 
	ncp.JCCo
,	ncp.Contract
,	jccm.Description
,	jccm.Department
,	SUBSTRING(jcdm.ClosedRevAcct,10,4)
,	jccm.udPOC	
,	jcmp.Name 
,	glpi.Description
,	jcdm.Description
,	NCPD.Rate
,	NCPC.Rate
,	hqco.HQCo
,	hqco.Name 
ORDER BY 1 ASC
go


print 'grant exec on spInterestNetCash to public'
go

grant exec on spInterestNetCash to public
go

/*
spInterestNetCash '11/1/2014'
spInterestNetCash '11/1/2014',0
spInterestNetCash '11/1/2014',1, ' 10205-'
spInterestNetCash '11/1/2014',1, ' 10004-'

select * from brvJCContStat where JCCo=1 and Contract=' 10004-' and Mth <= '11/1/2014'
select sum(ReceivedAmt) as Rec, sum(ActualCost) as Cst, sum(ContractAmt) from brvJCContStat where JCCo=1 and Contract=' 10004-' and Mth <= '11/1/2014'
*/
