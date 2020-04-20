SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE            PROC [dbo].[brptGLFinDetSelect]
       (@GLCo bCompany, @BegAcct bGLAcct='          ', @EndAcct bGLAcct='zzzzzzzzzz',
       @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050', @IncludeInactive char(1)='N',  
       @Source varchar(20)=' ', @Journal varchar(20)=' ', @DetailLevel char(1) = 'D',
       @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60))
    	/*created JRE Issue 26210  11/15/04 */
    	/* Issue 23660 Remove the #GLDetail table for Beg Balance and add Union statement with RecType='B' 03/04/04 NF */
         /* Issue 26210 Moved the select statement into a secondary procedure for performance reasons */ 
         /*Issue 27073 Fixed where clause to restrict by the first 2 characters of the Source field in GLDT and GLAS 5/31/05 DH*/ 	
         /*Issue 27073 Added @Source is null to Beg Balance Select statement 6/1/05 DH*/
 	/*Issue 29223 Add @IncludeInactive to Where clause 7/6/5 NF*/
       as
       set nocount on
  	
      if @Source=' '
  	begin
  		Select @Source = Null
  	end
      else
  	begin
  		select @Source=',' + @Source + ','
  	end
      
      if @Journal=' '
  	begin
  		Select @Journal = Null
  	end
       else
  	begin
  		select @Journal=',' + @Journal + ','
  	end    
  
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
  
  
  select GLAC.GLCo,GLAC.GLAcct,GLAC.Description,GLAC.AcctType,
       GLAC.SubType,GLAC.NormBal,GLAC.InterfaceDetail,GLAC.Active,
       GLAC.SummaryAcct,GLAC.CashAccrual,GLAC.CashOffAcct,
       GLAC.Part1,GLAC.Part2,GLAC.Part3,GLAC.Part4,GLAC.Part5,GLAC.Part6,
       SummaryDesc=COALESCE(@ErrorMessage,GLACSum.Description,GLAC.Description),
       SummaryActType=GLACSum.AcctType,
       SummarySubType=GLACSum.SubType, 
       SummaryActive=GLACSum.Active,
       SummaryNormBal=GLACSum.NormBal,
       BeginBal = (IsNull(GLYB.BeginBal,0) + IsNull(GLBL.NetAmt,0)),
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
  	(select GLCo, GLAcct, NetAmt=sum(GLBL.NetActivity) from GLBL with (nolock)
            where GLBL.GLCo=@GLCo
            and GLBL.GLAcct>=@BegAcct and GLBL.GLAcct<=@EndAcctFull and GLBL.Mth<@BegMonth and GLBL.Mth>=@FYBMO
  	  group by GLBL.GLCo,GLBL.GLAcct) as GLBL
  	on GLAC.GLCo=GLBL.GLCo and GLAC.GLAcct=GLBL.GLAcct
     Left Join GLYB with (nolock) on GLAC.GLCo=GLYB.GLCo and GLAC.GLAcct=GLYB.GLAcct and GLYB.FYEMO = @FYEMO
     Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
  
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo  and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @Source is null and @Journal is null
       and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
  
  Union All
    
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
       Mth=isnull(GLBL.Mth,'01/01/1950'), GLTrans=null, Jrnl=null, GLRef=null,
       SourceCo=Null, Source=Null, ActDate=null, DetailDesc=null, BatchId=null,
       Debit=Case when GLBL.NetActivity >0 then GLBL.NetActivity else 0 end,
       Credit=Case when GLBL.NetActivity <0 then -GLBL.NetActivity else 0 end,
       NetAmt=isnull(GLBL.NetActivity,0), Adjust='N',
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='A'
     FROM GLAC  with (nolock)
     Left Join GLAC   as GLACSum with (nolock) on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     /*  Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct  */
     Left Join GLBL with (nolock) on GLBL.GLCo=GLAC.GLCo and GLBL.GLAcct=GLAC.GLAcct and GLBL.Mth>=@BegMonth and GLBL.Mth<=@EndMonth
     Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo
       and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='A'
       and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
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
       BeginBal=0,
       Mth = '01/01/1950', GLTrans=null, Jrnl = null, GLRef = null,
       SourceCo = null, Source = null, ActDate=null, DetailDesc=null, BatchId=null,
       Debit=Case when GLYB.NetAdj>0 then GLYB.NetAdj else 0 end,
       Credit=Case when GLYB.NetAdj<0 then -GLYB.NetAdj else 0 end,
       NetAmt=isnull(GLYB.NetAdj,0), Adjust = 'Y',
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='A'
     FROM GLAC  with (nolock)
     Left Join GLAC  as GLACSum  with (nolock) on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     /*  Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct  */
     Left Join GLYB with (nolock) on GLYB.GLCo=GLAC.GLCo and GLYB.GLAcct=GLAC.GLAcct and GLYB.FYEMO=@FYEMO and GLYB.NetAdj <> 0
     Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='A'
        and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
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
       BeginBal=0,
       Mth=isnull(GLAS.Mth,'01/01/1950'), GLTrans=null, GLAS.Jrnl, GLAS.GLRef,
       GLAS.SourceCo, GLAS.Source, ActDate=null, DetailDesc=GLRF.Description, BatchId=null,
       Debit=Case when GLAS.NetAmt>0 then GLAS.NetAmt else 0 end,
       Credit=Case when GLAS.NetAmt<0 then -GLAS.NetAmt else 0 end,
       NetAmt=isnull(GLAS.NetAmt,0), IsNull(GLAS.Adjust,'N'),
       brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc,
       P1Desc, P2Desc,P3Desc,P4Desc,P5Desc,P6Desc,
     CoName=HQCO.Name,  BegAcct=@BegAcct,EndAcct=@EndAcct,BegMonth=@BegMonth,
     EndMonth=@EndMonth,ErrorMessage=@ErrorMessage,DetailLevel=@DetailLevel,RecType='R'
   FROM GLAC  with (nolock) 
     Left Join GLAC  as GLACSum with (nolock) on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
     /*  Left Join #GLDetail a on GLAC.GLCo=a.GLCo and GLAC.GLAcct=a.GLAcct  */
     Left Join GLAS with (nolock) on GLAS.GLCo=GLAC.GLCo and GLAS.GLAcct=GLAC.GLAcct and GLAS.Mth>=@BegMonth and GLAS.Mth<=@EndMonth
     Left Join GLRF with (nolock) on GLRF.GLCo=GLAS.GLCo and GLRF.Mth=GLAS.Mth and GLRF.Jrnl=GLAS.Jrnl and GLRF.GLRef=GLAS.GLRef
     Left Join brvGLFSPart2 with (nolock) on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.PartNo=2 and brvGLFSPart2.Part2I=GLAC.Part2
     Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
     Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
     Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
     where GLAC.GLCo=@GLCo  and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @DetailLevel='R'
       and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
       and (@Source is null or CHARINDEX(',' + Left(GLAS.Source,2) +',',@Source)>0)
       and (@Journal is null or CHARINDEX(',' + GLAS.Jrnl +',',@Journal)>0)
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
       and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
       and (@Source is null or CHARINDEX(',' + Left(GLDT.Source,2) +',',@Source)>0)
       and (@Journal is null or CHARINDEX(',' + GLDT.Jrnl +',',@Journal)>0)
  
     --  may be taking too much time, trying not ordering and let Crystal Order  JRE 3/21/02
  --  order by GLAC.GLCo, GLAC.GLAcct
  --end

GO
GRANT EXECUTE ON  [dbo].[brptGLFinDetSelect] TO [public]
GO
