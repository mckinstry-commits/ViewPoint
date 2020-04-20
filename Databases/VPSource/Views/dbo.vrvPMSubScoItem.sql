SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[vrvPMSubScoItem] AS 

SELECT PMSL.PMCo, 
       PMSL.Project, 
       PMSL.RecordType, 
       PMSL.Seq, 
       MinSeq, 
       PMSL.SLCo, 
       PMSL.SL, 
       PMSL.SLItem, 
       SubCOCount=(SELECT COUNT(*) 
                   FROM   PMSL a 
                   WHERE  a.PMCo = PMSL.PMCo 
                          AND a.SL = PMSL.SL 
                          AND a.SubCO IS NOT NULL), 
       PMSL.SLItemType, 
       PMSL.Amount, 
       PMSL.SubCO, 
       PMSubcontractCO.[Description] AS SubCODescription, 
       SLDescription=SLHD.[Description], 
       SLITSL=SLIT.SL, 
       OrigCost=( CASE 
                    WHEN SLItemType <> 2 THEN ( CASE 
                                                  WHEN RecordType = 'O' 
                                                       AND SLItemType IN ( 1, 4 
                                                           ) THEN 
                                                  Amount 
                                                  WHEN RecordType = 'C' 
                                                       AND SLItemType IN ( 1, 4 
                                                           ) 
                                                       AND MinSeq = Seq 
                                                       AND PMOI.ApprovedDate IS 
                                                           NOT 
                                                           NULL THEN 
                                                  Amount 
                                                  ELSE 0 
                                                END ) 
                    ELSE 0 
                  END ), 
       HQCO.HQCo, 
       HQCO.Name, 
       PMOI.[Description], 
       PMOI.ApprovedDate, 
       PMSL.ACO, 
       PMSL.InterfaceDate, 
       PMSL.SLItemDescription 
FROM   PMSL 
       LEFT OUTER JOIN PMSubcontractCO 
         ON PMSubcontractCO.SLCo = PMSL.SLCo 
            AND PMSubcontractCO.SL = PMSL.SL 
            AND PMSubcontractCO.SubCO = PMSL.SubCO 
       LEFT OUTER JOIN SLIT 
         ON PMSL.SLCo = SLIT.SLCo 
            AND PMSL.SL = SLIT.SL 
            AND PMSL.SLItem = SLIT.SLItem 
       LEFT OUTER JOIN (SELECT PMCo, 
                               SL, 
                               SLItem, 
                               MinSeq=MIN(Seq) 
                        FROM   PMSL 
                        GROUP  BY PMCo, 
                                  SL, 
                                  SLItem) AS SLMinSeq 
         ON SLMinSeq.PMCo = PMSL.PMCo 
            AND SLMinSeq.SL = PMSL.SL 
            AND SLMinSeq.SLItem = PMSL.SLItem 
       INNER JOIN HQCO HQCO 
         ON PMSL.PMCo = HQCO.HQCo 
       LEFT OUTER JOIN PMOI PMOI 
         ON PMSL.PMCo = PMOI.PMCo 
            AND PMSL.Project = PMOI.Project 
            AND isnull(PMSL.PCOType, '') = isnull(PMOI.PCOType, '') 
            AND isnull(PMSL.PCO, '') = isnull(PMOI.PCO, '') 
            AND isnull(PMSL.PCOItem, '') = isnull(PMOI.PCOItem, '') 
            AND PMSL.ACO = PMOI.ACO 
            AND PMSL.ACOItem = PMOI.ACOItem 
       LEFT OUTER JOIN SLHD SLHD 
         ON PMSL.SLCo = SLHD.SLCo 
            AND PMSL.SL = SLHD.SL 


GO
GRANT SELECT ON  [dbo].[vrvPMSubScoItem] TO [public]
GRANT INSERT ON  [dbo].[vrvPMSubScoItem] TO [public]
GRANT DELETE ON  [dbo].[vrvPMSubScoItem] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMSubScoItem] TO [public]
GO
