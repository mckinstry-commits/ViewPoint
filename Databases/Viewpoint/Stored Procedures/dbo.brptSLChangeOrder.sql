SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[brptSLChangeOrder]
        (@SLCo tinyint, @BeginSL VARCHAR(30) ='', @EndSL VARCHAR(30)= 'zzzzzzzzzzzzzzzzzzzzzzzz')
      /* created 06/19/97 Tracy*/
      /*     mod 06/27/99 JRE took out group by */
      /* mod 04/10/00 added SLHD Notes per Carol and for Customer Stewart Perry*/
      /*mod 06/05 JRE added update statement to fix MinSeq problem*/
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 fixed : notes. Issue #20721 */
      /*  Mod 9/28/04 CR Mod left Joined JCJM to the first select stmt for Job security */
      /*  Issue 25933 Added with(nolock) to the from and join statements NF 11/11/04 */
      /*  Get the Unit cost from SLIT per Issue 25448 NF 03/08/05  */
      /* Issue #135813 expanded Subcontract to varchar(30) */
      
        as
        set nocount on
         create table #SLChangeOrder
            (SLCo            tinyint              NULL,
            SL				 VARCHAR(30)          NULL,
            SLChangeOrder       int    Null,
            AppChangeOrder		varchar(10)	NULL,
            VendorGroup		tinyint		NULL,
            Vendor		int		NULL,
            JCCo		tinyint		NULL,
            Job			varchar(10)	NULL,
            OrigCost		Numeric(16,2)		NULL,
            PrevChangeOrders	Numeric(16,2)		NULL,
            PrevSeq smallint identity(1,1)   
            )
        
        CREATE UNIQUE CLUSTERED INDEX  btiSLChangeOrder
            ON  #SLChangeOrder(SLCo,SL,SLChangeOrder)
        
      
        /* insert each unique ChangeOrder per SL Info */
        /* the MIN(SLCD.SLChangeOrder) is used to find the previous change order amounts */
        insert into #SLChangeOrder
        (SLCo, SL, SLChangeOrder,AppChangeOrder,VendorGroup, Vendor, JCCo, Job, OrigCost, PrevChangeOrders)
        Select SLHD.SLCo, SLHD.SL, SLCD.SLChangeOrder, MIN(SLCD.AppChangeOrder), MIN(SLHD.VendorGroup), MIN(SLHD.Vendor), MIN(SLHD.JCCo),
         MIN(SLHD.Job),
         OrigCost=(select sum(SLIT.OrigCost) from SLIT with(nolock) where SLIT.SLCo=SLHD.SLCo and SLIT.SL=SLHD.SL)
        ,PrevChangeOrders=0
         FROM SLHD with(nolock)
   	Left Join SLCD with(nolock) on SLCD.SLCo=SLHD.SLCo and SLCD.SL=SLHD.SL
           Left join JCJM with(nolock) on JCJM.JCCo=SLHD.SLCo and JCJM.Job=SLHD.Job
         where SLHD.SLCo=@SLCo and SLHD.SL>=@BeginSL and  SLHD.SL<=@EndSL and (SLHD.Job = JCJM.Job or SLHD.Job is null)
   
           
         group by
           SLHD.SLCo, SLHD.SL, SLCD.SLChangeOrder
         order by SLCD.SLChangeOrder
           /*, SLHD.VendorGroup, SLHD.Vendor, SLHD.JCCo,   SLHD.Job */
   
   	/*
    	select a.*,SLCD.* from SLCD, #SLChangeOrder a,  #SLChangeOrder
        	where  SLCD.SLCo=#SLChangeOrder.SLCo and SLCD.SL=#SLChangeOrder.SL
   	and a.SLCo=#SLChangeOrder.SLCo and a.SL=#SLChangeOrder.SL and a.PrevSeq<#SLChangeOrder.PrevSeq and
                 SLCD.SLCo=a.SLCo and  SLCD.SL=a.SL
   	*/
   
   
        /* update the temp file with the previous change order amounts */
   update #SLChangeOrder
   set #SLChangeOrder.PrevChangeOrders= (select ISNULL(sum(SLCD.ChangeCurCost),0) 
                                         from SLCD with(nolock)
   					join #SLChangeOrder a with(nolock) on a.SLCo=#SLChangeOrder.SLCo 
   					and a.SL=#SLChangeOrder.SL and a.PrevSeq<#SLChangeOrder.PrevSeq 
     	  	              	      	and SLCD.SLCo=a.SLCo and  SLCD.SL=a.SL 
   					and SLCD.SLChangeOrder =a.SLChangeOrder)
   
   create table #PrevCost
    (SLCo            tinyint              NULL,
       SLChangeOrder       smallint    Null,
    	Mth smalldatetime NULL,
   	SLTrans int NULL,
   	SL        varchar(10)            NULL,
       	SLItem    smallint		NULL,
   	PrevCost  Numeric(16,2)		NULL)
   
   insert into #PrevCost (SLCo , SLChangeOrder, Mth, SLTrans, SL,  SLItem, PrevCost)
   select SLCo, SLChangeOrder, Mth, SLTrans, SL, SLItem , 
        PrevChgOrder=(select sum(case when t.UM='LS' then c.ChangeCurCost
        		when c.ChangeCurUnits<>0 and c.ChangeCurUnitCost<>0 then (c.ChangeCurUnits)*(c.ChangeCurUnitCost)
        		when c.ChangeCurUnits<>0 and c.ChangeCurUnitCost=0 then c.ChangeCurUnits*t.CurUnitCost
        		when c.ChangeCurUnits=0 and c.ChangeCurUnitCost<>0 then t.CurUnits*c.ChangeCurUnitCost
        		else 0 end) 
   		From SLIT t with(nolock)
        			Join SLCD c with(nolock) on c.SLCo=t.SLCo and c.SL=t.SL and c.SLItem=t.SLItem
   		Where t.SLCo=@SLCo and c.SL=SLCD.SL and c.SLChangeOrder < SLCD.SLChangeOrder)
   From SLCD with(nolock)
   Where SLCo=@SLCo and SL>=@BeginSL and SL<=@EndSL and SLChangeOrder>=0 and SLChangeOrder <=32767
   
   
   
   
   
     /* from #SLChangeOrder,SLCD
        where  SLCD.SLCo=#SLChangeOrder.SLCo and SLCD.SL=#SLChangeOrder.SL */
   
   
   
   /* select the results */
   set nocount off
        select SLCo=a.SLCo, SL=a.SL, SLItem=SLCD.SLItem,a.SLChangeOrder,
        	ACO=a.AppChangeOrder, SLChgOrder=SLCD.SLChangeOrder,
        	ActualDate=SLCD.ActDate, SLCODesc=SLCD.Description,
        	SLCD.UM, SLCD.ChangeCurUnits, SLCD.ChangeCurUnitCost, SLCD.ChangeCurCost,
        	VendorGroup=a.VendorGroup, Vendor=a.Vendor, VendName=APVM.Name, VendAdd=APVM.Address,
        	VendCity=APVM.City, VendState=APVM.State, VendZip=APVM.Zip,JCCo=a.JCCo,
        	Job=a.Job,JobDesc=JCJM.Description, JobAdd=JCJM.ShipAddress, JobCity=JCJM.ShipCity, JobState=JCJM.ShipState,
        	JobZip=JCJM.ShipZip, OrigCost=a.OrigCost, PrevChangeOrders=#PrevCost.PrevCost,
        	CoName=HQCO.Name,CoAddress=HQCO.Address, CoCity=HQCO.City, CoState=HQCO.State, CoZip=HQCO.Zip,
                   SLIT.Phase, JCJP.Item, ItemCurUnitCost=SLIT.CurUnitCost, ItemCurUnits=SLIT.CurUnits,
                   SLItemNote=SLIT.Notes,SLHeaderNote=SLHD.Notes,SLHDNotes=SLHD.Notes,SLCD.Notes
     from #SLChangeOrder a with(nolock)
        join SLCD with(nolock) on SLCD.SLCo=a.SLCo and SLCD.SL=a.SL and SLCD.SLChangeOrder=a.SLChangeOrder
        join #PrevCost with(nolock) on SLCD.SLCo=#PrevCost.SLCo and SLCD.Mth=#PrevCost.Mth and SLCD.SLTrans=#PrevCost.SLTrans
        join HQCO with(nolock) on HQCO.HQCo=a.SLCo
        left join APVM with(nolock) on APVM.VendorGroup=a.VendorGroup and APVM.Vendor=a.Vendor
        left join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
        left join SLHD with(nolock) on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL
        left join SLIT with(nolock) on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem
        left join JCJP with(nolock) on JCJP.JCCo=SLIT.JCCo and JCJP.Job=SLIT.Job and JCJP.Phase=SLIT.Phase and JCJP.PhaseGroup=SLIT.PhaseGroup
        --join #PrevCost on a.SLCo=#PrevCost.SLCo and a.SL=#PrevCost.SL and a.SLChangeOrder=#PrevCost.SLChangeOrder and SLIT.SLItem=#PrevCost.SLItem

GO
GRANT EXECUTE ON  [dbo].[brptSLChangeOrder] TO [public]
GO
