SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   View [dbo].[brvGLFSSum] as 
    Select GLAC.*,
      SummaryDesc=isnull(GLACSum.Description,GLAC.Description),
      SummaryActType=GLACSum.AcctType,
      SummarySubType=GLACSum.SubType,
      SummaryActive=GLACSum.Active,
      SummaryNormBal=GLACSum.NormBal,
      GLDT.Mth,GLDT.Adjust,GLDT.SourceCo,GLDT.Source,GLDT.Jrnl,GLDT.GLRef,
      Debit=Case 
        when GLDT.Amount>0 then GLDT.Amount
        else 0 end,
      Credit=Case 
        when GLDT.Amount<0 then -GLDT.Amount
        else 0 end,
      NetAmt=isnull(GLDT.Amount,0),
    GLDT.GLTrans,GLDT.ActDate,TransDesc=GLDT.Description, GLDT.BatchId,
    
      GLFP.FiscalPd, GLFP.FiscalYr , GLYB.FYEMO, BeginBal=isnull(GLYB.BeginBal,0),
    brvGLFSPart2.Part2I,brvGLFSPart2.Part2IDesc, brvGLFSPart3.Part3I,brvGLFSPart3.Part3IDesc
    ,
    /*
    "P1Desc"=(select GLPD.Description from GLPD where GLPD.GLCo=GLAC.GLCo and GLPD.PartNo=1),
    "P2Desc"=(select GLPD.Description from GLPD where GLPD.GLCo=GLAC.GLCo and GLPD.PartNo=2)
    */
    /*
     "P1Desc"=Case when GLPD.PartNo=1 then GLPD.Description
       else "" end,
       "P2Desc"=Case when GLPD.PartNo=2 then GLPD.Description
       else "" end,
       "P3Desc"=Case when GLPD.PartNo=3 then GLPD.Description
       else "" end
    */
    "P1Desc"=GLPD1.Description,"P2Desc"=GLPD2.Description,"P3Desc"=GLPD3.Description,
    "P4Desc"=GLPD4.Description
    /*,"P5Desc"=GLPD5.Description,"P6Desc"=GLPD6.Description*/
    
    FROM (GLAC 
    Left Join GLAC as GLACSum 
    on GLACSum.GLCo=GLAC.GLCo and GLACSum.GLAcct=GLAC.SummaryAcct
    Left Join GLDT as GLDT on GLDT.GLCo=GLAC.GLCo and GLDT.GLAcct=GLAC.GLAcct
    Left Join GLFP on GLFP.GLCo=GLDT.GLCo and GLFP.Mth=GLDT.Mth)
    Left Join GLYB on GLYB.GLCo=GLDT.GLCo and GLYB.GLAcct=GLAC.GLAcct and 
    /* DATEPART(Month,GLYB.FYEMO)=GLFP.FiscalPd and */DATEPART(year,GLYB.FYEMO)=GLFP.FiscalYr
    Left Join brvGLFSPart2 on brvGLFSPart2.GLCo=GLAC.GLCo and brvGLFSPart2.Part2I=GLAC.Part2
    Left Join brvGLFSPart3 on brvGLFSPart3.GLCo=GLAC.GLCo and brvGLFSPart3.Part3I=GLAC.Part3
    Left Join GLPD as GLPD1 on GLPD1.GLCo=GLAC.GLCo and GLPD1.PartNo=1
    Left Join GLPD as GLPD2 on GLPD2.GLCo=GLAC.GLCo and GLPD2.PartNo=2
    Left Join GLPD as GLPD3 on GLPD3.GLCo=GLAC.GLCo and GLPD3.PartNo=3
    Left Join GLPD as GLPD4 on GLPD4.GLCo=GLAC.GLCo and GLPD4.PartNo=4
    /*Left Join GLPD as GLPD5 on GLPD5.GLCo=GLAC.GLCo and GLPD5.PartNo=5
    Left Join GLPD as GLPD6 on GLPD6.GLCo=GLAC.GLCo and GLPD6.PartNo=6*/

GO
GRANT SELECT ON  [dbo].[brvGLFSSum] TO [public]
GRANT INSERT ON  [dbo].[brvGLFSSum] TO [public]
GRANT DELETE ON  [dbo].[brvGLFSSum] TO [public]
GRANT UPDATE ON  [dbo].[brvGLFSSum] TO [public]
GO
