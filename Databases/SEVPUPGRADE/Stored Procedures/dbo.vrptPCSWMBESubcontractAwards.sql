SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[vrptPCSWMBESubcontractAwards] (@Company            bCompany, 
                                                 @BeginProject       bContract, 
                                                 @EndProject         bContract, 
                                                 @ThroughDate        bDate, 
                                                 @CommitmentType     VARCHAR(1), 
                                                 @ValidationDateType VARCHAR(1)) 
AS 
/************************************************************************ 
* CREATED:  HH 09/22/10 - Initial version    
* MODIFIED: HH 06/17/11 - TK-06056/TK-06057 Differentiation  
*              between CommitmentTypes (SL/PO) and validation  
*              against MWBE certificate dates 
*       
* Purpose of Stored Procedure: 
*  Get the awarded amounts of all subcontracts/purchase orders and their  
*  respective change orders (commitments). Awarded amount is a commitment  
*  amount that has been utilized in a project associated with a potential  
*  project by vendors with a MWBE certificate that is valid for the time  
*  period a commitment has been placed (@ValidationDateType = 'C') or a  
*  commitment has been invoiced (@ValidationDateType = 'I').  
*   
* 
*  Notes: 
*  Reports that use: PCMWBEAwards.rpt 
*   
*   
*************************************************************************/ 
  --== Result Table 
  CREATE TABLE #Result 
    ( 
       JCCo                   TINYINT, 
       Project                VARCHAR(30), 
       [Contract]             VARCHAR(30), 
       PotentialProject       VARCHAR(30), 
       VendorGroup            TINYINT, 
       Vendor                 INT, 
       CertificateType        VARCHAR(20), 
       ContractValue          DECIMAL(15, 2) DEFAULT(0), 
       SubcontractValue       DECIMAL(15, 2) DEFAULT(0), 
       CurrentPurchaseDollars DECIMAL(15, 2) DEFAULT(0), 
       CurSubPct              DECIMAL(15, 4) DEFAULT(0), 
       GoalPct                DECIMAL(15, 4) DEFAULT(0), 
       ActualPurchaseDollars  DECIMAL(15, 2) DEFAULT(0), 
       ActSubPct              DECIMAL(15, 4) DEFAULT(0), 
       ActContractPct         DECIMAL(15, 4) DEFAULT(0), 
       GoalMetYN              CHAR 
    ); 

  /*** current project goals infos **/ 
  INSERT INTO #Result 
              (JCCo, 
               Project, 
               [Contract], 
               PotentialProject, 
               VendorGroup, 
               CertificateType, 
               GoalPct, 
               GoalMetYN) 
  SELECT JM.JCCo, 
         JM.Job, 
         CM.[Contract], 
         PW.PotentialProject, 
         --JM.VendorGroup,  
         PPC.VendorGroup, 
         PPC.CertificateType, 
         PPC.GoalPct, 
         PPC.GoalMetYN 
  FROM   JCJM JM 
         INNER JOIN JCCM CM 
           ON CM.[Contract] = JM.[Contract] 
              AND CM.JCCo = JM.JCCo 
         INNER JOIN PCPotentialWork PW 
           ON PW.PotentialProject = CM.PotentialProject 
              AND CM.JCCo = PW.JCCo 
         INNER JOIN PCPotentialProjectCertificate PPC 
           ON PPC.PotentialProject = CM.PotentialProject 
              AND PPC.JCCo = CM.JCCo 
  WHERE  JM.JCCo = @Company 
         AND CM.[Contract] BETWEEN @BeginProject AND @EndProject; 

  /*** actual project MWBE goals infos that is setup for a potential project**/ 
  WITH Actuals ( JCCo, Job, [Contract], PotentialProject, ActualAmt, Vendor, 
       VendorGroup, CertificateType) 
       AS (SELECT APTL.JCCo, 
                  APTL.Job, 
                  JCJM.[Contract], 
                  PW.PotentialProject, 
                  SUM(APTL.GrossAmt) AS ActualAmt, 
                  APTH.Vendor, 
                  APTH.VendorGroup, 
                  PPC.CertificateType 
           FROM   APTL 
                  JOIN APTH 
                    ON APTH.APCo = APTL.APCo 
                       AND APTH.Mth = APTL.Mth 
                       AND APTH.APTrans = APTL.APTrans 
                  JOIN JCJM 
                    ON JCJM.JCCo = APTL.JCCo 
                       AND JCJM.Job = APTL.Job 
                  JOIN JCCM 
                    ON JCCM.JCCo = JCJM.JCCo 
                       AND JCCM.[Contract] = JCJM.[Contract] 
                  JOIN PCPotentialWork PW 
                    ON PW.JCCo = JCCM.JCCo 
                       AND PW.PotentialProject = JCCM.PotentialProject 
                  LEFT JOIN POIT 
                    ON POIT.JCCo = APTL.JCCo 
                       AND POIT.Job = APTL.Job 
                       AND POIT.PO = APTL.PO 
                       AND POIT.POItem = APTL.POItem 
                  LEFT JOIN POHD 
                    ON POHD.POCo = POIT.POCo 
                       AND POHD.PO = POIT.PO 
                       AND POHD.JCCo = POIT.JCCo 
                       AND POHD.Job = POIT.Job 
                  LEFT JOIN SLIT 
                    ON SLIT.JCCo = APTL.JCCo 
                       AND SLIT.Job = APTL.Job 
                       AND SLIT.SL = APTL.SL 
                       AND SLIT.SLItem = APTL.SLItem 
                  LEFT JOIN SLHD 
                    ON SLHD.SLCo = SLIT.SLCo 
                       AND SLHD.SL = SLIT.SL 
                       AND SLHD.JCCo = SLIT.JCCo 
                       AND SLHD.Job = SLIT.Job 
                  LEFT JOIN PCCertificates PPC 
                    ON PPC.Vendor = APTH.Vendor 
                       AND PPC.VendorGroup = APTH.VendorGroup 
           WHERE  APTL.APCo = @Company 
                  AND APTL.JCCo = @Company 
                  AND APTL.Job BETWEEN @BeginProject AND @EndProject 
                  AND APTH.InvDate <= @ThroughDate 
                  -- Amounts for SL or PO or both 
                  AND ( ( CASE 
                            WHEN @CommitmentType = 'S' THEN APTL.SL 
                          END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = 'P' THEN APTL.PO 
                              END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = '' THEN APTL.SL 
                              END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = '' THEN APTL.PO 
                              END ) IS NOT NULL ) 
                  AND PPC.CertificateType IS NOT NULL 
                  AND ( @ThroughDate <= PPC.ExpDate 
                         OR PPC.ExpDate IS NULL ) 
                  -- Validate MWBE certificate date against invoice or commitment date 
                  AND ( CASE 
                          WHEN @ValidationDateType = 'I' THEN APTH.InvDate 
                          WHEN @ValidationDateType = 'C' 
                               AND APTL.SL IS NOT NULL THEN SLHD.OrigDate 
                          WHEN @ValidationDateType = 'C' 
                               AND APTL.PO IS NOT NULL THEN POHD.OrderDate 
                        END ) BETWEEN PPC.StartDate AND PPC.EndDate 
           GROUP  BY APTH.Vendor, 
                     APTH.VendorGroup, 
                     APTL.JCCo, 
                     APTL.Job, 
                     JCJM.[Contract], 
                     PW.PotentialProject, 
                     PPC.CertificateType) 
  UPDATE #Result 
  SET    #Result.ActualPurchaseDollars = ActualAmt 
  FROM   Actuals 
  WHERE  #Result.JCCo = Actuals.JCCo 
         AND #Result.Project = Actuals.Job 
         AND #Result.[Contract] = Actuals.[Contract] 
         AND #Result.PotentialProject = Actuals.PotentialProject 
         AND #Result.VendorGroup = Actuals.VendorGroup 
         AND #Result.CertificateType = Actuals.CertificateType; 

  /*** actual project MWBE goals infos that is not setup for a potential project, but comes in from a vendor**/
  WITH Actuals ( JCCo, Job, [Contract], PotentialProject, ActualAmt, Vendor, 
       VendorGroup, CertificateType) 
       AS (SELECT APTL.JCCo, 
                  APTL.Job, 
                  JCJM.[Contract], 
                  PW.PotentialProject, 
                  SUM(APTL.GrossAmt) AS ActualAmt, 
                  APTH.Vendor, 
                  APTH.VendorGroup, 
                  PPC.CertificateType 
           FROM   APTL 
                  JOIN APTH 
                    ON APTH.APCo = APTL.APCo 
                       AND APTH.Mth = APTL.Mth 
                       AND APTH.APTrans = APTL.APTrans 
                  JOIN JCJM 
                    ON JCJM.JCCo = APTL.JCCo 
                       AND JCJM.Job = APTL.Job 
                  JOIN JCCM 
                    ON JCCM.JCCo = JCJM.JCCo 
                       AND JCCM.[Contract] = JCJM.[Contract] 
                  JOIN PCPotentialWork PW 
                    ON PW.JCCo = JCCM.JCCo 
                       AND PW.PotentialProject = JCCM.PotentialProject 
                  LEFT JOIN POIT 
                    ON POIT.JCCo = APTL.JCCo 
                       AND POIT.Job = APTL.Job 
                       AND POIT.PO = APTL.PO 
                       AND POIT.POItem = APTL.POItem 
                  LEFT JOIN POHD 
                    ON POHD.POCo = POIT.POCo 
                       AND POHD.PO = POIT.PO 
                       AND POHD.JCCo = POIT.JCCo 
                       AND POHD.Job = POIT.Job 
                  LEFT JOIN SLIT 
                    ON SLIT.JCCo = APTL.JCCo 
                       AND SLIT.Job = APTL.Job 
                       AND SLIT.SL = APTL.SL 
                       AND SLIT.SLItem = APTL.SLItem 
                  LEFT JOIN SLHD 
                    ON SLHD.SLCo = SLIT.SLCo 
                       AND SLHD.SL = SLIT.SL 
                       AND SLHD.JCCo = SLIT.JCCo 
                       AND SLHD.Job = SLIT.Job 
                  LEFT JOIN PCCertificates PPC 
                    ON PPC.Vendor = APTH.Vendor 
                       AND PPC.VendorGroup = APTH.VendorGroup 
           WHERE  APTL.APCo = @Company 
                  AND APTL.JCCo = @Company 
                  AND APTL.Job BETWEEN @BeginProject AND @EndProject 
                  AND APTH.InvDate <= @ThroughDate 
                  -- Amounts for SL or PO or both 
                  AND ( ( CASE 
                            WHEN @CommitmentType = 'S' THEN APTL.SL 
                          END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = 'P' THEN APTL.PO 
                              END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = '' THEN APTL.SL 
                              END ) IS NOT NULL 
                         OR ( CASE 
                                WHEN @CommitmentType = '' THEN APTL.PO 
                              END ) IS NOT NULL ) 
                  AND PPC.CertificateType IS NOT NULL 
                  AND ( @ThroughDate <= PPC.ExpDate 
                         OR PPC.ExpDate IS NULL ) 
                  -- Validate MWBE certificate date against invoice or commitment date 
                  AND ( CASE 
                          WHEN @ValidationDateType = 'I' THEN APTH.InvDate 
                          WHEN @ValidationDateType = 'C' 
                               AND APTL.SL IS NOT NULL THEN SLHD.OrigDate 
                          WHEN @ValidationDateType = 'C' 
                               AND APTL.PO IS NOT NULL THEN POHD.OrderDate 
                        END ) BETWEEN PPC.StartDate AND PPC.EndDate 
           GROUP  BY APTH.Vendor, 
                     APTH.VendorGroup, 
                     APTL.JCCo, 
                     APTL.Job, 
                     JCJM.[Contract], 
                     PW.PotentialProject, 
                     PPC.CertificateType) 
  INSERT INTO #Result 
              (JCCo, 
               Project, 
               [Contract], 
               PotentialProject, 
               ActualPurchaseDollars, 
               Vendor, 
               VendorGroup, 
               CertificateType) 
  SELECT Actuals.JCCo, 
         Actuals.Job, 
         Actuals.[Contract], 
         Actuals.PotentialProject, 
         Actuals.ActualAmt, 
         Actuals.Vendor, 
         Actuals.VendorGroup, 
         Actuals.CertificateType 
  FROM   Actuals 
  WHERE  NOT EXISTS (SELECT * 
                     FROM   #Result 
                     WHERE  #Result.[Contract] = Actuals.[Contract] 
                            AND #Result.PotentialProject = 
                                Actuals.PotentialProject 
                            AND #Result.VendorGroup = Actuals.VendorGroup 
                            AND #Result.CertificateType = 
                                Actuals.CertificateType) 

  CREATE TABLE #JobCalculations 
    ( 
       Job               VARCHAR(30), 
       [Contract]        VARCHAR(30), 
       ContractValue     DECIMAL(15, 2) DEFAULT(0), 
       OriginalCommitsSL DECIMAL(15, 2) DEFAULT(0), 
       OriginalCommitsPO DECIMAL(15, 2) DEFAULT(0), 
       ChangeOrdersSL    DECIMAL(15, 2) DEFAULT(0), 
       ChangeOrdersPO    DECIMAL(15, 2) DEFAULT(0), 
       SubcontractVal    DECIMAL(15, 2) DEFAULT(0) 
    ) 

  INSERT INTO #JobCalculations 
              (Job, 
               [Contract]) 
  SELECT Job, 
         [Contract] 
  FROM   JCJM 
  WHERE  JCCo = @Company 
         AND Job BETWEEN @BeginProject AND @EndProject 

  UPDATE JCal 
  SET    ContractValue = ContractValue.ContractValue, 
         OriginalCommitsSL = OriginalCommitsSL.OriginalCommitsSL, 
         OriginalCommitsPO = OriginalCommitsPO.OriginalCommitsPO, 
         ChangeOrdersSL = ChangeOrdersSL.ChangeOrdersSL, 
         ChangeOrdersPO = ChangeOrdersPO.ChangeOrdersPO, 
         /*SubcontractVal = ISNULL(OriginalCommitsSL.OriginalCommitsSL,0) + 
             ISNULL(OriginalCommitsPO.OriginalCommitsPO,0) + 
                             ISNULL(ChangeOrdersSL.ChangeOrdersSL,0) +  
                             ISNULL(ChangeOrdersPO.ChangeOrdersPO,0)*/ 
         SubcontractVal = CASE @CommitmentType 
                            WHEN '' THEN Isnull( 
                            OriginalCommitsSL.OriginalCommitsSL, 0) + 
         Isnull( 
                        OriginalCommitsPO.OriginalCommitsPO, 0) + Isnull( 
                        ChangeOrdersSL.ChangeOrdersSL, 0) + Isnull( 
         ChangeOrdersPO.ChangeOrdersPO, 0) 
         WHEN 'S' THEN Isnull(OriginalCommitsSL.OriginalCommitsSL, 0) + Isnull( 
          ChangeOrdersSL.ChangeOrdersSL, 0) 
         WHEN 'P' THEN Isnull(OriginalCommitsPO.OriginalCommitsPO, 0) + Isnull( 
          ChangeOrdersPO.ChangeOrdersPO, 0) 
         END 
  FROM   #JobCalculations AS JCal 
         OUTER APPLY (SELECT SUM(JCID.ContractAmt) AS ContractValue 
                      FROM   JCID 
                      WHERE  JCID.JCCo = @Company 
                             AND JCID.ActualDate <= @ThroughDate 
                             AND JCal.[Contract] = JCID.[Contract] 
                      GROUP  BY JCID.JCCo, 
                                JCID.[Contract]) AS ContractValue 
         OUTER APPLY (SELECT SUM(SLIT.OrigCost) AS OriginalCommitsSL 
                      FROM   SLIT 
                      WHERE  SLIT.JCCo = @Company 
                             AND SLIT.Job = JCal.Job) AS OriginalCommitsSL 
         OUTER APPLY (SELECT SUM(POIT.OrigCost) AS OriginalCommitsPO 
                      FROM   POIT 
                      WHERE  POIT.JCCo = @Company 
                             AND POIT.Job = JCal.Job) AS OriginalCommitsPO 
         OUTER APPLY (SELECT SUM(SLCD.ChangeCurCost) AS ChangeOrdersSL 
                      FROM   SLCD 
                             JOIN SLIT 
                               ON SLIT.SLCo = SLCD.SLCo 
                                  AND SLIT.SL = SLCD.SL 
                                  AND SLIT.SLItem = SLCD.SLItem 
                      WHERE  SLIT.JCCo = @Company 
                             AND SLIT.Job = JCal.Job 
                             AND SLCD.ActDate <= @ThroughDate) AS ChangeOrdersSL 
         OUTER APPLY (SELECT SUM(POCD.ChangeCurCost) AS ChangeOrdersPO 
                      FROM   POCD 
                             JOIN POIT 
                               ON POCD.POCo = POIT.POCo 
                                  AND POCD.PO = POIT.PO 
                                  AND POCD.POItem = POIT.POItem 
                      WHERE  POIT.JCCo = @Company 
                             AND POIT.Job = JCal.Job 
                             AND POCD.ActDate <= @ThroughDate) AS ChangeOrdersPO 

  --/*** percentage determining ***/ 
  UPDATE R 
  SET    ContractValue = JCal.ContractValue, 
         SubcontractValue = JCal.SubcontractVal, 
         CurrentPurchaseDollars = JCal.ContractValue * GoalPct, 
         CurSubPct = JCal.ContractValue * ( GoalPct / Nullif(JCal.SubcontractVal, 0) ), 
         ActSubPct = ( ActualPurchaseDollars / Nullif(JCal.SubcontractVal, 0) ), 
         ActContractPct = ( ActualPurchaseDollars / Nullif(JCal.ContractValue, 0 ) ) 
  FROM   #Result R 
         JOIN #JobCalculations JCal 
           ON R.Project = JCal.Job 
              AND R.[Contract] = JCal.[Contract] 
  WHERE  JCCo = @Company 

  DROP TABLE #JobCalculations 

  /*SELECT * 
  FROM #Result	
  ORDER  BY JCCo, 
            Project, 
            [Contract], 
            PotentialProject */
  
  -- Return Result Group By CertificateType
  SELECT	JCCo						,
			Project						,
			[Contract]					,
			PotentialProject			,
			CertificateType				,
			ContractValue				,
			SubcontractValue			,
			SUM(CurrentPurchaseDollars) AS CurrentPurchaseDollars	,
			SUM(CurSubPct)				AS CurSubPct,
			SUM(GoalPct)				AS GoalPct,
			SUM(ActualPurchaseDollars)	AS ActualPurchaseDollars,
			SUM(ActSubPct)				AS ActSubPct,
			SUM(ActContractPct)			AS ActContractPct,
			GoalMetYN             
  FROM   #Result 
  GROUP BY  JCCo                  ,
			Project               ,
			[Contract]            ,
			PotentialProject      ,
			
			CertificateType       ,
			ContractValue         ,
			SubcontractValue      ,
			GoalMetYN             
  ORDER  BY JCCo, 
            Project, 
            [Contract], 
            PotentialProject
            
            
            
--exec vrptPCSWMBESubcontractAwards 1, '    0-', '    0-', '2011-06-30', '', 'C'
GO
GRANT EXECUTE ON  [dbo].[vrptPCSWMBESubcontractAwards] TO [public]
GO
