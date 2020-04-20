SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brpt(bsp)cmstmtrpt    Script Date: 8/28/99 9:33:45 AM ******/
    CREATE                       proc [dbo].[brptCMstmtrpt]
      @Company tinyint=null,
      @CMAcct smallint=null, /* *****Added****** */
      /*@BeginningCMAcct smallint=null,*/
      /*@EndingCMAcct smallint=null,*/
      @StmtDate smalldatetime=null,
      @OSThruDayMth char(1)=null,	--Issue 20622 NF 02/11/04
      @OSThruDate smalldatetime=null,  --Issue 20622 NF 02/11/04
      @OSThruMth smalldatetime = null,  --Issue 20622 NF 02/11/04
      @ClearDetailFlag char(1)=null,
      @OutDetailFlag char(1)=null,
      @ThruMonth smalldatetime=null--5/2/02 AA
      as
      set nocount on
   
      if @OSThruDayMth = 'D' 
   	select @OSThruMth = '12/01/2050'
      if @OSThruDayMth = 'M' 
   	select @OSThruDate = '12/31/2050'   --Issue 20622 NF 02/11/04
   
      /* create temp table of CM Detail from the CM Detail Table*/
      /* 5/16made joins ansii standard, removed the begin and end E.T. */
      create table #CMDetail
      
      (Co tinyint null,
      Mth	smalldatetime null,
      CMTrans	integer	null, 
      CMAcct smallint null,
      StmtDate smalldatetime null,
      StmtType tinyint null, /* 0= on statement, 1= outstanding */
      CMTransType tinyint null,/* 0=,Adjustments,1=checks,2=Deposit,3=Transfers,4=EFT*/
      Source char(10) null,
      ActDate smalldatetime null,
      Description varchar(30) null,
      Amount decimal(16,2) null,
      ClearedAmt decimal(16,2) null,
      CMRef varchar(10) null,
      CMRefSeq tinyint null,
      
      Payee varchar(20) null,
      CMGLAcct char(20) null,
      GLAcct char(20) null,
      Void char(1) null,
      BegBal float null,
      WorkBal decimal(16,2) null,
      StmtBal decimal(16,2) null,
      Adjustments decimal(16,2) null,
      
      Checks decimal(16,2) null,
      Deposits decimal(16,2) null,
      Transfers decimal(16,2) null,
      EFTs decimal (16,2) null,
      OutAdjust decimal(16,2) null,
      OutChecks decimal(16,2) null,
      OutDeposits decimal(16,2) null,
      OutTransfers decimal(16,2) null,
      OutEFTs decimal(16,2) null,
      Status tinyint null,
      ClearDate smalldatetime null,
      OutGLAdjust decimal(16,2) null,-- 5/2/2002 AA.
      OutGLChecks decimal(16,2) null, --5/2/02
      OutGLDeposits decimal(16,2) null,--5/2/02
      OutGLTransfers decimal(16,2) null,--5/2/02
      OutGLEFTs decimal(16,2) null,--5/2/02
     )
      
      /*insert CM Detail */
      insert into #CMDetail
      select a.CMCo,a.Mth,a.CMTrans,a.CMAcct,a.StmtDate,
      case when (a.StmtDate > @StmtDate or a.StmtDate is null)then 1 else 0 end, /* Statement type */
      case when a.CMTransType<>4 then a.CMTransType else 1 end, /*a.CMTransType,*/
      a.Source,a.ActDate,a.Description, a.Amount, a.ClearedAmt, a.CMRef,
      a.CMRefSeq,a.Payee,a.CMGLAcct,a.GLAcct,a.Void,0,0,0,
      
      case when a.CMTransType=0 AND a.StmtDate=@StmtDate AND a.Void<>'Y' then a.ClearedAmt else 0 end,
      case when a.CMTransType=1 AND a.StmtDate=@StmtDate AND a.Void<>'Y' then a.ClearedAmt else 0 end,
      case when a.CMTransType=2 AND a.StmtDate=@StmtDate AND a.Void<>'Y' then a.ClearedAmt else 0 end,
      case when a.CMTransType=3 AND a.StmtDate=@StmtDate AND a.Void<>'Y' then a.ClearedAmt else 0 end,
      case when a.CMTransType=4 AND a.StmtDate=@StmtDate AND a.Void<>'Y' then a.ClearedAmt else 0 end,
      
      case when a.CMTransType=0 AND (a.StmtDate>@StmtDate or a.StmtDate is null)AND a.ActDate<=@OSThruDate 
   	AND a.Mth<=@OSThruMth AND a.Void<>'Y' then a.Amount else 0 end,  --Issue 20622 NF 02/11/04
      case when a.CMTransType=1 AND (a.StmtDate>@StmtDate or a.StmtDate is null)AND a.ActDate<=@OSThruDate 
   	AND a.Mth<=@OSThruMth AND a.Void<>'Y' then a.Amount else 0 end,  --Issue 20622 NF 02/11/04
      case when a.CMTransType=2 AND (a.StmtDate>@StmtDate or a.StmtDate is null)AND a.ActDate<=@OSThruDate 
   	AND a.Mth<=@OSThruMth AND a.Void<>'Y' then a.Amount else 0 end,  --Issue 20622 NF 02/11/04
      case when a.CMTransType=3 AND (a.StmtDate>@StmtDate or a.StmtDate is null)AND a.ActDate<=@OSThruDate 
   	AND a.Mth<=@OSThruMth AND a.Void<>'Y' then a.Amount else 0 end,  --Issue 20622 NF 02/11/04
      case when a.CMTransType=4 AND (a.StmtDate>@StmtDate or a.StmtDate is null)AND a.ActDate<=@OSThruDate 
   	AND a.Mth<=@OSThruMth AND a.Void<>'Y' then a.Amount else 0 end,0,  --Issue 20622 NF 02/11/04
      a.ClearDate,
      
     --Addition made by Aghaa 5/2/2002
      case when a.CMTransType=0 AND (a.StmtDate>@StmtDate or a.StmtDate is null)
      AND a.Mth<=@ThruMonth AND a.Void<>'Y' then a.Amount else 0 end,
      case when a.CMTransType=1 AND (a.StmtDate>@StmtDate or a.StmtDate is null)
      AND a.Mth<=@ThruMonth AND a.Void<>'Y' then a.Amount else 0 end,
      case when a.CMTransType=2 AND (a.StmtDate>@StmtDate or a.StmtDate is null)
      AND a.Mth<=@ThruMonth AND a.Void<>'Y' then a.Amount else 0 end,
      case when a.CMTransType=3 AND (a.StmtDate>@StmtDate or a.StmtDate is null)
      AND a.Mth<=@ThruMonth AND a.Void<>'Y' then a.Amount else 0 end,
      case when a.CMTransType=4 AND (a.StmtDate>@StmtDate or a.StmtDate is null)
      AND a.Mth<=@ThruMonth AND a.Void<>'Y' then a.Amount else 0 end
     
      
      from CMDT a
      where a.CMCo=@Company and /*a.CMAcct>=@BeginningCMAcctand a.CMAcct<=@EndingCMAcct*/
      	a.CMAcct=@CMAcct and (a.StmtDate>=@StmtDate or a.StmtDate is null)
      
      /*insert CM Statement Balance Information from CMST*/
      
      insert into #CMDetail
      select b.CMCo,null,0, b.CMAcct,b.StmtDate,
      0, /*type */
      null, /*cm trans type */
      null, /* source */
      null, /*act date */
      null, /*desc */
      0,0,
      null, /*cm ref */
      0,null,null,null,null,b.BegBal,b.WorkBal,b.StmtBal,0,0,0,0,0,0,0,0,0,0,Status ,null,0,0,0,0,0
      from CMST b
      where b.CMCo=@Company and    /*b.CMAcct>=@BeginningCMAcct and b.CMAcct<=@EndingCMAcct */
      	b.CMAcct=@CMAcct and b.StmtDate=@StmtDate 
      
      
      
      /*insert a record for cleared adjustments*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,a.StmtDate,0, /* 0= on statement, 1= outstanding */
      0, /* 0=Adj,1=check,2=Deposit,3=Transfer, 4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC /*,  #CMDetail a*/
      join #CMDetail a on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct */
      	CMAC.CMAcct=@CMAcct and a.StmtDate=@StmtDate
      Group by CMAC.CMCo, CMAC.CMAcct, a.StmtDate
      
      
      /*insert a record for cleared checks*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,a.StmtDate,0, /* 0= on statement, 1= outstanding */
      1, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC /*,  #CMDetail a*/
      join #CMDetail a on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
      where CMAC.CMCo=@Company and   /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct  */
      	CMAC.CMAcct=@CMAcct and a.StmtDate=@StmtDate
      Group by CMAC.CMCo, CMAC.CMAcct, a.StmtDate
      
      /*insert a record for cleared Deposits*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,a.StmtDate,0, /* 0= on statement, 1= outstanding */
      2, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC /*,  #CMDetail a*/
      join #CMDetail a on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
      where CMAC.CMCo=@Company and /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct */
      	CMAC.CMAcct=@CMAcct and a.StmtDate=@StmtDate
      Group by CMAC.CMCo, CMAC.CMAcct, a.StmtDate
      
      /*insert a record for cleared Transfers*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,a.StmtDate,0, /* 0= on statement, 1= outstanding */
      3, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      
      from CMAC /*,  #CMDetail a*/
      join #CMDetail a on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct */
      	CMAC.CMAcct=@CMAcct and a.StmtDate=@StmtDate
      Group by CMAC.CMCo, CMAC.CMAcct, a.StmtDate
      
      /*insert a record for cleared EFTs*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,a.StmtDate,0, /* 0= on statement, 1= outstanding */
      4, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC /*,  #CMDetail a*/
      join #CMDetail a on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
      where CMAC.CMCo=@Company and /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct */
      	CMAC.CMAcct=@CMAcct and a.StmtDate=@StmtDate
      Group by CMAC.CMCo, CMAC.CMAcct, a.StmtDate
      
      /*insert a record for Outstanding Adjustments*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,null,1, /* 0= on statement, 1= outstanding */
      0, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC
      where CMAC.CMCo=@Company and   /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct */
      	CMAC.CMAcct=@CMAcct
      
      /*insert a record for Outstanding Checks*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,null,1, /* 0= on statement, 1= outstanding */
      1, /* 0=Adj,1=check,2=Deposit,3=Transfer 4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct*/
      	CMAC.CMAcct=@CMAcct
   
      /*insert a record for Outstanding Deposits*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,null,1, /* 0= on statement, 1= outstanding */
      2, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct*/
      	CMAC.CMAcct=@CMAcct
      
      
      /*insert a record for Outstanding Transfers*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,null,1, /* 0= on statement, 1= outstanding */
      3, /* 0=Adj,1=check,2=Deposit,3=Transfer,EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct*/
      	CMAC.CMAcct=@CMAcct
      
      /*insert a record for Outstanding EFTs*/
      insert into #CMDetail
      select CMAC.CMCo,null,0, CMAC.CMAcct,null,1, /* 0= on statement, 1= outstanding */
      4, /* 0=Adj,1=check,2=Deposit,3=Transfer,EFT*/
      null,null,null,0,0,null,0,null,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null,0,0,0,0,0
      
      from CMAC
      where CMAC.CMCo=@Company and    /*CMAC.CMAcct>=@BeginningCMAcct and CMAC.CMAcct<=@EndingCMAcct*/
      	CMAC.CMAcct=@CMAcct
      
      select a.*,
   	AccountDesc=c.Description,
   	ClearDetailFlag=@ClearDetailFlag,OutDetailFlag=@OutDetailFlag,
   	CoName=d.Name,
   	CMACGL=c.GLAcct,--addition 3/28/02 by AA*/
   	ParamCompany=@Company,
   	ParamCMAcct=@CMAcct,
   	--ParamBegCMAcct=@BeginningCMAcct,
   	--ParamEndingCMAcct=@EndingCMAcct,
   	ParamStmtDate=@StmtDate,
   	ParamOSThruActDate=@OSThruDate,
           ParamOSThruMth=@OSThruMth,
   	ParamClearDetailFlag=@ClearDetailFlag,
   	ParamOutDetailFlag=@OutDetailFlag,
   	ParamThruMonth=@ThruMonth -- 5/2/02 AA
      
      from #CMDetail a /*,CMAC c, HQCO d*/
      	join CMAC c on c.CMCo=a.Co and c.CMAcct=a.CMAcct
      	join HQCO d on d.HQCo=a.Co
      	/*where a.Co=c.CMCo and a.CMAcct=c.CMAcct and a.Co=d.HQCo*/
      --and isnull(ActDate,'1/1/1950') <= (case when StmtType = 1 then @OSThruDate else isnull(ActDate,'1/1/1950') end)
      order by a.Co,a.CMAcct,a.StmtType,a.StmtDate

GO
GRANT EXECUTE ON  [dbo].[brptCMstmtrpt] TO [public]
GO
