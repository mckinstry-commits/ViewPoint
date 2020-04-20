USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckJobCostDetail]    Script Date: 12/16/2014 1:20:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[mckJobCostDetail](
    @Company bCompany
   --,@ConJobFlag char(1) = 'C'  -- C-Contract, J-Job
   ,@Contract bContract --= NULL
   ,@Job bJob = NULL
   ,@CostType tinyint = 0
   ,@BeginDate bDate = null
   ,@EndDate bDate = null
   ,@BeginGLMonth bMonth = null
   ,@EndGLMonth bMonth = null
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
* 2014/06/12   ZachFu   Joined to udEquipAttributes view to get Fleet information         *
* 2014/11/25   Mahendarb	1. Added "Posted Date" & GL Month 2. Removed Actual Date      *
* 2014/12/16   EricS	 Removed mfnEnumerateJobs because it's slow	 					  *
*                                                                                         *
*******************************************************************************************/
BEGIN

IF COALESCE(@Contract, @Job, '') = ''
   RETURN;

-- SSRS is passing default value of the previous week if not entered
-- Assignment below if for testing
IF @BeginDate IS NULL
   SET @BeginDate = DATEADD("d",-7,GETDATE())

IF @EndDate IS NULL
   SET @EndDate = GETDATE()
   
SET @BeginGLMonth = DATEADD("d",-(Day(@BeginGLMonth)) +1,@BeginGLMonth)
SET @EndGLMonth = DATEADD("d",-(Day(@EndGLMonth)) +1,@EndGLMonth)


SELECT @Job = REPLACE(@Job,'',NULL)
--SET @Contract = dbo.mfnFormatWithLeading(@Contract,' ',7)
--SET @Job = dbo.mfnFormatWithLeading(@Job, ' ', 10)

;WITH SRCDetail
AS
(
SELECT
    jcjm.Contract AS Contract
	,bjcc.Job
	,bjcc.Phase
   ,jcjp.[Description] AS [PhaseDesc]
	,ISNULL(jcct.Description,'Unknown') AS CostType
	--,bjcc.ActualDate
	,bjcc.PostedDate 
	,bjcc.Mth as GLMonth	
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
   ,eqa.Value AS Fleet
	,COALESCE(bjcc.PO,bjcc.SL) AS POSL
	,bjcc.APRef AS APRef
   ,SUM(CASE WHEN bjcc.EarnType = 5 OR bjcc.EarnType IS NULL THEN bjcc.ActualHours ELSE 0 END) AS Reghrs
   ,SUM(CASE WHEN bjcc.EarnType = 6 THEN bjcc.ActualHours ELSE 0 END) AS OVhrs
   ,SUM(CASE WHEN bjcc.EarnType NOT IN (5,6) THEN bjcc.ActualHours ELSE 0 END) AS OThrs
   ,SUM(bjcc.ActualHours) AS ActualHrs
	,SUM(bjcc.ActualCost) AS ActualCost -- Tot Amount
  	,apph.PaidDate AS CheckDate
  	,apph.CMRef AS CheckNumber
	,apph.Amount AS CheckAmt
   ,bjcc.DetlDesc
FROM 
	brvJCCDDetlDesc bjcc WITH (NOLOCK)
   --JOIN
   --   [dbo].[mfnEnumerateJobs] (@ConJobValue,',',@ConJobFlag) enj
   --      ON enj.Job = bjcc.Job
	JOIN
      JCJM jcjm WITH (NOLOCK)
         ON jcjm.JCCo = bjcc.JCCo
            AND jcjm.Job = bjcc.Job
			AND (jcjm.Contract = ISNULL(dbo.mfnFormatWithLeading(@Contract,' ',7),jcjm.Contract) AND jcjm.Job = ISNULL(dbo.mfnFormatWithLeading(@Job, ' ', 10),jcjm.Job))
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
				AND bjcc.Job =  jcjp.Job
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
   LEFT JOIN
      udEquipAttributes eqa
         ON eqa.Co = bjcc.EMCo
            AND eqa.Equipment = bjcc.EMEquip
            AND eqa.Type = 'McKinstry Fleet Number'
WHERE
   bjcc.JCCo = @Company
   AND (bjcc.Phase >= ' ' AND bjcc.Phase <= 'zzzzzzzzzzzzzzzzzzzz')
   AND bjcc.ActualCost <> 0
   AND bjcc.PostedDate BETWEEN @BeginDate AND @EndDate
   AND bjcc.Mth BETWEEN @BeginGLMonth AND @EndGLMonth
   AND 
        ( CASE
            WHEN @CostType <> 0 AND jcct.CostType = @CostType THEN 1
            WHEN @CostType = 0 THEN 1
         END) = 1
       
GROUP BY
		bjcc.JCCo
		,jcjm.Contract
		,bjcc.Job
		,bjcc.Phase
		,jcjp.[Description]
		,ISNULL(jcct.Description,'Unknown')
		,bjcc.PostedDate 
		,bjcc.Mth
		--,bjcc.ActualDate
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
		,eqa.Value
		,bjcc.CostTrans
		,COALESCE(bjcc.PO,bjcc.SL)
		,bjcc.APRef
		,apph.PaidDate
		,apph.CMRef
		,apph.Amount
		,bjcc.DetlDesc
)
SELECT
		Contract
		,Job
		,CostType
		,Phase
		,PhaseDesc
		--,ActualDate
		,PostedDate 
		,GLMonth
		,Source
		,SRCid
		,SRCname
		,Fleet
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
		,DetlDesc
FROM
   SRCDetail
GROUP BY
		Contract
		,Job
		,CostType
		,Phase
		,PhaseDesc
		--,ActualDate
		,PostedDate 
		,GLMonth
		,Source
		,SRCid
		,SRCname
		,Fleet
		,POSL
		,APRef
		,CheckDate
		,CheckNumber
		,CheckAmt
		,DetlDesc
ORDER BY
		Contract
		,Job
		,CostType
		,Phase
		--,ActualDate;
		,PostedDate 
		,GLMonth
END


