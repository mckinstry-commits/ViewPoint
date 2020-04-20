SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspcmdbaudit    Script Date: 8/28/99 9:33:45 AM ******/
   CREATE  Procedure [dbo].[bspcmdbaudit]
   @Company tinyint=null,
   @BatchId int=null,
   @MTH smalldatetime = '11/1/96'
   as
   set nocount on
   /* create temp table of CM Records from the Audit Batch*/
   begin
   
   create table #CMRecords 
   
   (Co tinyint null, 
   BatchId int null,
   OLDNEW char(3) null,
   BatchSeq int null,
   BatchTransType char(1) null,
   CMTrans int null,
   CMAcct smallint null,
   CMTransType tinyint null,
   ActDate smalldatetime null,
   Description varchar(30) null,
   Amount float null,
   CMRef varchar(10) null,
   CMRefSeq tinyint null,
   Payee varchar(20) null,
   GLCo tinyint null,
   CMGLAcct char(20) null,
   GLAcct char(20) null,
   Void char(1) null)
   
   /*insert CM Records */
   insert into #CMRecords
   select CMDB.Co ,CMDB.BatchId ,'NEW',CMDB.BatchSeq,CMDB.BatchTransType,
   CMDB.CMTrans,CMDB.CMAcct,
   CMDB.CMTransType ,CMDB.ActDate,CMDB.Description,CMDB.Amount,CMDB.CMRef,
   CMDB.CMRefSeq,CMDB.Payee,CMDB.GLCo,CMDB.CMGLAcct,CMDB.GLAcct,CMDB.Void
   from CMDB
   where CMDB.BatchTransType in ('A','C')
   and CMDB.Co=@Company and CMDB.BatchId=@BatchId and Mth=@MTH
   
   
   insert into #CMRecords
   select CMDB.Co ,CMDB.BatchId ,'OLD',CMDB.BatchSeq,CMDB.BatchTransType,
   CMDB.CMTrans,CMDB.OldCMAcct,CMDB.CMTransType ,CMDB.OldActDate,
   CMDB.OldDesc,CMDB.OldAmount,CMDB.OldCMRef,
   CMDB.OldCMRefSeq,CMDB.OldPayee,CMDB.OldGLCo,CMDB.OldCMGLAcct,
   CMDB.OldGLAcct,CMDB.OldVoid
   from CMDB
   where CMDB.BatchTransType in ('C','D')
   and CMDB.Co=@Company and CMDB.BatchId=@BatchId and Mth=@MTH
   
   select a.Co,a.BatchId,a.OLDNEW,a.BatchSeq,a.BatchTransType,a.CMTrans,a.CMAcct,
   CMacctDescription=CMAC.Description,
   a.CMTransType,a.ActDate,a.Description,a.Amount,a.CMRef,a.CMRefSeq,
   a.Payee,a.GLCo,a.CMGLAcct,CMGLDescription=c.Description,
   a.GLAcct,GLDescription=g.Description,a.Void,
   BatchMonth=@MTH,
   DSPMth=Convert(varchar(2),DATEPART(mm, @MTH)) + '/'
         +  SubString(Convert(varchar(4),DATEPART(yy, @MTH)),3,2)
    
   from #CMRecords a
   left join GLAC g on a.GLCo=g.GLCo and a.GLAcct=g.GLAcct
   left join GLAC c on a.GLCo=c.GLCo and a.CMGLAcct=c.GLAcct
   left join CMAC  on a.Co=CMAC.CMCo and a.CMAcct=CMAC.CMAcct
   end

GO
GRANT EXECUTE ON  [dbo].[bspcmdbaudit] TO [public]
GO
