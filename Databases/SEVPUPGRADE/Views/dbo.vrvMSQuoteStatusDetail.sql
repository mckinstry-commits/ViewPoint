SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  view [dbo].[vrvMSQuoteStatusDetail] as 
	/* Used in the MS Quote Status report Issue 29929 4/6/6 NF */
select MSQH.MSCo, MSQH.Quote, MSQH.QuoteType, QuoteDesc=MSQH.Description, Active= MSQH.Active, RecType= 'Quote', 
       Seq=MSQD.Seq, LocGroup=INLM.LocGroup, Loc=MSQD.FromLoc,   --6
     CustGroup=CustGroup, Customer = Customer, CustPO=CustPO, CustJob=CustJob,  --4
     MatlGroup=MSQD.MatlGroup, Category=HQMT.Category, Material=MSQD.Material, UM=MSQD.UM,  --4
     MSQD_QuoteUnits=MSQD.QuoteUnits, MSQD_UnitPrice=MSQD.UnitPrice, MSQD_ECM=MSQD.ECM, 
     MSQD_ReqDate=MSQD.ReqDate, Status=MSQD.Status, --5
     MSQD_OrderUnits=MSQD.OrderUnits, MSQD_SoldUnits=MSQD.SoldUnits, 	--2					
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, --4
     MSTD_Mth=NULL, MSTD_SaleDate=NULL, MSTD_MatlUnits=NULL, --3
     MSTD_UnitPrice=NULL, MSTD_ECM=NULL, MSTD_MatlTotal=NULL  --3
     
From MSQH 
join MSQD on MSQH.MSCo = MSQD.MSCo and MSQH.Quote= MSQD.Quote
join INLM on MSQD.MSCo = INLM.INCo and MSQD.FromLoc = INLM.Loc
left outer join HQMT on MSQD.MatlGroup = HQMT.MatlGroup and MSQD.Material = HQMT.Material
where MSQH.QuoteType = 'C'
     
	union all

select MSCo, Quote, NULL, NULL, NULL,'MSMD',  Seq, LocGroup, Loc, 
        NULL,NULL,NULL,NULL,
        MatlGroup, Category, Material=NULL, UM,
     	NULL, NULL, NULL, NULL, NULL, 
	NULL, NULL, 
	Rate, UnitPrice, ECM, MinAmt,
	NULL, NULL, NULL, 
        NULL, NULL, NULL
	
From MSMD

     union all  

select MSCo, NULL, NULL, NULL,'MSTD',NULL, Seq=NULL,LocGroup=INLM.LocGroup, Loc=FromLoc, 
     MSTD.CustGroup,MSTD.Customer,MSTD.CustJob,MSTD.CustPO,
     MatlGroup= MSTD.MatlGroup, Category=NULL, Material=MSTD.Material, UM=MSTD.UM,  
     MSQD_QuoteUnits=0, MSQD_UnitPrice=0, MSQD_ECM=NULL, MSQD_ReqDate=NULL, Status=NULL, 
     MSQD_OrderUnits=0, MSQD_SoldUnits=0, 						
     MSMD_Rate=0.00, MSMD_UnitPrice=0.00, MSMD_ECM=NULL, MSMD_MinAmt=0.00, 
     MSTD_Mth=MSTD.Mth, MSTD_SaleDate=MSTD.SaleDate, MSTD_MatlUnits=MSTD.MatlUnits, 
     MSTD_UnitPrice=MSTD. UnitPrice, MSTD_ECM= MSTD.ECM, MSTD_MatlTotal=MSTD.MatlTotal

from MSTD 
join INLM on MSTD.MSCo = INLM.INCo and MSTD.FromLoc = INLM.Loc
where MSTD.Customer is not NULL


 




GO
GRANT SELECT ON  [dbo].[vrvMSQuoteStatusDetail] TO [public]
GRANT INSERT ON  [dbo].[vrvMSQuoteStatusDetail] TO [public]
GRANT DELETE ON  [dbo].[vrvMSQuoteStatusDetail] TO [public]
GRANT UPDATE ON  [dbo].[vrvMSQuoteStatusDetail] TO [public]
GO
