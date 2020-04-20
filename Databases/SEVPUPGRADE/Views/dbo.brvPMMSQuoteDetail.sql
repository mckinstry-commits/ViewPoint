SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      view [dbo].[brvPMMSQuoteDetail] 
    
    AS
    
     SELECT  
     Sort=2, QuoteOverrideDefaultDesc='MS Quote Detail', MSQH.Job, MSQH.MSCo, MSQH.Quote, MSQH.Description, 
     MSQH.Contact, MSQH.PriceTemplate, MSQH.TaxCode, MSQH.HaulTaxOpt, MSQH.QuotedBy, MSQH.QuoteDate, MSQH.ExpDate,
     MSQH.Active,MSQH.Loc,
     
     FromLoc=MSQD.FromLoc, Material=MSQD.Material, MSQD.UM, QuoteUnits=MSQD.QuoteUnits,UnitPrice=MSQD.UnitPrice,
     MSQD.ECM, MSQD.ReqDate, Status=MSQD.Status, OrderUnits=MSQD.OrderUnits,SoldUnits=MSQD.SoldUnits, 
     MSQD.Notes,MatlGroup=MSQD.MatlGroup,
     
     PMMF_location=NULL, PMMF_MaterialCode=NULL, PMMF_MtlDescription=NULL, PMMF_Phase=NULL,
     PMMF_CT=NULL, PMMF_Units=NULL, PMMF_UnitCost=NULL,PMMF_ACO=NULL,PMMF_ACOItem=NULL,
     PMMF_Seq=NULL,PMMF_PMCo=NULL
    
     FROM MSQH
     JOIN MSQD on MSQD.MSCo = MSQH.MSCo AND MSQD.Quote = MSQH.Quote AND MSQD.FromLoc = MSQH.Loc 
            
     UNION ALL
    
     SELECT   
     1, QuoteOverrideDefaultDesc='PM Quote Detail',PMMF.Project, PMMF.PMCo, PMMF.Quote, NULL, NULL,
     NULL, PMMF.TaxCode, NULL, NULL, NULL, NULL, NULL,NULL, 
    
     NULL, NULL, PMMF.UM, NULL, NULL, PMMF.ECM, PMMF.ReqDate, NULL, NULL, 
     NULL, NULL,NULL,
     
     PMMF_location=Location, PMMF_MaterialCode=MaterialCode, PMMF_MtlDescription=MtlDescription, PMMF_Phase=Phase,
     PMMF_CT=CostType, PMMF_Units=Units, PMMF_UnitCost=UnitCost,PMMF_ACO=ACO,PMMF_ACOItem=ACOItem,
     PMMF_Seq=Seq,PMMF_PMCo=PMCo
    
     FROM MSQH 
     JOIN PMMF on MSQH.MSCo = PMMF.PMCo AND MSQH.Job = PMMF.Project

GO
GRANT SELECT ON  [dbo].[brvPMMSQuoteDetail] TO [public]
GRANT INSERT ON  [dbo].[brvPMMSQuoteDetail] TO [public]
GRANT DELETE ON  [dbo].[brvPMMSQuoteDetail] TO [public]
GRANT UPDATE ON  [dbo].[brvPMMSQuoteDetail] TO [public]
GO
