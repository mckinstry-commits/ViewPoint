SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[brvMSInvTotal]
    
    as
    
    /*select MSID.Co, MSID.Mth, MSID.BatchId, MSID.BatchSeq, TotalSummary=0, MSID.MatlGroup, MSID.Material, MSID.UM, MSID.UnitPrice, TotalUnitsMatl=0,
    TotalMatl=0, TotalHaul=0, TotalTax=0  From MSID
    Join MSTD on MSTD.MSCo=MSID.Co AND MSTD.Mth=MSID.Mth AND MSTD.MSTrans=MSID.MSTrans*/
    
    --union
    select MSID.Co, MSID.Mth, Seq=max(MSTD.MSTrans), TotalSummary=1, MSID.MatlGroup, MSID.Material, MatlDesc=HQMT.Description, MSID.UM, TotalUnitsMatl=sum(MSTD.MatlUnits),
    TotalMatl=sum(MatlTotal), TotalHaul=sum(HaulTotal), TotalTax=sum(TaxTotal)  From MSID
    Join MSTD on MSTD.MSCo=MSID.Co AND MSTD.Mth=MSID.Mth AND MSTD.MSTrans=MSID.MSTrans
    Join HQMT on HQMT.MatlGroup=MSTD.MatlGroup and HQMT.Material=MSTD.Material
    Group By MSID.Co, MSID.Mth, MSID.MatlGroup, MSID.Material, HQMT.Description, MSID.UM, MSID.UnitPrice

GO
GRANT SELECT ON  [dbo].[brvMSInvTotal] TO [public]
GRANT INSERT ON  [dbo].[brvMSInvTotal] TO [public]
GRANT DELETE ON  [dbo].[brvMSInvTotal] TO [public]
GRANT UPDATE ON  [dbo].[brvMSInvTotal] TO [public]
GRANT SELECT ON  [dbo].[brvMSInvTotal] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvMSInvTotal] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvMSInvTotal] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvMSInvTotal] TO [Viewpoint]
GO
