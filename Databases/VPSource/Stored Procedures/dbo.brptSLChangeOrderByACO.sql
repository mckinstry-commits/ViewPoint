SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- drop proc  dbo.brptSLChangeOrder 
          /****** Object:  Stored Procedure dbo.brptSLChangeOrder    Script Date: 8/28/99 9:32:30 AM ******/
          CREATE    proc [dbo].[brptSLChangeOrderByACO]
          (@SLCo tinyint, @BeginSL VARCHAR(30) ='', @EndSL VARCHAR(30)= 'zzzzzzzzzzzzzzzzzzzzzzzz')
       --@BeginCO varchar(10)= '',
      -- @BeginCO smallint =0,
       --   @EndCO varchar(10)= 'zzzzzzzzz')
       --@EndCO smallint =9999)
      /* created 06/19/97 Tracy*/
      /*     mod 06/27/99 JRE took out group by */
      /* mod 04/10/00 added SLHD Notes per Carol and for Customer Stewart Perry*/
      /*mod 06/05 JRE added update statement to fix MinSeq problem*/
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : notes. Issue #20721 */
      /*  Issue 25934 Added with(nolock) to the from and join statements NF 11/11/04 */
      /* Get the Unit Cost from SLIT per Issue 25448 NF 12/22/04 */
      /* Issue #135813 expanded Subcontract to varchar(30) */
      
          as
          create table #SLChangeOrder
              (SLCo				tinyint              NULL,
              SL				VARCHAR(30)          NULL,
              SLChangeOrder       smallint    Null,
              AppChangeOrder		varchar(10)	NULL,
              VendorGroup		tinyint		NULL,
              Vendor		int		NULL,
              JCCo		tinyint		NULL,
              Job			varchar(10)	NULL,
              OrigCost		Numeric(16,2)		NULL,
              PrevChangeOrders	Numeric(16,2)		NULL,
              MinSeq		smallint        NULL
          
              )
          
          CREATE UNIQUE CLUSTERED INDEX  btiSLChangeOrder
              ON  #SLChangeOrder(SLCo,SL,SLChangeOrder,AppChangeOrder)
          
          
          /* insert each unique ChangeOrder per SL Info */
          /* the MIN(SLCD.SLChangeOrder) is used to find the previous change order amounts */
          insert into #SLChangeOrder
          		(SLCo, SL, SLChangeOrder,AppChangeOrder,VendorGroup, Vendor, JCCo, Job, OrigCost, PrevChangeOrders, MinSeq)
          		Select SLHD.SLCo, SLHD.SL, SLCD.SLChangeOrder, SLCD.AppChangeOrder, MIN(SLHD.VendorGroup), MIN(SLHD.Vendor), MIN(SLHD.JCCo),
           	MIN(SLHD.Job),
           	OrigCost=(select sum(SLIT.OrigCost) from SLIT with(nolock) 
 			  where SLIT.SLCo=SLHD.SLCo and SLIT.SL=SLHD.SL and SLIT.ItemType <> 3), 
   		PrevChangeOrders=0,MIN(SLCD.SLChangeOrder)
           FROM SLHD with(nolock)
           Left Join SLCD with(nolock)on SLCD.SLCo=SLHD.SLCo and SLCD.SL=SLHD.SL
           where SLHD.SLCo=@SLCo and SLHD.SL>=@BeginSL and  SLHD.SL<=@EndSL
              
           group by
             SLHD.SLCo, SLHD.SL,SLCD.SLChangeOrder,SLCD.AppChangeOrder
             /*, SLHD.VendorGroup, SLHD.Vendor, SLHD.JCCo,   SLHD.Job */
      
          update #SLChangeOrder
      set MinSeq=(select Min(a.MinSeq) From #SLChangeOrder a with(nolock) where a.SLCo=#SLChangeOrder.SLCo and a.SL=#SLChangeOrder.SL and
        a.AppChangeOrder= #SLChangeOrder.AppChangeOrder)
          
          /* update the temp file with the previous change order amounts */
          update #SLChangeOrder
          set PrevChangeOrders=
          (select ISNULL(sum(SLCD.ChangeCurCost),0) from SLCD with(nolock)
            where  SLCD.SLCo=#SLChangeOrder.SLCo and SLCD.SL=#SLChangeOrder.SL
                  and SLCD.SLChangeOrder<MinSeq 
       --and 
       --isnull(SLCD.AppChangeOrder,0)<>isnull(#SLChangeOrder.AppChangeOrder,0)
          -- group by
          --   #SLChangeOrder.SLCo, #SLChangeOrder.SL, #SLChangeOrder.SLChangeOrder
          )
          
          
   
   
        /* select the results */
        select SLCo=a.SLCo, SL=a.SL, SLItem=SLCD.SLItem,a.SLChangeOrder,
        	ACO=a.AppChangeOrder, SLChgOrder=SLCD.SLChangeOrder,
        	ActualDate=SLCD.ActDate, SLCODesc=SLCD.Description,
        	SLCD.UM, SLCD.ChangeCurUnits, SLCD.ChangeCurUnitCost, SLCD.ChangeCurCost,
        	VendorGroup=a.VendorGroup, Vendor=a.Vendor, VendName=APVM.Name, VendAdd=APVM.Address,
        	VendCity=APVM.City, VendState=APVM.State, VendZip=APVM.Zip,JCCo=a.JCCo,
        	Job=a.Job,JobDesc=JCJM.Description, JobAdd=JCJM.ShipAddress, JobCity=JCJM.ShipCity, JobState=JCJM.ShipState,
        	JobZip=JCJM.ShipZip, OrigCost=a.OrigCost, PrevChangeOrders=a.PrevChangeOrders,
        	CoName=HQCO.Name,CoAddress=HQCO.Address, CoCity=HQCO.City, CoState=HQCO.State, CoZip=HQCO.Zip,
                   SLIT.Phase, JCJP.Item, SLIT_CurUnitCost = SLIT.CurUnitCost,
                   SLItemNote=SLIT.Notes, SLHeaderNote=SLHD.Notes, ChangeOrderNotes=SLCD.Notes
     from #SLChangeOrder a with(nolock)
        join SLCD with(nolock) on SLCD.SLCo=a.SLCo and SLCD.SL=a.SL and SLCD.SLChangeOrder=a.SLChangeOrder and SLCD.AppChangeOrder = a.AppChangeOrder
        join HQCO with(nolock) on HQCO.HQCo=a.SLCo
        left join APVM with(nolock) on APVM.VendorGroup=a.VendorGroup and APVM.Vendor=a.Vendor
        left join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
        left join SLHD with(nolock) on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL
        left join SLIT with(nolock) on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem
        left join JCJP with(nolock) on JCJP.JCCo=SLIT.JCCo and JCJP.Job=SLIT.Job and JCJP.Phase=SLIT.Phase and JCJP.PhaseGroup=SLIT.PhaseGroup
   
          /* select the results 
          select SLCo=a.SLCo, SL=a.SL, SLItem=SLCD.SLItem,a.SLChangeOrder,
          	ACO=a.AppChangeOrder, SLChgOrder=SLCD.SLChangeOrder,
          	ActualDate=SLCD.ActDate, SLCODesc=SLCD.Description,
          	SLCD.UM, SLCD.ChangeCurUnits, SLCD.ChangeCurUnitCost, SLCD.ChangeCurCost,
          	VendorGroup=a.VendorGroup, Vendor=a.Vendor, VendName=APVM.Name, VendAdd=APVM.Address,
          	VendCity=APVM.City, VendState=APVM.State, VendZip=APVM.Zip,JCCo=a.JCCo,
          	Job=a.Job,JobDesc=JCJM.Description, JobAdd=JCJM.ShipAddress, JobCity=JCJM.ShipCity, JobState=JCJM.ShipState,
          	JobZip=JCJM.ShipZip, OrigCost=a.OrigCost, PrevChangeOrders=a.PrevChangeOrders,a.MinSeq,
          	CoName=HQCO.Name,CoAddress=HQCO.Address, CoCity=HQCO.City, CoState=HQCO.State, CoZip=HQCO.Zip,
                   SLIT.Phase, JCJP.Item, SLHDNotes=SLHD.Notes
       from #SLChangeOrder a
          join SLCD on SLCD.SLCo=a.SLCo and SLCD.SL=a.SL and SLCD.SLChangeOrder=a.SLChangeOrder
          join HQCO on HQCO.HQCo=a.SLCo
          left join APVM on APVM.VendorGroup=a.VendorGroup and APVM.Vendor=a.Vendor
          left join JCJM on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
          left join SLHD on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL
          left join SLIT on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem
          left join JCJP on JCJP.JCCo=SLIT.JCCo and JCJP.Job=SLIT.Job and JCJP.Phase=SLIT.Phase and JCJP.PhaseGroup=SLIT.PhaseGroup  */

GO
GRANT EXECUTE ON  [dbo].[brptSLChangeOrderByACO] TO [public]
GO
