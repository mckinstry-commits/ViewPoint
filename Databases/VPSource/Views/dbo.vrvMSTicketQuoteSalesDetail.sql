SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    view [dbo].[vrvMSTicketQuoteSalesDetail] as
/***************************
This view is used in MS Quote Status Report
(note unusual joins on derived tables since the Quote field doesn't exist in MSTD)

created on issue #29929 NF



****************************/
select MSDetail.MSCo, MSDetail.CustGroup, MSDetail.Customer, MSDetail.CustName, MSDetail.CustJob, MSDetail.CustPO,
	MSDetail.LocGroup,MSDetail.FromLoc, MSDetail.MatlGroup, MSDetail.Material, MSDetail.MatlDesc, MSDetail.Category, 
	MSDetail.UM,MSDetail.UnitPrice, MSDetail.MatlUnits,MSDetail.CoName, 
        Active= (case when MSPriceOR.Active is null then MSQ.Active else MSPriceOR.Active end),
        QuoteType = (case when MSPriceOR.QuoteType is null then MSQ.QuoteType else MSPriceOR.QuoteType end),
        QuoteDesc = (case when MSPriceOR.Description is null then MSQ.Description else MSPriceOR.Description end), 
        MSQ.QuoteUnits, MSQ.OrderUnits,
        Quote = (case when MSPriceOR.Quote is null then MSQ.Quote else MSPriceOR.Quote end),
	PriceOR = (case when MSPriceOR.Quote is null then 'QD' else 'MD' end)
       
from (select MSTD.MSCo, MSTD.CustGroup, MSTD.Customer, CustName = ARCM.Name, MSTD.CustJob, MSTD.CustPO, 
       INLM.LocGroup, MSTD.FromLoc,CoName = HQCO.Name,
       MSTD.MatlGroup, MSTD.Material, HQMT.Category, MatlDesc = HQMT.Description, MSTD.UM, MSTD.UnitPrice, 
       MatlUnits=sum(MSTD.MatlUnits)
        
	from MSTD
 		join INLM on MSTD.MSCo  = INLM.INCo and MSTD.FromLoc = INLM.Loc
 		join HQMT on MSTD.MatlGroup = HQMT.MatlGroup and MSTD.Material = HQMT.Material
                join HQCO on MSTD.MSCo = HQCO.HQCo
		join ARCM on MSTD.CustGroup = ARCM.CustGroup and MSTD.Customer = ARCM.Customer
	where  SaleType = 'C'
	group by MSTD.MSCo, MSTD.CustGroup, MSTD.Customer, ARCM.Name, MSTD.CustJob, MSTD.CustPO,
        	 INLM.LocGroup, MSTD.FromLoc, HQCO.Name,
        	 MSTD.MatlGroup, MSTD.Material, HQMT.Category, HQMT.Description, MSTD.UM, MSTD.UnitPrice) as MSDetail

left join (select MSQH.MSCo, MSQH.Quote, MSQH.CustGroup, MSQH.Customer, MSQH.CustJob, MSQH.CustPO,MSQH.Active, MSQH.QuoteType,
       			MSQH.Description, MSQD.FromLoc, MSQD.MatlGroup, MSQD.Material, MSQD.UM,HQMT.Category, INLM.LocGroup,
                  	MSQD.QuoteUnits, MSQD.UnitPrice, MSQD.ECM, MSQD.OrderUnits, MSQD.SoldUnits
      		 from MSQD with(nolock)
			join MSQH on MSQD.MSCo = MSQH.MSCo and MSQH.Quote = MSQD.Quote
			join HQMT on MSQD.MatlGroup = HQMT.MatlGroup and MSQD.Material = HQMT.Material
			join INLM on MSQD.MSCo = INLM.INCo and MSQD.FromLoc = INLM.Loc
		 where MSQH.QuoteType = 'C' ) AS MSQ
	on MSDetail.MSCo = MSQ.MSCo and
	   MSDetail.CustGroup = MSQ.CustGroup and
	   MSDetail.Customer = MSQ.Customer and
           MSDetail.FromLoc = MSQ.FromLoc and
           IsNull(MSDetail.CustJob,'') = IsNull(MSQ.CustJob,'') and
           IsNull(MSDetail.CustPO,'') = IsNull(MSQ.CustPO,'') and
	   MSDetail.MatlGroup = MSQ.MatlGroup and
	   MSDetail.Material = MSQ.Material and
	   MSDetail.UM = MSQ.UM and
	   MSDetail.Category = MSQ.Category

left join (	select MSMD.MSCo, MSMD.Quote, MSMD.Seq, MSQH.CustGroup, MSQH.Customer, MSQH.CustJob, MSQH.CustPO,
                       MSQH.Active, MSQH.QuoteType, MSQH.Description,
       			MSMD.Loc, MSMD.MatlGroup,  MSMD.UM, MSMD.UnitPrice, MSMD.LocGroup,
       			MSMD.Category, MSMD.ECM
		from MSMD with(noLock)
		join MSQH on MSMD.MSCo = MSQH.MSCo and MSMD.Quote = MSQH.Quote
		where MSQH.QuoteType = 'C' ) as MSPriceOR
     on MSDetail.MSCo = MSPriceOR.MSCo and
	   MSDetail.CustGroup = MSPriceOR.CustGroup and
	   MSDetail.Customer = MSPriceOR.Customer and
	   MSDetail.FromLoc = IsNull(MSPriceOR.Loc,MSDetail.FromLoc) and
           IsNull(MSDetail.CustJob,'') = IsNull(MSPriceOR.CustJob,'') and
           IsNull(MSDetail.CustPO,'') = IsNull(MSPriceOR.CustPO,'') and
	   MSDetail.MatlGroup = MSPriceOR.MatlGroup and
	        
	   MSDetail.UM = MSPriceOR.UM and
	   MSDetail.Category = MSPriceOR.Category

where 
(case when MSPriceOR.Quote is null then MSQ.Quote else MSPriceOR.Quote end) is not null








GO
GRANT SELECT ON  [dbo].[vrvMSTicketQuoteSalesDetail] TO [public]
GRANT INSERT ON  [dbo].[vrvMSTicketQuoteSalesDetail] TO [public]
GRANT DELETE ON  [dbo].[vrvMSTicketQuoteSalesDetail] TO [public]
GRANT UPDATE ON  [dbo].[vrvMSTicketQuoteSalesDetail] TO [public]
GO
