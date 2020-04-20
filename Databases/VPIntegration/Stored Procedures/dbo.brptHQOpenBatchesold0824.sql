SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc dbo.brptHQOpenBatchesold0824 (@Co bCompany, @Mth bMonth)
 as
 /* spins through each batch table and lists the status of the batch */
 /* JRE 2/20/00  */
 /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                    fixed : using tables instead of views. Issue #20721 */
 begin
 set nocount on
 
 create table #batch
 (Co              tinyint             NULL,
  Mth             smalldatetime       NULL,
  BatchId         int	     NULL,
  TableName	 varchar(10)         NULL,
  Status          tinyint	     NULL)
 
 
 insert into #batch
 select distinct j.APCo, j.Mth, j.BatchId, TableName='APEM',isnull(h.Status,9)  from APEM j 
 left join HQBC h on h.Co=j.APCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.APCo=@Co
 
 insert into #batch 
 select distinct j.APCo, j.Mth, j.BatchId, TableName='APGL',isnull(h.Status,9)  from APGL j 
 left join HQBC h on h.Co=j.APCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.APCo=@Co
 
 insert into #batch 
 select distinct j.APCo, j.Mth, j.BatchId, TableName='APIN',isnull(h.Status,9)  from APIN j
 left join HQBC h on h.Co=j.APCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.APCo=@Co 
 
 insert into #batch 
 select distinct j.APCo, j.Mth, j.BatchId, TableName='APJC',isnull(h.Status,9)  from APJC j 
 left join HQBC h on h.Co=j.APCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.APCo=@Co 
 
 insert into #batch 
 select distinct j.APCo, j.Mth, j.BatchId, TableName='APPG',isnull(h.Status,9)  from APPG j 
 left join HQBC h on h.Co=j.APCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.APCo=@Co 
 
 insert into #batch 
 select distinct j.ARCo, j.Mth, j.BatchId, TableName='ARBC',isnull(h.Status,9)  from ARBC j 
 left join HQBC h on h.Co=j.ARCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.ARCo=@Co 
 
 insert into #batch 
 select distinct j.ARCo, j.Mth, j.BatchId, TableName='ARBI',isnull(h.Status,9)  from ARBI j 
 left join HQBC h on h.Co=j.ARCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.ARCo=@Co 
 
 insert into #batch 
 select distinct j.ARCo, j.Mth, j.BatchId, TableName='ARBJ',isnull(h.Status,9)  from ARBJ j 
 left join HQBC h on h.Co=j.ARCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.ARCo=@Co 
 
 insert into #batch 
 select distinct j.CMCo, j.Mth, j.BatchId, TableName='CMDA',isnull(h.Status,9)  from CMDA j 
 left join HQBC h on h.Co=j.CMCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.CMCo=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APCD',isnull(h.Status,9)  from APCD j
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APCT',isnull(h.Status,9)  from APCT j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APDB',isnull(h.Status,9)  from APDB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APHB',isnull(h.Status,9)  from APHB j
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APLB',isnull(h.Status,9)  from APLB j
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APPB',isnull(h.Status,9)  from APPB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='APTB',isnull(h.Status,9)  from APTB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='ARBA',isnull(h.Status,9)  from ARBA j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='ARBH',isnull(h.Status,9)  from ARBH j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='ARBL',isnull(h.Status,9)  from ARBL j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='ARBM',isnull(h.Status,9)  from ARBM j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='CMDB',isnull(h.Status,9)  from CMDB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='CMTA',isnull(h.Status,9)  from CMTA j
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='CMTB',isnull(h.Status,9)  from CMTB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='EMBF',isnull(h.Status,9)  from EMBF j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='EMBM',isnull(h.Status,9)  from EMBM j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='EMLB',isnull(h.Status,9)  from EMLB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLDA',isnull(h.Status,9)  from GLDA j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLDB',isnull(h.Status,9)  from GLDB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLJA',isnull(h.Status,9)  from GLJA j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLJB',isnull(h.Status,9)  from GLJB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLRA',isnull(h.Status,9)  from GLRA j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='GLRB',isnull(h.Status,9)  from GLRB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='HRBB',isnull(h.Status,9)  from HRBB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='HRBD',isnull(h.Status,9)  from HRBD j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='INAB',isnull(h.Status,9)  from INAB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='INPB',isnull(h.Status,9)  from INPB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='INPD',isnull(h.Status,9)  from INPD j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='INTB',isnull(h.Status,9)  from INTB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JBAL',isnull(h.Status,9)  from JBAL j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JBAR',isnull(h.Status,9)  from JBAR j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCCB',isnull(h.Status,9)  from JCCB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCCC',isnull(h.Status,9)  from JCCC j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCIB',isnull(h.Status,9)  from JCIB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCPB',isnull(h.Status,9)  from JCPB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCPP',isnull(h.Status,9)  from JCPP j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCXA',isnull(h.Status,9)  from JCXA j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='JCXB',isnull(h.Status,9)  from JCXB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='POCB',isnull(h.Status,9)  from POCB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='POHB',isnull(h.Status,9)  from POHB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='POIB',isnull(h.Status,9)  from POIB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='PORB',isnull(h.Status,9)  from PORB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='POXB',isnull(h.Status,9)  from POXB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='PRAB',isnull(h.Status,9)  from PRAB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='PRTB',isnull(h.Status,9)  from PRTB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='SLCB',isnull(h.Status,9)  from SLCB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='SLHB',isnull(h.Status,9)  from SLHB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='SLIB',isnull(h.Status,9)  from SLIB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co  
 
 insert into #batch 
 select distinct j.Co, j.Mth, j.BatchId, TableName='SLXB',isnull(h.Status,9)  from SLXB j 
 left join HQBC h on h.Co=j.Co and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.Co=@Co 
 
 insert into #batch 
 select distinct j.EMCo, j.Mth, j.BatchId, TableName='EMBC',isnull(h.Status,9)  from EMBC j 
 left join HQBC h on h.Co=j.EMCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.EMCo=@Co 
 
 insert into #batch 
 select distinct j.EMCo, j.Mth, j.BatchId, TableName='EMGL',isnull(h.Status,9)  from EMGL j 
 left join HQBC h on h.Co=j.EMCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.EMCo=@Co  
 
 insert into #batch 
 select distinct j.EMCo, j.Mth, j.BatchId, TableName='EMIN',isnull(h.Status,9)  from EMIN j 
 left join HQBC h on h.Co=j.EMCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.EMCo=@Co 
 
 insert into #batch 
 select distinct j.EMCo, j.Mth, j.BatchId, TableName='EMJC',isnull(h.Status,9)  from EMJC j 
 left join HQBC h on h.Co=j.EMCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.EMCo=@Co  
 
 insert into #batch 
 select distinct j.INCo, j.Mth, j.BatchId, TableName='INAG',isnull(h.Status,9)  from INAG j 
 left join HQBC h on h.Co=j.INCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.INCo=@Co 
 
 insert into #batch 
 select distinct j.INCo, j.Mth, j.BatchId, TableName='INPG',isnull(h.Status,9)  from INPG j 
 left join HQBC h on h.Co=j.INCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.INCo=@Co  
 
 insert into #batch 
 select distinct j.INCo, j.Mth, j.BatchId, TableName='INTG',isnull(h.Status,9)  from INTG j
 left join HQBC h on h.Co=j.INCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.INCo=@Co  
 
 insert into #batch 
 select distinct j.JBCo, j.Mth, j.BatchId, TableName='JBBM',isnull(h.Status,9)  from JBBM j 
 left join HQBC h on h.Co=j.JBCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.JBCo=@Co 
 
 insert into #batch 
 select distinct j.JBCo, j.Mth, j.BatchId, TableName='JBGL',isnull(h.Status,9)  from JBGL j 
 left join HQBC h on h.Co=j.JBCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.JBCo=@Co 
 
 insert into #batch 
 select distinct j.JBCo, j.Mth, j.BatchId, TableName='JBJC',isnull(h.Status,9)  from JBJC j 
 left join HQBC h on h.Co=j.JBCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.JBCo=@Co 
 
 insert into #batch 
 select distinct j.JCCo, j.Mth, j.BatchId, TableName='JCDA',isnull(h.Status,9)  from JCDA j 
 left join HQBC h on h.Co=j.JCCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.JCCo=@Co
 
 insert into #batch 
 select distinct j.JCCo, j.Mth, j.BatchId, TableName='JCIA',isnull(h.Status,9)  from JCIA j 
 left join HQBC h on h.Co=j.JCCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.JCCo=@Co 
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POCA',isnull(h.Status,9)  from POCA j 
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co 
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POCI',isnull(h.Status,9)  from POCI j
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co 
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POIA',isnull(h.Status,9)  from POIA j
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co  
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POII',isnull(h.Status,9)  from POII j 
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='PORA',isnull(h.Status,9)  from PORA j 
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co 
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='PORI',isnull(h.Status,9)  from PORI j 
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co 
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POXA',isnull(h.Status,9)  from POXA j
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co  
 
 insert into #batch 
 select distinct j.POCo, j.Mth, j.BatchId, TableName='POXI',isnull(h.Status,9)  from POXI j 
 left join HQBC h on h.Co=j.POCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.POCo=@Co 
 
 insert into #batch 
 select distinct j.SLCo, j.Mth, j.BatchId, TableName='SLCA',isnull(h.Status,9)  from SLCA j 
 left join HQBC h on h.Co=j.SLCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.SLCo=@Co 
 
 insert into #batch 
 select distinct j.SLCo, j.Mth, j.BatchId, TableName='SLIA',isnull(h.Status,9)  from SLIA j 
 left join HQBC h on h.Co=j.SLCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.SLCo=@Co 
 
 insert into #batch 
 select distinct j.SLCo, j.Mth, j.BatchId, TableName='SLXA',isnull(h.Status,9)  from SLXA j 
 left join HQBC h on h.Co=j.SLCo and h.Mth=j.Mth and h.BatchId=j.BatchId
 where j.Mth<=@Mth and j.SLCo=@Co 
 
 insert into #batch
 select Co, Mth, BatchId, TableName, Status
 from HQBC c where Mth<=@Mth and Co=@Co 
 and not exists (select * from #batch b where b.Co=c.Co and b.Mth=c.Mth and b.BatchId=c.BatchId)
 
 set nocount on
 
 select a.Co,a.Mth,a.BatchId,a.TableName,Status=case when a.Status >=7 then 9 else a.Status end, 
        HQBCStatus=c.Status, c.Source, c.InUseBy, c.DateCreated,c.CreatedBy, c.Rstrict, c.PRGroup, c.PREndDate,
        c.DatePosted, c.DateClosed , h.Name
 from #batch a   
 join HQCO h on h.HQCo=a.Co
 left join HQBC c on c.Co=a.Co and c.Mth=a.Mth and c.BatchId=a.BatchId
 end
GO
GRANT EXECUTE ON  [dbo].[brptHQOpenBatchesold0824] TO [public]
GO
