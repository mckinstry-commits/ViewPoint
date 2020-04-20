SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptCMStmtDD    Script Date: 8/27/03 10:50:00 AM ******/
   /***Created for use with CM Statement DrillDown ****/
   
   CREATE                       proc [dbo].[brptCMStmtDD]
     @Company tinyint=null,
     @CMAcct smallint=null, 
     @StmtDate smalldatetime=null,
     @ThruActDate smalldatetime=null
    
     as
     set nocount on
     /* create temp table of CM Detail from the CM Detail Table*/
    
     create table #CMStmtDetail
     
     (CMCo		tinyint		null,
     Mth		smalldatetime	null,
     CMTrans	integer		null, 
     CMAcct	smallint	null,
     StmtDate	smalldatetime	null,
     StmtType	tinyint		null, /* 0= on statement, 1= outstanding */
     CMTransType	tinyint		null,/* 0=,Adjustments,1=checks,2=Deposit,3=Transfers,4=EFT*/
     Source	char(10)	null,
     ActDate	smalldatetime	null,
     CMDTDesc	varchar(30)	null,
     Amount	decimal(16,2)	null,
     ClearedAmt	decimal(16,2)	null,
     CMRef		varchar(10)	null,
     CMRefSeq	tinyint		null,
     Payee		varchar(20)	null,
     GLAcct	char(20)	null,
     Void		char(1)		null,
     BegBal	float		null,
     WorkBal	decimal(16,2)	null,
     StmtBal	decimal(16,2)	null,
     Adjustments	decimal(16,2)	null,
     Checks	decimal(16,2)	null,
     Deposits	decimal(16,2)	null,
     Transfers	decimal(16,2)	null,
     EFTs		decimal (16,2)	null,
     OSAdjust	decimal(16,2)	null,
     OSChecks	decimal(16,2)	null,
     OSDeposits	decimal(16,2)	null,
     OSTransfers	decimal(16,2)	null,
     OSEFTs	decimal(16,2)	null,
     Status	tinyint		null,
     ClearDate	smalldatetime	null,
      )
     
     /*insert CM Detail */
     insert into #CMStmtDetail
       select CMDT.CMCo,CMDT.Mth,CMDT.CMTrans,CMDT.CMAcct,CMDT.StmtDate,
     	case when (CMDT.StmtDate > @StmtDate or CMDT.StmtDate is null) then 1 else 0 end, /* Statement type */
     	case when CMDT.CMTransType<>4 then CMDT.CMTransType else 1 end,   /* CMTransType */
       CMDT.Source,CMDT.ActDate,CMDT.Description, CMDT.Amount, CMDT.ClearedAmt, CMDT.CMRef,
       CMDT.CMRefSeq,CMDT.Payee,CMDT.GLAcct, CMDT.Void,0,0,0,
     	case when CMDT.CMTransType=0 AND CMDT.StmtDate=@StmtDate AND CMDT.Void<>'Y' then CMDT.ClearedAmt else 0 end,
     	case when CMDT.CMTransType=1 AND CMDT.StmtDate=@StmtDate AND CMDT.Void<>'Y' then CMDT.ClearedAmt else 0 end,
   	case when CMDT.CMTransType=2 AND CMDT.StmtDate=@StmtDate AND CMDT.Void<>'Y' then CMDT.ClearedAmt else 0 end,
   	case when CMDT.CMTransType=3 AND CMDT.StmtDate=@StmtDate AND CMDT.Void<>'Y' then CMDT.ClearedAmt else 0 end,
     	case when CMDT.CMTransType=4 AND CMDT.StmtDate=@StmtDate AND CMDT.Void<>'Y' then CMDT.ClearedAmt else 0 end,
   	case when CMDT.CMTransType=0 AND (CMDT.StmtDate>@StmtDate or CMDT.StmtDate is null) AND CMDT.ActDate<=@ThruActDate AND CMDT.Void<>'Y' then CMDT.Amount else 0 end,
   	case when CMDT.CMTransType=1 AND (CMDT.StmtDate>@StmtDate or CMDT.StmtDate is null) AND CMDT.ActDate<=@ThruActDate AND CMDT.Void<>'Y' then CMDT.Amount else 0 end,
   	case when CMDT.CMTransType=2 AND (CMDT.StmtDate>@StmtDate or CMDT.StmtDate is null) AND CMDT.ActDate<=@ThruActDate AND CMDT.Void<>'Y' then CMDT.Amount else 0 end,
    	case when CMDT.CMTransType=3 AND (CMDT.StmtDate>@StmtDate or CMDT.StmtDate is null) AND CMDT.ActDate<=@ThruActDate AND CMDT.Void<>'Y' then CMDT.Amount else 0 end,
   	case when CMDT.CMTransType=4 AND (CMDT.StmtDate>@StmtDate or CMDT.StmtDate is null) AND CMDT.ActDate<=@ThruActDate AND CMDT.Void<>'Y' then CMDT.Amount else 0 end,
      0,CMDT.ClearDate
     
     from CMDT With (NoLock)
     where CMDT.CMCo=@Company and CMDT.CMAcct=@CMAcct and (CMDT.StmtDate>=@StmtDate or CMDT.StmtDate is null)
     
      
     /*insert CM Statement Balance Information from CMST*/
     
     insert into #CMStmtDetail
     select CMST.CMCo,null,0, CMST.CMAcct,CMST.StmtDate,
     0, /*type */
     null, /*cm trans type */
     null, /* source */
     null, /*act date */
     null, /*desc */
     0,0,
     null, /*cm ref */
     0,null,null,null,CMST.BegBal,CMST.WorkBal,CMST.StmtBal,0,0,0,0,0,0,0,0,0,0,Status ,null
  
     from CMST With (NoLock)
     where CMST.CMCo=@Company and CMST.CMAcct=@CMAcct and CMST.StmtDate=@StmtDate 
     
     
     
     /*insert a record for cleared adjustments*/
     insert into #CMStmtDetail
     select CMAC.CMCo,null,0, CMAC.CMAcct,#CMStmtDetail.StmtDate,0, /* 0= on statement, 1= outstanding */
     0, /* 0=Adj,1=check,2=Deposit,3=Transfer, 4=EFT*/
     null,null,null,0,0,null,0,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null
     
     from CMAC With (NoLock)
       join #CMStmtDetail on #CMStmtDetail.CMCo=CMAC.CMCo and #CMStmtDetail.CMAcct=CMAC.CMAcct
     where CMAC.CMCo=@Company and CMAC.CMAcct=@CMAcct and #CMStmtDetail.StmtDate=@StmtDate
     
     Group by CMAC.CMCo, CMAC.CMAcct, #CMStmtDetail.StmtDate
     
     
     /*insert a record for cleared checks*/
     insert into #CMStmtDetail
     select CMAC.CMCo,null,0, CMAC.CMAcct,#CMStmtDetail.StmtDate,0, /* 0= on statement, 1= outstanding */
     1, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
     null,null,null,0,0,null,0,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null
     
     from CMAC With (NoLock)
       join #CMStmtDetail on #CMStmtDetail.CMCo=CMAC.CMCo and #CMStmtDetail.CMAcct=CMAC.CMAcct
     where CMAC.CMCo=@Company and CMAC.CMAcct=@CMAcct and #CMStmtDetail.StmtDate=@StmtDate
     
     Group by CMAC.CMCo, CMAC.CMAcct, #CMStmtDetail.StmtDate
     
     /*insert a record for cleared Deposits*/
     insert into #CMStmtDetail
     select CMAC.CMCo,null,0, CMAC.CMAcct,#CMStmtDetail.StmtDate,0, /* 0= on statement, 1= outstanding */
     2, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
     null,null,null,0,0,null,0,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null
     
     from CMAC With (NoLock)
       join #CMStmtDetail  on #CMStmtDetail.CMCo=CMAC.CMCo and #CMStmtDetail.CMAcct=CMAC.CMAcct
     where CMAC.CMCo=@Company and CMAC.CMAcct=@CMAcct and #CMStmtDetail.StmtDate=@StmtDate
     
     Group by CMAC.CMCo, CMAC.CMAcct, #CMStmtDetail.StmtDate
     
     /*insert a record for cleared Transfers*/
     insert into #CMStmtDetail
     select CMAC.CMCo,null,0, CMAC.CMAcct,#CMStmtDetail.StmtDate,0, /* 0= on statement, 1= outstanding */
     3, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
     null,null,null,0,0,null,0,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null
     
     
     from CMAC With (NoLock)
       join #CMStmtDetail on #CMStmtDetail.CMCo=CMAC.CMCo and #CMStmtDetail.CMAcct=CMAC.CMAcct
     where CMAC.CMCo=@Company and CMAC.CMAcct=@CMAcct and #CMStmtDetail.StmtDate=@StmtDate
       
     Group by CMAC.CMCo, CMAC.CMAcct, #CMStmtDetail.StmtDate
     
     /*insert a record for cleared EFTs*/
     insert into #CMStmtDetail
     select CMAC.CMCo,null,0, CMAC.CMAcct,#CMStmtDetail.StmtDate,0, /* 0= on statement, 1= outstanding */
     4, /* 0=Adj,1=check,2=Deposit,3=Transfer,4=EFT*/
     null,null,null,0,0,null,0,null,null,null,0,0,0,0,0,0,0,0,0,0,0,0,0,0,null
     
     from CMAC With (NoLock)
       join #CMStmtDetail on #CMStmtDetail.CMCo=CMAC.CMCo and #CMStmtDetail.CMAcct=CMAC.CMAcct
     where CMAC.CMCo=@Company and CMAC.CMAcct=@CMAcct and #CMStmtDetail.StmtDate=@StmtDate
       
     Group by CMAC.CMCo, CMAC.CMAcct, #CMStmtDetail.StmtDate
      
     
     
     select #CMStmtDetail.*, AccountDesc=CMAC.Description,
     CoName=HQCO.Name,  
     ParamCompany=@Company,
     ParamCMAcct=@CMAcct,
     ParamStmtDate=@StmtDate,
     ParamThruActDate=@ThruActDate
       
     from #CMStmtDetail  
       join CMAC With (NoLock) on CMAC.CMCo=#CMStmtDetail.CMCo and CMAC.CMAcct=#CMStmtDetail.CMAcct
       join HQCO With (NoLock) on HQCO.HQCo=#CMStmtDetail.CMCo
     where IsNull(#CMStmtDetail.ActDate,'01/01/1950') <= @ThruActDate
     order by #CMStmtDetail.CMCo,#CMStmtDetail.CMAcct,#CMStmtDetail.StmtType,#CMStmtDetail.StmtDate

GO
GRANT EXECUTE ON  [dbo].[brptCMStmtDD] TO [public]
GO
