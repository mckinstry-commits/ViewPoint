SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************
   Created:		n/a
   Modified:	6/14/2011 HH: B-04969 / TK-05750 
				(adjustment to new Subcontract change order workflow)
   
   Report utilized:		PMSubCOs.rpt
*************************************************************/

CREATE VIEW [dbo].[brvPMSubSco] AS 

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
                          AND (a.SubCO IS NOT NULL OR a.RecordType = 'C')),
	   ApprovedSubCOCount=(SELECT COUNT(*) 
                   FROM   PMSL a 
                   
                   LEFT OUTER JOIN PMSubcontractCO 
						ON PMSubcontractCO.SLCo = a.SLCo 
						AND PMSubcontractCO.SL = a.SL 
						AND PMSubcontractCO.SubCO = a.SubCO 
                   
                   LEFT OUTER JOIN PMOI PMOI 
						ON a.PMCo = PMOI.PMCo 
						AND a.Project = PMOI.Project 
						AND Isnull(a.PCOType, '') = Isnull(PMOI.PCOType, '') 
						AND Isnull(a.PCO, '') = Isnull(PMOI.PCO, '') 
						AND Isnull(a.PCOItem, '') = Isnull(PMOI.PCOItem, '') 
						AND Isnull(a.ACO, '') = Isnull(PMOI.ACO, '') 
						AND Isnull(a.ACOItem, '') = Isnull(PMOI.ACOItem, '') 
                   
                   WHERE  a.PMCo = PMSL.PMCo 
                          AND a.SL = PMSL.SL 
                          AND (PMSubcontractCO.DateApproved IS NOT NULL OR PMOI.ApprovedDate IS NOT NULL)
                          AND (a.SubCO IS NOT NULL OR a.RecordType = 'C')),
       PMSL.SLItemType, 
       PMSL.Amount, 
       PMSL.SubCO, 
       PMSubcontractCO.[Description] AS SubCODescription, 
       SLDescription=SLHD.[Description], 
       SLITSL=SLIT.SL, 
       OrigCost=( CASE 
                    WHEN SLItemType <> 2 THEN ( CASE 
                                                  WHEN RecordType = 'O' 
													   AND PMSL.SubCO IS NULL 
                                                       AND SLItemType IN ( 1, 4 ) THEN 
                                                  Amount
                                                  WHEN RecordType = 'C' 
                                                       AND SLItemType IN ( 1, 4 ) 
                                                       AND MinSeq = Seq 
                                                       AND PMOI.ApprovedDate IS NOT NULL THEN 
                                                  Amount 
                                                  ELSE 0 
                                                END ) 
                    ELSE 0 
                  END ), 
       HQCO.HQCo, 
       HQCO.Name, 
       PMOI.[Description], 
       ApprovedDate = ( CASE
							WHEN PMSL.RecordType = 'O' AND PMSL.SubCO IS NULL
								THEN PMSL.InterfaceDate
							WHEN PMSubcontractCO.DateApproved IS NOT NULL THEN
								PMSubcontractCO.DateApproved
							ELSE  
								(CASE
									WHEN PMOI.ApprovedDate IS NOT NULL THEN
										PMOI.ApprovedDate
									ELSE NULL
							 END)
					 END),
       PMSL.ACO, 
       PMSL.InterfaceDate 
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
            AND Isnull(PMSL.PCOType, '') = Isnull(PMOI.PCOType, '') 
            AND Isnull(PMSL.PCO, '') = Isnull(PMOI.PCO, '') 
            AND Isnull(PMSL.PCOItem, '') = Isnull(PMOI.PCOItem, '') 
            AND 
            Isnull(PMSL.ACO, '') = Isnull(PMOI.ACO, '') 
            AND Isnull(PMSL.ACOItem, '') = Isnull(PMOI.ACOItem, '') 
       LEFT OUTER JOIN SLHD SLHD 
         ON PMSL.SLCo = SLHD.SLCo 
            AND PMSL.SL = SLHD.SL 





GO
GRANT SELECT ON  [dbo].[brvPMSubSco] TO [public]
GRANT INSERT ON  [dbo].[brvPMSubSco] TO [public]
GRANT DELETE ON  [dbo].[brvPMSubSco] TO [public]
GRANT UPDATE ON  [dbo].[brvPMSubSco] TO [public]
GO
