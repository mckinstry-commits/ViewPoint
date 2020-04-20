SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                        proc [dbo].[brptSubContrDrillDown]
    
      (@SLCo bCompany, @BeginSubContract VARCHAR(30) ='', @EndSubContract VARCHAR(30)= 'zzzzzzzzzzzzzzzzzzzzzzzz',
       @BegJob bJob='', @EndJob bJob='zzzzzzzzzz', @BegVendor bVendor=0, @EndVendor bVendor=9999999)
      /*@BegInvoicedDate bDate, @ThroughDate bDate,
      @IncludeInvoiceDetails bYN='Y',
      @IncludeCODetails bYN='Y'),@IncludeBCDetails bYN='Y')*/
      /* created 12/24/97 Tracy 
            last modified 04/17/02 E.T. 
    	Modified 12/26/02 CR  added Job to Type O insert statement                              
      */ 
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                           fixed : Concatination, notes & using tables instead of views. Issue #20721 */
      /* Issue 25594 10/08/04 Correct joins for Job Security NF */
      /* issue #135813 expanded SL to varchar(30) GF */
   
      with Recompile 
      as
      create table #SubContrDrillDown
      
          (SLCo            	tinyint              NULL,
           SL       	VARCHAR(30)             NULL,
          SubDesc		VARCHAR(60)         Null,
          SubJCCo		tinyint			Null,
          SubJob		varchar(10)		Null,
          SubStatus		tinyint		     Null,
          SLVendor		int		     Null,
          VendorName		varchar (60)	     Null,
          VendorAddress	varchar (60)		Null,
          VendorCitySTZip	varchar (60)		Null,
          SLItem            	smallint             NULL,
          ItemType       	tinyint              NULL,
          ItemAddon		tinyint			Null,
          ItemAddonPct		decimal (6,4)		Null,
          ItemAddonDesc		varchar (30)		Null,
          ItemDesc		varchar (60) 	     NULL,
          ItemUM		varchar (3)	     NULL,
          ItemJCCo		tinyint              NULL,
          ItemJob       	varchar(10)          NULL,
          JobDesc		varchar (30)	     Null,
          JobAddress		varchar (60)		Null,
          JobCitySTZip	varchar (60)		Null,
          ItemPhaseGrp	tinyint		     NULL,
          ItemPhase		varchar(20)	     NULL,
          ItemJCCType		tinyint		     NULL,
          ItemGLCo		tinyint			Null,
          ItemGLAcct		char (20)		Null,
          ItemWCRetPct	numeric(6,4)		Null,
          ItemSMRetPct	numeric(6,4)		Null,
          ItemOrigUnits 	decimal(12,3)        NULL,
      
          ItemOrigUC 		decimal(16,2)        NULL,
          ItemOrigCost   	decimal(12,2)        NULL,
          ItemCurUnits  	decimal(12,3)        NULL,
          ItemCurUC 		decimal(16,2)        NULL,
          ItemCurCost  	decimal(12,2)        NULL,
          ItemInvUnits	decimal(12,3)		Null,
          ItemInvCost		decimal(12,2)		Null,
      
          COMonth		smalldatetime		Null,
          COSLTrans		int			Null,
          InternalChangeOrder smallint		Null,
          AppChangeOrder	varchar (10)		Null,
          CODate		smalldatetime		Null,
          CODesc		varchar (60)		Null,
          COUM		varchar (3)		Null,
          COUnits		decimal (12,3)		Null,
          COUnitCost		decimal (16,2)		Null,
          COCost		decimal (16,2)		Null,
      
          CompCode		varchar(10)		Null,
          CompSeq		smallint		Null,
      
          CompVendorGroup	tinyint			Null,
          CompVendor		int			Null,
          CompDesc		varchar(30)		Null,
          CompVerify		char(1)			Null,
          CompExpDate		smalldatetime		Null,
          CompComplied	char(1)			Null,
      
          /*BilledUnits	decimal (12,3)		NULL,
          BilledAmt    	 decimal(12,2)        NULL,
          PaidAmt		decimal(12,2)	     NULL,
          Retain        	decimal(12,2)        NULL,
          Discounts   	decimal(12,2)        NULL,*/
      
          APMth		smalldatetime		Null,
          APTrans		int			Null,
          APRef		varchar (15)		Null,
          APInvDate		smalldatetime		Null,
          APTransDesc		varchar(30)		Null,
          APLine		smallint		Null,
          APSLItem		smallint		Null,
          APLineDesc		varchar(30)		Null,
          APGLCo		tinyint			Null,
          APGLAcct		varchar(20)		Null,
          APSeq		tinyint			Null,
          APPayType		tinyint			Null,
          APPayTypeDesc	varchar (30)		Null,
          APUM		varchar (3)		Null,
          APUnits		decimal (12,3)		Null,
          APUnitCost		decimal (16,2)		Null,
          APLineType		tinyint			Null,
          APAmount		decimal (12,2)		Null,
          APDiscount		decimal (12,2)		Null,
          APPaidAmt		decimal (12,2)		Null,
          CMCo            	tinyint              NULL ,
          APBank		smallint		Null,
          APCheck		varchar (10)		Null,
          CheckSeq    tinyint         Null,
          PaidMth     smalldatetime       Null,
          PaidDate		smalldatetime		Null,
          ReportSeq		varchar (1)		Null
          )
      
      /* insert SL Header and Item info*/
      insert into #SubContrDrillDown
      (SLCo,SL,SubDesc,SubJCCo,SubJob,SubStatus,SLVendor,SLItem,ItemType,ItemAddon,
          ItemAddonPct,ItemDesc,ItemUM,ItemJCCo,ItemJob,ItemPhaseGrp,ItemPhase,ItemJCCType,ItemGLCo,
          ItemGLAcct,ItemWCRetPct,ItemSMRetPct,ItemOrigUnits,ItemOrigUC,ItemOrigCost,
          ItemCurUnits,ItemCurUC,ItemCurCost,ItemInvUnits,ItemInvCost
      )
      Select SLHD.SLCo,SLHD.SL,SLHD.Description,SLHD.JCCo,SLHD.Job,SLHD.Status,SLHD.Vendor,
      	SLIT.SLItem,SLIT.ItemType,SLIT.Addon,SLIT.AddonPct,SLIT.Description,SLIT.UM,
      	SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,SLIT.GLCo,
          SLIT.GLAcct,SLIT.WCRetPct,SLIT.SMRetPct,SLIT.OrigUnits,SLIT.OrigUnitCost,SLIT.OrigCost,
          SLIT.CurUnits,SLIT.CurUnitCost,SLIT.CurCost,SLIT.InvUnits,SLIT.InvCost
      
      FROM SLIT SLIT
      Left Join SLHD WITH (NOLOCK) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
      
      where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract 
            and isnull(SLIT.Job,'') between @BegJob and @EndJob
            and isnull(SLHD.Vendor,0) between @BegVendor and @EndVendor
      and SLHD.Status<>3
      
      /* insert Compliance info for SubContract */
      insert into #SubContrDrillDown
      (SLCo,SL,CompCode,
          CompSeq,CompVendorGroup,CompVendor,CompDesc,CompVerify,CompExpDate,CompComplied,ReportSeq
      )
      select SLCT.SLCo,SLCT.SL,SLCT.CompCode,SLCT.Seq,SLCT.VendorGroup,SLCT.Vendor,SLCT.Description,
      SLCT.Verify,SLCT.ExpDate,SLCT.Complied,'C'
      
      FROM SLCT SLCT
      left Join SLHD WITH (NOLOCK) on SLHD.SLCo=SLCT.SLCo and SLHD.SL=SLCT.SL
      
      where SLCT.SLCo=@SLCo and SLCT.SL>= @BeginSubContract and SLCT.SL<= @EndSubContract 
            and isnull(SLHD.Job,'') between @BegJob and @EndJob
            and isnull(SLCT.Vendor,0) between @BegVendor and @EndVendor
      and SLHD.Status<>3
      
      /* insert Change Order details info */
      insert into #SubContrDrillDown
      (SLCo,SL,ItemJCCo, ItemJob,SLItem,ItemType,ItemDesc,COMonth,
          COSLTrans,InternalChangeOrder,AppChangeOrder,CODate,CODesc,COUM,COUnits,COUnitCost,
          COCost,ReportSeq)
      
      select SLCD.SLCo,SLCD.SL,SLIT.JCCo,SLIT.Job,SLCD.SLItem,SLIT.ItemType,SLIT.Description,SLCD.Mth,SLCD.SLTrans,SLCD.SLChangeOrder,
      	SLCD.AppChangeOrder,SLCD.ActDate,SLCD.Description,SLCD.UM,
      	SLCD.ChangeCurUnits,SLCD.ChangeCurUnitCost,SLCD.ChangeCurCost,'O'
      	/* Added Job 12/26/02 CR */
      FROM SLCD
      Join SLIT WITH (NOLOCK) on SLIT.SLCo=SLCD.SLCo and SLIT.SL=SLCD.SL and SLIT.SLItem=SLCD.SLItem
      Left Join SLHD WITH (NOLOCK) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
      
      where SLCD.SLCo=@SLCo and SLCD.SL>= @BeginSubContract and SLCD.SL<= @EndSubContract /*and SLHD.Status<>3*/
            and isnull(SLIT.Job,'') between @BegJob and @EndJob
            and isnull(SLHD.Vendor,0) between @BegVendor and @EndVendor
    
      /* insert AP invoice detail info */
      insert into #SubContrDrillDown
      
      (SLCo,SL, SLItem,ItemType,ItemDesc,ItemJCCo,ItemJob,/*ItemPhase,ItemJCCType,ItemGLAcct,*/
          APMth,APTrans,APRef,APInvDate,APTransDesc,APLine,APSLItem,APLineDesc,APGLCo,APGLAcct,
          APSeq,APPayType,APUM,APUnits,APUnitCost,APLineType,APAmount,APDiscount,
          APPaidAmt,CMCo,APBank,APCheck,CheckSeq,PaidMth,PaidDate,ReportSeq
          )
      Select APTL.APCo,APTL.SL, APTL.SLItem,Max(SLIT.ItemType),Max(SLIT.Description),Max(SLIT.JCCo),Max(SLIT.Job),
            /*Max(SLIT.Phase),Max(SLIT.JCCType),Max(SLIT.GLAcct),*/
      	APTL.Mth,APTL.APTrans,Max(APTH.APRef),Max(APTH.InvDate),Max( APTH.Description),
      	APTL.APLine,APTL.SLItem, max(APTL.Description),Max(APTL.GLCo),Max(APTL.GLAcct),APTD.APSeq,
      	APTD.PayType,Max(APTL.UM),
      	Max(APTL.Units),Max(APTL.UnitCost),
      	APTL.LineType,APTD.Amount,
      	APTD.DiscTaken,
      	sum(case when APTD.Status>2 then (APTD.Amount) else 0 end),
      	APTD.CMCo,APTD.CMAcct,APTD.CMRef,APTD.CMRefSeq,APTD.PaidMth,APTD.PaidDate,'A'
      
      FROM APTL
      Join APTD WITH (NOLOCK) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and
      	APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine
      Join APTH WITH (NOLOCK) on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans 
      Join SLIT WITH (NOLOCK) on SLIT.SLCo=APTL.APCo and SLIT.SL=APTL.SL and SLIT.SLItem=APTL.SLItem
      
      where APTL.APCo=@SLCo and APTL.SL>= @BeginSubContract and APTL.SL<= @EndSubContract
            and isnull(APTL.Job,'') between @BegJob and @EndJob
            and isnull(APTH.Vendor,0) between @BegVendor and @EndVendor
      
      GROUP BY
      	APTL.APCo,APTL.SL, APTL.SLItem,SLIT.Description,APTL.Mth,APTL.APTrans,
      	APTL.APLine,APTD.PayType,APTL.LineType,APTD.APSeq,APTD.CMAcct,APTD.CMRef,APTD.Amount,
      	APTD.DiscTaken,APTD.CMCo,APTD.CMRefSeq,APTD.PaidMth,APTD.PaidDate
      
      /*GROUP BY SLCD.SLCo,SLCD.SL,SLCD.SLItem,SLIT.JCCo,SLIT.Job,SLCD.SLChangeOrder,SLCD.ActDate,
      SLCD.Mth,SLCD.Description,SLCD.UM*/
      
      /* select the results */
      select  a.SLCo,
      	a.ReportSeq,
      	a.SL,
    
      	SubDesc=SLHD.Description,
      	a.SubJCCo,a.SubJob,
      	SubStatus=SLHD.Status,
      	SLVendor=SLHD.Vendor,
      
      	VendorName=APVM.Name,
      	VendorAddress=APVM.Address,
      	VendorCitySTZip=IsNull(APVM.City,'')+', '+IsNull(APVM.State,'')+' '+IsNull(APVM.Zip,''),
            a.SLItem,
          	a.ItemType,
          	ItemAddon=a.ItemAddon,
          	ItemAddonPct=a.ItemAddon,
          	ItemAddonDesc=SLAD.Description,
             	a.ItemDesc,
          	a.ItemUM,
          	a.ItemJCCo,
          	a.ItemJob,
          	JobDesc=JCJM.Description,
          	JobAddress=JCJM.MailAddress,
          	JobCitySTZip=IsNull(JCJM.MailCity,'')+', '+IsNull(JCJM.MailState,'')+' '+IsNull(JCJM.MailZip,''),
          	a.ItemPhaseGrp,
          	a.ItemPhase,
          	a.ItemJCCType,ItemGLCo,ItemGLAcct,ItemWCRetPct,ItemSMRetPct,
          	a.ItemOrigUnits,a.ItemOrigUC,a.ItemOrigCost,a.ItemCurUnits,a.ItemCurUC,
          	a.ItemCurCost,a.ItemInvUnits,a.ItemInvCost,
            a.COMonth,a.COSLTrans,a.InternalChangeOrder,a.AppChangeOrder,a.CODate,a.CODesc,
          	a.COUM,a.COUnits,a.COUnitCost,a.COCost,
            a.CompCode,a.CompSeq,a.CompVendorGroup,a.CompVendor,a.CompDesc,a.CompVerify,
          	a.CompExpDate,a.CompComplied,
          	a.APMth,a.APTrans,a.APRef,a.APInvDate,a.APTransDesc,a.APLine,a.APSLItem,a.APLineDesc,
          	a.APGLCo,a.APGLAcct,a.APSeq,a.APPayType,
          	APPayTypeDesc=APPT.Description,
          	a.APUM,a.APUnits,a.APUnitCost,
          	a.APLineType,a.APAmount,a.APDiscount, a.APPaidAmt,a.CMCo,a.APBank,a.APCheck,a.CheckSeq,
              a.PaidMth, a.PaidDate, CMDT.ClearDate,
      
        BegSub=@BeginSubContract, EndSub=@EndSubContract,
           CoName=HQCO.Name,
           HeaderNotes=SLHD.Notes, ItemNotes=SLIT.Notes, CONotes=SLCD.Notes
      
      from #SubContrDrillDown a
      
      Join HQCO WITH (NOLOCK) on HQCO.HQCo=a.SLCo
      Join SLHD WITH (NOLOCK) on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL
      Left Join SLIT WITH (NOLOCK) on SLIT.SLCo=a.SLCo and SLIT.SL=SLHD.SL and SLIT.SLItem=a.SLItem
      Left Join SLCD WITH (NOLOCK) on SLCD.SLCo=a.SLCo and SLCD.Mth=a.COMonth and SLCD.SLTrans=a.COSLTrans /*SLCD.SL=a.SL and SLCD.SLItem=SLIT.SLItem*/
      Left Join JCJM WITH (NOLOCK) on JCJM.JCCo=a.SubJCCo and JCJM.Job=a.SubJob  --SLHD Jobs
      Left join JCJM b WITH (NOLOCK) on b.JCCo=a.ItemJCCo and b.Job=a.ItemJob    --SLIT Jobs
      Left Join APVM WITH (NOLOCK) on APVM.VendorGroup=SLHD.VendorGroup and APVM.Vendor=SLHD.Vendor
      Left Join SLAD WITH (NOLOCK) on SLAD.SLCo=a.SLCo and SLAD.Addon=a.ItemAddon
      Left Join APPT WITH (NOLOCK) on APPT.APCo=a.SLCo and APPT.PayType=a.APPayType
      Left Join CMDT WITH (NOLOCK) on CMDT.CMCo=a.CMCo and CMDT.Mth=a.PaidMth and CMDT.CMAcct=a.APBank
      and CMDT.CMRef=a.APCheck and CMDT.CMRefSeq=a.CheckSeq
      
      where HQCO.HQCo=@SLCo and SLHD.SL>=@BeginSubContract and SLHD.SL<=@EndSubContract
        and (a.SubJob = JCJM.Job or  a.SubJob is null)
        and (a.ItemJob = b.Job or a.ItemJob is null)
        
       
      
      Order By a.SLCo,a.ReportSeq,a.SL,a.SLItem

GO
GRANT EXECUTE ON  [dbo].[brptSubContrDrillDown] TO [public]
GO
