SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptPOChangeOrder    Script Date: 8/28/99 9:32:30 AM ******/
     --drop proc brptPOChangeOrder
     CREATE      proc [dbo].[brptPOChangeOrder]
     (@POCo tinyint, @BeginPO varchar(30) =' ', @EndPO varchar(30)= 'zzzzzzzzz')
     /* created 02/21/00 Tracy*/
     
     as
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : notes. Issue #20721 */
     /*  Issue 25923 Added with(nolock) to the from and join statements NF 11/11/04 */
      
     
    create table #ChangeOrder
        (POCo            tinyint              NULL,
        PO        varchar(30)            NULL,
        ChangeOrder       varchar(10)    Null,
    	POItem    tinyint		NULL,
    	POITItem    tinyint		NULL,
    --    AppChangeOrder	varchar(10)	NULL,
        ActDate		smalldatetime	null,
        VendorGroup		tinyint		NULL,
        Vendor		int		NULL,
        JCCo		tinyint		NULL,
        Job			varchar(10)	NULL,
        OrigCost		Numeric(16,2)		NULL,
        PrevCOAmtonDate	Numeric(16,2)		NULL,
    	UM  		varchar(3)    NULL,
        MinSeq		smallint identity(1,1)
        )
    
    CREATE UNIQUE CLUSTERED INDEX  btiChangeOrder
        ON  #ChangeOrder(POCo,PO,ChangeOrder,POItem,POITItem)
    
    declare @BeginCO varchar(10),@EndCO varchar(10)
    select  @BeginCO='',@EndCO ='zzzzzzzzzz'
    
    
    /* insert each unique ChangeOrder per PO Info */
    /* the MIN(POCD.ChangeOrder) is used to find the previous change order amounts */
    insert into #ChangeOrder
    (POCo, PO, ChangeOrder,POITItem,POItem,ActDate,VendorGroup, Vendor, JCCo, Job, OrigCost, PrevCOAmtonDate,UM
    --, MinSeq
    )
    Select POHD.POCo, POHD.PO, POCD.ChangeOrder, POIT.POItem, POCD.POItem, MIN(POCD.ActDate), MIN(POHD.VendorGroup), MIN(POHD.Vendor), MIN(POHD.JCCo),
     MIN(POHD.Job),
     OrigCost=(select sum(POIT.OrigCost) from POIT where POIT.POCo=POHD.POCo and POIT.PO=POHD.PO)
    ,PrevCOAmtonDate=0,MIN(POIT.UM)
    --,MIN(POCD.ChangeOrder)
     FROM POHD with(nolock)
      Join POCD with(nolock) on POCD.POCo=POHD.POCo and POCD.PO=POHD.PO 
      Join POIT with(nolock) on POIT.POCo=POCD.POCo and POIT.PO=POCD.PO and POIT.POItem = POCD.POItem
      Left join JCJM with(nolock) on POHD.JCCo = JCJM.JCCo and POHD.Job = JCJM.Job 
     where POHD.POCo=@POCo and POHD.PO>=@BeginPO and  POHD.PO<=@EndPO
          and POCD.ChangeOrder>=@BeginCO  and POCD.ChangeOrder<=@EndCO 
          and (POHD.Job = JCJM.Job or POHD.Job is Null)
     group by
       POHD.POCo, POHD.PO, POCD.ChangeOrder, POCD.POItem, POIT.POItem
       /*, POHD.VendorGroup, POHD.Vendor, POHD.JCCo,   POHD.Job */
    
    
    delete from #ChangeOrder
    where POItem<>POITItem
       and exists (select * from POCD a where a.POCo=#ChangeOrder.POCo and a.PO=#ChangeOrder.PO
            and a.ChangeOrder=#ChangeOrder.ChangeOrder and a.POItem=#ChangeOrder.POITItem)
    
    /* update the temp file with the previous change order amounts based on the Actual Date 
    update #ChangeOrder
    set PrevCOAmtonDate=(select ISNULL(sum(POCD.ChangeCurCost),0) from #ChangeOrder a  , POCD
      		     where a.POCo=#ChangeOrder.POCo and a.PO=#ChangeOrder.PO and a.POItem=#ChangeOrder.POItem 
    				and a.ActDate<#ChangeOrder.ActDate
     				and POCD.POCo=a.POCo and  POCD.PO=a.PO and POCD.ChangeOrder =a.ChangeOrder)
    where POItem=POITItem */
    
    
     /* update the temp file with the previous change order amounts based on the Change order number */
    
    
    
    create table #PrevCost
     (POCo            tinyint              NULL,
        ChangeOrder       varchar(10)    Null,
    	PO        varchar(30)            NULL,
        	POItem    tinyint		NULL,
    	PrevCost  Numeric(16,2)		NULL)
    
    insert into #PrevCost (POCo ,  ChangeOrder, PO,  POItem, PrevCost)
    select POCo, ChangeOrder, PO, POItem , (select sum(c.ChgTotCost)--case when t.UM='LS' then c.ChangeCurCost 
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost<>0 and c.ECM='E' then (c.ChangeCurUnits*(c.CurUnitCost+t.CurUnitCost)+t.CurUnits*c.CurUnitCost)
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost<>0 and c.ECM='C' then (c.ChangeCurUnits*(c.CurUnitCost+t.CurUnitCost)+t.CurUnits*c.CurUnitCost)/100
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost<>0 and c.ECM='M' then (c.ChangeCurUnits*(c.CurUnitCost+t.CurUnitCost)+t.CurUnits*c.CurUnitCost)/1000	
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost=0 and c.ECM='E' then (c.ChangeCurUnits*t.CurUnitCost)
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost=0 and c.ECM='C' then (c.ChangeCurUnits*t.CurUnitCost)/100	
    	--when c.ChangeCurUnits<>0 and c.CurUnitCost=0 and c.ECM='M' then (c.ChangeCurUnits*t.CurUnitCost)/1000
    	--when c.ChangeCurUnits=0 and c.CurUnitCost<>0 and c.ECM='E' then (c.CurUnitCost*t.CurUnits)
    	--when c.ChangeCurUnits=0 and c.CurUnitCost<>0 and c.ECM='C' then (c.CurUnitCost*t.CurUnits)/100
    	--when c.ChangeCurUnits=0 and c.CurUnitCost<>0 and c.ECM='M' then (c.CurUnitCost*t.CurUnits)/1000
    	--end) 
           	From POIT t with(nolock)
             		Join POCD c with(nolock) on c.POCo=t.POCo and c.PO=t.PO and c.POItem=t.POItem
    		Where t.POCo=@POCo and c.PO=POCD.PO and c.ChangeOrder < POCD.ChangeOrder)
   
    From POCD with(nolock) 
    Where POCo=@POCo and PO>=@BeginPO and PO <=@EndPO and ChangeOrder>=' ' and ChangeOrder <= 'zzzzzzzzzz'
    group by POCo, ChangeOrder, PO, POItem
    
    
    
    
    
    create table #TaxRate
        (TaxGroup            tinyint              NULL,
        TaxCode        varchar(10)            NULL,
        	TaxRate    decimal(8,6)  	NULL)
    
    insert into #TaxRate (TaxGroup,TaxCode ,TaxRate)
    select HQTX.TaxGroup, HQTX.TaxCode, isnull(max(HQTX.NewRate), sum(HQTX2.NewRate))
    From HQTX with(nolock)
    Left Outer Join HQTL with(nolock) on HQTX.TaxGroup=HQTL.TaxGroup and HQTX.TaxCode=HQTL.TaxCode
    Left Outer Join HQTX HQTX2 with(nolock) on HQTL.TaxGroup=HQTX2.TaxGroup and HQTL.TaxLink=HQTX2.TaxCode
    Group By HQTX.TaxGroup, HQTX.TaxCode
    
    /* select the results */
    
    select POCo=a.POCo, PO=a.PO, POItem=POCD.POItem,a.POITItem,a.ChangeOrder,
    	POMth=POCD.Mth,
    	ActualDate=a.ActDate, POCODesc=POCD.Description,POCD.ECM,
    	POCD.UM, ChangeCurUnits= (case when a.POItem<>a.POITItem then 0.0 else POCD.ChangeCurUnits end), 
    	POCD.CurUnitCost, ChangeCurCost=(case when a.POItem<>a.POITItem then 0.0 else POCD.ChangeCurCost end),
    	POCD.ChangeBOUnits,POCD.ChangeBOCost, POCD.ChgTotCost,
    	VendorGroup=a.VendorGroup, Vendor=a.Vendor, VendName=APVM.Name, VendAdd=APVM.Address,
    	VendCity=APVM.City, VendState=APVM.State, VendZip=APVM.Zip,JCCo=a.JCCo,
    	Job=a.Job,JobDesc=JCJM.Description, JobAdd=JCJM.ShipAddress, JobCity=JCJM.ShipCity, JobState=JCJM.ShipState,
    	JobZip=JCJM.ShipZip, OrigCost=a.OrigCost, PrevCOAmtonDate=a.PrevCOAmtonDate,
    	CoName=HQCO.Name,CoAddress=HQCO.Address, CoCity=HQCO.City, CoState=HQCO.State, CoZip=HQCO.Zip ,POITCurUC=POIT.CurUnitCost,POITTaxCode=POIT.TaxCode,TaxRate=#TaxRate.TaxRate,
    	POITUnits=POIT.CurUnits,MinSeq,#PrevCost.PrevCost,CONotes=POCD.Notes,ItemNotes=POIT.Notes,HeaderNotes=POHD.Notes
    from #ChangeOrder a with(nolock)
    join POCD with(nolock) on POCD.POCo=a.POCo and POCD.PO=a.PO and POCD.ChangeOrder=a.ChangeOrder and POCD.POItem=a.POItem
    join POIT with(nolock) on POCD.POCo=POIT.POCo and POCD.PO=POIT.PO and POCD.POItem=POIT.POItem 
    join POHD with(nolock) on POHD.POCo=a.POCo and POHD.PO=a.PO
    join HQCO with(nolock) on HQCO.HQCo=a.POCo
    join #PrevCost with(nolock) on a.POCo=#PrevCost.POCo and a.PO=#PrevCost.PO and a.ChangeOrder=#PrevCost.ChangeOrder and a.POItem=#PrevCost.POItem
    left join APVM with(nolock) on APVM.VendorGroup=a.VendorGroup and APVM.Vendor=a.Vendor
    left join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
    left join  #TaxRate with(nolock) on POIT.TaxGroup= #TaxRate.TaxGroup and POIT.TaxCode= #TaxRate.TaxCode

GO
GRANT EXECUTE ON  [dbo].[brptPOChangeOrder] TO [public]
GO
