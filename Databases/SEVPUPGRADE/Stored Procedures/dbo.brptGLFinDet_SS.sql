SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptGLFinDet_SS    Script Date: 8/28/99 9:33:49 AM ******/
     /****** Object:  PROC dbo.brptGLFinDet_SS    Script Date: 3/3/97 2:24:47 PM ******/
    CREATE             PROC dbo.brptGLFinDet_SS
     (@GLCo bCompany, @BegAcct bGLAcct='          ', @EndAcct bGLAcct='zzzzzzzzzz',
     @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050',@DetailLevel char(1) = 'D')
     /*created 8/26/97 */
     /*changed report to use GLAC instead of GLAC for security*/
     /*mod JRE 3/27/02 Timing out for large GLs.  Re-wrote the get beginning balance to be more effecient
       by eliminating an update by using a derived table in the insert, and reducing the size of #GLDetail*/
     /*changed TRL 4/3/2002 Took out the IF BEGIN END statements used for selecting by detail level.  Added Union
      statments and RecType field */
     /*mod JRE 4/23/03  issue 21042 change  GLCO .. NOT NULL to GLCO .. NULL */
     as
     set nocount on
     declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
     select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'
     create table #GLDetail
     ( GLCo	tinyint		NULL, --issue 21042
       GLAcct	char(20)	NULL,
       BeginBal decimal (16,2)	NULL,
       NetAdj   decimal (12,2) Null
     )
     
     
     CREATE UNIQUE CLUSTERED INDEX #tmpGLDetaili
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
     from GLCO
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
     from GLFY  
     where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
     if @@rowcount=0
     	begin
     	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
     	insert into #GLDetail (GLCo,GLAcct)
     	select @GLCo,min(GLAcct)
     		from GLAC
     		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
     	end
     	goto selectresults
     end
     
     /* get Fiscal Year Begin Month */
     select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
     from GLFY 
     where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
     if @@rowcount=0
     	begin
     	select @ErrorMessage= '**** Fiscal Year End Beginning Month not set up****'
     	insert into #GLDetail (GLCo,GLAcct)
       	select @GLCo,min(GLAcct)
     		from GLAC
     		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
     	goto selectresults
     	end
     
     /* check if ending month is in same year as begin month */
     if @EndMonth <@BegMonth or @FYBMO is null
     	begin
     	select @ErrorMessage= '**** End month may not be less than the begin month ****'
     	insert into #GLDetail (GLCo,GLAcct)
     	select @GLCo,min(GLAcct)
     		from GLAC
     		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
     	goto selectresults
     	end
     if @EndMonth > @FYEMO or @FYEMO is null
     	begin
     	select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
     	insert into #GLDetail (GLCo,GLAcct)
     	select @GLCo,min(GLAcct)
     		from GLAC
     		where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
     	goto selectresults
     	end
   
   --******************************************************************************************************
   --* Begin Processing Here 
   --******************************************************************************************************
   
     /* Begin Balance */
     /* insert from GLYB  */
     insert into #GLDetail
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
     where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull 
     
     
   --******************************************************************************************************
   --* select the results
   --******************************************************************************************************
   
   selectresults:
     /* use GLBL	 to get detail */
  --   if @DetailLevel='A'  
  --   begin
     /*select the results*/
    
     select GLAC.GLCo,GLAC.GLAcct,GLAC.Description,GLAC.AcctType,
       GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
       GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
       GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
       SummaryDesc=COALESCE(@ErrorMessage,GLACSum.Description,GLAC.Description),
       SummaryActType=GLACSum.AcctType,
       SummarySubType=GLACSum.SubType, 
       SummaryActive=GLACSum.Active,
       SummaryNormBal=GLACSum.NormBal,
       a.BeginBal,
       GLBL.Mth, GLTrans=null, Jrnl=null, GLRef=null,
       SourceCo=Null, Source=Null, ActDate=null, DetailDesc=null, BatchId=null, Vendor=0,
       Debit=Case when GLBL.NetActivity >0 then GLBL.NetActivity else 0 end,
       Credit=Case when GLBL.NetActivity <0 then -GLBL.NetActivity else 0 end,
       NetAmt=isnull(GLBL.NetActivity,0),0,  Adjust=' ',
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='A'
     FROM GLAC as GLAC
     Left Join GLAC as GLACSum on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct
     Left Join GLBL on GLBL.GLCo=a.GLCo and GLBL.GLAcct=a.GLAcct and GLBL.Mth>=@BegMonth and GLBL.Mth<=@EndMonth
     Left Join brvGLFSPart2 on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo
       and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='A'
     -- order by GLAC.GLCo, GLAC.GLAcct
     
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
       a.BeginBal,
       Mth = Null, GLTrans=null, Jrnl = null, GLRef = null,
       SourceCo = null, Source = null, ActDate=null, DetailDesc=null, BatchId=null,Vendor=0,
       Debit=Case when GLYB.NetAdj>0 then GLYB.NetAdj else 0 end,
       Credit=Case when GLYB.NetAdj<0 then -GLYB.NetAdj else 0 end,
       NetAmt=isnull(GLYB.NetAdj,0),0,  Adjust = 'Y',
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='A'
     FROM GLAC as GLAC
     Left Join GLAC as GLACSum on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct
     Left Join GLYB on GLYB.GLCo=a.GLCo and GLYB.GLAcct=a.GLAcct and GLYB.FYEMO=@FYEMO and GLYB.NetAdj <> 0
     Left Join brvGLFSPart2 on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='A'
     --order by GLAC.GLCo, GLAC.GLAcct
  --   end
  union all
     /* GLAS*/
  --   if @DetailLevel='R'  
  --   begin
     /*select the results*/
     select GLAC.GLCo,GLAC.GLAcct,GLAC.Description,GLAC.AcctType,
       GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
       GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
       GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
       SummaryDesc=COALESCE(@ErrorMessage,GLACSum.Description,GLAC.Description),
       SummaryActType=GLACSum.AcctType,
       SummarySubType=GLACSum.SubType, 
       SummaryActive=GLACSum.Active,
       SummaryNormBal=GLACSum.NormBal,
       a.BeginBal,
       GLAS.Mth, GLTrans=null, GLAS.Jrnl, GLAS.GLRef,
       GLAS.SourceCo, GLAS.Source, ActDate=null, DetailDesc=GLRF.Description, BatchId=null,Vendor=0,
       Debit=Case when GLAS.NetAmt>0 then GLAS.NetAmt else 0 end,
       Credit=Case when GLAS.NetAmt<0 then -GLAS.NetAmt else 0 end,
       NetAmt=isnull(GLAS.NetAmt,0),0,  GLAS.Adjust,
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='R'
   FROM GLAC as GLAC
     Left Join GLAC as GLACSum on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct
     Left Join GLAS on GLAS.GLCo=a.GLCo and GLAS.GLAcct=a.GLAcct and GLAS.Mth>=@BegMonth and GLAS.Mth<=@EndMonth
     Left Join GLRF on GLRF.GLCo=GLAS.GLCo and GLRF.Mth=GLAS.Mth and GLRF.Jrnl=GLAS.Jrnl and GLRF.GLRef=GLAS.GLRef
     Left Join brvGLFSPart2 on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo  and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='R'
  --   order by GLAC.GLCo, GLAC.GLAcct
  -- end
     
   /* use GLDT for detail or Ref */
  -- if @DetailLevel='D'
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
       a.BeginBal,
       GLDT.Mth, GLDT.GLTrans, GLDT.Jrnl, GLDT.GLRef,
       GLDT.SourceCo, GLDT.Source, GLDT.ActDate, DetailDesc=IsNull(GLDT.Description,' '), GLDT.BatchId, Vendor=CASE When isnumeric(substring(GLDT.Description,2,4))=1 then CAST(substring(GLDT.Description,2,4) as numeric) end,
       Debit=Case when GLDT.Amount>0 then GLDT.Amount else 0 end,
       Credit=Case when GLDT.Amount<0 then -GLDT.Amount else 0 end,
       NetAmt=isnull(GLDT.Amount,0),0,  GLDT.Adjust,
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=IsNull(@ErrorMessage,' '),DetailLevel=@DetailLevel,RecType='D'
     
     FROM GLAC as GLAC
     Left Join GLAC as GLACSum on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct
     Left Join GLDT on GLDT.GLCo=a.GLCo and GLDT.GLAcct=a.GLAcct and GLDT.Mth>=@BegMonth and GLDT.Mth<=@EndMonth
     Left Join brvGLFSPart2 on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='D'
  
     --  may be taking too much time, trying not ordering and let Crystal Order  JRE 3/21/02
  --  order by GLAC.GLCo, GLAC.GLAcct
  --end
GO
GRANT EXECUTE ON  [dbo].[brptGLFinDet_SS] TO [public]
GO
