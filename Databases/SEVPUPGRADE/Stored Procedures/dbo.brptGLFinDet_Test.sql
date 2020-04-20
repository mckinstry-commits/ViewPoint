SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptGLFinDet_Test    Script Date: 8/28/99 9:33:49 AM ******/
    /****** Object:  PROC dbo.brptGLFinDet_Test   Script Date: 3/3/97 2:24:47 PM ******/
   CREATE                        PROC dbo.brptGLFinDet_Test
    (@GLCo bCompany, @BegAcct bGLAcct='          ', @EndAcct bGLAcct='zzzzzzzzzz',
    @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050',@DetailLevel char(1) = 'D')
 	/*created 10/12/04 */
 	/*Made copy of dbo.brptGLFinDet and changed to execute level='D' and level='R'
 	  in separate stored procedures */
 	
    as
    set nocount on
    declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
 
 /* Execute other Stored Procedures for Account or Reference */
    If @DetailLevel= 'A' 
      Begin
 	exec brptGLFinDet_Acct
 		@GLCo, @BegAcct, @EndAcct, @BegMonth, @EndMonth, @DetailLevel
 	goto bspexit
      END
    If  @DetailLevel= 'R' 
      Begin
 	exec brptGLFinDet_Ref
 		@GLCo, @BegAcct, @EndAcct, @BegMonth, @EndMonth, @DetailLevel
 	goto bspexit
      END
 
 /* if @DetailLevel='D' */
 
    select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'
    /*create table */
    
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
    from GLCO with (nolock)
    Left Join GLPD as GLPD1 on GLPD1.GLCo=GLCO.GLCo and GLPD1.PartNo=1
    Left Join GLPD as GLPD2 on GLPD2.GLCo=GLCO.GLCo and GLPD2.PartNo=2
    Left Join GLPD as GLPD3 on GLPD3.GLCo=GLCO.GLCo and GLPD3.PartNo=3
    Left Join GLPD as GLPD4 on GLPD4.GLCo=GLCO.GLCo and GLPD4.PartNo=4
    Left Join GLPD as GLPD5 on GLPD5.GLCo=GLCO.GLCo and GLPD5.PartNo=5
    Left Join GLPD as GLPD6 on GLPD6.GLCo=GLCO.GLCo and GLPD6.PartNo=6
    where GLCO.GLCo=@GLCo
    
     /* if no begin month then get it from the end month */
    if @BegMonth is null
    begin
    select @BegMonth = GLFY.BeginMth
    from GLFY  with (nolock)
    where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
    if @@rowcount=0
    	begin
    	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
    	/* insert into #GLDetail (GLCo,GLAcct)
    	select @GLCo,min(GLAcct)
    		from GLAC
    		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull  Issue 23660 */
    	end
    	goto selectresults
    end
    
    /* get Fiscal Year Begin Month */
    select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
    from GLFY  with (nolock)
    where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
    if @@rowcount=0
    	begin
    	select @ErrorMessage= '**** Fiscal Year End Beginning Month not set up****'
    	/*  insert into #GLDetail (GLCo,GLAcct)
      	select @GLCo,min(GLAcct)
    		from GLAC
    		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull  Issue 23660 */ 
    	goto selectresults
    	end
    
    /* check if ending month is in same year as begin month */
    if @EndMonth <@BegMonth or @FYBMO is null
    	begin
    	select @ErrorMessage= '**** End month may not be less than the begin month ****'
    	/*   insert into #GLDetail (GLCo,GLAcct)
    	select @GLCo,min(GLAcct)
    		from GLAC
    		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull   Issue 23660 */
    	goto selectresults
    	end
    if @EndMonth > @FYEMO or @FYEMO is null
    	begin
    	select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
    	/*  insert into #GLDetail (GLCo,GLAcct)
    	select @GLCo,min(GLAcct)
    		from GLAC
 
    		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull   Issue 23660 */
    	goto selectresults
 
    	end
  
  --******************************************************************************************************
  --* Begin Processing Here 
  --******************************************************************************************************
  
    /* Begin Balance (per Issue 23660 now a union statement in selectresults)  */
    /* insert from GLYB  */
   /* insert into #GLDetail
    (GLCo,GLAcct,BeginBal,NetAdj)
    select GLAC.GLCo,GLAC.GLAcct,isnull(GLYB.BeginBal,0)+isnull(GLAS.NetAmt,0),IsNull(GLYB.NetAdj,0)
    from GLAC
    Left Join GLAC as GLACSum on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
    Left join GLYB on GLAC.GLCo=GLYB.GLCo and GLAC.GLAcct=GLYB.GLAcct and GLYB.FYEMO=@FYEMO
    left join (select GLCo, GLAcct, NetAmt=sum(GLAS.NetAmt) 
  				from GLAS
         			where GLAS.Mth<@BegMonth and GLAS.Mth>=@FYBMO
         			group by GLAS.GLCo,GLAS.GLAcct) as GLAS
         			on GLAS.GLCo=GLAC.GLCo and GLAS.GLAcct=GLAC.GLAcct 
    where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull     Issue 23660 */
    
    
  --******************************************************************************************************
  --* select the results
  --******************************************************************************************************
  
  selectresults:
 
 
 
    /* use GLBL	 to get detail */
 --   if @DetailLevel='A'  
 --   begin
    /*select the results*/
 	/* Beginning Balance Record */
 select GLAC.GLCo,GLAC.GLAcct,GLAC.Description,GLAC.AcctType,
      GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
      GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
      GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
      SummaryDesc=COALESCE(@ErrorMessage,GLACSum.Description,GLAC.Description),
      SummaryActType=GLACSum.AcctType,
      SummarySubType=GLACSum.SubType, 
      SummaryActive=GLACSum.Active,
      SummaryNormBal=GLACSum.NormBal,
      BeginBal = (IsNull(GLYB.BeginBal,0) + IsNull(GLAS.NetAmt,0)),
      Mth=@EndMonth, GLTrans=null, Jrnl=null, GLRef=null,
      SourceCo=null, Source=null, ActDate=null, DetailDesc=null, BatchId=null,
      Debit=0,
      Credit=0,
      NetAmt=0, Adjust='N',
      brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
      P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
    CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
    EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='B'
  FROM GLAC  as GLAC  with (nolock)
    Left Join GLAC  as GLACSum  with (nolock) on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
    /*  Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct  */
    Left Join  
 	(select GLCo, GLAcct, NetAmt=sum(GLAS.NetAmt) from GLAS with (nolock)
           where GLAS.GLCo=@GLCo
           and GLAS.GLAcct>=@BegAcct and GLAS.GLAcct<=@EndAcctFull and GLAS.Mth<@BegMonth and GLAS.Mth>=@FYBMO
 	  group by GLAS.GLCo,GLAS.GLAcct) as GLAS
 	on GLAC.GLCo=GLAS.GLCo and GLAC.GLAcct=GLAS.GLAcct
    Left Join GLYB with (nolock) on GLAC.GLCo=GLYB.GLCo and GLAC.GLAcct=GLYB.GLAcct and GLYB.FYEMO = @FYEMO
    Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
    Left Join brvGLFSPart3 with (nolock)on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
    Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
    Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
    where GLAC.GLCo=@GLCo  and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
 
  /* use GLDT for detail or Ref */
 -- @DetailLevel='D'
 -- begin
    /*select the results*/
 
 Union all
   
  select GLAC.GLCo,GLAC.GLAcct,GLAC.Description,GLAC.AcctType,
      GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
      GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
      GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
      SummaryDesc=COALESCE(@ErrorMessage,GLACSum.Description,GLAC.Description),
      SummaryActType=GLACSum.AcctType,
      SummarySubType=GLACSum.SubType, 
      SummaryActive=GLACSum.Active,
      SummaryNormBal=GLACSum.NormBal,
      BeginBal=0,
      Mth=isnull(GLDT.Mth,'01/01/1950'), GLDT.GLTrans, GLDT.Jrnl, GLDT.GLRef,
      GLDT.SourceCo, GLDT.Source, GLDT.ActDate, DetailDesc=IsNull(GLDT.Description,' '), GLDT.BatchId,
      Debit=Case when GLDT.Amount>0 then GLDT.Amount else 0 end,
      Credit=Case when GLDT.Amount<0 then -GLDT.Amount else 0 end,
      NetAmt=isnull(GLDT.Amount,0),  IsNull(GLDT.Adjust,'N'),
      brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
      P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
    CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
    EndMonth=@EndMonth,ErrorMessage=IsNull(@ErrorMessage,' '),DetailLevel=@DetailLevel,RecType='D'
    
    FROM GLAC  with (nolock) 
    Left Join GLAC  as GLACSum  with (nolock) on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
    /*Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct*/
    Left Join GLDT with (nolock) on GLDT.GLCo=GLAC.GLCo and GLDT.GLAcct=GLAC.GLAcct and GLDT.Mth>=@BegMonth and GLDT.Mth<=@EndMonth
    Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
    Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
    Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
    Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
    where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='D'
 
    --  may be taking too much time, trying not ordering and let Crystal Order  JRE 3/21/02
 --  order by GLAC.GLCo, GLAC.GLAcct
 --end
 
 
 
 
 bspexit:
GO
GRANT EXECUTE ON  [dbo].[brptGLFinDet_Test] TO [public]
GO