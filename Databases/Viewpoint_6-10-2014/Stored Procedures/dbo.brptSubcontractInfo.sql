SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[brptSubcontractInfo]
           (@SLCo bCompany, @BeginSubContract VARCHAR(30) ='', @EndSubContract VARCHAR(30)= 'zzzzzzzzzzzzzzzzzzzzzzzzz',
           @BegInvoicedDate bDate, @ThroughDate bDate,
           @IncludeInvoiceDetails bYN='Y',
           @IncludeCODetails bYN='Y', 
           @BeginJob bJob='', @EndJob bJob='zzzzzzzzzz', @BeginVendor bVendor=0, @EndVendor bVendor=999999, 
           @ExcludeBC bYN, @OpenClosedAll char(1)='A')
    with recompile
         /* created 12/15/97 TF last changed 7/28/99 changed Paid <=date or null*/
         /*  mod JRE 11/10/99 added @BeginJob, @EndJob bJob, @BeginVendor bVendor, @EndVendor bVendor*/
         /* 1/17/00 added  "Held Retainage" for 'SL Subcontracts By Job'  (SLSubReportJobSort.rpt) 
      and 'SL Subcontract Ledger Report' SLSubLedgerReport.rpt */
         /* 1/15/01 DARINH  Added BackCharge Units and Amount to temp table - used by SL Ledger and Subs by Job report*/
     
         /*NOTE --DARINH- @ThroughDate parameter is actually a Month End parameter, changed procedure to compare mth to @ThroughDate
      for AP Trans detail and SL Change Orders*/ 
         /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                            fixed : Concatination & using tables instead of views. Issue #20721 */
         /* Mod 4/18/03 E.T. added case statements and parameter for OpenClosedAll */
        /* Mod 11/03/04 JE Issue #26024 added with no locks, and improved where clause */
        /* Mod 06/25/2010 GF - issue #135813 expanded SL to varchar(30) */
        
           as
           create table #SubContractStatus
               (SLCo            	tinyint            	NULL,
               SL        		VARCHAR(30)           	NULL,
               SubDesc			VARCHAR(60)       	Null,
               SubStatus		tinyint		    	Null,
               Vendor			int		     	Null,
               SLItem            smallint           	NULL,
               Addon			tinyint			Null,
               AddonPct		numeric(6,4)		Null,
               AddonDesc		Char (30)		Null,
               ItemType       	tinyint              	NULL,
               ItemDesc		varchar (60) 	     	NULL,
               ItemUM		varchar (3)	     	NULL,
               JCCo			tinyint              	NULL,
               Job       		varchar(10)          	NULL,
               PhaseGrp		tinyint		     	NULL,
               Phase			varchar(20)	     	NULL,
               JCCType		tinyint		     	NULL,
               OrigItemCost   	decimal(12,2)        	NULL,
               ChangeOrderCost	decimal (12,2)	     	NULL,
               CurrItemCost  	decimal(12,2)        	NULL,
               OrigItemUnits 	decimal(12,3)        	NULL,
               ChangeOrderUnits	decimal (12,3)	     	NULL,
               CurrItemUnits  	decimal(12,3)        	NULL,
               OrigItemUC 		decimal(16,2)        	NULL,
               ChangeOrderUC		decimal (16,2)       	NULL,
               CurrItemUC 		decimal(16,2)        	NULL,
               ToDateBilledUnits	decimal (12,3)		NULL,
               CurrBilledUnits	decimal	(12,3)		Null,
               ToDateBilledAmt	decimal(12,2)        	NULL,
               CurrBilledAmt     	decimal(12,2)        	NULL,
               PaidAmt		decimal(12,2)	     	NULL,
               ToDateRetain        	decimal(12,2)        	NULL,
               CurrRetain		decimal (12,2)		Null,
      	  HeldRetain		decimal (12,2)		Null,
               ToDateDiscounts   	decimal(12,2)        	NULL,
               CurrDiscounts		decimal (12,2)		Null,
      	       APMth			smalldatetime		Null,
               APTrans		int			Null,
               APRef			varchar (15)		Null,
               APInvDate		smalldatetime		Null,
               APLine		smallint		Null,
               APSeq			tinyint			Null,
               APPayType		tinyint			Null,
               APUM			varchar (3)		Null,
               APUnits		decimal (12,3)		Null,
               APUnitCost		decimal (16,2)		Null,
               APLineType		tinyint			Null,
               APAmount		decimal (12,2)		Null,
               APDiscount		decimal (12,2)		Null,
               APPaidAmt		decimal (12,2)		Null,
               APBank		smallint		Null,
               APCheck		varchar (10)		Null,
               InternalChangeOrder 	smallint		Null,
               AppChangeOrder	varchar (10)		Null,
               CODate		smalldatetime		Null,
               COMonth		smalldatetime		Null,
               COTrans		int			Null,
               CODesc		varchar (60)		Null,
               COUM			varchar (3)		Null,
               COUnits		decimal (12,3)		Null,
               COUnitCost		decimal (16,2)		Null,
               COCost		decimal (16,2)		Null,
               ReportSeq		varchar (1)		Null
               )
          
        /* insert Change Order info for SubContract item */
           insert into #SubContractStatus
           (SLCo,SL,SLItem,ItemType,Addon,AddonPct,AddonDesc,ItemDesc,ItemUM,JCCo,Job,PhaseGrp,Phase,JCCType,
               OrigItemCost,ChangeOrderCost,OrigItemUnits,ChangeOrderUnits,OrigItemUC,ChangeOrderUC
            )
           Select SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,Max(SLIT.Addon),Max(SLIT.AddonPct),
           	Max(SLAD.Description),Max(SLIT.Description),SLIT.UM,
               SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,SLIT.OrigCost,
               sum(case when SLCD.Mth <=@ThroughDate then (SLCD.ChangeCurCost) else 0 end),
               SLIT.OrigUnits,
               sum(case when SLCD.Mth <=@ThroughDate then (SLCD.ChangeCurUnits) else 0 end),
               SLIT.OrigUnitCost,
               sum(case when SLCD.Mth <=@ThroughDate then (SLCD.ChangeCurUnitCost) else 0 end)
          
           FROM SLIT with(nolock) 
           Left Join SLCD with(nolock) on SLCD.SLCo=SLIT.SLCo and SLCD.SL=SLIT.SL and SLCD.SLItem=SLIT.SLItem
           Left Join SLAD with(nolock) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
           Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
          
           where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
   -- This is actually slower	AND SLHD.SLCo=@SLCo and SLHD.SL>= @BeginSubContract and SLHD.SL<= @EndSubContract
             and isnull(SLIT.Job,'') between @BeginJob and @EndJob
             and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
             and 1=(case when SLIT.ItemType=3 AND @ExcludeBC='Y' then SLIT.ItemType else 1 end)
          
    group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType, SLIT.UM,SLIT.JCCo,
           	SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType, SLIT.OrigCost, SLIT.OrigUnits,
           	SLIT.OrigUnitCost
          
           /* insert AP info for SubContract item */
           insert into #SubContractStatus
           (SLCo,SL,SLItem,ItemType,Addon,AddonPct,AddonDesc,ItemDesc,ItemUM,JCCo,Job,PhaseGrp,Phase,JCCType,
           ToDateBilledUnits,CurrBilledUnits,ToDateBilledAmt,CurrBilledAmt,PaidAmt,
           ToDateRetain,CurrRetain,HeldRetain,ToDateDiscounts,CurrDiscounts)
          
           Select SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,Max(SLIT.Addon),Max(SLIT.AddonPct),
           	Max(SLAD.Description),
           	Max(SLIT.Description),SLIT.UM,
           	SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,
           	(case when 
          --APTH.InvDate>=@BegInvoicedDate and 
          	APTH.Mth<=@ThroughDate then
           	APTL.Units else 0 end),
           	(case when APTH.Mth>=@BegInvoicedDate and APTH.Mth<=@ThroughDate then
              	APTL.Units else 0 end),
                  	sum(case when APTH.Mth <=@ThroughDate then (APTD.Amount) else 0 end),
           	sum (case when APTH.Mth>=@BegInvoicedDate and APTH.Mth<=@ThroughDate then
           	APTD.Amount else 0 end),
           	sum(case when APTD.Status>2 and APTH.Mth <=@ThroughDate and (APTD.PaidMth<=@ThroughDate or
                 APTD.PaidMth is null)
          	then (APTD.Amount) else 0 end),
           	sum(case when APCO.RetPayType=APTD.PayType
           	and (APTD.PaidMth Is Null or APTD.PaidMth>@ThroughDate) then (APTD.Amount) else 0 end),
          
           	sum(case when APCO.RetPayType=APTD.PayType
           	and (APTD.PaidMth Is Null or APTD.PaidMth>@ThroughDate) and
           	(APTH.InvDate>=@BegInvoicedDate and APTH.Mth<=@ThroughDate)
           	then (APTD.Amount) else 0 end),
      
      /*Retainage Held*/
      	sum(case when APCO.RetPayType=APTD.PayType
           	and ((APTD.PaidMth Is Null or APTD.PaidMth>@ThroughDate) and APTD.Status=2) then (APTD.Amount) else 0 end),
      /*	sum(case when APCO.RetPayType=APTD.PayType
           	and ((APTD.PaidDate Is Null or APTD.PaidDate>@ThroughDate) and APTD.Status=2) then (APTD.Amount) else 0 end),
      */
          
           	sum(case when APTH.Mth <=@ThroughDate then (APTD.DiscTaken) else 0 end),
          
           	sum(case when APTH.Mth <=@ThroughDate and
           	(APTH.InvDate>=@BegInvoicedDate and APTH.Mth<=@ThroughDate)
           	then (APTD.DiscTaken) else 0 end)
      	
             
               FROM SLIT with(nolock)  
           Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
           Left Join APTL with(nolock) on APTL.APCo=SLIT.SLCo and APTL.SL=SLIT.SL and APTL.SLItem=SLIT.SLItem
           Left Join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans
           	and APTD.APLine=APTL.APLine
           Left Join APTH with(nolock) on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans
   		and APTH.Vendor between @BeginVendor and @EndVendor
           Left Join SLAD with(nolock) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
           Left Join APCO with(nolock) on APCO.APCo=APTL.APCo
          
           where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
             and SLHD.SLCo=@SLCo and SLHD.SL>= @BeginSubContract and SLHD.SL<= @EndSubContract
             and isnull(SLIT.Job,'') between @BeginJob and @EndJob
             and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
             and 1=(case when SLIT.ItemType=3 AND @ExcludeBC='Y' then SLIT.ItemType else 1 end)
           group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,SLIT.UM,
           	SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,APTL.APTrans,
      --APTD.APLine,APTD.APSeq,
      		APTL.Units, APTH.Mth
      --APCO.RetPayType,APTD.PayType,APTD.PaidDate, APTD.Status,APTD.Amount
          
           /* insert invoice details info */
           insert into #SubContractStatus
           (SLCo,SL, SLItem,ItemType,JCCo,Job,APMth,APTrans,APRef,APInvDate,APLine,APSeq,APPayType,
           	APUM,APUnits,APUnitCost,APLineType,APAmount,APDiscount, APPaidAmt,APBank,APCheck,
           	ReportSeq)
          
           Select APTL.APCo,APTL.SL, APTL.SLItem,Max(SLIT.ItemType),Max(SLIT.JCCo),Max(SLIT.Job),
           	APTH.Mth,APTL.APTrans,Max(APTH.APRef),APTH.InvDate,APTL.APLine,APTD.APSeq,
           	APTD.PayType,APTL.UM,
           	(case when APTH.Mth <=@ThroughDate then (APTL.Units) else 0 end),
           	(case when APTH.Mth <=@ThroughDate then (APTL.UnitCost) else 0 end),
           	APTL.LineType,sum(case when APTH.Mth <=@ThroughDate then (APTD.Amount) else 0 end),
           	sum(case when APTH.Mth <=@ThroughDate then (APTD.DiscTaken) else 0 end),
           	sum(case when APTD.Status>2 and APTH.Mth <=@ThroughDate and (APTD.PaidMth<=@ThroughDate
          	or APTD.PaidMth is null)
         	then (APTD.Amount) else 0 end),
          	(case when APTD.PaidMth<=@ThroughDate then APTD.CMAcct else null end) ,	
          	(case when APTD.PaidMth<=@ThroughDate then APTD.CMRef else null end) ,'1'
          
           FROM APTL with(nolock) 
           Join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and
           	APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine
           Join APTH with(nolock) on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans and
           	APTH.Mth <=@ThroughDate
           Join SLIT with(nolock) on SLIT.SLCo=APTL.APCo and SLIT.SL=APTL.SL and SLIT.SLItem=APTL.SLItem
           Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL  
           where APTL.APCo=@SLCo and isnull(APTL.SL,'')>= @BeginSubContract and isnull(APTL.SL,'')<= @EndSubContract
              and SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
              and SLHD.SLCo=@SLCo and SLHD.SL>= @BeginSubContract and SLHD.SL<= @EndSubContract
              and isnull(SLIT.Job,'') between @BeginJob and @EndJob
              and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor  
   		 and APTH.Vendor between @BeginVendor and @EndVendor  
              and 1=(case when SLIT.ItemType=3 AND @ExcludeBC='Y' then SLIT.ItemType else 1 end)
           and @IncludeInvoiceDetails='Y'
          
           GROUP BY
           	APTL.APCo,APTL.Mth,APTL.APTrans,APTL.APLine,APTL.SL, APTL.SLItem,
           	APTH.Mth,APTL.APTrans, APTH.InvDate,APTL.APLine,APTD.PayType,
           	APTL.UM,APTL.Units,
           	APTL.UnitCost,APTL.LineType,APTD.APSeq,APTD.CMAcct,APTD.CMRef,APTD.PaidMth, APTD.PaidDate
          
           /* insert Change Order details info */
           insert into #SubContractStatus
           (SLCo,SL,SLItem,ItemType,JCCo,Job,InternalChangeOrder,AppChangeOrder,CODate,
          
           	COMonth,COTrans,CODesc,COUM,COUnits,COUnitCost,COCost,ReportSeq)
          
         
           select SLCD.SLCo,SLCD.SL,SLCD.SLItem,SLIT.ItemType,SLIT.JCCo,SLIT.Job,SLCD.SLChangeOrder,
           	SLCD.AppChangeOrder,SLCD.ActDate,SLCD.Mth,SLTrans,SLCD.Description,SLCD.UM,
           	(case when SLCD.Mth <=@ThroughDate then (SLCD.ChangeCurUnits) else 0 end),
           	(case when SLCD.Mth <=@ThroughDate then (SLIT.OrigUnitCost)+(SLCD.ChangeCurUnitCost) else 0 end),
           	(case when SLCD.Mth <=@ThroughDate then (SLCD.ChangeCurCost) else 0 end),'2'
          
          
           FROM SLCD with(nolock) 
           Join SLIT with(nolock) on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem
           Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL  
              and isnull(SLIT.Job,'') between @BeginJob and @EndJob
              and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
          
           where SLCD.SLCo=@SLCo and SLCD.SL>= @BeginSubContract and SLCD.SL<= @EndSubContract
   	   and SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
   	   and SLHD.SLCo=@SLCo and SLHD.SL>= @BeginSubContract and SLHD.SL<= @EndSubContract
              and isnull(SLIT.Job,'') between @BeginJob and @EndJob
              and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
              and 1=(case when SLIT.ItemType=3 AND @ExcludeBC='Y' then SLIT.ItemType else 1 end)
           and @IncludeCODetails='Y'
          
          
           /*GROUP BY SLCD.SLCo,SLCD.SL,SLCD.SLItem,SLIT.JCCo,SLIT.Job,SLCD.SLChangeOrder,SLCD.ActDate,
           SLCD.Mth,SLCD.Description,SLCD.UM*/
          
   --create index biSLSubContractStatus on #SubContractStatus (SLCo ,SL, JCCo ,Job)
   
           /* select the results */
           select  a.SLCo,
           	a.SL,
           	SubDesc=SLHD.Description,
           	SubStatus=SLHD.Status,
           	Vendor=APVM.Vendor,
          
           	VendorName=APVM.Name,
           	VendorAddress=APVM.Address,
           	VendorCitySTZip=IsNull(APVM.City,'')+', '+IsNull(APVM.State,'')+' '+IsNull(APVM.Zip,''),
              	a.SLItem,
               	a.ItemType,
               	a.Addon,a.AddonPct,a.AddonDesc,
               	a.ItemDesc,
               	a.ItemUM,
               	a.JCCo,
               	a.Job,
               	JobDesc=JCJM.Description,
               	JobAddress=JCJM.MailAddress,
               	JobCitySTZip=IsNull(JCJM.MailCity,'')+', '+IsNull(JCJM.MailState,'')+' '+IsNull(JCJM.MailZip,''),
          
               	a.PhaseGrp,
               	a.Phase,
               	a.JCCType,
               	a.OrigItemCost,
               	a.ChangeOrderCost,
               	CurrItemCost= a.OrigItemCost+isnull(a.ChangeOrderCost,0),
     		/*(case when a.ItemUM <>'LS' then a.OrigItemCost+(isnull(a.ChangeOrderUnits,0)*(a.OrigItemUC+isnull(a.ChangeOrderUC,0))) else a.OrigItemCost+isnull(a.ChangeOrderCost,0) end),
               	+ ((a.OrigItemUnits+a.ChangeOrderUnits)*(a.OrigItemUC+a.ChangeOrderUC)),*/
               	a.OrigItemUnits,
               	a.ChangeOrderUnits,
               	CurrItemUnits=(a.OrigItemUnits+a.ChangeOrderUnits),
               	a.OrigItemUC,
               	a.ChangeOrderUC,
               	CurrItemUC=(a.OrigItemUC+a.ChangeOrderUC),
     	BackChargeAmt = (case when a.ItemType=3 then a.OrigItemCost else 0 end),
     	BackChargeUnits=(case when a.ItemType=3 then a.OrigItemUnits else 0 end),
               	a.ToDateBilledUnits,
          
               	a.CurrBilledUnits,
          
               	a.ToDateBilledAmt,
          
               	a.CurrBilledAmt,
               	a.PaidAmt,
              	a.ToDateRetain,
              	a.CurrRetain,
      		a.HeldRetain,
               	a.ToDateDiscounts,
               	a.CurrDiscounts,
      		a.APTrans,a.APRef,a.APInvDate,a.APLine,a.APSeq,a.APPayType,a.APUM,a.APUnits,a.APUnitCost,
               	a.APLineType,a.APAmount,a.APDiscount, a.APPaidAmt,a.APBank,a.APCheck,
               	a.InternalChangeOrder,a.AppChangeOrder,a.CODate,
               	a.COMonth,a.COTrans,a.CODesc,a.COUM,a.COUnits,a.COUnitCost,a.COCost,a.ReportSeq,
          
             BegSub=@BeginSubContract, EndSub=@EndSubContract,
            BegInvoiceDate=@BegInvoicedDate, ThroughDate=@ThroughDate,
               CoName=HQCO.Name, JCCM.ContractStatus
          
           from #SubContractStatus a with(nolock) 
          
           Join HQCO with(nolock) on HQCO.HQCo=a.SLCo
           Join SLHD with(nolock) on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL
           Left Join JCJM with(nolock) on JCJM.JCCo=a.JCCo and JCJM.Job=a.Job
           --left join JCJM b on  b.JCCo=a.JCCo and b.Job=a.Job
           Left join JCCM with(nolock) on JCCM.JCCo=JCJM.JCCo and JCCM.Contract=JCJM.Contract and JCCM.ContractStatus<>0
           Left Join APVM with(nolock) on APVM.VendorGroup=SLHD.VendorGroup and APVM.Vendor=SLHD.Vendor
          
     
          
           where a.SLCo=@SLCo and a.SL>=@BeginSubContract and a.SL<=@EndSubContract  and
   	 SLHD.SLCo=@SLCo and SLHD.SL>=@BeginSubContract and SLHD.SL<=@EndSubContract  and
            JCCM.ContractStatus=case when @OpenClosedAll<>'S' then 
                			(case when @OpenClosedAll='O' then 1 
                                          when @OpenClosedAll='C' then 3
                                          when @OpenClosedAll='A' then JCCM.ContractStatus 
                                     end )
                			when @OpenClosedAll='S' then
     				case when JCCM.ContractStatus=1 then 1
     				     when JCCM.ContractStatus=2 then 2
     				end
           			   end

GO
GRANT EXECUTE ON  [dbo].[brptSubcontractInfo] TO [public]
GO
