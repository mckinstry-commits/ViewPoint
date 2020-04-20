SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptCMCheckbook    Script Date: 8/28/99 9:33:48 AM ******/
      CREATE   proc [dbo].[brptCMCheckbook]
      (@CMCo bCompany,@CMAcct bCMAcct=null,@BegDate bDate=null,@EndDate bDate=null,
      @BegBal bDollar, @CalcBegBal bYN)
       as
      /* Mod 05/09/01 JRE send BeginBalance even if there is no detail  Issue #13399*/ 
      /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                         fixed : =Null & using tables instead of views. Issue #20721 */
      /*  Issue 25897 Added with(nolock) to the from and join statements NF 11/11/04 */
     
      
      declare  @StmtBal bDollar, @LastStmtDate bDate,	@OpenAmts bDollar
      
      if @CalcBegBal='Y'
      begin
      /* get last statment date */
      select @LastStmtDate=Max(StmtDate) from CMST with(nolock)
      	where CMCo=@CMCo and CMAcct=@CMAcct and Status=1 and StmtDate<@BegDate
      
      /* get last statement balance */
      select @StmtBal=StmtBal from CMST with(nolock)
      	where CMCo=@CMCo and CMAcct=@CMAcct and Status=1 and StmtDate=@LastStmtDate
      
      if @LastStmtDate is not null
      begin
      /* get open amounts from CMDT */
      select @OpenAmts=sum(Amount) from CMDT with(nolock)
      	where CMCo=@CMCo and CMAcct=@CMAcct
      	and (StmtDate is null or StmtDate>@LastStmtDate)
      	and ActDate<@BegDate and Void<>'Y'
      end
      else
      begin
      /* get open amounts from CMDT */
      select @OpenAmts=sum(Amount) from CMDT with(nolock)
      	where CMCo=@CMCo and CMAcct=@CMAcct
      	and ActDate<@BegDate and Void<>'Y'
      end
      end
      else
      begin  /* use Begin Bal as enetered */
      select @StmtBal=@BegBal, @OpenAmts=0
      end
      
      SELECT
        CMCo=HQCO.HQCo,CMAcct=@CMAcct,CMDT.CMTransType,CMDT.Source,CMDT.ActDate,
        'DetailDesc'=CMDT.Description, CMDT.Amount,CMDT.CMRef,CMDT.Void,
        HQCO.HQCo,HQCO.Name, 'AcctDesc'=CMAC.Description,
       'BegBal'=IsNull(@StmtBal,0)+IsNull(@OpenAmts,0),'BegDate'=@BegDate,
       'EndDate'=@EndDate,'CalcBegBal?'=@CalcBegBal
      FROM
        HQCO with(nolock) -- Issue #13399
        JOIN CMAC with(nolock) ON HQCO.HQCo =CMAC.CMCo AND  CMAC.CMAcct=@CMAcct   -- Issue #13399
        Left JOIN CMDT with(nolock) ON CMDT.CMCo= HQCO.HQCo AND CMDT.CMAcct=@CMAcct AND  -- Issue #13399
          CMDT.ActDate>=@BegDate AND CMDT.ActDate<=@EndDate  -- Issue #13399
   
   
      WHERE
          HQCO.HQCo= @CMCo    -- Issue #13399
   
      ORDER BY
          CMDT.CMCo  ASC,     
          CMDT.CMAcct  ASC,
          CMDT.ActDate  ASC

GO
GRANT EXECUTE ON  [dbo].[brptCMCheckbook] TO [public]
GO
