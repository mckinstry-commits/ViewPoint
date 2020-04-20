SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[brptHQOpenBatches] (@Co bCompany, @BMth bMonth='01/01/1950', @EMth bMonth, @OpenBatchesOnly bYN)
   as
/* spins through each batch table and lists the status of the batch */
   /* JRE 2/20/00  */
   /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                      fixed : using tables instead of views. Issue #20721 */
   /* Mod 8/24/04 E.T. for issue 25179, add begining month and change through month to 
                  ending month,  add Open Batches only parameter to stored procedure. */
   /* Issue 25906 Performance improvements "wiht (nolock)"  and review for missing Batch Tables  03/29/05 NF*/
   /* Issue 27543 Additional batch tables added to procedure.  05/24/05 NF */
   /* Issue 00000 Extend #batch.TableName from varchar(10) to varchar(100).  05/17/11 HH */
   begin
   set nocount on
   
   create table #batch
   (Co              tinyint             NULL,
    Mth             smalldatetime       NULL,
    BatchId         int	     NULL,
    TableName	 varchar(100)         NULL,
    Status          tinyint	     NULL)
   
   
   insert into #batch
   select distinct APEM.APCo, APEM.Mth, APEM.BatchId, TableName='APEM',isnull(HQBC.Status,9)  from APEM  with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APEM.APCo and HQBC.Mth=APEM.Mth and HQBC.BatchId=APEM.BatchId
   where APEM.Mth>=@BMth and APEM.Mth<=@EMth and APEM.APCo=@Co
   
   insert into #batch 
   select distinct APGL.APCo, APGL.Mth, APGL.BatchId, TableName='APGL',isnull(HQBC.Status,9)  from APGL with(nolock)
   left join HQBC  with(nolock) on HQBC.Co=APGL.APCo and HQBC.Mth=APGL.Mth and HQBC.BatchId=APGL.BatchId
   where APGL.Mth>=@BMth and APGL.Mth<=@EMth and APGL.APCo=@Co
   
   insert into #batch 
   select distinct APIN.APCo, APIN.Mth, APIN.BatchId, TableName='APIN',isnull(HQBC.Status,9)  from APIN with(nolock)
   left join HQBC  with(nolock) on HQBC.Co=APIN.APCo and HQBC.Mth=APIN.Mth and HQBC.BatchId=APIN.BatchId
   where APIN.Mth>=@BMth and APIN.Mth<=@EMth and APIN.APCo=@Co 
   
   insert into #batch 
   select distinct APJC.APCo, APJC.Mth, APJC.BatchId, TableName='APJC',isnull(HQBC.Status,9)  from APJC with(nolock)
   left join HQBC  with(nolock) on HQBC.Co=APJC.APCo and HQBC.Mth=APJC.Mth and HQBC.BatchId=APJC.BatchId
   where APJC.Mth>=@BMth and APJC.Mth<=@EMth and APJC.APCo=@Co 
   
   insert into #batch 
   select distinct APPG.APCo, APPG.Mth, APPG.BatchId, TableName='APPG',isnull(HQBC.Status,9)  from APPG with(nolock)
   left join HQBC  with(nolock) on HQBC.Co=APPG.APCo and HQBC.Mth=APPG.Mth and HQBC.BatchId=APPG.BatchId
   where APPG.Mth>=@BMth and APPG.Mth<=@EMth and APPG.APCo=@Co 
   
   insert into #batch 
   select distinct ARBC.ARCo, ARBC.Mth, ARBC.BatchId, TableName='ARBC',isnull(HQBC.Status,9)  from ARBC with(nolock)
   left join HQBC  with(nolock) on HQBC.Co=ARBC.ARCo and HQBC.Mth=ARBC.Mth and HQBC.BatchId=ARBC.BatchId
   where ARBC.Mth>=@BMth and ARBC.Mth<=@EMth and ARBC.ARCo=@Co 
   
   insert into #batch 
   select distinct ARBI.ARCo, ARBI.Mth, ARBI.BatchId, TableName='ARBI',isnull(HQBC.Status,9)  from ARBI with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBI.ARCo and HQBC.Mth=ARBI.Mth and HQBC.BatchId=ARBI.BatchId
   where ARBI.Mth>=@BMth and ARBI.Mth<=@EMth and ARBI.ARCo=@Co 
   
   insert into #batch 
   select distinct ARBJ.ARCo, ARBJ.Mth, ARBJ.BatchId, TableName='ARBJ',isnull(HQBC.Status,9)  from ARBJ with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBJ.ARCo and HQBC.Mth=ARBJ.Mth and HQBC.BatchId=ARBJ.BatchId
   where ARBJ.Mth>=@BMth and ARBJ.Mth<=@EMth and ARBJ.ARCo=@Co 
   
   insert into #batch 
   select distinct CMDA.CMCo, CMDA.Mth, CMDA.BatchId, TableName='CMDA',isnull(HQBC.Status,9)  from CMDA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=CMDA.CMCo and HQBC.Mth=CMDA.Mth and HQBC.BatchId=CMDA.BatchId
   where CMDA.Mth>=@BMth and CMDA.Mth<=@EMth and CMDA.CMCo=@Co 
   
   insert into #batch 
   select distinct APCD.Co, APCD.Mth, APCD.BatchId, TableName='APCD',isnull(HQBC.Status,9)  from APCD with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APCD.Co and HQBC.Mth=APCD.Mth and HQBC.BatchId=APCD.BatchId
   where APCD.Mth>=@BMth and APCD.Mth<=@EMth and APCD.Co=@Co 
   
   insert into #batch 
   
   select distinct APCT.Co, APCT.Mth, APCT.BatchId, TableName='APCT',isnull(HQBC.Status,9)  from APCT with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APCT.Co and HQBC.Mth=APCT.Mth and HQBC.BatchId=APCT.BatchId
   where APCT.Mth>=@BMth and APCT.Mth<=@EMth and APCT.Co=@Co  
   
   insert into #batch 
   select distinct APDB.Co, APDB.Mth, APDB.BatchId, TableName='APDB',isnull(HQBC.Status,9)  from APDB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APDB.Co and HQBC.Mth=APDB.Mth and HQBC.BatchId=APDB.BatchId
   where APDB.Mth>=@BMth and APDB.Mth<=@EMth and APDB.Co=@Co  
   
   insert into #batch 
   select distinct APHB.Co, APHB.Mth, APHB.BatchId, TableName='APHB',isnull(HQBC.Status,9)  from APHB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APHB.Co and HQBC.Mth=APHB.Mth and HQBC.BatchId=APHB.BatchId
   where APHB.Mth>=@BMth and APHB.Mth<=@EMth and APHB.Co=@Co  
   
   insert into #batch 
   select distinct APLB.Co, APLB.Mth, APLB.BatchId, TableName='APLB',isnull(HQBC.Status,9)  from APLB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APLB.Co and HQBC.Mth=APLB.Mth and HQBC.BatchId=APLB.BatchId
   where APLB.Mth>=@BMth and APLB.Mth<=@EMth and APLB.Co=@Co  
   
   insert into #batch 
   select distinct APPB.Co, APPB.Mth, APPB.BatchId, TableName='APPB',isnull(HQBC.Status,9)  from APPB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APPB.Co and HQBC.Mth=APPB.Mth and HQBC.BatchId=APPB.BatchId
   where APPB.Mth>=@BMth and APPB.Mth<=@EMth and APPB.Co=@Co  
   
   insert into #batch 
   select distinct APTB.Co, APTB.Mth, APTB.BatchId, TableName='APTB',isnull(HQBC.Status,9)  from APTB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=APTB.Co and HQBC.Mth=APTB.Mth and HQBC.BatchId=APTB.BatchId
   where APTB.Mth>=@BMth and APTB.Mth<=@EMth and APTB.Co=@Co  
   
   insert into #batch 
   select distinct ARBA.Co, ARBA.Mth, ARBA.BatchId, TableName='ARBA',isnull(HQBC.Status,9)  from ARBA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBA.Co and HQBC.Mth=ARBA.Mth and HQBC.BatchId=ARBA.BatchId
   where ARBA.Mth>=@BMth and ARBA.Mth<=@EMth and ARBA.Co=@Co 
   
   insert into #batch 
   select distinct ARBH.Co, ARBH.Mth, ARBH.BatchId, TableName='ARBH',isnull(HQBC.Status,9)  from ARBH with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBH.Co and HQBC.Mth=ARBH.Mth and HQBC.BatchId=ARBH.BatchId
   where ARBH.Mth>=@BMth and ARBH.Mth<=@EMth and ARBH.Co=@Co  
   
   insert into #batch 
   select distinct ARBL.Co, ARBL.Mth, ARBL.BatchId, TableName='ARBL',isnull(HQBC.Status,9)  from ARBL with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBL.Co and HQBC.Mth=ARBL.Mth and HQBC.BatchId=ARBL.BatchId
   where ARBL.Mth>=@BMth and ARBL.Mth<=@EMth and ARBL.Co=@Co  
   
   insert into #batch 
   select distinct ARBM.Co, ARBM.Mth, ARBM.BatchId, TableName='ARBM',isnull(HQBC.Status,9)  from ARBM with(nolock)
   left join HQBC with(nolock) on HQBC.Co=ARBM.Co and HQBC.Mth=ARBM.Mth and HQBC.BatchId=ARBM.BatchId
   where ARBM.Mth>=@BMth and ARBM.Mth<=@EMth and ARBM.Co=@Co  
   
   insert into #batch 
   select distinct CMDB.Co, CMDB.Mth, CMDB.BatchId, TableName='CMDB',isnull(HQBC.Status,9)  from CMDB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=CMDB.Co and HQBC.Mth=CMDB.Mth and HQBC.BatchId=CMDB.BatchId
   where CMDB.Mth>=@BMth and CMDB.Mth<=@EMth and CMDB.Co=@Co 
   
   insert into #batch 
   select distinct CMTA.Co, CMTA.Mth, CMTA.BatchId, TableName='CMTA',isnull(HQBC.Status,9)  from CMTA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=CMTA.Co and HQBC.Mth=CMTA.Mth and HQBC.BatchId=CMTA.BatchId
   where CMTA.Mth>=@BMth and CMTA.Mth<=@EMth and CMTA.Co=@Co  
   
   insert into #batch 
   select distinct CMTB.Co, CMTB.Mth, CMTB.BatchId, TableName='CMTB',isnull(HQBC.Status,9)  from CMTB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=CMTB.Co and HQBC.Mth=CMTB.Mth and HQBC.BatchId=CMTB.BatchId
   where CMTB.Mth>=@BMth and CMTB.Mth<=@EMth and CMTB.Co=@Co  
   
   insert into #batch 
   select distinct EMBF.Co, EMBF.Mth, EMBF.BatchId, TableName='EMBF',isnull(HQBC.Status,9)  from EMBF with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMBF.Co and HQBC.Mth=EMBF.Mth and HQBC.BatchId=EMBF.BatchId
   where EMBF.Mth>=@BMth and EMBF.Mth<=@EMth and EMBF.Co=@Co  
   
   
   insert into #batch 
   select distinct EMLB.Co, EMLB.Mth, EMLB.BatchId, TableName='EMLB',isnull(HQBC.Status,9)  from EMLB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMLB.Co and HQBC.Mth=EMLB.Mth and HQBC.BatchId=EMLB.BatchId
   where EMLB.Mth>=@BMth and EMLB.Mth<=@EMth and EMLB.Co=@Co 
   
   insert into #batch 
   select distinct GLDA.Co, GLDA.Mth, GLDA.BatchId, TableName='GLDA',isnull(HQBC.Status,9)  from GLDA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLDA.Co and HQBC.Mth=GLDA.Mth and HQBC.BatchId=GLDA.BatchId
   where GLDA.Mth>=@BMth and GLDA.Mth<=@EMth and GLDA.Co=@Co  
   
   insert into #batch 
   select distinct GLDB.Co, GLDB.Mth, GLDB.BatchId, TableName='GLDB',isnull(HQBC.Status,9)  from GLDB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLDB.Co and HQBC.Mth=GLDB.Mth and HQBC.BatchId=GLDB.BatchId
   where GLDB.Mth>=@BMth and GLDB.Mth<=@EMth and GLDB.Co=@Co 
   
   insert into #batch 
   select distinct GLJA.Co, GLJA.Mth, GLJA.BatchId, TableName='GLJA',isnull(HQBC.Status,9)  from GLJA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLJA.Co and HQBC.Mth=GLJA.Mth and HQBC.BatchId=GLJA.BatchId
   where GLJA.Mth>=@BMth and GLJA.Mth<=@EMth and GLJA.Co=@Co 
   
   insert into #batch 
   select distinct GLJB.Co, GLJB.Mth, GLJB.BatchId, TableName='GLJB',isnull(HQBC.Status,9)  from GLJB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLJB.Co and HQBC.Mth=GLJB.Mth and HQBC.BatchId=GLJB.BatchId
   where GLJB.Mth>=@BMth and GLJB.Mth<=@EMth and GLJB.Co=@Co
   
   insert into #batch 
   select distinct GLRA.Co, GLRA.Mth, GLRA.BatchId, TableName='GLRA',isnull(HQBC.Status,9)  from GLRA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLRA.Co and HQBC.Mth=GLRA.Mth and HQBC.BatchId=GLRA.BatchId
   where GLRA.Mth>=@BMth and GLRA.Mth<=@EMth and GLRA.Co=@Co
   
   insert into #batch 
   select distinct GLRB.Co, GLRB.Mth, GLRB.BatchId, TableName='GLRB',isnull(HQBC.Status,9)  from GLRB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=GLRB.Co and HQBC.Mth=GLRB.Mth and HQBC.BatchId=GLRB.BatchId
   where GLRB.Mth>=@BMth and GLRB.Mth<=@EMth and GLRB.Co=@Co  
   
   insert into #batch 
   select distinct HRBB.Co, HRBB.Mth, HRBB.BatchId, TableName='HRBB',isnull(HQBC.Status,9)  from HRBB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=HRBB.Co and HQBC.Mth=HRBB.Mth and HQBC.BatchId=HRBB.BatchId
   where HRBB.Mth>=@BMth and HRBB.Mth<=@EMth and HRBB.Co=@Co  
   
   insert into #batch 
   select distinct HRBD.Co, HRBD.Mth, HRBD.BatchId, TableName='HRBD',isnull(HQBC.Status,9)  from HRBD with(nolock)
   left join HQBC with(nolock) on HQBC.Co=HRBD.Co and HQBC.Mth=HRBD.Mth and HQBC.BatchId=HRBD.BatchId
   where HRBD.Mth>=@BMth and HRBD.Mth<=@EMth and HRBD.Co=@Co 
   
   insert into #batch 
   select distinct INAB.Co, INAB.Mth, INAB.BatchId, TableName='INAB',isnull(HQBC.Status,9)  from INAB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INAB.Co and HQBC.Mth=INAB.Mth and HQBC.BatchId=INAB.BatchId
   where INAB.Mth>=@BMth and INAB.Mth<=@EMth and INAB.Co=@Co  
   
   insert into #batch 
   select distinct INPB.Co, INPB.Mth, INPB.BatchId, TableName='INPB',isnull(HQBC.Status,9)  from INPB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INPB.Co and HQBC.Mth=INPB.Mth and HQBC.BatchId=INPB.BatchId
   where INPB.Mth>=@BMth and INPB.Mth<=@EMth and INPB.Co=@Co  
   
   insert into #batch 
   select distinct INPD.Co, INPD.Mth, INPD.BatchId, TableName='INPD',isnull(HQBC.Status,9)  from INPD with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INPD.Co and HQBC.Mth=INPD.Mth and HQBC.BatchId=INPD.BatchId
   where INPD.Mth>=@BMth and INPD.Mth<=@EMth and INPD.Co=@Co 
   
   insert into #batch 
   select distinct INTB.Co, INTB.Mth, INTB.BatchId, TableName='INTB',isnull(HQBC.Status,9)  from INTB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INTB.Co and HQBC.Mth=INTB.Mth and HQBC.BatchId=INTB.BatchId
   where INTB.Mth>=@BMth and INTB.Mth<=@EMth and INTB.Co=@Co 
   
   insert into #batch 
   select distinct JBAL.Co, JBAL.Mth, JBAL.BatchId, TableName='JBAL',isnull(HQBC.Status,9)  from JBAL with(nolock) 
   left join HQBC  with(nolock) on HQBC.Co=JBAL.Co and HQBC.Mth=JBAL.Mth and HQBC.BatchId=JBAL.BatchId
   where JBAL.Mth>=@BMth and JBAL.Mth<=@EMth and JBAL.Co=@Co  
   
   insert into #batch 
   select distinct JBAR.Co, JBAR.Mth, JBAR.BatchId, TableName='JBAR',isnull(HQBC.Status,9)  from JBAR with(nolock)
   left join HQBC with(nolock)  on HQBC.Co=JBAR.Co and HQBC.Mth=JBAR.Mth and HQBC.BatchId=JBAR.BatchId
   where JBAR.Mth>=@BMth and JBAR.Mth<=@EMth and JBAR.Co=@Co  
   
   insert into #batch 
   select distinct JCCB.Co, JCCB.Mth, JCCB.BatchId, TableName='JCCB',isnull(HQBC.Status,9)  from JCCB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCCB.Co and HQBC.Mth=JCCB.Mth and HQBC.BatchId=JCCB.BatchId
   where JCCB.Mth>=@BMth and JCCB.Mth<=@EMth and JCCB.Co=@Co  
   
   insert into #batch 
   select distinct JCCC.Co, JCCC.Mth, JCCC.BatchId, TableName='JCCC',isnull(HQBC.Status,9)  from JCCC with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCCC.Co and HQBC.Mth=JCCC.Mth and HQBC.BatchId=JCCC.BatchId
   where JCCC.Mth>=@BMth and JCCC.Mth<=@EMth and JCCC.Co=@Co  
   
   insert into #batch 
   select distinct JCIB.Co, JCIB.Mth, JCIB.BatchId, TableName='JCIB',isnull(HQBC.Status,9)  from JCIB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCIB.Co and HQBC.Mth=JCIB.Mth and HQBC.BatchId=JCIB.BatchId
   where JCIB.Mth>=@BMth and JCIB.Mth<=@EMth and JCIB.Co=@Co 
   
   insert into #batch 
   select distinct JCPB.Co, JCPB.Mth, JCPB.BatchId, TableName='JCPB',isnull(HQBC.Status,9)  from JCPB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCPB.Co and HQBC.Mth=JCPB.Mth and HQBC.BatchId=JCPB.BatchId
   where JCPB.Mth>=@BMth and JCPB.Mth<=@EMth and JCPB.Co=@Co 
   
   insert into #batch 
   select distinct JCPP.Co, JCPP.Mth, JCPP.BatchId, TableName='JCPP',isnull(HQBC.Status,9)  from JCPP with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCPP.Co and HQBC.Mth=JCPP.Mth and HQBC.BatchId=JCPP.BatchId
   where JCPP.Mth>=@BMth and JCPP.Mth<=@EMth and JCPP.Co=@Co 
   
   insert into #batch 
   select distinct JCXA.Co, JCXA.Mth, JCXA.BatchId, TableName='JCXA',isnull(HQBC.Status,9)  from JCXA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCXA.Co and HQBC.Mth=JCXA.Mth and HQBC.BatchId=JCXA.BatchId
   where JCXA.Mth>=@BMth and JCXA.Mth<=@EMth and JCXA.Co=@Co 
   
   insert into #batch 
   select distinct JCXB.Co, JCXB.Mth, JCXB.BatchId, TableName='JCXB',isnull(HQBC.Status,9)  from JCXB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCXB.Co and HQBC.Mth=JCXB.Mth and HQBC.BatchId=JCXB.BatchId
   where JCXB.Mth>=@BMth and JCXB.Mth<=@EMth and JCXB.Co=@Co  
   
   insert into #batch 
   select distinct POCB.Co, POCB.Mth, POCB.BatchId, TableName='POCB',isnull(HQBC.Status,9)  from POCB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POCB.Co and HQBC.Mth=POCB.Mth and HQBC.BatchId=POCB.BatchId
   where POCB.Mth>=@BMth and POCB.Mth<=@EMth and POCB.Co=@Co  
   
   insert into #batch 
   select distinct POHB.Co, POHB.Mth, POHB.BatchId, TableName='POHB',isnull(HQBC.Status,9)  from POHB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POHB.Co and HQBC.Mth=POHB.Mth and HQBC.BatchId=POHB.BatchId
   where POHB.Mth>=@BMth and POHB.Mth<=@EMth and POHB.Co=@Co 
   
   insert into #batch 
   select distinct POIB.Co, POIB.Mth, POIB.BatchId, TableName='POIB',isnull(HQBC.Status,9)  from POIB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POIB.Co and HQBC.Mth=POIB.Mth and HQBC.BatchId=POIB.BatchId
   where POIB.Mth>=@BMth and POIB.Mth<=@EMth and POIB.Co=@Co  
   
   insert into #batch 
   select distinct PORB.Co, PORB.Mth, PORB.BatchId, TableName='PORB',isnull(HQBC.Status,9)  from PORB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORB.Co and HQBC.Mth=PORB.Mth and HQBC.BatchId=PORB.BatchId
   where PORB.Mth>=@BMth and PORB.Mth<=@EMth and PORB.Co=@Co 
   
   insert into #batch 
   select distinct POXB.Co, POXB.Mth, POXB.BatchId, TableName='POXB',isnull(HQBC.Status,9)  from POXB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POXB.Co and HQBC.Mth=POXB.Mth and HQBC.BatchId=POXB.BatchId
   where POXB.Mth>=@BMth and POXB.Mth<=@EMth and POXB.Co=@Co 
   
   insert into #batch 
   select distinct PRAB.Co, PRAB.Mth, PRAB.BatchId, TableName='PRAB',isnull(HQBC.Status,9)  from PRAB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PRAB.Co and HQBC.Mth=PRAB.Mth and HQBC.BatchId=PRAB.BatchId
   where PRAB.Mth>=@BMth and PRAB.Mth<=@EMth and PRAB.Co=@Co
   
   insert into #batch 
   select distinct PRTB.Co, PRTB.Mth, PRTB.BatchId, TableName='PRTB',isnull(HQBC.Status,9)  from PRTB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PRTB.Co and HQBC.Mth=PRTB.Mth and HQBC.BatchId=PRTB.BatchId
   where PRTB.Mth>=@BMth and PRTB.Mth<=@EMth and PRTB.Co=@Co 
   
   insert into #batch 
   select distinct SLCB.Co, SLCB.Mth, SLCB.BatchId, TableName='SLCB',isnull(HQBC.Status,9)  from SLCB with(nolock) 
   left join HQBC with(nolock) on HQBC.Co=SLCB.Co and HQBC.Mth=SLCB.Mth and HQBC.BatchId=SLCB.BatchId
   where SLCB.Mth>=@BMth and SLCB.Mth<=@EMth and SLCB.Co=@Co  
   
   insert into #batch 
   select distinct SLHB.Co, SLHB.Mth, SLHB.BatchId, TableName='SLHB',isnull(HQBC.Status,9)  from SLHB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=SLHB.Co and HQBC.Mth=SLHB.Mth and HQBC.BatchId=SLHB.BatchId
   where SLHB.Mth>=@BMth and SLHB.Mth<=@EMth and SLHB.Co=@Co  
   
   insert into #batch 
   select distinct SLIB.Co, SLIB.Mth, SLIB.BatchId, TableName='SLIB',isnull(HQBC.Status,9)  from SLIB with(nolock)
   left join HQBC with(nolock) on HQBC.Co=SLIB.Co and HQBC.Mth=SLIB.Mth and HQBC.BatchId=SLIB.BatchId
   where SLIB.Mth>=@BMth and SLIB.Mth<=@EMth and SLIB.Co=@Co  
   
   insert into #batch 
   select distinct SLXB.Co, SLXB.Mth, SLXB.BatchId, TableName='SLXB',isnull(HQBC.Status,9)  from SLXB with(nolock) 
   left join HQBC with(nolock) on HQBC.Co=SLXB.Co and HQBC.Mth=SLXB.Mth and HQBC.BatchId=SLXB.BatchId
   where SLXB.Mth>=@BMth and SLXB.Mth<=@EMth and SLXB.Co=@Co 
   
   insert into #batch 
   select distinct EMBC.EMCo, EMBC.Mth, EMBC.BatchId, TableName='EMBC',isnull(HQBC.Status,9)  from EMBC with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMBC.EMCo and HQBC.Mth=EMBC.Mth and HQBC.BatchId=EMBC.BatchId
   where EMBC.Mth>=@BMth and EMBC.Mth<=@EMth and EMBC.EMCo=@Co 
   
   insert into #batch 
   select distinct EMGL.EMCo, EMGL.Mth, EMGL.BatchId, TableName='EMGL',isnull(HQBC.Status,9)  from EMGL with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMGL.EMCo and HQBC.Mth=EMGL.Mth and HQBC.BatchId=EMGL.BatchId
   where EMGL.Mth>=@BMth and EMGL.Mth<=@EMth and EMGL.EMCo=@Co  
   
   insert into #batch 
   select distinct EMIN.EMCo, EMIN.Mth, EMIN.BatchId, TableName='EMIN',isnull(HQBC.Status,9)  from EMIN with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMIN.EMCo and HQBC.Mth=EMIN.Mth and HQBC.BatchId=EMIN.BatchId
   where EMIN.Mth>=@BMth and EMIN.Mth<=@EMth and EMIN.EMCo=@Co 
   
   insert into #batch 
   select distinct EMJC.EMCo, EMJC.Mth, EMJC.BatchId, TableName='EMJC',isnull(HQBC.Status,9)  from EMJC with(nolock)
   left join HQBC with(nolock) on HQBC.Co=EMJC.EMCo and HQBC.Mth=EMJC.Mth and HQBC.BatchId=EMJC.BatchId
   where EMJC.Mth>=@BMth and EMJC.Mth<=@EMth and EMJC.EMCo=@Co  
   
   insert into #batch 
   select distinct INAG.INCo, INAG.Mth, INAG.BatchId, TableName='INAG',isnull(HQBC.Status,9)  from INAG with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INAG.INCo and HQBC.Mth=INAG.Mth and HQBC.BatchId=INAG.BatchId
   where INAG.Mth>=@BMth and INAG.Mth<=@EMth and INAG.INCo=@Co 
   
   insert into #batch 
   select distinct INPG.INCo, INPG.Mth, INPG.BatchId, TableName='INPG',isnull(HQBC.Status,9)  from INPG with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INPG.INCo and HQBC.Mth=INPG.Mth and HQBC.BatchId=INPG.BatchId
   where INPG.Mth>=@BMth and INPG.Mth<=@EMth and INPG.INCo=@Co  
   
   insert into #batch 
   select distinct INTG.INCo, INTG.Mth, INTG.BatchId, TableName='INTG',isnull(HQBC.Status,9)  from INTG with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INTG.INCo and HQBC.Mth=INTG.Mth and HQBC.BatchId=INTG.BatchId
   where INTG.Mth>=@BMth and INTG.Mth<=@EMth and INTG.INCo=@Co  
   
   insert into #batch 
   select distinct JBBM.JBCo, JBBM.Mth, JBBM.BatchId, TableName='JBBM',isnull(HQBC.Status,9)  from JBBM with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JBBM.JBCo and HQBC.Mth=JBBM.Mth and HQBC.BatchId=JBBM.BatchId
   where JBBM.Mth>=@BMth and JBBM.Mth<=@EMth and JBBM.JBCo=@Co 
   
   insert into #batch 
   select distinct JBGL.JBCo, JBGL.Mth, JBGL.BatchId, TableName='JBGL',isnull(HQBC.Status,9)  from JBGL with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JBGL.JBCo and HQBC.Mth=JBGL.Mth and HQBC.BatchId=JBGL.BatchId
   where JBGL.Mth>=@BMth and JBGL.Mth<=@EMth and JBGL.JBCo=@Co 
   
   insert into #batch 
   select distinct JBJC.JBCo, JBJC.Mth, JBJC.BatchId, TableName='JBJC',isnull(HQBC.Status,9)  from JBJC with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JBJC.JBCo and HQBC.Mth=JBJC.Mth and HQBC.BatchId=JBJC.BatchId
   where JBJC.Mth>=@BMth and JBJC.Mth<=@EMth and JBJC.JBCo=@Co 
   
   insert into #batch 
   select distinct JCDA.JCCo, JCDA.Mth, JCDA.BatchId, TableName='JCDA',isnull(HQBC.Status,9)  from JCDA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCDA.JCCo and HQBC.Mth=JCDA.Mth and HQBC.BatchId=JCDA.BatchId
   where JCDA.Mth>=@BMth and JCDA.Mth<=@EMth and JCDA.JCCo=@Co
   
   insert into #batch 
   select distinct JCIA.JCCo, JCIA.Mth, JCIA.BatchId, TableName='JCIA',isnull(HQBC.Status,9)  from JCIA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCIA.JCCo and HQBC.Mth=JCIA.Mth and HQBC.BatchId=JCIA.BatchId
   where JCIA.Mth>=@BMth and JCIA.Mth<=@EMth and JCIA.JCCo=@Co 
   
   insert into #batch 
   select distinct POCA.POCo, POCA.Mth, POCA.BatchId, TableName='POCA',isnull(HQBC.Status,9)  from POCA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POCA.POCo and HQBC.Mth=POCA.Mth and HQBC.BatchId=POCA.BatchId
   where POCA.Mth>=@BMth and POCA.Mth<=@EMth and POCA.POCo=@Co 
   
   insert into #batch 
   select distinct POCI.POCo, POCI.Mth, POCI.BatchId, TableName='POCI',isnull(HQBC.Status,9)  from POCI with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POCI.POCo and HQBC.Mth=POCI.Mth and HQBC.BatchId=POCI.BatchId
   where POCI.Mth>=@BMth and POCI.Mth<=@EMth and POCI.POCo=@Co 
   
   insert into #batch 
   select distinct POIA.POCo, POIA.Mth, POIA.BatchId, TableName='POIA',isnull(HQBC.Status,9)  from POIA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POIA.POCo and HQBC.Mth=POIA.Mth and HQBC.BatchId=POIA.BatchId
   where POIA.Mth>=@BMth and POIA.Mth<=@EMth and POIA.POCo=@Co  
   
   insert into #batch 
   select distinct POII.POCo, POII.Mth, POII.BatchId, TableName='POII',isnull(HQBC.Status,9)  from POII with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POII.POCo and HQBC.Mth=POII.Mth and HQBC.BatchId=POII.BatchId
   where POII.Mth>=@BMth and POII.Mth<=@EMth and POII.POCo=@Co
   
   insert into #batch 
   select distinct PORA.POCo, PORA.Mth, PORA.BatchId, TableName='PORA',isnull(HQBC.Status,9)  from PORA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORA.POCo and HQBC.Mth=PORA.Mth and HQBC.BatchId=PORA.BatchId
   where PORA.Mth>=@BMth and PORA.Mth<=@EMth and PORA.POCo=@Co 
   
   insert into #batch 
   select distinct PORI.POCo, PORI.Mth, PORI.BatchId, TableName='PORI',isnull(HQBC.Status,9)  from PORI with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORI.POCo and HQBC.Mth=PORI.Mth and HQBC.BatchId=PORI.BatchId
   where PORI.Mth>=@BMth and PORI.Mth<=@EMth and PORI.POCo=@Co 
   
   insert into #batch 
   select distinct POXA.POCo, POXA.Mth, POXA.BatchId, TableName='POXA',isnull(HQBC.Status,9)  from POXA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POXA.POCo and HQBC.Mth=POXA.Mth and HQBC.BatchId=POXA.BatchId
   where POXA.Mth>=@BMth and POXA.Mth<=@EMth and POXA.POCo=@Co  
   
   insert into #batch 
   select distinct POXI.POCo, POXI.Mth, POXI.BatchId, TableName='POXI',isnull(HQBC.Status,9)  from POXI with(nolock)
   left join HQBC with(nolock) on HQBC.Co=POXI.POCo and HQBC.Mth=POXI.Mth and HQBC.BatchId=POXI.BatchId
   where POXI.Mth>=@BMth and POXI.Mth<=@EMth and POXI.POCo=@Co 
   
   insert into #batch 
   select distinct SLCA.SLCo, SLCA.Mth, SLCA.BatchId, TableName='SLCA',isnull(HQBC.Status,9)  from SLCA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=SLCA.SLCo and HQBC.Mth=SLCA.Mth and HQBC.BatchId=SLCA.BatchId
   where SLCA.Mth>=@BMth and SLCA.Mth<=@EMth and SLCA.SLCo=@Co 
   
   insert into #batch 
   select distinct SLIA.SLCo, SLIA.Mth, SLIA.BatchId, TableName='SLIA',isnull(HQBC.Status,9)  from SLIA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=SLIA.SLCo and HQBC.Mth=SLIA.Mth and HQBC.BatchId=SLIA.BatchId
   where SLIA.Mth>=@BMth and SLIA.Mth<=@EMth and SLIA.SLCo=@Co 
   
   insert into #batch 
   select distinct SLXA.SLCo, SLXA.Mth, SLXA.BatchId, TableName='SLXA',isnull(HQBC.Status,9)  from SLXA with(nolock)
   left join HQBC with(nolock) on HQBC.Co=SLXA.SLCo and HQBC.Mth=SLXA.Mth and HQBC.BatchId=SLXA.BatchId
   where SLXA.Mth>=@BMth and SLXA.Mth<=@EMth and SLXA.SLCo=@Co 
   
   /*Additional Batch Tables added to SP.  Issue 27543 05/24/05 NF*/
   
   insert into #batch							
   select distinct	INCJ.INCo,	INCJ.Mth,	INCJ.BatchId,	TableName = 'INCJ',isnull(HQBC.Status,9)  from 	INCJ	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INCJ.INCo and HQBC.Mth=INCJ.Mth and HQBC.BatchId=INCJ.BatchId							
   where INCJ.Mth>=@BMth and INCJ.Mth<=@EMth and INCJ.INCo=@Co							
   
   insert into #batch							
   select distinct	INIB.Co,	INIB.Mth,	INIB.BatchId,	TableName = 'INIB',isnull(HQBC.Status,9)  from 	INIB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INIB.Co and HQBC.Mth=INIB.Mth and HQBC.BatchId=INIB.BatchId							
   where INIB.Mth>=@BMth and INIB.Mth<=@EMth and INIB.Co=@Co							
   
   insert into #batch							
   select distinct	INJC.INCo,	INJC.Mth,	INJC.BatchId,	TableName = 'INJC',isnull(HQBC.Status,9)  from 	INJC	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INJC.INCo and HQBC.Mth=INJC.Mth and HQBC.BatchId=INJC.BatchId							
   where INJC.Mth>=@BMth and INJC.Mth<=@EMth and INJC.INCo=@Co							
   
   insert into #batch							
   select distinct	INMB.Co,	INMB.Mth,	INMB.BatchId,	TableName = 'INMB',isnull(HQBC.Status,9)  from 	INMB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INMB.Co and HQBC.Mth=INMB.Mth and HQBC.BatchId=INMB.BatchId							
   where INMB.Mth>=@BMth and INMB.Mth<=@EMth and INMB.Co=@Co							
   
   insert into #batch							
   select distinct	INXB.Co,	INXB.Mth,	INXB.BatchId,	TableName = 'INXB',isnull(HQBC.Status,9)  from 	INXB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INXB.Co and HQBC.Mth=INXB.Mth and HQBC.BatchId=INXB.BatchId							
   where INXB.Mth>=@BMth and INXB.Mth<=@EMth and INXB.Co=@Co							
   
   insert into #batch							
   select distinct	INXI.INCo,	INXI.Mth,	INXI.BatchId,	TableName = 'INXI',isnull(HQBC.Status,9)  from 	INXI	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INXI.INCo and HQBC.Mth=INXI.Mth and HQBC.BatchId=INXI.BatchId							
   where INXI.Mth>=@BMth and INXI.Mth<=@EMth and INXI.INCo=@Co							
   
   insert into #batch							
   select distinct	INXJ.INCo,	INXJ.Mth,	INXJ.BatchId,	TableName = 'INXJ',isnull(HQBC.Status,9)  from 	INXJ	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=INXJ.INCo and HQBC.Mth=INXJ.Mth and HQBC.BatchId=INXJ.BatchId							
   where INXJ.Mth>=@BMth and INXJ.Mth<=@EMth and INXJ.INCo=@Co							
   
   insert into #batch							
   select distinct	JCIN.JCCo,	JCIN.Mth,	JCIN.BatchId,	TableName = 'JCIN',isnull(HQBC.Status,9)  from 	JCIN	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=JCIN.JCCo and HQBC.Mth=JCIN.Mth and HQBC.BatchId=JCIN.BatchId							
   where JCIN.Mth>=@BMth and JCIN.Mth<=@EMth and JCIN.JCCo=@Co							
   
   insert into #batch							
   select distinct	MSAP.MSCo,	MSAP.Mth,	MSAP.BatchId,	TableName = 'MSAP',isnull(HQBC.Status,9)  from 	MSAP	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSAP.MSCo and HQBC.Mth=MSAP.Mth and HQBC.BatchId=MSAP.BatchId							
   where MSAP.Mth>=@BMth and MSAP.Mth<=@EMth and MSAP.MSCo=@Co							
   
   
   insert into #batch							
   select distinct	MSAR.MSCo,	MSAR.Mth,	MSAR.BatchId,	TableName = 'MSAR',isnull(HQBC.Status,9)  from 	MSAR	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSAR.MSCo and HQBC.Mth=MSAR.Mth and HQBC.BatchId=MSAR.BatchId							
   where MSAR.Mth>=@BMth and MSAR.Mth<=@EMth and MSAR.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSEM.MSCo,	MSEM.Mth,	MSEM.BatchId,	TableName = 'MSEM',isnull(HQBC.Status,9)  from 	MSEM	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSEM.MSCo and HQBC.Mth=MSEM.Mth and HQBC.BatchId=MSEM.BatchId							
   where MSEM.Mth>=@BMth and MSEM.Mth<=@EMth and MSEM.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSGL.MSCo,	MSGL.Mth,	MSGL.BatchId,	TableName = 'MSGL',isnull(HQBC.Status,9)  from 	MSGL	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSGL.MSCo and HQBC.Mth=MSGL.Mth and HQBC.BatchId=MSGL.BatchId							
   where MSGL.Mth>=@BMth and MSGL.Mth<=@EMth and MSGL.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSHB.Co,	MSHB.Mth,	MSHB.BatchId,	TableName = 'MSHB',isnull(HQBC.Status,9)  from 	MSHB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSHB.Co and HQBC.Mth=MSHB.Mth and HQBC.BatchId=MSHB.BatchId							
   where MSHB.Mth>=@BMth and MSHB.Mth<=@EMth and MSHB.Co=@Co							
   
   insert into #batch							
   select distinct	MSIB.Co,	MSIB.Mth,	MSIB.BatchId,	TableName = 'MSIB',isnull(HQBC.Status,9)  from 	MSIB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSIB.Co and HQBC.Mth=MSIB.Mth and HQBC.BatchId=MSIB.BatchId							
   where MSIB.Mth>=@BMth and MSIB.Mth<=@EMth and MSIB.Co=@Co							
   
   insert into #batch							
   select distinct	MSID.Co,	MSID.Mth,	MSID.BatchId,	TableName = 'MSID',isnull(HQBC.Status,9)  from 	MSID	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSID.Co and HQBC.Mth=MSID.Mth and HQBC.BatchId=MSID.BatchId							
   where MSID.Mth>=@BMth and MSID.Mth<=@EMth and MSID.Co=@Co							
   
   insert into #batch							
   select distinct	MSIG.MSCo,	MSIG.Mth,	MSIG.BatchId,	TableName = 'MSIG',isnull(HQBC.Status,9)  from 	MSIG	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSIG.MSCo and HQBC.Mth=MSIG.Mth and HQBC.BatchId=MSIG.BatchId							
   where MSIG.Mth>=@BMth and MSIG.Mth<=@EMth and MSIG.MSCo=@Co							
   
   
   insert into #batch							
   select distinct	MSIN.MSCo,	MSIN.Mth,	MSIN.BatchId,	TableName = 'MSIN',isnull(HQBC.Status,9)  from 	MSIN	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSIN.MSCo and HQBC.Mth=MSIN.Mth and HQBC.BatchId=MSIN.BatchId							
   where MSIN.Mth>=@BMth and MSIN.Mth<=@EMth and MSIN.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSJC.MSCo,	MSJC.Mth,	MSJC.BatchId,	TableName = 'MSJC',isnull(HQBC.Status,9)  from 	MSJC	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSJC.MSCo and HQBC.Mth=MSJC.Mth and HQBC.BatchId=MSJC.BatchId							
   where MSJC.Mth>=@BMth and MSJC.Mth<=@EMth and MSJC.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSLB.Co,	MSLB.Mth,	MSLB.BatchId,	TableName = 'MSLB',isnull(HQBC.Status,9)  from 	MSLB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSLB.Co and HQBC.Mth=MSLB.Mth and HQBC.BatchId=MSLB.BatchId							
   where MSLB.Mth>=@BMth and MSLB.Mth<=@EMth and MSLB.Co=@Co							
   
   insert into #batch							
   select distinct	MSMA.MSCo,	MSMA.Mth,	MSMA.BatchId,	TableName = 'MSMA',isnull(HQBC.Status,9)  from 	MSMA	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSMA.MSCo and HQBC.Mth=MSMA.Mth and HQBC.BatchId=MSMA.BatchId							
   where MSMA.Mth>=@BMth and MSMA.Mth<=@EMth and MSMA.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSMG.MSCo,	MSMG.Mth,	MSMG.BatchId,	TableName = 'MSMG',isnull(HQBC.Status,9)  from 	MSMG	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSMG.MSCo and HQBC.Mth=MSMG.Mth and HQBC.BatchId=MSMG.BatchId							
   where MSMG.Mth>=@BMth and MSMG.Mth<=@EMth and MSMG.MSCo=@Co							
   
   
   insert into #batch							
   select distinct	MSMH.Co,	MSMH.Mth,	MSMH.BatchId,	TableName = 'MSMH',isnull(HQBC.Status,9)  from 	MSMH	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSMH.Co and HQBC.Mth=MSMH.Mth and HQBC.BatchId=MSMH.BatchId							
   where MSMH.Mth>=@BMth and MSMH.Mth<=@EMth and MSMH.Co=@Co							
   
   insert into #batch							
   select distinct	MSMX.MSCo,	MSMX.Mth,	MSMX.BatchId,	TableName = 'MSMX',isnull(HQBC.Status,9)  from 	MSMX	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSMX.MSCo and HQBC.Mth=MSMX.Mth and HQBC.BatchId=MSMX.BatchId							
   where MSMX.Mth>=@BMth and MSMX.Mth<=@EMth and MSMX.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSPA.MSCo,	MSPA.Mth,	MSPA.BatchId,	TableName = 'MSPA',isnull(HQBC.Status,9)  from 	MSPA	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSPA.MSCo and HQBC.Mth=MSPA.Mth and HQBC.BatchId=MSPA.BatchId							
   where MSPA.Mth>=@BMth and MSPA.Mth<=@EMth and MSPA.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSRB.MSCo,	MSRB.Mth,	MSRB.BatchId,	TableName = 'MSRB',isnull(HQBC.Status,9)  from 	MSRB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSRB.MSCo and HQBC.Mth=MSRB.Mth and HQBC.BatchId=MSRB.BatchId							
   where MSRB.Mth>=@BMth and MSRB.Mth<=@EMth and MSRB.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSTB.Co,	MSTB.Mth,	MSTB.BatchId,	TableName = 'MSTB',isnull(HQBC.Status,9)  from 	MSTB	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSTB.Co and HQBC.Mth=MSTB.Mth and HQBC.BatchId=MSTB.BatchId							
   where MSTB.Mth>=@BMth and MSTB.Mth<=@EMth and MSTB.Co=@Co							
   
   insert into #batch							
   select distinct	MSWG.MSCo,	MSWG.Mth,	MSWG.BatchId,	TableName = 'MSWG',isnull(HQBC.Status,9)  from 	MSWG	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSWG.MSCo and HQBC.Mth=MSWG.Mth and HQBC.BatchId=MSWG.BatchId							
   where MSWG.Mth>=@BMth and MSWG.Mth<=@EMth and MSWG.MSCo=@Co							
   
   insert into #batch							
   select distinct	MSWH.Co,	MSWH.Mth,	MSWH.BatchId,	TableName = 'MSWH',isnull(HQBC.Status,9)  from 	MSWH	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=MSWH.Co and HQBC.Mth=MSWH.Mth and HQBC.BatchId=MSWH.BatchId							
   where MSWH.Mth>=@BMth and MSWH.Mth<=@EMth and MSWH.Co=@Co							
   
   insert into #batch							
   select distinct	PMBC.Co,	PMBC.Mth,	PMBC.BatchId,	TableName = 'PMBC',isnull(HQBC.Status,9)  from 	PMBC	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PMBC.Co and HQBC.Mth=PMBC.Mth and HQBC.BatchId=PMBC.BatchId							
   where PMBC.Mth>=@BMth and PMBC.Mth<=@EMth and PMBC.Co=@Co							
   
   insert into #batch							
   select distinct	PORE.POCo,	PORE.Mth,	PORE.BatchId,	TableName = 'PORE',isnull(HQBC.Status,9)  from 	PORE	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORE.POCo and HQBC.Mth=PORE.Mth and HQBC.BatchId=PORE.BatchId							
   where PORE.Mth>=@BMth and PORE.Mth<=@EMth and PORE.POCo=@Co							
   
   insert into #batch							
   select distinct	PORG.POCo,	PORG.Mth,	PORG.BatchId,	TableName = 'PORG',isnull(HQBC.Status,9)  from 	PORG	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORG.POCo and HQBC.Mth=PORG.Mth and HQBC.BatchId=PORG.BatchId							
   where PORG.Mth>=@BMth and PORG.Mth<=@EMth and PORG.POCo=@Co							
   
   insert into #batch							
   select distinct	PORH.Co,	PORH.Mth,	PORH.BatchId,	TableName = 'PORH',isnull(HQBC.Status,9)  from 	PORH	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORH.Co and HQBC.Mth=PORH.Mth and HQBC.BatchId=PORH.BatchId							
   where PORH.Mth>=@BMth and PORH.Mth<=@EMth and PORH.Co=@Co							
   
   insert into #batch							
   select distinct	PORJ.POCo,	PORJ.Mth,	PORJ.BatchId,	TableName = 'PORJ',isnull(HQBC.Status,9)  from 	PORJ	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORJ.POCo and HQBC.Mth=PORJ.Mth and HQBC.BatchId=PORJ.BatchId							
   where PORJ.Mth>=@BMth and PORJ.Mth<=@EMth and PORJ.POCo=@Co							
   
   insert into #batch							
   select distinct	PORN.POCo,	PORN.Mth,	PORN.BatchId,	TableName = 'PORN',isnull(HQBC.Status,9)  from 	PORN	with(nolock)
   left join HQBC with(nolock) on HQBC.Co=PORN.POCo and HQBC.Mth=PORN.Mth and HQBC.BatchId=PORN.BatchId							
   where PORN.Mth>=@BMth and PORN.Mth<=@EMth and PORN.POCo=@Co
   
   create index biBatchHQ on #batch (Co, Mth, BatchId) WITH FILLFACTOR = 95
   
   insert into #batch
   select Co, Mth, BatchId, TableName, Status
   from HQBC with(nolock) 
   where Mth>=@BMth and Mth<=@EMth and Co=@Co and
   1=(case when @OpenBatchesOnly='Y' then 
   	(case when HQBC.Status=0 then 1 
   	when HQBC.Status=1 then 1
   	when HQBC.Status=2 then 1
   	when HQBC.Status=3 then 1
   	when HQBC.Status=4 then 1
   	when HQBC.Status=9 then 1
   	end)
   	When @OpenBatchesOnly='N' then 1
   else 0 end)
   and not exists (select * from #batch b where b.Co=HQBC.Co and b.Mth=HQBC.Mth and b.BatchId=HQBC.BatchId)
   
   set nocount off
   
   select a.Co,a.Mth,a.BatchId,a.TableName,Status=case when a.Status >=7 then 9 else a.Status end, 
          HQBCStatus=HQBC.Status, HQBC.Source, HQBC.InUseBy, HQBC.DateCreated, HQBC.CreatedBy, HQBC.Rstrict, HQBC.PRGroup, HQBC.PREndDate,
          HQBC.DatePosted, HQBC.DateClosed , UpdateNotes=HQBC.Notes, HQCO.Name
   from #batch a  
   join HQCO with(nolock) on HQCO.HQCo=a.Co
   left join HQBC with(nolock) on HQBC.Co=a.Co and HQBC.Mth=a.Mth and HQBC.BatchId=a.BatchId
   where 
   1=(case when @OpenBatchesOnly='Y' then 
   	(case when HQBC.Status=0 then 1 
   	when HQBC.Status=1 then 1
   	when HQBC.Status=2 then 1
   	when HQBC.Status=3 then 1
   	when HQBC.Status=4 then 1
   	when HQBC.Status=9 then 1
   	end)
   	When @OpenBatchesOnly='N' then 1
   else 0 end) 
   end

GO
GRANT EXECUTE ON  [dbo].[brptHQOpenBatches] TO [public]
GO
