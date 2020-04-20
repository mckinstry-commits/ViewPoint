SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptJCContractDeleteList    Script Date: 8/28/99 9:35:02 AM ******/
CREATE        proc [dbo].[brptJCContractDeleteList]

/***********************************************************
* CREATED BY: 		JRE 5/20/02   t 
* MODIFIED By :	 	AA 8/29/02
*					GF 06/25/2010 - issue #135813 expanded SL to 30 characters
*					TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)                 
* 
*
* USAGE:
* Prints audit list of possible errors when purging contracts 
* For Crystal Reports
*
* TYPE DEFINITION:
* INPUT PARAMETERS
*   JCCo to validate against
*   Contract  Contract to validate or
*   Month Month to validate

* OUTPUT PARAMETERS
*
*   @msg      error message if error occurs otherwise Description of Contract
* RETURN VALUE
*   0         success
*   1         Failure
* Issue 25912 Added with(nolock) to the from and join statements NF 11/11/04 
*****************************************************/

(@Company tinyint = 0, @Contract bContract = null) --, @Mth bMonth= null)
as
set nocount on
      
      declare @rcode int, @UseJobBilling bYN, @Status tinyint, @cursoropen tinyint, @validcount tinyint,
              @opendelete int, @tablename varchar(30), @sqlstring varchar(255), @sql1 varchar(30), @openpoitem int,
              @po varchar(30), @poitem bItem, @openslitem int, @sl VARCHAR(30), @slitem bItem, @slunits bUnits
    
      select @rcode = 0, @opendelete =0, @openpoitem=0, @openslitem=0
    
    /* create a table for the list of contracts to delete */
    create table #JCContracts (JCCo tinyint not null, Contract varchar(10) not null)
    create clustered index biJCContract on #JCContracts (JCCo, Contract)
    
    /* insert contracts to delete */ 
    if isnull(@Contract,'')='' 
    begin  --if there is no @contract then assume all contracts closed on or before the month 
    	insert into #JCContracts (JCCo, Contract)
    	select JCCo, Contract from JCCM with(nolock)
    -- where JCCM.JCCo=@Company and JCCM.ContractStatus=3 and JCCM.MonthClosed<=@Mth 
    end
    else
    begin -- insert the @contract passed in 
        insert into #JCContracts (JCCo, Contract)
        select @Company, @Contract
    end
    
    create table #JCCloseErrors (JCCo tinyint not null, Contract varchar(10) not null, Job varchar(10) null, 
        Co tinyint null, Mth smalldatetime null, BatchId int null, TableName varchar(10) null, Msg varchar(250) null)
    
         --ARBH
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, a.Contract, null, a.Co, a.Mth, a.BatchId, 'ARBH', 'Contract(s) in AR Batch '+Source+' BatchSeq='+convert(varchar(7),BatchSeq)
    	 from ARBH a with(nolock)
         join #JCContracts t with(nolock) on  a.JCCo=t.JCCo and a.Contract=t.Contract
    
         --JBIN
         insert into #JCCloseErrors 
    	 select distinct a.JBCo, a.Contract, null, a.JBCo, a.BillMonth, null,'JBIN', 'Contract(s) in JBIN BillMonth:'+
    		convert(varchar(8),BillMonth,1)+' BillNumber '+convert(varchar(12),BillNumber)
    	 from JBIN a with(nolock)
         join #JCContracts t with(nolock) on  a.JBCo=t.JCCo and a.Contract=t.Contract
    	 where InvStatus in ('A', 'C', 'D')
    
         --JCIA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, a.Contract, null, a.JCCo, a.Mth, a.BatchId, 'JCIA','Contract(s) in JC Revenue Adjustments Batch'
    	 from JCIA a with(nolock)
         join #JCContracts t with(nolock) on  a.JCCo=t.JCCo and a.Contract=t.Contract
    
         --JCIB
         insert into #JCCloseErrors 
    	 select distinct a.Co, a.Contract, null, a.Co, a.Mth, a.BatchId, 'JCIB','Contract(s) in JC Revenue Adjustments Batch'
    	 from JCIB a with(nolock)
         join #JCContracts t with(nolock) on  a.Co=t.JCCo and a.Contract=t.Contract
    
         --JCCC
         insert into #JCCloseErrors 
    	 select distinct a.Co, a.Contract, null, a.Co, a.Mth, a.BatchId, 'JCCC','Contract(s) in JC Close Batch'
    	 from JCCC a with(nolock)
         join #JCContracts t with(nolock) on  a.Co=t.JCCo and a.Contract=t.Contract
    
         --JCXB
         -- Ok if in close batch
        -- insert into #JCCloseErrors 
    	-- select distinct a.Co, a.Contract, null, a.Co, a.Mth, a.BatchId, 'JCXB','Contract(s) in JC Batch'
    	-- from JCXB a with(nolock)
        -- join #JCContracts t on  a.Co=t.JCCo and a.Contract=t.Contract
    
         --APUL
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.APCo, UIMth, null, 'APUL', 'Job in Unapproved Invoice'
    	 from APUL a with(nolock)
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    
         --APRL
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.APCo, null, null, 'APRL', 'Job in Recurring Invoice #'+a.InvId
    	 from APRL a with(nolock)
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         --APLB
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'APLB', 'Job in AP Entry Batch'
    	 from APLB a with(nolock)
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         insert into #JCCloseErrors 
         select distinct a.OldJCCo, j.Contract, a.OldJob, a.Co, a.Mth, a.BatchId, 'APLB', 'Old Job in AP Entry Batch'
    	 from APLB a with(nolock)
         join JCJM j with(nolock) on a.OldJCCo=j.JCCo and a.OldJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    
         --ARBL
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'ARBL', 'Job in AR Batch '
    	 from ARBL a with(nolock)
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, a.oldJob, a.Co, a.Mth, a.BatchId, 'ARBL', 'Old Job in ARBL'
         from ARBL a with(nolock)
         join JCJM j with(nolock) on a.oldJCCo=j.JCCo and a.oldJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         --EMBF
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'ARBL', 'Job in EM Posting'
    	 from EMBF a with(nolock)
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         insert into #JCCloseErrors 
    	 select distinct a.OldJCCo, j.Contract, a.OldJob, a.Co, a.Mth, a.BatchId, 'EMBF', 'Old Job in EM Posting'
         from EMBF a with(nolock)
         join JCJM j with(nolock) on a.OldJCCo=j.JCCo and a.OldJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         --EMLB
         insert into #JCCloseErrors 
    	 select distinct FromJCCo, j.Contract, FromJob, a.Co, a.Mth, a.BatchId, 'EMLB', 'Job in EM Equipment Location Transfer'
    	 from EMLB a with(nolock)
         join JCJM j with(nolock) on FromJCCo=j.JCCo and FromJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         insert into #JCCloseErrors 
    	 select distinct a.OldFromJCCo, j.Contract, a.OldFromJob, a.Co, a.Mth, a.BatchId, 'EMLB', 'Old From Job in EM Equipment Location Transfer'
         from EMLB a with(nolock) 
         join JCJM j with(nolock) on a.OldFromJCCo=j.JCCo and a.OldFromJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    
         insert into #JCCloseErrors 
    	 select distinct a.OldToJCCo, j.Contract, a.OldToJob, a.Co, a.Mth, a.BatchId, 'EMLB', 'Old To Job in EM Equipment Location Transfer'
         from EMLB a with(nolock) 
         join JCJM j with(nolock) on a.OldToJCCo=j.JCCo and a.OldToJob=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --POCA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.POCo, a.Mth, a.BatchId, 'POCA', 'Open PO Batch'
    	 from POCA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --PORA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.POCo, a.Mth, a.BatchId, 'PORA', 'Open PO Receipts Batch'
    	 from PORA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --POXA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.POCo, a.Mth, a.BatchId, 'POXA', 'Exists in PO Close Batch'
    	 from POXA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --POIB
         insert into #JCCloseErrors 
    	 select distinct a.PostToCo, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'POIB', 'Open PO Batch'
    	 from POIB a with(nolock) 
         join JCJM j with(nolock) on a.PostToCo=j.JCCo and a.Job=j.Job
         join #JCContracts t on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
         insert into #JCCloseErrors 
    	 select distinct a.OldPostToCo, j.Contract, a.OldJob, a.Co, a.Mth, a.BatchId, 'POIB', ''
    	 from POIB a with(nolock) 
         join JCJM j with(nolock) on a.OldPostToCo=j.JCCo and a.OldJob=j.Job
         join #JCContracts t on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    
    --POIT
         insert into #JCCloseErrors 
    	 select distinct a.PostToCo, j.Contract, j.Job, a.POCo, null,null , 'POIT', 'PO # '+convert(varchar(20),a.PO)+' Item:' + convert(varchar(20),a.POItem)+ ' is not closed'
    	 from POIT a with(nolock)
         join POHD b with(nolock) on b.POCo=a.POCo and b.PO=a.PO
         join JCJM j with(nolock) on a.PostToCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    	 where  b.Status<>2
               and (a.RemUnits <> 0 or a.RemCost <> 0 or a.RemTax <> 0)
    
    --PRTH
         insert into #JCCloseErrors 
    	 select distinct PRTH.JCCo, j.Contract, j.Job, PRTH.PRCo, null,null , 'PRTH', 'PR Timecards not interfaced'
    	 from PRTH with(nolock) 
         join PRPC with(nolock) on PRPC.PRCo = PRTH.PRCo and PRPC.PRGroup = PRTH.PRGroup and PRPC.PREndDate = PRTH.PREndDate
         join JCJM j with(nolock) on PRTH.JCCo=j.JCCo and PRTH.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    	 where  PRPC.JCInterface = 'N'
    
    --SLCA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.SLCo, a.Mth, a.BatchId, 'SLCA', 'Exists in SL Change Batch'
    	 from SLCA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --SLXA
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.SLCo, a.Mth, a.BatchId, 'SLXA', 'Exists in SL Close Batch'
    	 from SLXA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --SLIB
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'SLIB', 'Exists in SL Item Batch'
    	 from SLIB a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    -- SLIT 
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.SLCo, null, null, 'SLIT',
               'Exists in SLIT for SL#: ' + a.SL + ', Item: ' + convert(varchar(6), a.SLItem)
    	 from SLIT a with(nolock)
         join SLHD with(nolock) on SLHD.SLCo=a.SLCo and SLHD.SL=a.SL and SLHD.Status<>2
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    	 Where (case a.UM  when 'LS' then (a.CurCost - a.InvCost)
                          else (a.CurUnits - a.InvUnits) end)<>0
    
         
    --JCDA 266
         insert into #JCCloseErrors 
    	 select distinct a.JCCo, j.Contract, j.Job, a.JCCo, a.Mth, a.BatchId, 'JCDA', 'Exists in JC Cost Adjustment Batch'
    	 from JCDA a with(nolock) 
         join JCJM j with(nolock) on a.JCCo=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --JCCB
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'JCCB', 'Exists in JC Cost Adjustment Batch'
    	 from JCCB a with(nolock) 
         join JCJM j with(nolock) on a.Co=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    
    --JCPB
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'JCPB', 'Exists in JC Progress Batch'
    	 from JCPB a with(nolock) 
         join JCJM j with(nolock) on a.Co=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    --JCPP
         insert into #JCCloseErrors 
    	 select distinct a.Co, j.Contract, j.Job, a.Co, a.Mth, a.BatchId, 'JCPP', 'Exists in JC Progress Batch'
    	 from JCPP a with(nolock) 
         join JCJM j with(nolock) on a.Co=j.JCCo and a.Job=j.Job
         join #JCContracts t with(nolock) on  j.JCCo=t.JCCo and j.Contract=t.Contract
    
    select a.JCCo, a.Contract,a.Job, a.Co, a.Mth, a.BatchId,a.TableName, a.Msg,
    BatchSource=HQBC.Source,BatchInUseBy=HQBC.InUseBy,BatchCreated=HQBC.DateCreated,BatchCreatedBy=HQBC.CreatedBy,
    BatchPREndDate=HQBC.PREndDate,HQCO.HQCo, HQCO.Name, JCCM.Description
    from #JCCloseErrors a with(nolock)
    Left join HQBC HQBC with(nolock) on a.Co=HQBC.Co and a.Mth=HQBC.Mth and a.BatchId=HQBC.BatchId
    Join JCCM JCCM with(nolock) on a.JCCo=JCCM.JCCo and a.Contract=JCCM.Contract --AA 8/02
    Join HQCO HQCO with(nolock) on a.Co=HQCO.HQCo --AA 8/02
    
    --Where
    --a.Co=@Company and a.Contract=@Contract and  a.Mth=@Mth --AA 8/02

GO
GRANT EXECUTE ON  [dbo].[brptJCContractDeleteList] TO [public]
GO
