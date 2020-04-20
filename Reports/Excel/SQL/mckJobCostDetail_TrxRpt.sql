use Viewpoint
go

drop procedure [mckJobCostDetail_TrxRpt]
go

create PROCEDURE [dbo].[mckJobCostDetail_TrxRpt](
    @Company bCompany
   --,@ConJobFlag char(1) = 'C'  -- C-Contract, J-Job
   ,@Contract bContract = NULL
   ,@Job bJob = NULL
   ,@CostType tinyint = 0
   ,@BeginDate bDate = null
   ,@EndDate bDate = null
  --,@BeginGLMonth bMonth = null
  -- ,@EndGLMonth bMonth = null
  , @Dept bDept = null 
)
AS
/******************************************************************************************
* mkkJobcostDetail                                                                        *
*                                                                                         *
* Purpose: for SSRS Job Cost Transaction Detail Report                                    *
*                                                                                         *
*                                                                                         *
* Date			By			Comment                                                           *
* ==========	========	===================================================             *
* 2013/12/05	Arun Thomas	Created                                                           *
* 2015/18/05	Mahendar	Modified : Added Dept, Contract Name and POC#*
* 2015/05/26	BillO		Modified : Added Detailed Desc and made dynamic based on Source (PR = Employee Name else De)scription *
*                                                                                        *
*                                                                                         *
*******************************************************************************************/
BEGIN

--IF COALESCE(@Contract, @Job, '') = ''
--   RETURN;

-- SSRS is passing default value of the previous week if not entered
-- Assignment below if for testing
IF @BeginDate IS NULL
   SET @BeginDate = DATEADD("d",-7,GETDATE())

IF @EndDate IS NULL
   SET @EndDate = GETDATE()
   
--SET @BeginGLMonth = DATEADD("d",-(Day(@BeginGLMonth)) +1,@BeginGLMonth)
--SET @EndGLMonth = DATEADD("d",-(Day(@EndGLMonth)) +1,@EndGLMonth)


--SELECT @Job = REPLACE(@Job,'',NULL)

--SET @Contract = dbo.mfnFormatWithLeading(@Contract,' ',7)
--SET @Job = dbo.mfnFormatWithLeading(@Job, ' ', 10)

--SELECT @Contract = ISNULL(@Contract, JCJM.Contract)
--FROM JCJM WHERE JCCo = @Company AND Job = dbo.mfnFormatWithLeading(@Job, ' ',10)


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
      WHEN jcct.CostType = 4 THEN ISNULL(apvm.Name, prehn.FullName )--,ISNULL(bjcc.DetlDesc,'Not Available'))
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
  --	,apph.PaidDate AS CheckDate
  	--,apph.CMRef AS CheckNumber
	--,apph.Amount AS CheckAmt
	-- 2015/05/26 - BillO - Added Synamic DetlDesc
   ,case bjcc.Source when 'PR Entry' then coalesce(cast(prehn.Employee as varchar(10)),'') + ' - ' + coalesce(prehn.FullName,'') else bjcc.Description end as DetlDesc
--   ,bjcc.Description
  /*,CASE --grouping request
		WHEN jcct.CostType =1 THEN NULL
        ELSE bjcc.DetlDesc
	END AS DetlDesc*/
	,jccm.Description  as ContractName
	, jccm.Department 
	, jcjm.ProjectMgr as POC
FROM 
	brvJCCDDetlDesc bjcc WITH (NOLOCK)
   --JOIN
   --   [dbo].[mfnEnumerateJobs] (@ConJobValue,',',@ConJobFlag) enj
   --      ON enj.Job = bjcc.Job
	INNER JOIN
      JCJM jcjm WITH (NOLOCK)
         ON jcjm.JCCo = bjcc.JCCo
            AND jcjm.Job = bjcc.Job
			AND jcjm.Job = bjcc.Job
			AND (jcjm.Contract = ISNULL(dbo.mfnFormatWithLeading(@Contract,' ',7),jcjm.Contract) 
			AND jcjm.Job = ISNULL(dbo.mfnFormatWithLeading(@Job, ' ', 10),jcjm.Job))
			
   JOIN
	   JCCT jcct WITH (NOLOCK)
			ON jcct.PhaseGroup = bjcc.PhaseGroup
			   AND jcct.CostType = bjcc.CostType
   JOIN
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
	/*LEFT JOIN
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
			   AND apph.EFTSeq = appd.EFTSeq*/
   LEFT JOIN
      udEquipAttributes eqa
         ON eqa.Co = bjcc.EMCo
            AND eqa.Equipment = bjcc.EMEquip
            AND eqa.Type = 'McKinstry Fleet Number'
            
	LEFT JOIN  JCCM jccm on jccm.Contract = jcjm.Contract and 
							jccm.JCCo = jcjm.JCCo
WHERE
	bjcc.JCCo = @Company
	AND (bjcc.Phase >= ' ' AND bjcc.Phase <= 'zzzzzzzzzzzzzzzzzzzz')
	AND bjcc.ActualCost <> 0
	AND bjcc.PostedDate BETWEEN @BeginDate AND @EndDate
	--commented to remove parameters
	-- AND bjcc.Mth BETWEEN @BeginGLMonth AND @EndGLMonth
	AND 
		( CASE
            WHEN @CostType <> 0 AND jcct.CostType = @CostType THEN 1
            WHEN @CostType = 0 THEN 1
			WHEN @CostType IS NULL THEN 1
         END) = 1
	AND 
	(CASE 
	WHEN @Dept IS NULL THEN 1
	WHEN jccm.Department in ( select Element from dbo.mckfunc_Split(@Dept,',')) THEN 1
	END ) = 1
	 
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
			WHEN jcct.CostType = 4 THEN ISNULL(apvm.Name, prehn.FullName) --,ISNULL(bjcc.DetlDesc,'Not Available'))
			ELSE ISNULL(apvm.Name,bjcc.DetlDesc) -- Vendor Name
		END
		,eqa.Value
		,bjcc.CostTrans
		,COALESCE(bjcc.PO,bjcc.SL)
		,bjcc.APRef
		,jccm.Description --contract Name.
		, jccm.Department 
		, jcjm.ProjectMgr
		--,apph.PaidDate
		--,apph.CMRef
		--,apph.Amount
		-- 2015/05/26 - BillO - Added Synamic DetlDesc
		,case bjcc.Source when 'PR Entry' then coalesce(cast(prehn.Employee as varchar(10)),'') + ' - ' + coalesce(prehn.FullName,'') else bjcc.Description end
		--,bjcc.DetlDesc
		--,bjcc.Description
		 /*,CASE  --grouping request
		WHEN jcct.CostType =1 THEN NULL  
        ELSE bjcc.DetlDesc
	END */
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
		,SRCid AS [ID]
		,SRCname AS [NAME]
		,Fleet AS [EQUIPMENT #]
		,POSL AS [PO/SC #]
		,APRef
		,SUM(Reghrs) AS [Reg]
		,SUM(OVhrs) AS [OvT]
		,SUM(OThrs) AS [Oth]
		,SUM(ActualHrs) AS TotHrs
		,SUM(ActualCost) As TotAmount
		,ContractName
		,Department
		,POC
		--,CheckDate
		--,CheckNumber
		--,CheckAmt
		-- 2015/05/26 - BillO - Added Synamic DetlDesc
		,DetlDesc
		--,Description
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
		,ContractName
		,Department
		,POC
		--,CheckDate
		--,CheckNumber
		--,CheckAmt
		-- 2015/05/26 - BillO - Added Synamic DetlDesc
		,DetlDesc
		--,Description
ORDER BY
		Contract
		,Job
		,CostType
		,Phase
		--,ActualDate;
		,PostedDate 
		,GLMonth
END

go

grant exec on [mckJobCostDetail_TrxRpt] to public 
go