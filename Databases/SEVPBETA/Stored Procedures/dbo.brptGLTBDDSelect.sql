SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptGLFinDet    Script Date: 8/28/99 9:33:49 AM ******/
     /****** Object:  PROC dbo.brptGLFinDet    Script Date: 3/3/97 2:24:47 PM ******/
     --drop PROC brptGLTBDD
    CREATE                   PROC [dbo].[brptGLTBDDSelect]
     (@GLCo bCompany, @BegAcct bGLAcct=' ', @EndAcct bGLAcct='zzzzzzzzzz',
     @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050', @IncludeInactive char(1)='N',
     @Source varchar(20)=' ',@Journal varchar(20)=' ', @DetailLevel char(1) = 'D',
     @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60))
     /*created 8/26/97 */
     /*changed report to use GLAC instead of GLAC for security*/
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                        fixed : using tables instead of views. Issue #20721 */
     /* Mod 4/29/03 JRE changed #GLDetail.GLCo from NOT Null to Null Issue 21042 
        Mod 6/12/03 DH Removed UNIQUE from clustered index on GLDetail - caused error in Crystal 9
        Issue 20721*
        Mod 8/5/03 DH Issue 22016.  Remmed out update section that added net activity a second time to the
                                    Beginning Balance. */
    /*  Issue 25905 Added with(nolock) to the from and join statements NF 11/11/04 */
    /*  Issue 29150 Change to two SP like the other GL Trial Balance reports NF 08/11/05 */ 
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
     from GLCO with(nolock)
     Left Join GLPD as GLPD1 with(nolock) on GLPD1.GLCo=GLCO.GLCo and GLPD1.PartNo=1
     Left Join GLPD as GLPD2 with(nolock) on GLPD2.GLCo=GLCO.GLCo and GLPD2.PartNo=2
     Left Join GLPD as GLPD3 with(nolock) on GLPD3.GLCo=GLCO.GLCo and GLPD3.PartNo=3
     Left Join GLPD as GLPD4 with(nolock) on GLPD4.GLCo=GLCO.GLCo and GLPD4.PartNo=4
     Left Join GLPD as GLPD5 with(nolock) on GLPD5.GLCo=GLCO.GLCo and GLPD5.PartNo=5
     Left Join GLPD as GLPD6 with(nolock) on GLPD6.GLCo=GLCO.GLCo and GLPD6.PartNo=6
     where GLCO.GLCo=@GLCo
    
    
    
     /* Begin Balance */
    
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
         MthBegBal=0,
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
       Left Join brvGLFSPart3 with (nolock) on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.PartNo=3 and brvGLFSPart3.Part3I=GLAC.Part3
    
       Left Join #GLParts on GLAC.GLCo=#GLParts.GLCo
       Join HQCO with (nolock) on HQCO.HQCo=GLAC.GLCo
       where GLAC.GLCo=@GLCo  and GLAC.GLAcct>=@BegAcct and GLAC.GLAcct<=@EndAcctFull and @Source is null and @Journal is null
         and GLAC.Active=(Case when @IncludeInactive = 'N' then 'Y' else GLAC.Active end)
   UNION ALL  
    
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
         MthBegBal=(Select sum(z.NetAmt) from GLAS z
                    where GLDT.GLCo = z.GLCo and GLDT.GLAcct = z.GLAcct and z.Mth >=@BegMonth and z.Mth < GLDT.Mth),
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

GO
GRANT EXECUTE ON  [dbo].[brptGLTBDDSelect] TO [public]
GO
