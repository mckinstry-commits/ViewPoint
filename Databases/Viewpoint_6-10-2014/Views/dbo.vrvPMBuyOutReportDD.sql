SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


   
   
   CREATE    view [dbo].[vrvPMBuyOutReportDD]
  
  /*****
   Created:  DH 6/21/11
   Usage:   Adapted from the brvPMBuyOutReport view, this view is used on the 
			Uncommitted Drilldown subreport of the PM Contract Analysis Drilldown.
            Returns Current Estimated, Committed, and Uncommitted amounts 
            in order to analyze what has or has not been bought out for
            subcontracts, purchase orders, and material orders.  Committed and
            Uncommitted comes from PMSL and PMMF whereas estimated pulls from 
            JCCH (Original) and PMOL for approved change order data.  PCO, ACO, SL, PO,
            and MO data also returned, which enables users to drill down to details making up
            the amounts.
    
    ********/
         
   
    as
   
   --Original Estimated
   select JCCH.JCCo, JCCH.Job, JCCH.PhaseGroup, JCCH.Phase, JCCH.CostType, JCCH.BuyOutYN, 
		  SL_PO_MO=NULL, SL_PO_MO_Description=NULL, Seq=NULL, PCOType=NULL, PCO=NULL, PCOStatus=NULL, ACO=NULL,
          Estimated=JCCH.OrigCost, Pending=0, CommittedAmt=0
          ,UncommittedAmt=0
          ,RecType='JCCH'
   from JCCH 
   
   UNION ALL
   
   --Approved Change Order Costs from PMOL included in EstCost.
   select PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, NULL, 
		  SL_PO_MO=NULL, SL_PO_MO_Description=NULL, Seq=NULL, PMOL.PCOType, PMOL.PCO, PMOI.Status, PMOL.ACO
          , sum(case when PMOL.ACO is not null then PMOL.EstCost else 0 end) as Estimated 
          , sum(case when PMSC.IncludeInProj in ( 'Y', 'C' ) 
						and PMOL.PCO is not NULL and PMOL.ACO is NULL
				    then PMOL.EstCost
			    else 0
			  end) as Pending
          
		  ,CommittedAmt=0
          ,UncommittedAmt=0
          ,RecType='PMOL'
   from PMOL
   JOIN PMOI 
          ON PMOI.PMCo = PMOL.PMCo 
             AND PMOI.Project = PMOL.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMOL.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMOL.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMOL.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMOL.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMOL.ACOItem,'')
	LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status            
       
   group by PMOL.PMCo, PMOL.Project, PMOL.PhaseGroup, PMOL.Phase, PMOL.CostType, PMOL.PCOType, PMOI.Status, PMOL.PCO, PMOL.ACO
   
   UNION ALL
   
   --Committed and Uncommitted From PM PO Material Detail
   select PMMF.PMCo, PMMF.Project, PMMF.PhaseGroup, PMMF.Phase, PMMF.CostType, NULL, 
		  SL_PO=PMMF.PO, SL_PO_Description=POHD.Description, PMMF.Seq, PMMF.PCOType, PMMF.PCO, PMOI.Status, PMMF.ACO,
          Estimated=0, Pending=0,
          /*Committed = Assigned to a PO (PO is not null) on an (O)riginal RecordType
                        or PO is not null on an Approved Change Order (ACO is not null)*/
          CommittedAmt=(case when PMMF.PCO is not NULL and PMMF.ACO is NULL 
								then 0 
							 when PMMF.PO is not NULL and PMMF.RecordType='O'
								then PMMF.Amount	
							  when PMMF.PO is not NULL and PMMF.ACO is not NULL
								then PMMF.Amount
							  else 0	
						 end)
          /*Uncommitted = PO is unassigned on (O)riginal RecordType
                          or PO unassigned on an ACO
                          or PMMF entry exists on a pending change order with a status to be
                          displayed or calculated in Projections
           */                          						 
          ,UncommittedAmt=(case when PMMF.RecordType='C' and PMSC.IncludeInProj in ( 'Y', 'C' ) 
										and PMMF.PCO is not NULL and PMMF.ACO is NULL
									then PMMF.Amount
								when PMMF.ACO is not NULL and PMMF.PO is NULL
									then PMMF.Amount
								when PMMF.RecordType='O' and PMMF.PO is null
									then PMMF.Amount
						  else 0
						  end)
          ,RecType='PMMF_PO'
   from PMMF
   LEFT JOIN PMOI 
          ON PMOI.PMCo = PMMF.PMCo 
             AND PMOI.Project = PMMF.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMMF.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMMF.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMMF.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMMF.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMMF.ACOItem,'')
   LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status

   LEFT JOIN POHD
		    on  POHD.POCo=PMMF.POCo
			and POHD.PO=PMMF.PO        
   
   where MaterialOption = 'P' 
   
   
   UNION ALL
   
   --
   select PMMF.PMCo, PMMF.Project, PMMF.PhaseGroup, PMMF.Phase, PMMF.CostType, NULL, 
		  SL_PO_MO=PMMF.MO, SL_PO_MO_Description=INMO.Description, PMMF.Seq, PMMF.PCOType, PMMF.PCO, PMOI.Status, PMMF.ACO,
          Estimated=0, Pending=0, 
          CommittedAmt=PMMF.Amount
          ,UncommittedAmt=0
          ,RecType='PMMF_MO' 
   from PMMF
   JOIN INMO ON  INMO.INCo = PMMF.INCo
			 AND INMO.MO = PMMF.MO
   LEFT JOIN PMOI 
          ON PMOI.PMCo = PMMF.PMCo 
             AND PMOI.Project = PMMF.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMMF.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMMF.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMMF.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMMF.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMMF.ACOItem,'')
   LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status			 
   where  MaterialOption = 'M'  
   
   
   UNION ALL
   
   select PMSL.PMCo, PMSL.Project, PMSL.PhaseGroup, PMSL.Phase, PMSL.CostType, NULL, 
		  SL_PO_MO=PMSL.SL, SL_PO_MO_Description=SLHD.Description, PMSL.Seq, PMSL.PCOType, PMSL.PCO, PMOI.Status, PMSL.ACO,
          Estimated=0, Pending=0, 
          /*Committed = Assigned to a SL (SL is not null) on an (O)riginal RecordType
                        or SL is not null on an Approved Change Order (ACO is not null)*/
          CommittedAmt=(case when PMSL.PCO is not NULL and PMSL.ACO is NULL 
								then 0 
							 when PMSL.SL is not NULL and PMSL.RecordType='O'
								then PMSL.Amount	
							  when PMSL.SL is not NULL and PMSL.ACO is not NULL
								then PMSL.Amount
							  else 0	
						 end)
          /*Uncommitted = SL is unassigned on (O)riginal RecordType
                          or SL unassigned on an ACO
                          or PMSL entry exists on a pending change order with a status to be
                          displayed or calculated in Projections
           */                          						 
          ,UncommittedAmt=(case when PMSL.RecordType='C' and PMSC.IncludeInProj in ( 'Y', 'C' ) 
										and PMSL.PCO is not NULL and PMSL.ACO is NULL
									then PMSL.Amount
								when PMSL.ACO is not NULL and PMSL.SL is NULL
									then PMSL.Amount
								when PMSL.RecordType='O' and PMSL.SL is null
									then PMSL.Amount
						  else 0
						  end)
          ,RecType='PMSL'
          
   from PMSL
    LEFT JOIN PMOI 
          ON PMOI.PMCo = PMSL.PMCo 
             AND PMOI.Project = PMSL.Project 
             AND isnull(PMOI.PCOType,'') = isnull(PMSL.PCOType,'')
             AND isnull(PMOI.PCO,'') = isnull(PMSL.PCO,'')
             AND isnull(PMOI.PCOItem,'') = isnull(PMSL.PCOItem,'')
             AND isnull(PMOI.ACO,'') = isnull(PMSL.ACO,'')
             AND isnull(PMOI.ACOItem,'') = isnull(PMSL.ACOItem,'')
   LEFT JOIN PMSC 
          on PMSC.Status = PMOI.Status

   LEFT JOIN SLHD
		  on  SLHD.SLCo = PMSL.SLCo
		  and SLHD.SL = PMSL.SL


GO
GRANT SELECT ON  [dbo].[vrvPMBuyOutReportDD] TO [public]
GRANT INSERT ON  [dbo].[vrvPMBuyOutReportDD] TO [public]
GRANT DELETE ON  [dbo].[vrvPMBuyOutReportDD] TO [public]
GRANT UPDATE ON  [dbo].[vrvPMBuyOutReportDD] TO [public]
GRANT SELECT ON  [dbo].[vrvPMBuyOutReportDD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPMBuyOutReportDD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPMBuyOutReportDD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPMBuyOutReportDD] TO [Viewpoint]
GO
