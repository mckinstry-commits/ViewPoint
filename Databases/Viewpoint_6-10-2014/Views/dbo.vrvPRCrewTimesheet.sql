SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************    
Purpose:  Crew Time Sheet    
    
NOTE:    
 This view was written remove the SQL from Crystal report    
 PR Crew Timesheet Entry List and apply the Nolock option     
 in SQL Server to advoid data base contention issues.    
      
Maintenance Log:    
 Coder   Date   Issue#  Description of Change    
 CWirtz   2/20/08 125224 New    
 DML    07/24/08 128868 Added PRRE.LineSeq    
 DML    08/01/08  128868 Added PRCW.Seq as CrewSeq and removed PRRE.LineSeq (added 07/24/08)   
 DML    10/10/11 D-03062 / Issue 139996 (Mult. records in PRCW causing duplicate TS entries) 
 JayR   06/22/2012  TK-15965  Remove unneeded paranthesis that caused various SQL Tools(Visual Studio...) to barf. 
********************************************************************/    
CREATE  VIEW [dbo].[vrvPRCrewTimesheet]
AS
    --**     
 SELECT PRRH.PRCo ,
        PRRH.Crew ,
        PRRH.PostDate ,
        PRRH.SheetNum ,
        HQCO_PR.Name ,
        PRCR.Description AS DescriptionPRCR ,
        PRRH.JCCo ,
        PRRH.Job ,
        PRRH.Status ,
        PRRH.Shift ,     
--    
        PRRH.Phase1CostType ,
        PRRH.Phase2CostType ,
        PRRH.Phase3CostType ,
        PRRH.Phase4CostType ,
        PRRH.Phase5CostType ,
        PRRH.Phase6CostType ,
        PRRH.Phase7CostType ,
        PRRH.Phase8CostType ,     
--    
        PRRH.Phase1Units ,
        PRRH.Phase2Units ,
        PRRH.Phase3Units ,
        PRRH.Phase4Units ,
        PRRH.Phase5Units ,
        PRRH.Phase6Units ,
        PRRH.Phase7Units ,
        PRRH.Phase8Units ,     
--    
        PRRH.Phase1 ,
        PRRH.Phase2 ,
        PRRH.Phase3 ,
        PRRH.Phase4 ,
        PRRH.Phase5 ,
        PRRH.Phase6 ,
        PRRH.Phase7 ,
        PRRH.Phase8 ,     
--     
        JCJP_1.Description AS DescriptionJCJP_1 ,
        JCJP_2.Description AS DescriptionJCJP_2 ,
        JCJP_3.Description AS DescriptionJCJP_3 ,
        JCJP_4.Description AS DescriptionJCJP_4 ,
        JCJP_5.Description AS DescriptionJCJP_5 ,
        JCJP_6.Description AS DescriptionJCJP_6 ,
        JCJP_7.Description AS DescriptionJCJP_7 ,
        JCJP_8.Description AS DescriptionJCJP_8 ,    
--     
        PREH.Suffix ,
        PREH.LastName ,
        PREH.FirstName ,
        PREH.MidName ,
        PRRE.Employee ,
        PRRE.Craft ,
        PRRE.Class ,     
--    
        PRRE.Phase1RegHrs ,
        PRRE.Phase1OTHrs ,
        PRRE.Phase1DblHrs ,
        PRRE.Phase2RegHrs ,
        PRRE.Phase2OTHrs ,
        PRRE.Phase2DblHrs ,
        PRRE.Phase3RegHrs ,
        PRRE.Phase3OTHrs ,
        PRRE.Phase3DblHrs ,
        PRRE.Phase4RegHrs ,
        PRRE.Phase4OTHrs ,
        PRRE.Phase4DblHrs ,
        PRRE.Phase5RegHrs ,
        PRRE.Phase5OTHrs ,
        PRRE.Phase5DblHrs ,
        PRRE.Phase6RegHrs ,
        PRRE.Phase6OTHrs ,
        PRRE.Phase6DblHrs ,
        PRRE.Phase7RegHrs ,
        PRRE.Phase7OTHrs ,
        PRRE.Phase7DblHrs ,
        PRRE.Phase8RegHrs ,
        PRRE.Phase8OTHrs ,
        PRRE.Phase8DblHrs ,     
--    
        JCJM.Description AS DescriptionJCJM ,     
--    
        JCJP_1.Phase AS PhaseJCJP_1 ,
        JCJP_2.Phase AS PhaseJCJP_2 ,
        JCJP_3.Phase AS PhaseJCJP_3 ,
        JCJP_4.Phase AS PhaseJCJP_4 ,
        JCJP_5.Phase AS PhaseJCJP_5 ,
        JCJP_6.Phase AS PhaseJCJP_6 ,
        JCJP_7.Phase AS PhaseJCJP_7 ,
        JCJP_8.Phase AS PhaseJCJP_8 ,    
--    
        JCPM_1.Description AS DescriptionJCPM_1 ,
        JCPM_2.Description AS DescriptionJCPM_2 ,
        JCPM_3.Description AS DescriptionJCPM_3 ,
        JCPM_4.Description AS DescriptionJCPM_4 ,
        JCPM_5.Description AS DescriptionJCPM_5 ,
        JCPM_6.Description AS DescriptionJCPM_6 ,
        JCPM_7.Description AS DescriptionJCPM_7 ,
        JCPM_8.Description AS DescriptionJCPM_8 ,      
--    
        JCCH_1.CostType AS CostTypeJCCH_1 ,
        JCCH_2.CostType AS CostTypeJCCH_2 ,
        JCCH_3.CostType AS CostTypeJCCH_3 ,
        JCCH_4.CostType AS CostTypeJCCH_4 ,
        JCCH_5.CostType AS CostTypeJCCH_5 ,
        JCCH_6.CostType AS CostTypeJCCH_6 ,
        JCCH_7.CostType AS CostTypeJCCH_7 ,
        JCCH_8.CostType AS CostTypeJCCH_8 ,     
--    
        JCCH_1.UM AS UMJCCH_1 ,
        JCCH_2.UM AS UMJCCH_2 ,
        JCCH_3.UM AS UMJCCH_3 ,
        JCCH_4.UM AS UMJCCH_4 ,
        JCCH_5.UM AS UMJCCH_5 ,
        JCCH_6.UM AS UMJCCH_6 ,
        JCCH_7.UM AS UMJCCH_7 ,
        JCCH_8.UM AS UMJCCH_8 ,     
--    
        JCPC_1.UM AS UMJCPC_1 ,
        JCPC_2.UM AS UMJCPC_2 ,
        JCPC_3.UM AS UMJCPC_3 ,
        JCPC_4.UM AS UMJCPC_4 ,
        JCPC_5.UM AS UMJCPC_5 ,
        JCPC_6.UM AS UMJCPC_6 ,
        JCPC_7.UM AS UMJCPC_7 ,
        JCPC_8.UM AS UMJCPC_8 ,     
--    
        PRRH.Notes ,    
--    
        PRCW.Seq AS CrewSeq
FROM    PRRH PRRH ( NOLOCK )
            INNER JOIN HQCO HQCO_PR ( NOLOCK ) 
                  ON PRRH.PRCo = HQCO_PR.HQCo
        LEFT OUTER JOIN JCJM JCJM ( NOLOCK ) 
                  ON PRRH.JCCo = JCJM.JCCo
            AND PRRH.Job = JCJM.Job
        INNER JOIN PRRE PRRE ( NOLOCK ) 
                  ON PRRH.PRCo = PRRE.PRCo 
            AND  PRRH.Crew = PRRE.Crew 
            AND PRRH.PostDate = PRRE.PostDate 
            AND PRRH.SheetNum = PRRE.SheetNum 
        LEFT OUTER JOIN JCJP JCJP_1 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_1.JCCo 
            AND PRRH.Job = JCJP_1.Job 
            AND PRRH.Phase1 = JCJP_1.Phase 
        LEFT OUTER JOIN JCJP JCJP_5 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_5.JCCo 
                  AND PRRH.Job = JCJP_5.Job 
            AND PRRH.PhaseGroup = JCJP_5.PhaseGroup 
            AND PRRH.Phase5 = JCJP_5.Phase 
        LEFT OUTER JOIN JCJP JCJP_2 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_2.JCCo 
                  AND PRRH.Job = JCJP_2.Job 
                  AND PRRH.PhaseGroup = JCJP_2.PhaseGroup 
                  AND PRRH.Phase2 = JCJP_2.Phase 
            LEFT OUTER JOIN JCJP JCJP_6 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_6.JCCo 
            AND PRRH.Job = JCJP_6.Job 
            AND PRRH.PhaseGroup = JCJP_6.PhaseGroup 
                  AND PRRH.Phase6 = JCJP_6.Phase 
        LEFT OUTER JOIN JCJP JCJP_3 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_3.JCCo 
            AND PRRH.Job = JCJP_3.Job
            AND PRRH.PhaseGroup = JCJP_3.PhaseGroup 
            AND PRRH.Phase3 = JCJP_3.Phase
        LEFT OUTER JOIN JCJP JCJP_7 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_7.JCCo 
            AND PRRH.Job = JCJP_7.Job 
            AND PRRH.PhaseGroup = JCJP_7.PhaseGroup 
            AND PRRH.Phase7 = JCJP_7.Phase 
            LEFT OUTER JOIN JCJP JCJP_4 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_4.JCCo
            AND PRRH.Job = JCJP_4.Job
                  AND PRRH.PhaseGroup = JCJP_4.PhaseGroup
                  AND PRRH.Phase4 = JCJP_4.Phase 
        LEFT OUTER JOIN JCJP JCJP_8 ( NOLOCK ) 
                  ON PRRH.JCCo = JCJP_8.JCCo 
            AND PRRH.Job = JCJP_8.Job 
            AND PRRH.PhaseGroup = JCJP_8.PhaseGroup 
            AND PRRH.Phase8 = JCJP_8.Phase 
        INNER JOIN PRCR PRCR ( NOLOCK ) 
                  ON PRRH.PRCo = PRCR.PRCo 
            AND PRRH.Crew = PRCR.Crew
        LEFT OUTER JOIN JCCH JCCH_1 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_1.JCCo 
            AND PRRH.Job = JCCH_1.Job 
                  AND PRRH.PhaseGroup = JCCH_1.PhaseGroup
              AND PRRH.Phase1 = JCCH_1.Phase 
            AND PRRH.Phase1CostType = JCCH_1.CostType 
            LEFT OUTER JOIN JCCH JCCH_2 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_2.JCCo 
            AND PRRH.Job = JCCH_2.Job 
            AND PRRH.PhaseGroup = JCCH_2.PhaseGroup
            AND PRRH.Phase2 = JCCH_2.Phase 
            AND PRRH.Phase2CostType = JCCH_2.CostType 
        LEFT OUTER JOIN JCCH JCCH_3 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_3.JCCo 
            AND PRRH.Job = JCCH_3.Job 
            AND PRRH.PhaseGroup = JCCH_3.PhaseGroup 
              AND PRRH.Phase3 = JCCH_3.Phase 
            AND PRRH.Phase3CostType = JCCH_3.CostType 
        LEFT OUTER JOIN JCCH JCCH_4 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_4.JCCo 
            AND PRRH.Job = JCCH_4.Job
                  AND PRRH.PhaseGroup = JCCH_4.PhaseGroup 
                  AND PRRH.Phase4 = JCCH_4.Phase
            AND PRRH.Phase4CostType = JCCH_4.CostType 
        LEFT OUTER JOIN JCCH JCCH_5 ( NOLOCK ) 
                  ON  PRRH.JCCo = JCCH_5.JCCo 
            AND PRRH.Job = JCCH_5.Job
            AND PRRH.PhaseGroup = JCCH_5.PhaseGroup 
            AND PRRH.Phase5 = JCCH_5.Phase 
            AND PRRH.Phase5CostType = JCCH_5.CostType 
            LEFT OUTER JOIN JCCH JCCH_6 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_6.JCCo 
            AND PRRH.Job = JCCH_6.Job 
            AND PRRH.PhaseGroup = JCCH_6.PhaseGroup 
            AND PRRH.Phase6 = JCCH_6.Phase 
            AND PRRH.Phase6CostType = JCCH_6.CostType 
            LEFT OUTER JOIN JCCH JCCH_7 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_7.JCCo 
                  AND PRRH.Job = JCCH_7.Job 
            AND PRRH.PhaseGroup = JCCH_7.PhaseGroup 
                  AND PRRH.Phase7 = JCCH_7.Phase 
            AND PRRH.Phase7CostType = JCCH_7.CostType 
        LEFT OUTER JOIN JCCH JCCH_8 ( NOLOCK ) 
                  ON PRRH.JCCo = JCCH_8.JCCo 
            AND PRRH.Job = JCCH_8.Job 
            AND PRRH.PhaseGroup = JCCH_8.PhaseGroup 
            AND PRRH.Phase8 = JCCH_8.Phase 
            AND PRRH.Phase8CostType = JCCH_8.CostType 
        LEFT OUTER JOIN JCPM JCPM_1 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_1.PhaseGroup 
            AND PRRH.Phase1 = JCPM_1.Phase 
        LEFT OUTER JOIN JCPC JCPC_1 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_1.PhaseGroup 
            AND PRRH.Phase1 = JCPC_1.Phase 
            AND PRRH.Phase1CostType = JCPC_1.CostType 
        LEFT OUTER JOIN JCPM JCPM_2 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_2.PhaseGroup 
            AND PRRH.Phase2 = JCPM_2.Phase 
        LEFT OUTER JOIN JCPC JCPC_2 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_2.PhaseGroup 
            AND PRRH.Phase2 = JCPC_2.Phase 
            AND PRRH.Phase2CostType = JCPC_2.CostType 
        LEFT OUTER JOIN JCPM JCPM_3 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_3.PhaseGroup 
            AND PRRH.Phase3 = JCPM_3.Phase
        LEFT OUTER JOIN JCPC JCPC_3 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_3.PhaseGroup 
            AND PRRH.Phase3 = JCPC_3.Phase 
            AND PRRH.Phase3CostType = JCPC_3.CostType 
        LEFT OUTER JOIN JCPM JCPM_4 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_4.PhaseGroup 
            AND PRRH.Phase4 = JCPM_4.Phase 
        LEFT OUTER JOIN JCPC JCPC_4 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_4.PhaseGroup 
            AND PRRH.Phase4 = JCPC_4.Phase 
            AND PRRH.Phase4CostType = JCPC_4.CostType 
        LEFT OUTER JOIN JCPM JCPM_5 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_5.PhaseGroup 
            AND PRRH.Phase5 = JCPM_5.Phase 
        LEFT OUTER JOIN JCPC JCPC_5 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_5.PhaseGroup 
            AND PRRH.Phase5 = JCPC_5.Phase 
            AND PRRH.Phase5CostType = JCPC_5.CostType 
        LEFT OUTER JOIN JCPM JCPM_6 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_6.PhaseGroup 
            AND PRRH.Phase6 = JCPM_6.Phase 
        LEFT OUTER JOIN JCPC JCPC_6 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_6.PhaseGroup 
            AND PRRH.Phase6 = JCPC_6.Phase 
            AND PRRH.Phase6CostType = JCPC_6.CostType 
        LEFT OUTER JOIN JCPM JCPM_7 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_7.PhaseGroup 
            AND PRRH.Phase7 = JCPM_7.Phase 
        LEFT OUTER JOIN JCPC JCPC_7 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_7.PhaseGroup 
            AND PRRH.Phase7 = JCPC_7.Phase 
            AND PRRH.Phase7CostType = JCPC_7.CostType 
        LEFT OUTER JOIN JCPM JCPM_8 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPM_8.PhaseGroup 
            AND PRRH.Phase8 = JCPM_8.Phase 
        LEFT OUTER JOIN JCPC JCPC_8 ( NOLOCK ) 
                  ON PRRH.PhaseGroup = JCPC_8.PhaseGroup 
            AND PRRH.Phase8 = JCPC_8.Phase 
            AND PRRH.Phase8CostType = JCPC_8.CostType 
        LEFT OUTER JOIN PREH PREH ( NOLOCK ) 
                  ON  PRRE.PRCo = PREH.PRCo 
            AND PRRE.Employee = PREH.Employee 
--LEFT OUTER JOIN PRCW PRCW (NOLOCK)     
-- ON (PRRE.PRCo=PRCW.PRCo) AND (PRRE.Crew=PRCW.Crew) AND (PRRE.Employee=PRCW.Employee)    
  
/** added per Gary Gilmore to fix D-03062 / Issue 139996) **/
        LEFT OUTER JOIN ( SELECT    PRCW.PRCo ,
                                    PRCW.Crew ,
                                    PRCW.Employee ,
                                    MIN(PRCW.Seq) AS [Seq]
                          FROM      PRCW (NOLOCK)
                                    JOIN PRRE (NOLOCK) ON ( PRRE.PRCo = PRCW.PRCo )
                                                          AND ( PRRE.Crew = PRCW.Crew )
                                                          AND ( PRRE.Employee = PRCW.Employee )
                          GROUP BY  PRCW.PRCo ,
                                    PRCW.Crew ,
                                    PRCW.Employee
                        ) AS PRCW ON ( PRRE.PRCo = PRCW.PRCo )
                                     AND ( PRRE.Crew = PRCW.Crew )
                                     AND ( PRRE.Employee = PRCW.Employee )  
/** end of fix for D-03062 / Issue 139996) **/
GO
GRANT SELECT ON  [dbo].[vrvPRCrewTimesheet] TO [public]
GRANT INSERT ON  [dbo].[vrvPRCrewTimesheet] TO [public]
GRANT DELETE ON  [dbo].[vrvPRCrewTimesheet] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRCrewTimesheet] TO [public]
GRANT SELECT ON  [dbo].[vrvPRCrewTimesheet] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPRCrewTimesheet] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPRCrewTimesheet] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPRCrewTimesheet] TO [Viewpoint]
GO
