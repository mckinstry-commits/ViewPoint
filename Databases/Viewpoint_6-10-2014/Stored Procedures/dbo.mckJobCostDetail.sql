SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.mckJobCostDetail(
    @Company bCompany
   ,@ConJobFlag char(1) = 'C'  -- C-Contract, J-Job
   ,@ConJobValue varchar(1000)
   ,@CostType tinyint = 0
   ,@BeginDate date = null
   ,@EndDate date = null
)
AS
/******************************************************************************************
* mkkJobcostDetail                                                                        *
*                                                                                         *
* Purpose: for SSRS Job Cost Transaction Detail Report                                    *
*                                                                                         *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================               *
* 2013/12/05	ZachFu	Created                                                           *
* 2014/04/24   ZachFu   Used function dbo.mfnEnumerateJobs to get job values              *
* 2014/06/06   ZachFu   Showed operator who is assigned to equipment for "OE" JCTransType *
*                                                                                         *
*                                                                                         *
*******************************************************************************************/
BEGIN

IF @ConJobValue IS NULL
   RETURN;

-- SSRS is passing default value of the previous week if not entered
-- Assignment below if for testing
IF @BeginDate IS NULL
   SET @BeginDate = CAST(DATEADD("d",-7,GETDATE()) AS date);

IF @EndDate IS NULL
   SET @EndDate = CAST(GETDATE() AS date);


;WITH SRCDetail
AS
(
SELECT
    jcjm.Contract AS Contract
	,RTRIM(LTRIM(bjcc.Job)) AS [Job]
	,bjcc.Phase
   ,ISNULL(jcjp.[Description],' ') AS [PhaseDesc]
	,ISNULL(jcct.Description,'Unknown') AS CostType
	,CAST(bjcc.ActualDate AS date) AS ActualDate
  	,bjcc.Source As Source
	,CASE
		WHEN jcct.CostType IN (1,5) THEN prehn.Employee -- Emp Number
      WHEN jcct.CostType = 4 THEN COALESCE(apvm.Vendor, prehn.Employee)
		ELSE apvm.Vendor
	 END AS SRCid
	,CASE
		WHEN jcct.CostType IN (1,5) THEN ISNULL(prehn.FullName,bjcc.DetlDesc)  -- Emp Name
      WHEN jcct.CostType = 4 THEN COALESCE(apvm.Name, prehn.FullName,bjcc.DetlDesc)
		ELSE ISNULL(apvm.Name,bjcc.DetlDesc) -- Vendor Name
	 END AS SRCname
	,COALESCE(bjcc.PO,bjcc.SL) AS POSL
	,bjcc.APRef AS APRef
   ,SUM(CASE WHEN bjcc.EarnType = 5 OR bjcc.EarnType IS NULL THEN bjcc.ActualHours ELSE 0 END) AS Reghrs
   ,SUM(CASE WHEN bjcc.EarnType = 6 THEN bjcc.ActualHours ELSE 0 END) AS OVhrs
   ,SUM(CASE WHEN bjcc.EarnType NOT IN (5,6) THEN bjcc.ActualHours ELSE 0 END) AS OThrs
   ,SUM(bjcc.ActualHours) AS ActualHrs
	,SUM(bjcc.ActualCost) AS ActualCost -- Tot Amount
  	,CAST(apph.PaidDate AS date) AS CheckDate
  	,apph.CMRef AS CheckNumber
	,apph.Amount AS CheckAmt
FROM 
	brvJCCDDetlDesc bjcc WITH (NOLOCK)
   JOIN
      [dbo].[mfnEnumerateJobs] (@ConJobValue,',',@ConJobFlag) enj
         ON RTRIM(LTRIM(enj.Job)) = RTRIM(LTRIM(bjcc.Job))
	JOIN
      JCJM jcjm WITH (NOLOCK)
         ON jcjm.JCCo = bjcc.JCCo
            AND RTRIM(LTRIM(jcjm.Job)) = RTRIM(LTRIM(bjcc.Job))
   JOIN
	   JCCT jcct WITH (NOLOCK)
			ON jcct.PhaseGroup = bjcc.PhaseGroup
			   AND jcct.CostType = bjcc.CostType
   LEFT JOIN
     HQCO hqco WITH (NOLOCK)
      ON hqco.HQCo = bjcc.JCCo
   LEFT JOIN
      APVM apvm WITH (NOLOCK)
         ON apvm.VendorGroup = bjcc.VendorGroup
            AND apvm.Vendor = bjcc.Vendor
   LEFT JOIN
      JCJP jcjp WITH (NOLOCK)
			ON  bjcc.JCCo = jcjp.JCCo
				AND RTRIM(LTRIM(bjcc.Job)) = RTRIM(LTRIM(jcjp.Job))
				AND bjcc.PhaseGroup = jcjp.PhaseGroup
				AND bjcc.Phase = jcjp.Phase
	LEFT JOIN
		[dbo].[PREHName] prehn WITH (NOLOCK)
			ON prehn.PRCo = bjcc.PRCo
			   AND prehn.Employee = bjcc.Employee
	LEFT JOIN
		APPD appd WITH (NOLOCK)   -- didn't cause dups
			ON  appd.APCo = bjcc.APCo
				 AND appd.APTrans = bjcc.APTrans
             AND appd.APRef = bjcc.APRef
	LEFT JOIN
      APPH apph WITH (NOLOCK) 
         ON apph.APCo = appd.APCo
			   AND apph.CMCo = appd.CMCo
			   AND apph.CMAcct = appd.CMAcct
			   AND apph.PayMethod = appd.PayMethod
			   AND apph.CMRef = appd.CMRef
			   AND apph.CMRefSeq = appd.CMRefSeq
			   AND apph.EFTSeq = appd.EFTSeq
WHERE
   bjcc.JCCo = @Company
   AND (bjcc.Phase >= ' ' AND bjcc.Phase <= 'zzzzzzzzzzzzzzzzzzzz')
   AND bjcc.ActualCost <> 0
   AND bjcc.ActualDate BETWEEN @BeginDate AND @EndDate
   AND (
         CASE
            WHEN @CostType <> 0 AND jcct.CostType = @CostType THEN 1
            WHEN @CostType = 0 THEN 1
         END
       ) = 1
GROUP BY
    bjcc.JCCo
   ,jcjm.Contract
	,bjcc.Job
	,bjcc.Phase
   ,ISNULL(jcjp.[Description],' ')
	,ISNULL(jcct.Description,'Unknown')
	,CAST(bjcc.ActualDate AS date)
  	,bjcc.Source
   ,CASE
		WHEN jcct.CostType IN (1,5) THEN prehn.Employee -- Emp Number
      WHEN jcct.CostType = 4 THEN COALESCE(apvm.Vendor, prehn.Employee)
		ELSE apvm.Vendor
	 END
	,CASE
		WHEN jcct.CostType IN (1,5) THEN ISNULL(prehn.FullName,bjcc.DetlDesc)  -- Emp Name
      WHEN jcct.CostType = 4 THEN COALESCE(apvm.Name, prehn.FullName,bjcc.DetlDesc)
		ELSE ISNULL(apvm.Name,bjcc.DetlDesc) -- Vendor Name
	 END
   ,bjcc.CostTrans
	,COALESCE(bjcc.PO,bjcc.SL)
	,bjcc.APRef
  	,CAST(apph.PaidDate AS date)
	,apph.CMRef
  	,apph.Amount
)
SELECT
    Contract
	,Job
 	,CostType
	,Phase
   ,PhaseDesc
	,ActualDate
  	,Source
	,SRCid
	,SRCname
	,POSL
	,APRef
   ,SUM(Reghrs) AS 'RG'
   ,SUM(OVhrs) AS 'OV'
   ,SUM(OThrs) AS 'OT'
   ,SUM(ActualHrs) AS TotHrs
	,SUM(ActualCost) As TotAmount
  	,CheckDate
	,CheckNumber
  	,CheckAmt
FROM
   SRCDetail
GROUP BY
    Contract
	,Job
 	,CostType
	,Phase
   ,PhaseDesc
	,ActualDate
  	,Source
	,SRCid
   ,SRCname
	,POSL
	,APRef
   ,CheckDate
	,CheckNumber
  	,CheckAmt
ORDER BY
    Contract
	,Job
 	,CostType
	,Phase
   ,ActualDate;

END
GO
GRANT EXECUTE ON  [dbo].[mckJobCostDetail] TO [public]
GO
