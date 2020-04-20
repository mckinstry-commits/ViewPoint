SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptGLFinDetBud    Script Date: 8/28/99 9:33:49 AM ******/
   /****** Object:  PROC dbo.brptGLFinDetBud    Script Date: 3/3/97 2:24:47 PM ******/
   CREATE         PROC [dbo].[brptGLFinDetBud]
   (@GLCo bCompany, @BegAcct bGLAcct='          ', @EndAcct bGLAcct='zzzzzzzzzz',
   @BegMonth bMonth = null, @EndMonth bMonth = null,
   --@DetailLevel char(1) = 'D',
   @BudgetCode char(10)='')
   /*created 8/26/97 */
   /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                      fixed : =Null & using tables instead of views. Issue #20721 */
   /* Issue 25864 add with (nolock) DW 10/22/04*/
   as
   
   declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
   select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'
   create table #GLDetail
   (
     GLCo		tinyint		NULL,
     GLAcct	char(20)	NULL,
     FiscalPd  smalldatetime   Null,
     Mth       smalldatetime   Null,
     SummaryDesc  varchar(60)	NULL,
     SummaryActType  char(1)	NULL,
     SummarySubType  char(1)	NULL,
     SummaryActive  char(1)	NULL,
     SummaryNormBal  char(1)	NULL,
   --  BeginBal	decimal (16,2)	NULL,
     BegAcct char(20) NULL,
     EndAcct char(20) NULL,
     BegMonth smalldatetime NULL,
     EndMonth smalldatetime NULL,
     DetailLevel char(1) NULL,
     BudgetCode  char(10)  Null ,
     BudgetAmt        decimal (16,2) Null,
     BudgetDebit      decimal (16,2) Null,
     BudgetCredit     decimal (16,2) Null,
   --
     GLTrans int null,
     Jrnl varchar(2) null,
     GLRef varchar(10) null,
     SourceCo tinyint null,
     Source varchar(10) null,
     ActDate smalldatetime null,
     DetailDesc varchar(60) null,
     BatchId int null,
     DebitAmt decimal (16,2) Null,
     CreditAmt decimal (16,2) Null,
     NetAmt decimal (16,2) Null,
     AdjustYN varchar(1) null
   )
   
   
   CREATE NONCLUSTERED INDEX #tmpGLDetaili
       ON #GLDetail(GLCo,GLAcct)
   
   /*created 8/26/97 */
   
   create table #GLParts
   (GLCo tinyint null,
   P1Desc varchar(30) null,
   P2Desc varchar(30) null,
   P3Desc varchar(30) null,
   P4Desc varchar(30) null,
   P5Desc varchar(30) null,
   P6Desc varchar(30) null)
   
   /* fill GL Parts */
   insert into #GLParts
   select GLCO.GLCo, GLPD1.Description, GLPD2.Description,GLPD3.Description,
   GLPD4.Description, GLPD5.Description,GLPD6.Description
   from GLCO with(nolock)
   Left Join GLPD as GLPD1 with(nolock) on GLPD1.GLCo=GLCO.GLCo and GLPD1.PartNo=1
   Left Join GLPD as GLPD2 with(nolock) on GLPD2.GLCo=GLCO.GLCo and GLPD2.PartNo=2
   Left Join GLPD as GLPD3 with(nolock) on GLPD3.GLCo=GLCO.GLCo and GLPD3.PartNo=3
   Left Join GLPD as GLPD4 with(nolock) on GLPD4.GLCo=GLCO.GLCo and GLPD4.PartNo=4
   Left Join GLPD as GLPD5 with(nolock) on GLPD5.GLCo=GLCO.GLCo and GLPD5.PartNo=5
   Left Join GLPD as GLPD6 with(nolock) on GLPD6.GLCo=GLCO.GLCo and GLPD6.PartNo=6
   where GLCO.GLCo=@GLCo
   
   /* if no begin month then get it from the end month */
   if @BegMonth is null
   begin
   select @BegMonth = GLFY.BeginMth
   from GLFY with(nolock)
   where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
   if @@rowcount=0
   	begin
   	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
   	insert into #GLDetail (GLCo,GLAcct,SummaryDesc,
     		BegAcct,EndAcct,BegMonth,EndMonth
   --        ,DetailLevel
           )
   	select @GLCo,min(GLAcct),@ErrorMessage,
   		@BegAcct,@EndAcct,@BegMonth,@EndMonth
   --        ,@DetailLevel
   		from GLAC with(nolock)
   		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull
   	goto selectresults
   	end
   end
   
   /* get Fiscal Year Begin Month */
   select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
   from GLFY with(nolock)
   where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
   if @@rowcount=0
   	begin
   	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
   	insert into #GLDetail (GLCo,GLAcct,SummaryDesc,
     		BegAcct,EndAcct,BegMonth,EndMonth
   --        ,DetailLevel
           )
   
   	select @GLCo,min(GLAcct),@ErrorMessage,
   		@BegAcct,@EndAcct,@BegMonth,@EndMonth
   --        ,@DetailLevel
   		from GLAC with(nolock)
   		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull
   	goto selectresults
   	end
   
   /* check if ending month is in same year as begin month */
   if @EndMonth <@BegMonth or @FYBMO is null
   	begin
   	select @ErrorMessage= '**** End month may not be less than the begin month ****'
   	insert into #GLDetail (GLCo,GLAcct,SummaryDesc,
     		BegAcct,EndAcct,BegMonth,EndMonth
   --        ,DetailLevel
           )
   	select @GLCo,min(GLAcct),@ErrorMessage,
   		@BegAcct,@EndAcct,@BegMonth,@EndMonth
   --        ,@DetailLevel
   		from GLAC with(nolock)
   		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull
   	goto selectresults
   	end
   if @EndMonth > @FYEMO or @FYEMO is null
   	begin
   	select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
   	insert into #GLDetail (GLCo,GLAcct,SummaryDesc,
     		BegAcct,EndAcct,BegMonth,EndMonth
   --        ,DetailLevel
   )
   	select @GLCo,min(GLAcct),@ErrorMessage,
   		@BegAcct,@EndAcct,@BegMonth,@EndMonth
   --        ,@DetailLevel
   		from GLAC with(nolock)
   		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull
   	goto selectresults
   	end
   
   Insert into #GLDetail
   (GLCo,GLAcct,Mth,BudgetCode,BudgetAmt,BudgetDebit,BudgetCredit
     )
   select GLBD.GLCo,GLBD.GLAcct,GLBD.Mth,GLBD.BudgetCode,
   BudgetAmt=isnull(GLBD.BudgetAmt,0),
   BudgetDebit=Case when GLBD.BudgetAmt>0 then GLBD.BudgetAmt else 0 end,
   BudgetCredit=Case when GLBD.BudgetAmt<0 then -GLBD.BudgetAmt else 0 end
   
   From GLBD with(nolock)
   --left Join #GLDetail a on GLBD.GLCo=a.GLCo and GLBD.GLAcct=a.GLAcct and GLBD.Mth=a.Mth
   where GLBD.BudgetCode=@BudgetCode
   and GLCo=@GLCo and GLBD.GLAcct>=@BegAcct and GLBD.GLAcct<=@EndAcctFull
   and Mth between @BegMonth and @EndMonth
   
   Insert into #GLDetail
   (GLCo,GLAcct,Mth,GLTrans,Jrnl,GLRef,SourceCo,Source,ActDate,DetailDesc,
   BatchId,DebitAmt,CreditAmt,NetAmt,AdjustYN)
   
    select GLDT.GLCo,GLDT.GLAcct,GLDT.Mth,
     GLTrans, Jrnl, GLRef, SourceCo, Source, ActDate, Description,
     BatchId,
     Debit=Case when GLDT.Amount>0 then GLDT.Amount else 0 end,
     Credit=Case when GLDT.Amount<0 then -GLDT.Amount else 0 end,
     NetAmt=isnull(GLDT.Amount,0), AdjustYN=GLDT.Adjust
    from GLDT with(nolock)
   where GLCo=@GLCo and GLAcct between @BegAcct and @EndAcctFull
   and Mth between @BegMonth and @EndMonth
   
   selectresults:
   
   begin
   /*select the results*/
   select GLAC.GLCo,GLAC.GLAcct,a.Mth,FiscalPd=GLFP.FiscalPd,GLAC.Description,GLAC.AcctType,
     GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
     GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
     GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
     a.SummaryDesc, a.SummaryActType, a.SummarySubType, a.SummaryActive,
     a.SummaryNormBal,
   --  a.BeginBal,
     a.GLTrans, a.Jrnl, a.GLRef,a.SourceCo, a.Source, a.ActDate,
     a.DetailDesc, a.BatchId,a.DebitAmt,a.CreditAmt,
     a.NetAmt, a.AdjustYN,
     brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
     P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     a.BudgetCode,  a.BudgetAmt,  a.BudgetDebit,  a.BudgetCredit,
   CoName=HQCO.Name,  a.BegAcct,a.EndAcct,a.BegMonth,a.EndMonth,@ErrorMessage
   --,a.DetailLevel
   
   FROM GLAC with(nolock)
   Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct and a.Mth>=@BegMonth and a.Mth<=@EndMonth
   Left Join brvGLFSPart2 with(nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
   Left Join brvGLFSPart3 with(nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
   Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
   /*Left*/ Join GLBD with(nolock) on GLBD.GLCo=GLAC.GLCo and GLBD.GLAcct=GLAC.GLAcct and GLBD.BudgetCode=@BudgetCode and GLBD.Mth=a.Mth
   Join HQCO with(nolock) on HQCO.HQCo=GLAC.GLCo
   Join GLFP with(nolock) on GLFP.GLCo=a.GLCo and GLFP.Mth=a.Mth
   where GLAC.GLCo=@GLCo
     and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull
   order by GLAC.GLCo, GLAC.GLAcct
   
   end

GO
GRANT EXECUTE ON  [dbo].[brptGLFinDetBud] TO [public]
GO
