SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspPMSUBItemDocMerge]
    /*******************************************************************************
    * Created By:   GF 06/04/2001
    * Modified By:	DC 6/29/10 - #135813 - expand subcontract number
    *
    * Build query statement for use in PM Subcontract documents with items.
    *
    *
    * Pass:
    * @apco             AP Company
    * @project          PM Project
    * @sl               Subcontract
    * @vendorgroup      VendorGroup
    *
    **************************************/
    (@pmco bCompany, @apco bCompany, @project bJob, @sl VARCHAR(30), --bSL, DC #135813
    @vendorgroup bGroup)
    as
   
    create table #SUBITEMS
    (SLCo           tinyint         null,
     SL             varchar(30)     null, --DC #135813
     SLItem         varchar(20)     null,
     Item           varchar(20)     null,
     ItemDesc       varchar(60)     null,
     Units          numeric(16,3)   not null,
     UM             varchar(3)      null,
     UnitPrice      numeric(16,5)   not null,
     Amount         numeric(16,2)   not null,
     Notes          varchar(6000)   null
    )
   
   
   -- insert SLIT information
   insert into #SUBITEMS (SLCo, SL, SLItem, Item, ItemDesc, Units, UM, UnitPrice, Amount, Notes)
   select @apco, @sl, i.SLItem, p.Item, i.Description, isnull(i.CurUnits,0), i.UM, isnull(i.CurUnitCost,0), isnull(i.CurCost,0), i.Notes
   from bSLIT i with (nolock) 
   left join JCJP p with (nolock) on p.JCCo=i.JCCo and p.Job=i.Job and p.PhaseGroup=i.PhaseGroup and p.Phase=i.Phase
   where i.SLCo=@apco and i.SL=@sl and i.VendorGroup=@vendorgroup and i.ItemType in (1,4)
   
   
   -- insert PMSL information
   insert into #SUBITEMS (SLCo, SL, SLItem, Item, ItemDesc, Units, UM, UnitPrice, Amount, Notes)
   select @apco, @sl, l.SLItem, p.Item, l.SLItemDescription, isnull(l.Units,0), l.UM, isnull(l.UnitCost,0), isnull(l.Amount,0), l.Notes
   from bPMSL l with (nolock) 
   left join JCJP p with (nolock) on p.JCCo=l.PMCo and p.Job=l.Project and p.PhaseGroup=l.PhaseGroup and p.Phase=l.Phase
   where l.PMCo=@pmco and l.SLCo=@apco and l.SL=@sl and l.SLItemType in (1,4) --and l.Project=@project
   and l.SendFlag = 'Y' and InterfaceDate is null
   and not exists(select top 1 1 from #SUBITEMS where #SUBITEMS.SL=l.SL and #SUBITEMS.SLItem=l.SLItem)
   
   
   -- select results
   select SLCo, SL, SLItem, Item, ItemDesc, Units, UM, UnitPrice, Amount, Notes
   from #SUBITEMS
   order by SLCo, SL, SLItem

GO
GRANT EXECUTE ON  [dbo].[bspPMSUBItemDocMerge] TO [public]
GO
