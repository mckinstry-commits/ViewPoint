SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/************************************/
CREATE   proc [dbo].[bspJCACProcess]
/*************************************
* Created By:	SE  3/17/97
* Modified By:	GF 07/17/2000 - Issue #7158
*				GF 10/02/2000 - Issue #10739 - allocations calculated using neg rate
*				GF 02/28/2001 - Issue #12483 - allocations using departments from bJCCI not bJCCM
*				GF 03/01/2001 - Issue #12591 - allocations using revenue basis, make work.
*				GF 03/05/2001 - Issue #12529 - add allocation phase/cost type to JCJP/JCCH depending on addlockedphase flag
*				GF 06/13/2002 - Issue #17269 - add include soft close jobs.
*				DANF 09/05/02 - Issue #17738 add phase group to bspJCCAGlacctDflt & bspJCADDCOSTTYPE
*				GF 09/12/2002 - ISSUE #17269 Need to add TOJCCo for JCCB table.
*				GF 01/13/2003 - Issue #19902 changed @amtcolumn option to work as a flat amount.
*				GF 05/04/2004 - issue #24474 added code for posted job and posted department. Was not available.
*				DANF 05/10/2005 - Issue # 28604 add index to temp table by company and job.
*				DANF 05/24/2005 - Issue # 28754 update allocation code to cost detail add MatlGroup
*				DANF 06/22/2005 - Issue # 28787 Update last run information to Allocation Code.
*				DANF 09/21/2005 - Issue # 29266 Spread Revenue to Multiple Jobs.
*				GG	12/20/2005	- #119687 - fix basis accumulation for revenue based allocations
*				DANF 01/06/2005 - Issue # 119790 Backout issues 29266 and 119687
*				DANF 01/06/2005 - Issue # 119791 6.x recode of issue 119790
*				DAN SO 12/18/2008 - Issue # 126229 - Allow Date Range on Actual or Posted Dates
*				GF	02/02/2009	- issue #132141 - Missing check for soft-closed job status and soft closed flag for revenue.
*				CHS 10/02/2009	- issue #134072 - change error message
*				GF 06/01/2010 - issue #137811 write out JCCB.OffsetGLCo to batch table.
*				GF 02/12/2012 TK-12940 #145729 where clause for date range incorrect resulting in incorrect basis
*
*
* USAGE:
* used by JCACRUN to process an allocation
*
* Pass in :
*	JCCo, Mth, BatchId, AllocationCode, AllocationDate, Job, Dept, Amt, Rate
*      BeginDate, EndDate, GetBasis, Reversal, AddLockedPhase, SoftCloseJobs
*
* NOTE:  If MthDateFlag is M then Begin and End Date are not used
*
* Returns
*	BasisAmount, Error message and return code
*
* Error returns no rows
*******************************/
  (@jcco bCompany, @mth bMonth, @batchid bBatchID, @alloccode smallint, @allocdate bDate,
   @job bJob, @dept bDept, @allocamt bDollar, @allocrate bRate, @begindate bDate, @enddate bDate,
   @getbasis tinyint=0, @reversal tinyint, @addlockedphase bYN, @softclose bYN, @basis bDollar output,
   @msg varchar(255) output)
   as
   set nocount on
  
   declare @rcode tinyint, @status tinyint, @numrows int, @openjccb tinyint, @openjobbasis tinyint, @errmsg varchar(255),
           @selectjobs varchar(1), @selectdepts varchar(1), @allocbasis varchar(1), @amtrateflag varchar(1),
           @amtcolumn varchar(30), @ratecolumn varchar(30), @mthdateflag varchar(1), @phasegroup bGroup,
           @phase bPhase, @costtype bJCCType, @glco bCompany, @debitacct bGLAcct, @creditacct bGLAcct,
           @description bDesc, @glacct bGLAcct, @stdum bUM, @alloctotal bDollar, @allocdebitacct bGLAcct,
           @alloctype tinyint, @cjcco bCompany, @cjob bJob, @cphase bPhase, @ccosttype bJCCType,
           @addjcco bCompany, @addjob bJob, @addallocamt bDollar, @batchseq int, @addphase bPhase,
           @addcosttype bJCCType, @override bYN, @matlgroup bGroup

  
   select @rcode = 0, @openjccb = 0, @openjobbasis = 0
  
   create table #JobTable (
             JCCo        tinyint        not null,
             Job         varchar(10)    not null,
             Contract    varchar(20)    null,
             Item        varchar(20)    null,
             Phase       varchar(20)    null,
             CostType    tinyint        null,
             AllocAmt    numeric(12, 2) not null,
             AllocRate   numeric(12, 6) not null,
             Basis       numeric(12, 2) not null)

  CREATE NONCLUSTERED INDEX #JobTable
      ON #JobTable(JCCo,Job)
  
  CREATE NONCLUSTERED INDEX #ContractTable
      ON #JobTable(JCCo,Contract)
  
   create table #JobBasis (
             JCCo        tinyint        not null,
             Job         varchar(10)    not null,
             Basis       numeric(12, 2) not null,
             Contract    varchar(20)    null,
             Item        varchar(20)    null,
             Phase       varchar(20)    null,
             CostType    tinyint        null)

  CREATE NONCLUSTERED INDEX #JobBasis
      ON #JobBasis(JCCo,Job)
  
  CREATE NONCLUSTERED INDEX #ContractBasis
      ON #JobBasis(JCCo,Contract)
  
   -- Validate Batch info
   exec @rcode = bspHQBatchProcessVal @jcco, @mth, @batchid, 'JC CostAdj', 'JCCB', @errmsg output, @status output
   if @rcode <> 0
       begin
       select @msg = @errmsg, @rcode = 1
       goto bspexit
       end
  
   if @status <> 0
       begin
      	select @msg = 'Invalid Batch status!', @rcode = 1
      	goto bspexit
      	end
  
   -- Start by getting information about the allocation code
   select @selectjobs=SelectJobs, @selectdepts=SelectDepts, @allocbasis=AllocBasis,
          @amtrateflag=AmtRateFlag, @amtcolumn=AmtColumn, @ratecolumn=RateColumn,
          @mthdateflag=MthDateFlag, @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType,
          @glco=GLCo, @allocdebitacct=DebitAcct, @creditacct=CreditAcct, @description=Description
   from bJCAC where JCCo=@jcco and AllocCode=@alloccode
   if @@rowcount <> 1
       begin
       select @msg = 'Invalid Allocation code!', @rcode = 1
       goto bspexit
       end
  
  if @amtcolumn is null and @allocamt is null and @amtrateflag = 'A'
  	begin
  	select @msg = 'Missing allocation amount or job column, cannot create!', @rcode = 1
  	goto bspexit
  	end
  
   if @ratecolumn is null and @allocrate is null and @amtrateflag = 'R'
       begin
       select @msg = 'Missing allocation rate or job column, cannot create!', @rcode = 1
       goto bspexit
       end
  
   select @matlgroup=MatlGroup 
   from dbo.bHQCO with (nolock)
   where HQCo=@jcco


   if @allocbasis='R'
       begin
       if @phase is null
           begin
           select @msg = 'Missing phase code, must have phase when doing revenue allocation', @rcode = 1
           goto bspexit
           end
       if @costtype is null
           begin
           select @msg = 'Missing cost type, must have cost type when doing revenue allocation', @rcode = 1
           goto bspexit
           end
       end
  
   -- Since there are many different ways an allocation can be processed
   -- i.e. By Type(Amount, Rate), and Depending on Basis(Cost, Hours, Revenue, Field)
   -- We need to have a different select for each one.
   -- split out into two sections, one specific for revenue
   if @allocbasis <> 'R'
   BEGIN
  	if @selectjobs = 'P'
  		begin
  		if @selectdepts = 'P'
  			begin
  			-- posted job and posted department
  			insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
  			select @jcco, @job, p.Phase, 0, 0, 0
  			from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
  			where p.JCCo=@jcco and p.Job=@job and j.JobStatus = 1
  			and exists(select * from bJCCI c where c.JCCo=j.JCCo and c.Contract=j.Contract and c.Department=@dept and c.Item=p.Item)
  			end
  		else
  			begin
  			-- posted job
  			insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
  			select @jcco, @job, p.Phase, 0, 0, 0
  			from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
  			where p.JCCo=@jcco and p.Job=@job and j.JobStatus = 1
  			end
  		end
  
  	if @selectjobs = 'A'
  		begin
  		if @selectdepts = 'P'
               -- all jobs posted department
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, p.Phase, 0, 0, 0
               from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
               where p.JCCo=@jcco and j.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCCI c where c.JCCo=j.JCCo and c.Contract=j.Contract and c.Department=@dept and c.Item=p.Item)
  
           if @selectdepts = 'A'
               -- all jobs and all departments
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, p.Phase, 0, 0, 0
               from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
               where p.JCCo=@jcco and j.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'D'
               -- all jobs, selected departments
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, p.Phase, 0, 0, 0
               from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
               where p.JCCo=@jcco and j.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCCI c where c.JCCo=j.JCCo and c.Contract=j.Contract and c.Item=p.Item
               and exists(select * from bJCAD d where d.JCCo=j.JCCo and d.AllocCode=@alloccode and d.Department=c.Department))
           end
  
       if @selectjobs = 'J'
           begin
  
           if @selectdepts = 'P'
               -- selected jobs posted department
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, p.Phase, 0, 0, 0
               from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
               join bJCAJ a on j.JCCo=a.JCCo and j.Job=a.Job
               where p.JCCo=@jcco and j.JCCo=@jcco and a.JCCo=@jcco and a.AllocCode=@alloccode
  			 and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCCI c where c.JCCo=j.JCCo and c.Contract=j.Contract and c.Department=@dept and c.Item=p.Item)
  
           if @selectdepts = 'A'
               -- selected jobs and all departments
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, p.Phase, 0, 0, 0
               from bJCJP p join bJCAJ a on a.JCCo=p.JCCo and a.Job=p.Job
               join bJCJM j on j.JCCo=a.JCCo and j.Job=a.Job
               where p.JCCo=@jcco and a.JCCo=@jcco and a.AllocCode=@alloccode and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'D'
               -- selected jobs, selected departments
               insert into #JobTable(JCCo, Job, Phase, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, p.Phase, 0, 0, 0
  			 from bJCJP p join bJCJM j on j.JCCo=p.JCCo and j.Job=p.Job
               join bJCAJ a on a.JCCo=j.JCCo and a.Job=j.Job
               where p.JCCo=@jcco and j.JCCo=@jcco and a.JCCo=@jcco and a.AllocCode=@alloccode
  			 and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCCI c where c.JCCo=j.JCCo and c.Contract=j.Contract and c.Item=p.Item
               and exists(select * from bJCAD d where d.JCCo=j.JCCo and d.AllocCode=@alloccode and d.Department=c.Department))
           end
  
       -- insert a record into #JobTable with no phase/cost type
       insert into #JobTable(JCCo, Job, AllocAmt, AllocRate, Basis)
       select a.JCCo, a.Job, 0, 0, 0
       from #JobTable a where a.JCCo=@jcco
       and (select count(*) from #JobTable where JCCo=@jcco and Job=a.Job and Phase is null) = 0
       group by a.JCCo,a.Job
       order by a.JCCo,a.Job
  
       --------------------------------------------------------------------------------------------------
       -- now calculate the basis amounts
       if @allocbasis = 'C' or @allocbasis = 'H'
           begin
           -- get basis from Cost or hours in JCCP
           -- if begin date is null then use month, otherwise use date range
           if @mthdateflag = 'M'
               insert into #JobBasis(JCCo, Job, Phase, CostType, Basis)
               select d.JCCo, d.Job, d.Phase, d.CostType,
                   'Basis'= CASE @allocbasis WHEN 'C' THEN isnull(sum(ActualCost),0)
                                             WHEN 'H' THEN isnull(sum(ActualHours),0)
                                             END
               from bJCCD d join #JobTable t on d.JCCo=t.JCCo and d.Job=t.Job and d.Phase=t.Phase
               where d.CostType in (select CostType from bJCAT c where c.JCCo=d.JCCo
               and c.AllocCode=@alloccode) and d.Mth=@mth
               group by d.JCCo, d.Job, d.Phase, d.CostType
           else

               insert into #JobBasis(JCCo, Job, Phase, CostType, Basis )
               select d.JCCo, d.Job, d.Phase, d.CostType,
                   'Basis'= case @allocbasis WHEN 'C' THEN isnull(sum(ActualCost),0)
                                             WHEN 'H' THEN isnull(sum(ActualHours),0)
                         		              END
               from bJCCD d join #JobTable t on d.JCCo=t.JCCo and d.Job=t.Job and d.Phase=t.Phase
               where d.CostType in (select CostType from bJCAT c where c.JCCo=d.JCCo and c.AllocCode=@alloccode)
			   ----TK-12940
			   AND ((@mthdateflag = 'R' AND d.ActualDate >= @begindate AND d.ActualDate <= @enddate)	-- New Code - Issue# 126229
				OR  (@mthdateflag = 'P' AND d.PostedDate >= @begindate AND d.PostedDate <= @enddate)) -- New Code - Issue# 126229
--               and d.ActualDate >= @begindate and d.ActualDate <=@enddate							-- Old Code - Issue# 126229
               group by d.JCCo, d.Job, d.Phase, d.CostType
           end
  
       -- remove multiple job entries from #JobTable
       delete from #JobTable where Phase is not null
   END
  
  
   -- now do the revenue section
   if @allocbasis = 'R'
   BEGIN
  	if @selectjobs = 'P'
  		begin
  		if @selectdepts = 'P'
  			begin
  			-- posted job and posted department
  			insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
  			select @jcco, @job, j.Contract, c.Item, 0, 0, 0
  			from bJCCI c join bJCJM j on j.JCCo=c.JCCo and j.Contract=c.Contract
  			where c.JCCo=@jcco and j.JCCo=@jcco and c.Department=@dept and j.Job=@job and (j.JobStatus=1  or (j.JobStatus = 2 and @softclose = 'Y')) ---- 132141
  			end
  		else
  			begin
  			-- posted job
  			insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
  			select @jcco, @job, j.Contract, c.Item, 0, 0, 0
  			from bJCCI c join bJCJM j on j.JCCo=c.JCCo and j.Contract=c.Contract
  			where c.JCCo=@jcco and j.JCCo=@jcco and j.Job=@job and (j.JobStatus=1  or (j.JobStatus = 2 and @softclose = 'Y')) ---- 132141
  			end
  		end
  
  	if @selectjobs = 'A'
  		begin
  		if @selectdepts = 'P'
               -- all jobs posted department
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, j.Contract, c.Item, 0, 0, 0
               from bJCCI c join bJCJM j on j.JCCo=c.JCCo and j.Contract=c.Contract
               where j.JCCo=@jcco and c.JCCo=@jcco and c.Department=@dept
  			 and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'A'
               -- all jobs and all departments
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, j.Contract, c.Item, 0, 0, 0
               from bJCCI c join bJCJM j on j.JCCo=c.JCCo and j.Contract=c.Contract
               where c.JCCo=@jcco and j.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'D'
               -- all jobs, selected departments
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select j.JCCo, j.Job, j.Contract, c.Item, 0, 0, 0
               from bJCJM j join bJCCI c on c.JCCo=j.JCCo and c.Contract=j.Contract
        		 where j.JCCo=@jcco and c.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCAD d where d.JCCo=j.JCCo and d.AllocCode=@alloccode and d.Department=c.Department)
           end
  
       if @selectjobs = 'J'
           begin
           if @selectdepts = 'P'
               -- selected jobs posted department
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, j.Contract, c.Item, 0, 0, 0
               from bJCJM j join bJCAJ a on a.JCCo=j.JCCo and a.Job=j.Job
               join bJCCI c on c.JCCo=j.JCCo and c.Contract=j.Contract
               where j.JCCo=@jcco and a.JCCo=@jcco and a.AllocCode=@alloccode and c.Department=@dept
  			 and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'A'
               -- selected jobs and all departments
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, j.Contract, c.Item, 0, 0, 0
               from bJCAJ a join bJCJM j on j.JCCo=a.JCCo and j.Job=a.Job
               join bJCCI c on c.JCCo=j.JCCo and c.Contract=j.Contract
               where a.JCCo=@jcco and a.AllocCode=@alloccode and j.JCCo=@jcco and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
  
           if @selectdepts = 'D'
               -- selected jobs, selected departments
               insert into #JobTable(JCCo, Job, Contract, Item, AllocAmt, AllocRate, Basis)
               select a.JCCo, a.Job, j.Contract, c.Item, 0, 0, 0
               from bJCJM j join bJCAJ a on a.JCCo=j.JCCo and a.Job=j.Job
               join bJCCI c on c.JCCo=j.JCCo and c.Contract=j.Contract
               where j.JCCo=@jcco and a.JCCo=@jcco and a.AllocCode=@alloccode
  			 and (j.JobStatus = 1 or (j.JobStatus = 2 and @softclose = 'Y'))
               and exists(select * from bJCAD d where d.JCCo=j.JCCo and d.AllocCode=@alloccode and d.Department=c.Department)
           end
  
       -- try to remove multiple jobs to the same contract
       delete from #JobTable
       where Job <> (select min(Job) from #JobTable b where b.Contract=#JobTable.Contract)
  
       -- get revenue basis
       if @allocbasis = 'R'
           begin
           --allocation based on amount distributed by Revenue
           if @mthdateflag = 'M'
               insert into #JobBasis(JCCo, Job, Basis)
               select j.JCCo, j.Job, 'Basis'=isnull(sum(BilledAmt),0)
               from bJCID i join #JobTable t on t.JCCo=i.JCCo and t.Contract=i.Contract and t.Item=i.Item
               join bJCJM j on j.JCCo=t.JCCo and j.Job=t.Job
               where i.Mth=@mth
               group by j.JCCo, j.Job
           else

               insert into #JobBasis(JCCo, Job, Basis)
               select j.JCCo, j.Job, 'Basis'=isnull(sum(BilledAmt),0)
               from bJCID i join #JobTable t on t.JCCo=i.JCCo and t.Contract=i.Contract and t.Item=i.Item
               join bJCJM j on j.JCCo=t.JCCo and j.Job=t.Job
               ----TK-12940
			   WHERE ((@mthdateflag = 'R' AND i.ActualDate >= @begindate AND i.ActualDate <= @enddate)	-- New Code - Issue# 126229
			      OR (@mthdateflag = 'P' AND i.PostedDate >= @begindate AND i.PostedDate <= @enddate))	-- New Code - Issue# 126229
--               where i.ActualDate >=@begindate and i.ActualDate <=@enddate							-- Old Code - Issue# 126229
               group by j.JCCo, j.Job
           end
  
       -- insert a record into #JobTable with no item
       insert into #JobTable(JCCo, Job, Contract, AllocAmt, AllocRate, Basis)
       select a.JCCo, a.Job, a.Contract, 0, 0, 0
       from #JobTable a where a.JCCo=@jcco
       and (select count(*) from #JobTable where JCCo=@jcco and Job=a.Job and Item is null) = 0
       group by a.JCCo,a.Job,a.Contract
       order by a.JCCo,a.Job,a.Contract
  
       -- remove multiple job entries from #JobTable
       delete from #JobTable where Item is not null
   END
  
   -- now that we have the basis, if all we wanted was the basis, then return
   if @getbasis = 1
   BEGIN
       select @basis = isnull(sum(Basis),0) from #JobBasis
       select @msg = 'Basis returned.', @rcode=0
       goto bspexit
   END
  
   -------------------------------------------------------------------------------------------------------
   -- @alloctype = 1 JCAC phase is not null and costtype is not null
   -- @alloctype = 2 JCAC phase not null and costtype is null
   -- @alloctype = 3 JCAC phase is null and costtype is not null
   -- @alloctype = 4 JCAC phase is null and costtype is null
   if @phase is not null and @costtype is not null select @alloctype = 1
   if @phase is not null and @costtype is null select @alloctype = 2
   if @phase is null and @costtype is not null select @alloctype = 3
   if @phase is null and @costtype is null select @alloctype = 4
  
   select @cjcco=min(JCCo) from #JobTable
   while @cjcco is not null
   begin
       select @cjob=min(Job) from #JobTable where JCCo=@cjcco
       while @cjob is not null
       begin
  
        if @alloctype = 1
            begin
            -- update job table with basis for selected phase and cost type
            select @basis=isnull(sum(Basis),0)
        	  from #JobBasis where JCCo=@cjcco and Job=@cjob
            update #JobTable set Phase=@phase, CostType=@costtype, Basis=@basis
            where JCCo=@cjcco and Job=@cjob
            end
  
        if @alloctype = 2
            begin
              select @ccosttype=min(CostType) from bJCCT where PhaseGroup=@phasegroup
              while @ccosttype is not null
              begin
  
                -- update job table with basis for selected phase and each cost type
                select @basis=isnull(sum(Basis),0)
                from #JobBasis where JCCo=@cjcco and Job=@cjob and CostType=@ccosttype
                if @@rowcount <> 0
                    begin
                    insert into #JobTable(JCCo,Job,Phase,CostType,AllocAmt,AllocRate,Basis)
                    select @cjcco, @cjob, @phase, @ccosttype, 0, 0, @basis
                    end
  
              select @ccosttype=min(CostType) from bJCCT where PhaseGroup=@phasegroup and CostType > @ccosttype
              end
            end
  
        if @alloctype = 3
            begin
              select @cphase=min(Phase) from #JobBasis where JCCo=@cjcco and Job=@cjob
              while @cphase is not null
              begin
  
                -- update job table with basis for each phase and selected cost type
                select @basis=isnull(sum(Basis),0)
                from #JobBasis where JCCo=@cjcco and Job=@cjob and Phase=@cphase
                if @@rowcount <> 0
                    begin
                    insert into #JobTable(JCCo,Job,Phase,CostType,AllocAmt,AllocRate,Basis)
                    select @cjcco, @cjob, @cphase, @costtype, 0, 0, @basis
                    end
  
              select @cphase=min(Phase) from #JobBasis where JCCo=@cjcco and Job=@cjob and Phase > @cphase
              end
            end
  
        if @alloctype = 4
            begin
            -- update job table with basis for each phase and cost type
            insert into #JobTable(JCCo,Job,Phase,CostType,AllocAmt,AllocRate,Basis)
            select a.JCCo, a.Job, a.Phase, a.CostType, 0, 0, a.Basis
            from #JobBasis a where a.JCCo=@cjcco and a.Job=@cjob
            end
  
      select @cjob=min(Job) from #JobTable where JCCo=@cjcco and Job > @cjob
      end
    select @cjcco=min(JCCo) from #JobTable where JCCo > @cjcco
    end
  
   -- remove any records from #JobTable that do not have a phase/costtype
   delete from #JobTable where Phase is null or CostType is null
  
   -- remove any records from #JobTable that do not have a basis amount
   delete from #JobTable where Basis = 0 and @amtcolumn is null
  
    -- make sure we ended up with something
    select @numrows = count(*) from #JobTable
    if @numrows=0
        begin
--      select @msg = 'No jobs selected for allocation!', @rcode=1 -- issue #134072
        select @msg = 'No Jobs fitting your criteria selected for allocation!', @rcode=1
        goto bspexit
        end
  
    -- update the AllocRate column in #JobTable with the Job
    -- user column (@amtcolumn or @ratecolumn) if applicable
    if @amtcolumn is not null
          exec ('update #JobTable set AllocRate = isnull(' + @amtcolumn + ',0)' +
            ' from #JobTable t, JCJM j where t.JCCo=j.JCCo and t.Job=j.Job')
  
    if @ratecolumn is not null
          exec ('update #JobTable set AllocRate = isnull(' + @ratecolumn + ',0)' +
                  ' from #JobTable t, JCJM j where t.JCCo=j.JCCo and t.Job=j.Job')
    
    -- once basis has been calculated then we can calculate the allocation based on Type
    if @amtrateflag = 'A'
    BEGIN
        if @amtcolumn is null
            begin
            update #JobTable set AllocAmt = (Basis/(select sum(Basis) from #JobTable))*@allocamt
            end
        else
       	  begin
            --update #JobTable set AllocAmt = (Basis/(select sum(Basis) from #JobTable)*isnull(AllocRate,0))
  		  -- changed to work like flat amount
  		  update #JobTable set AllocAmt = isnull(AllocRate,0)
            end
    END
  
    if @amtrateflag = 'R'
    BEGIN
      if @ratecolumn is null
            begin
            update #JobTable set AllocAmt = Basis * isnull(@allocrate,0)
         end
    else
    begin
            update #JobTable set AllocAmt = Basis * isnull(AllocRate,0)
            end
    END
  
  
   done_calculating:
  
   -- declare cursor on #JobTable for update JC Cost Adjustment Batch
   declare bcJCCB cursor for select JCCo, Job, AllocAmt, Phase, CostType
   from #JobTable
   -- open cursor
   open bcJCCB
  
   -- set open cursor flag to true
   select @openjccb = 1, @alloctotal = 0
  
   JCCB_loop:
   fetch next from bcJCCB into @addjcco, @addjob, @addallocamt, @addphase, @addcosttype
  
   if @@fetch_status <> 0 goto bcJCCB_end
  
  if @addallocamt <> 0
      begin
      select @override = @addlockedphase
      -- validate standard phase - if it doesnt exist in JCJP try to add it depending on override flag
      exec @rcode = bspJCADDPHASE @addjcco, @addjob, @phasegroup, @addphase, @override, null, @errmsg output
  
      -- validate Cost Type - if JCCH doesnt exist try to add it depending on override flag
      exec @rcode = bspJCADDCOSTTYPE @jcco=@addjcco, @job=@addjob, @phasegroup=@phasegroup, @phase=@addphase,
                  @costtype=@addcosttype, @um=null, @override=@addlockedphase, @msg=@errmsg output
  
       select @stdum=UM from bJCCH where JCCo=@addjcco and Job=@addjob
       and PhaseGroup=@phasegroup and Phase=@addphase and CostType=@addcosttype
  
       if @stdum is null
           begin
           select @stdum = UM from bJCPC
           where PhaseGroup=@phasegroup and Phase=@addphase and CostType=@addcosttype
           end
  
       if @stdum is null select @stdum = 'LS'
  
       -- if debit account is null then get from department
       select @debitacct = @allocdebitacct
       if @debitacct is null
           begin
           -- get debit acct
           exec @rcode = bspJCCAGlacctDflt @addjcco,@addjob,@phasegroup,@addphase,@addcosttype,'Y',@glacct output,@errmsg output
           select @debitacct = @glacct
           end
  
       -- get next available batch sequence
		----#137811
       select @batchseq = isnull(max(BatchSeq),0)+1 from bJCCB where Co=@jcco and Mth=@mth and BatchId=@batchid
       insert into bJCCB(Co, Mth, BatchId, BatchSeq, Source, TransType, CostTrans, Job, PhaseGroup, Phase,
                   CostType, ActualDate, JCTransType, Description, GLCo, GLTransAcct, GLOffsetAcct,
                   ReversalStatus, UM, Hours, Units, Cost, AllocCode, ToJCCo, MatlGroup, OffsetGLCo)
       values(@addjcco, @mth, @batchid, @batchseq, 'JC CostAdj', 'A', null, @addjob, @phasegroup, @addphase,
                   @addcosttype, @allocdate, 'CA', @description, @glco, @debitacct, @creditacct,
                   @reversal, @stdum, 0, 0, @addallocamt, @alloccode, @addjcco, @matlgroup, @glco)
		----#137811
       select @alloctotal=@alloctotal + @addallocamt
       end
  
   goto JCCB_loop
  
   bcJCCB_end:
   -- if we're allocating an amount, and not using a column in JCJM check and
   -- make sure that we allocated the full amount
   -- if there is a rounding descrepency we add it to the last item
   if @amtrateflag='A' and @amtcolumn is null
       begin
       if @alloctotal <> @allocamt
           begin
           update bJCCB set Cost=Cost +(@allocamt-@alloctotal)
           where Co=@addjcco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
           end
       end
  
  -- Update allocation code with Last run information.
  update dbo.bJCAC 
  set LastPosted = @allocdate, 
  	LastBeginDate = @begindate, 
  	LastEndDate = @enddate, 
  	LastMonth = @mth,
  	PrevPosted = LastPosted,
  	PrevMonth = LastMonth,
  	PrevBeginDate = LastBeginDate,
  	PrevEndDate = LastEndDate
  where JCCo=@jcco and AllocCode=@alloccode

  select @rcode = 0
  
  
  
  bspexit:
  	if @openjccb = 1
  		begin
  		close bcJCCB
  		deallocate bcJCCB
  		select @openjccb = 0
  		end
  
  	drop table #JobBasis
  	drop table #JobTable
  
  	if @rcode<>0 select @msg=@msg
  	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJCACProcess] TO [public]
GO
