CREATE TABLE [dbo].[bJCCM]
(
[JCCo] [dbo].[bCompany] NULL,
[Contract] [dbo].[bContract] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Department] [dbo].[bDept] NOT NULL,
[ContractStatus] [tinyint] NOT NULL,
[OriginalDays] [smallint] NOT NULL CONSTRAINT [DF_bJCCM_OriginalDays] DEFAULT ((0)),
[CurrentDays] [smallint] NOT NULL CONSTRAINT [DF_bJCCM_CurrentDays] DEFAULT ((0)),
[StartMonth] [dbo].[bMonth] NOT NULL,
[MonthClosed] [dbo].[bMonth] NULL,
[ProjCloseDate] [dbo].[bDate] NULL,
[ActualCloseDate] [dbo].[bDate] NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[TaxInterface] [dbo].[bYN] NOT NULL,
[TaxGroup] [dbo].[bGroup] NULL CONSTRAINT [DF_bJCCM_TaxGroup] DEFAULT ((0)),
[TaxCode] [dbo].[bTaxCode] NULL,
[RetainagePCT] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bJCCM_RetainagePCT] DEFAULT ((0)),
[DefaultBillType] [dbo].[bBillType] NOT NULL,
[OrigContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_OrigContractAmt] DEFAULT ((0)),
[ContractAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_ContractAmt] DEFAULT ((0)),
[BilledAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_BilledAmt] DEFAULT ((0)),
[ReceivedAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_ReceivedAmt] DEFAULT ((0)),
[CurrentRetainAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_CurrentRetainAmt] DEFAULT ((0)),
[InBatchMth] [dbo].[bMonth] NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[SIMetric] [dbo].[bYN] NULL CONSTRAINT [DF_bJCCM_SIMetric] DEFAULT ('N'),
[ProcessGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BillAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BillState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BillZip] [dbo].[bZip] NULL,
[BillNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BillOnCompletionYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCM_BillOnCompletionYN] DEFAULT ('N'),
[CustomerReference] [dbo].[bDesc] NULL,
[CompleteYN] [dbo].[bYN] NOT NULL,
[RoundOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCM_RoundOpt] DEFAULT ('N'),
[ReportRetgItemYN] [dbo].[bYN] NOT NULL,
[ProgressFormat] [dbo].[bDesc] NULL,
[TMFormat] [dbo].[bDesc] NULL,
[BillGroup] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[BillDayOfMth] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ArchitectName] [dbo].[bDesc] NULL,
[ArchitectProject] [dbo].[bDesc] NULL,
[ContractForDesc] [dbo].[bDesc] NULL,
[StartDate] [dbo].[bDate] NULL,
[JBTemplate] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JBFlatBillingAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_JBFlatBillingAmt] DEFAULT ((0)),
[JBLimitOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCM_JBLimitOpt] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[RecType] [tinyint] NULL,
[OverProjNotes] [varchar] (8000) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bJCCM_OverProjNotes] DEFAULT (NULL),
[ClosePurgeFlag] [dbo].[bYN] NULL CONSTRAINT [DF_bJCCM_ClosePurgeFlag] DEFAULT ('N'),
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NULL,
[SecurityGroup] [int] NULL,
[UpdateJCCI] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCM_UpdateJCCI] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BillCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[MaxRetgOpt] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCM_MaxRetgOpt] DEFAULT ('N'),
[MaxRetgPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_bJCCM_MaxRetgPct] DEFAULT ((0.0000)),
[MaxRetgAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJCCM_MaxRetgAmt] DEFAULT ((0.00)),
[InclACOinMaxYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCCM_InclACOinMaxYN] DEFAULT ('Y'),
[MaxRetgDistStyle] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCCM_MaxRetgDistStyle] DEFAULT ('C'),
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udGMAXAmt] [dbo].[bDollar] NULL,
[udPOC] [dbo].[bProjectMgr] NULL,
[udConMethod] [smallint] NULL,
[udConChannel] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udPrimeYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCCM__udPrimeYN__DEFAULT] DEFAULT ('N'),
[udSubstantiation] [varchar] (30) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btJCCMd] ON [dbo].[bJCCM] for DELETE as
/*-----------------------------------------------------------------
* Created: JRE 01/27/97
* Modified: bc 10/19/99  added JBGC process group update
*			DanF 04/12/00 Added delete of data security
*			DanF 04/27/04 Issue 17370 - Use VA Purge Security Entries to purge security entries.
*			GF 10/26/2004 - issue #25828 clean-up trigger performance
*			GG 04/18/07 - #30116 - data security review, removed cursor to delete bJBGC
*			GF 09/03/2009 - issue #129897 - when not purging contract remove contract from potential work
*
*
* This trigger rejects delete in bJCCM (JC Contract Master) if the following error condition exist:
*		entries exist in JCOH
*		entries exist in JCCI
*		entries exist in JCJM
*		(Future checks AR,JB,PM,???)
*
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @validcnt int, @numrows int, @jcco bCompany, 
	@oldprocessgroup varchar(10), @contract bContract, @opencursor tinyint
    
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
  
-- -- -- check JCCI
if exists(select top 1 1 from deleted d join dbo.bJCCI i (nolock) on i.JCCo=d.JCCo and i.Contract=d.Contract)
	begin
	select @errmsg = 'Entries exist in Contract Items'
	goto error
	end
-- -- -- check JCOH
if exists(select top 1 1 from deleted d join dbo.bJCOH h (nolock) on h.JCCo=d.JCCo and h.Contract=d.Contract)
	begin
	select @errmsg = 'Entries exist in JC Change Order Header'
	goto error
	end
-- -- -- check JCJM
if exists(select top 1 1 from deleted d join dbo.bJCJM j (nolock) on j.JCCo=d.JCCo and j.Contract=d.Contract)
	begin
	select @errmsg = 'Entries exist in JC Job Master'
	goto error
	end
   
-- -- -- delete the process group grid with contract information for any deleted contracts with a process group
delete dbo.bJBGC
from dbo.bJBGC c 
join deleted d on c.JBCo = d.JCCo and c.Contract = d.Contract and c.ProcessGroup = d.ProcessGroup


---- #129897
---- update PC Potential Work removing contract when not purging
update dbo.PCPotentialWork set Contract = null, Awarded = 'N', AllowForecast = 'Y', AwardedDate = null
from dbo.PCPotentialWork p join deleted d on d.JCCo=p.JCCo and d.Contract=p.Contract and d.PotentialProject=p.PotentialProject
where d.PotentialProject is not null and d.ClosePurgeFlag = 'N'

delete dbo.vJCForecastMonth
from dbo.vJCForecastMonth m
join deleted d on d.JCCo=m.JCCo and d.Contract=m.Contract
where d.ClosePurgeFlag = 'N'


---- -- -- begin process
--if @numrows = 1
--select @jcco=JCCo, @contract=Contract, @oldprocessgroup = ProcessGroup
--from deleted
--else
--begin
---- use a cursor to process each updated row
--declare bJCCM_delete cursor LOCAL FAST_FORWARD
--for select JCCo, Contract, ProcessGroup
--from deleted
--
--open bJCCM_delete
--set @opencursor = 1
--
--fetch next from bJCCM_delete into @jcco, @contract, @oldprocessgroup
--
--if @@fetch_status <> 0
--	begin
--	select @errmsg = 'Cursor error'
--	goto error
--	end
--end
--
--
--delete_check:
---- -- -- if process group is not null delete from bJBGC
--if @oldprocessgroup is not null
--begin
--delete bJBGC where JBCo=@jcco and ProcessGroup=@oldprocessgroup and Contract=@contract
--end
--
---- finished with validation and deletes (except HQ Audit)
--Valid_Finished:
--if @numrows > 1
--begin
--fetch next from bJCCM_delete into @jcco, @contract, @oldprocessgroup
--	if @@fetch_status = 0
--		goto delete_check
--	else
--		begin
--		close bJCCM_delete
--		deallocate bJCCM_delete
--	set @opencursor = 0
--		end
--	end
  
-- -- --    select @jcco = min(JCCo) from deleted
-- -- --    while @jcco is not null
-- -- --      begin
-- -- --      select @contract = min(Contract) from deleted where JCCo = @jcco
-- -- --      while @contract is not null
-- -- --        begin
-- -- --        select @oldprocessgroup = d.ProcessGroup
-- -- --        from deleted d
-- -- --        where d.JCCo = @jcco and d.Contract = @contract
-- -- --  
-- -- --        if @oldprocessgroup is not null
-- -- --        delete bJBGC where JBCo = @jcco and ProcessGroup = @oldprocessgroup and Contract = @contract
-- -- --  
-- -- --        /* reset variable on every pass */
-- -- --        select @oldprocessgroup = null
-- -- --        select @contract = min(Contract) from deleted where JCCo = @jcco and Contract > @contract
-- -- --        end
-- -- --  
-- -- --      select @jcco = min(JCCo) from deleted where JCCo > @jcco
-- -- --      end
 
-- -- -- Audit inserts
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCCM', 'Contract:' + d.Contract, d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d 
join dbo.bJCCO c (nolock) on d.JCCo=c.JCCo
where c.AuditContracts = 'Y'
   
return
   
error:
--	if @opencursor = 1
--		begin
--		close bJCCM_delete
--		deallocate bJCCM_delete
--		set @opencursor = 0
--		end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Contract!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[btJCCMi] on [dbo].[bJCCM] for INSERT as

/*-----------------------------------------------------------------
* Created: ??
* Modified:	bc 10/19/99  added process group insert
*			bc  03/23/00 added bill address update
*			bc 12/26/00 added seq to JBGC insert per table change
*			kb 9/24/1 - issue #14687
*			allenn 09/24/01 - issue #14468
*			10/25/2001 SR - added DataType Security, DDDU, insertion if securing bJob in DDDT - #15041
*			12/03/01 - Removed Data Type Security fix the insert should be done in VB. = # 15353        
*  			DANF 03/20/04 - Issue 20980 Assign security group by Contract.
*			GF 10/26/2004 - issue #25828 clean-up trigger performance
*			GG 04/18/07 - #30116 - data security review, adds entries for both default and named security groups
*								- removed cursor used to insert bJBGC entries
*			GF 03/08/2008 - issue #127076 country and state validation
*			DAN SO 08/18/2009 - Issue #129897 - JC Forecast update Potential Work and insert forecast months
*			TJL 11/30/09 - Issue #129894, Max Retainage Enh.  Update JCCI.Retg% without prompt when MaxRetgOpt = 'P' or 'A'
*		 	JG 11/17/10 - Removed references to PMPotentialWork for change of PC Potential Projects
*
*
* This trigger rejects delete in bJCCM (JC Contract Master) if the following error condition exists:
*		invalid JCCO - company
*		invalid JCDM - department
*		invalid HQGP - customer group
*		invalid ARCM - customer
*		invalid HQPT - payment terms
*		invalid HQTX - tax code
* 		invalid Contract Status (0,1,2,3)
*		invalid DefaultBillType (P,T,N,B)
********************************************************************/
declare @errmsg varchar(255), @validcnt int, @numrows int,  @nullcnt int,
		@jcco bCompany, @contract bContract, @processgroup varchar(10), @seq int, 
		@secure bYN, @opencursor tinyint, @validcnt2 int,
		@Awarded bYN, @PotentialProject varchar(20)
   
SELECT @numrows = @@rowcount
IF @numrows = 0 return
SET nocount on

set @opencursor = 0

-- -- -- validate JC Company number
SELECT @validcnt = count(*) from dbo.bJCCO j (nolock) join inserted i ON j.JCCo = i.JCCo
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid JC Company '
	GOTO error
	END
-- -- -- validate Department
SELECT @validcnt = count(*) from dbo.bJCDM a (nolock) join inserted i ON a.JCCo = i.JCCo and a.Department = i.Department
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Department '
	GOTO error
	END
-- -- -- validate CustGroup
SELECT @validcnt = count(*) FROM dbo.bHQGP h (nolock) join inserted i ON h.Grp = i.CustGroup
SELECT @nullcnt = count(*) FROM inserted WHERE CustGroup is null and Customer is null
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Customer Group '
	GOTO error
	END
-- -- -- validate Customer
SELECT @validcnt = count(*) FROM dbo.bARCM a (nolock) join inserted i ON a.CustGroup = i.CustGroup and a.Customer = i.Customer
SELECT @nullcnt = count(*) FROM inserted WHERE Customer is null
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Customer '
	GOTO error
	END
-- -- -- validate HQ Payment Terms
SELECT @validcnt = count(*) FROM dbo.bHQPT a (nolock) join inserted i ON a.PayTerms = i.PayTerms
SELECT @nullcnt = count(*) FROM inserted WHERE PayTerms is NULL
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Payment Terms '
	GOTO error
	END
-- -- -- validate Tax Group - cannot be null
SELECT @validcnt = count(*) FROM dbo.bHQGP h (nolock) join inserted i ON h.Grp =i.TaxGroup
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Tax Group '
	GOTO error
	END
-- -- -- validate tax code
SELECT @validcnt = count(*) FROM dbo.bHQTX h (nolock) join inserted i ON h.TaxGroup=i.TaxGroup and  h.TaxCode = i.TaxCode
SELECT  @nullcnt = count(*) FROM inserted WHERE TaxCode is NULL
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Tax Code '
	GOTO error
	END
-- -- -- validate Contract Status
SELECT @validcnt = count(*) FROM inserted i where i.ContractStatus in (0,1,2,3)
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Contract Status '
	GOTO error
	END
-- -- -- actual date closed
SELECT @validcnt = count(*) FROM inserted i where i.ContractStatus in (0,1) and i.ActualCloseDate is not NULL
IF @validcnt <> 0
	BEGIN
	SELECT @errmsg = 'Contract is Open or Pending, Actual Close Date is not allowed '
	GOTO error
	END
-- -- -- validate month closed
SELECT @validcnt = count(*) FROM inserted where MonthClosed is not NULL and MonthClosed < StartMonth
IF @validcnt <> 0
	BEGIN
	SELECT @errmsg = 'Month Closed may not be earlier than the start month '
	GOTO error
	END
-- -- -- validate Default Bill Type
SELECT @validcnt = count(*) FROM inserted i where i.DefaultBillType in ('P','T','N','B')
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Default Bill Type '
	GOTO error
	END
-- -- -- validate process group
SELECT @validcnt = count(*) FROM dbo.bJBPG h (nolock) join inserted i ON h.JBCo=i.JCCo and  h.ProcessGroup = i.ProcessGroup
SELECT @nullcnt = count(*) FROM inserted WHERE ProcessGroup is NULL
IF @validcnt + @nullcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Process Group '
	GOTO error
	END

---- validate country
select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.BillCountry=c.Country
select @nullcnt = count(*) from inserted where BillCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Bill Country'
	goto error
	end

---- validate country and state
select @validcnt = count(*) from dbo.bHQST s with (nolock) join inserted i on i.BillCountry=s.Country and i.BillState=s.State
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.BillState
		where i.BillCountry is null and i.BillState is not null
select @nullcnt = count(*) from inserted i where i.BillState is null
if @validcnt + @validcnt2 + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country/State combination'
	goto error
	end
   
----	JG 11/17/10 - Removed for change of PC Potential Projects   
------ Issue: #129897
------ validate Potential Project
--select @validcnt = count(*) from dbo.vPCPotentialWork p with (nolock) 
--				   join inserted i on i.JCCo=p.JCCo and i.PotentialProject=p.PotentialProject
--				   WHERE p.Contract is null
--select @nullcnt = count(*) from inserted where PotentialProject is null
--if @validcnt + @nullcnt <> @numrows
--	begin
--	select @errmsg = 'Invalid Potential Project'
--	goto error
--	end

 ---- validate MaxRetgOpt - Issue #129894
 if update(MaxRetgOpt)
	begin
	select @validcnt = count(*) from inserted i where i.MaxRetgOpt in ('N', 'P', 'A')
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Maximum Retainage Option'
		goto error
  		end
  	end
 
  ---- validate MaxRetgDistStyle - Issue #129894
 if update(MaxRetgDistStyle)
	begin
	select @validcnt = count(*) from inserted i where i.MaxRetgDistStyle in ('C', 'I')
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Maximum Retainage Distribution Style'
		goto error
  		end
  	end 	

-- -- -- update JCCM.CurrentDays
update dbo.bJCCM set CurrentDays = i.OriginalDays
from inserted i join dbo.bJCCM c on c.JCCo = i.JCCo and c.Contract = i.Contract
where c.CurrentDays <> i.CurrentDays

-- add JB Process Group Sequences for inserted Contracts
insert dbo.bJBGC (JBCo, ProcessGroup, Seq, Contract)
select i.JCCo, i.ProcessGroup,
	-- get next Seq# for the JBCo and ProcessGroup combination
	isnull(max(c.Seq),0) + row_number() over(partition by c.JBCo, c.ProcessGroup order by c.JBCo, c.ProcessGroup),
	i.Contract
from inserted i
left join dbo.bJBGC c on c.JBCo = i.JCCo and c.ProcessGroup = i.ProcessGroup
where i.ProcessGroup is not null
group by i.JCCo, i.ProcessGroup, i.Contract, c.JBCo, c.ProcessGroup

--#30116 - initialize Data Security for bContract default security group
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bContract' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bContract', i.JCCo, i.Contract, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bContract' and s.Qualifier = i.JCCo 
						and s.Instance = i.Contract and s.SecurityGroup = @dfltsecgroup)
	end 

---- Setup default security group to have access if securing bContract
select @secure = Secure
from dbo.DDDTShared (nolock) where Datatype = 'bContract'
if @@rowcount = 1 and @secure <> 'N'
   	begin
   	insert dbo.vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
   	select 'bContract', i.JCCo, i.Contract, i.SecurityGroup
   	from inserted i
	where not exists(select 1 from dbo.vDDDS with (nolock) where Datatype = 'bContract' and Qualifier = i.JCCo
						and Instance = i.Contract and SecurityGroup = i.SecurityGroup)                
   	end



--------------------------
--------------------------
-- ISSUE: #129897 --
---- before creating cursor on inserted rows check to see if we really need add PCForecastMonth records.
----set @validcnt = 0
----select validcnt=count(*) from inserted i
----where i.PotentialProject is not null
----and exists(select top 1 1 from dbo.vPCForecastMonth p with (nolock) where p.JCCo=i.JCCo
----			and p.PotentialProject=i.PotentialProject)
----if @validcnt = 0 goto HQMA_Audit

--	JG 11/17/10 - Removed for change of PC Potential Projects
------ update Potential Work table and assign contract
--update dbo.vPCPotentialWork
--		set Contract=i.Contract, Awarded = 'Y', AllowForecast = 'N', AwardedDate = GETDATE()
--from dbo.vPCPotentialWork p
--join inserted i on i.JCCo=p.JCCo and i.PotentialProject=p.PotentialProject
--where i.PotentialProject is not null and p.Contract is null

------ insert JC Forecast Month detail from PC Forecast Month detail for potential project
--insert dbo.vJCForecastMonth (JCCo, Contract, ForecastMonth, RevenuePct, CostPct, Notes)
--select p.JCCo, i.Contract, p.ForecastMonth, p.RevenuePct, p.CostPct, p.Notes
--from dbo.vPCForecastMonth p
--join inserted i on i.JCCo=p.JCCo and i.PotentialProject=p.PotentialProject
--join dbo.vPCPotentialWork w on w.JCCo=i.JCCo and w.PotentialProject=i.PotentialProject
--where i.PotentialProject is not null
--and datepart(month,i.StartMonth) = datepart(month,w.StartDate)
--and datepart(year,i.StartMonth) = datepart(year,w.StartDate)
--and not exists(select top 1 1 from dbo.vJCForecastMonth m with (nolock) where m.JCCo=i.JCCo
--			and m.Contract=i.Contract and m.ForecastMonth=p.ForecastMonth)
			
			

---- create cursor on inserted for contracts with potential project assigned
--if @numrows = 1
--	begin
--	select @jcco=JCCo, @PotentialProject = PotentialProject
--	from inserted i
--	end
--else
--	begin
--	declare bcPotentialProject cursor fast_forward for select i.JCCo, i.PotentialProject
--	from inserted i
--	where i.PotentialProject is not null
--	and exists(select top 1 1 from dbo.vPCForecastMonth p with (nolock) where p.JCCo=i.JCCo
--				and p.PotentialProject=i.PotentialProject)
  
--  	open bcPotentialProject
--  	set @opencursor = 1
  
--  	fetch next from bcPotentialProject into @jcco, @PotentialProject
--	if @@fetch_status <> 0
--		begin
--		select @errmsg = 'Cursor error'
--		goto error
--		end
--	end


--potential_check:





--if @numrows > 1
--	begin
--  	fetch next from bcPotentialProject into @jcco, @PotentialProject

--	if @@fetch_status = 0
--		goto potential_check
--	else
--		begin
--		close bcPotentialProject
--		deallocate bcPotentialProject
--		end
--	end





HQMA_Audit:
---- Audit inserts 
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract, 
   		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
FROM inserted i
join dbo.bJCCO c (nolock) on c.JCCo=i.JCCo
where c.AuditContracts = 'Y'



return



error:
   	SELECT @errmsg = isnull(@errmsg,'') +  ' - cannot insert Contract!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************/
CREATE  trigger [dbo].[btJCCMu] on [dbo].[bJCCM] for UPDATE as
/*-----------------------------------------------------------------
*	This trigger rejects delete in bJCCM (JC Contract Master)
* Modified:  bc 10/19/99  added JBGC update for process group
*            GF 08/18/2000 when start month changed, update JCID & JCCD
*                          for Original estimates to new start month
*            bc 12/26/00 - added seq to JBGC insert per table change
*            bc 01/30/01 - if a job is soft closed, then remove the contract from bJBGC
*            GF 10/31/2001 - Issue #15097 - not correctly changing start month in JCID & JCCD
*			   GF 08/20/2002 - Issue #18330 - updating JCCI when SI region changes.
*			   GF 01/29/2003 - issue #20189 - when update start month and moving JCCD records to
*								noew month keep posted date. only change actual date to equal
*								new start month.
*			   RT 08/11/03 - Issue #22004, audit additional fields.
*			   RT 09/19/03 - #22004, added isnull() to allow auditing of fields changing to/from null.
*			   GF 11/07/2003 - issue #22944 - problem with CurrentDays update, also cleaned up trigger.
*  		   DF 03/20/2004 - Issue #20980 - Added Group security to contract and job master.
*				GF 05/25/2005 - 6.x
*		TJL 03/07/08 - Issue #127077, International Addresses
*			GF 03/08/2008 - issue #127076 country and state validation
*			GF 07/02/2008 - issue #128864 do not delete from bJBGC when contract is closed.
*			GF 04/22/2009 - issue #132326 remmed out moving estimates when start month changed and moved to JCCI update trigger
*			CC 06/11/2009 - issue #133487 added check on data security update to not remove default group.
*			GF 06/30/2009 - issue #132326 update StartMonth
*			DAN SO 08/18/2009 - Issue #129897 - JC Contract Forecasting
*		TJL 11/30/09 - Issue #129894, Max Retainage Enh.  Update JCCI.Retg% when JCCM.ExclACOinMaxYN = 'Y'
*			GF 01/04/2009 - issue #136920 - possible null tax group when updated from JCCM
*
*
*	 IF the following error condition exists:
*
*		invalid JCCO - company
*		invalid JCDM - department
*		invalid HQGP - customer group
*		invalid ARCM - customer
*		invalid HQPT - payment terms
*		invalid HQTX - tax code
* 	invalid Contract Status (0,1,2,3)
*		invalid DefaultBillType (P,T,N,B)
******************************************************************/
 declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
 		@jcco bCompany, @contract bContract, @processgroup varchar(10), @oldprocessgroup varchar(10),
 		@startmonth bMonth, @oldstartmonth bMonth, @retcode int, @retmsg varchar(255),
 		@seq int, @contractstatus tinyint, @validcnt2 int
 
 declare @sequence int, @openjcid tinyint, @openjccd tinyint,
         @jcidtrans bTrans, @oldjcidtrans bTrans, @item bContractItem, @jctranstype varchar(2),
         @transsource varchar(10), @description bTransDesc, @contractamt bDollar,
         @contractunits bUnits, @unitprice bUnitCost,
         @jccdtrans bTrans, @oldjccdtrans bTrans, @job bJob, @phasegroup bGroup, @phase bPhase,
         @costtype bJCCType, @source bSource, @um bUM, @esthours bHrs, @estunits bUnits,
         @estcost bDollar, @postedum bUM, @deleteflag bYN, @jbbillstatus char(1),
         @jbbillmonth bMonth, @jbbillnumber int, @jobcontract bContract, @jccdmonth bMonth,
         @thrumonth bMonth, @posteddate bDate, @NewSecurityGroup int, @OldSecurityGroup int,
         @Awarded bYN, @iPotentialProject VARCHAR(20), @dPotentialProject VARCHAR(20)
 
 SELECT @numrows = @@rowcount
 IF @numrows = 0 return
 SET nocount on
 
 select @retcode=0, @openjcid=0, @openjccd=0
 
 -- validate company and contract
 SELECT @validcnt=count(*) from inserted i JOIN deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
 IF @validcnt <> @numrows
     BEGIN
  	SELECT @errmsg = 'Changes to JCCo or Contract are not allowed'
  	GOTO error
  	END
 
 -- validate Department
 if update(Department)
     BEGIN
     SELECT @validcnt = count(*) FROM bJCDM a with (nolock) 
 	join inserted i on a.JCCo = i.JCCo and a.Department = i.Department
     IF @validcnt <> @numrows
         BEGIN
         SELECT @errmsg = 'Invalid Department'
         GOTO error
         END
     END
 
 -- validate customer group and customer
 IF UPDATE(CustGroup) or UPDATE(Customer)
     BEGIN
     SELECT @validcnt = count(*) FROM bHQGP h with (nolock) JOIN inserted i on h.Grp = i.CustGroup
     IF @validcnt <> @numrows
         BEGIN
         SELECT @errmsg = 'Invalid Customer Group'
         GOTO error
         END
 
     SELECT @validcnt = count(*) FROM bARCM a with (nolock) join inserted i on
     	a.CustGroup = i.CustGroup and a.Customer = i.Customer

     SELECT  @nullcnt = count(*) FROM inserted WHERE Customer is NULL
     IF @validcnt+ @nullcnt <> @numrows
         BEGIN
         SELECT @errmsg = 'Invalid Customer'
         GOTO error
         END
     END
 
 -- validate HQ Payment Terms
 if UPDATE(PayTerms)
 	BEGIN
 	SELECT @validcnt = count(*) FROM bHQPT a with (nolock) JOIN inserted i ON a.PayTerms = i.PayTerms
 	SELECT @nullcnt = count(*) FROM inserted WHERE PayTerms is NULL
 	IF @validcnt+isNULL( @nullcnt,0) <> @numrows
 		BEGIN
 		SELECT @errmsg = 'Invalid Payment Terms'
 		GOTO error
 		END
 	END
 
 if UPDATE(TaxGroup) or UPDATE(TaxCode)
     BEGIN
     SELECT @validcnt = count(*) FROM bHQTX h with (nolock) 
 	JOIN inserted i on h.TaxGroup=i.TaxGroup and  h.TaxCode = i.TaxCode
 	SELECT  @nullcnt = count(*) FROM inserted WHERE TaxCode is NULL
     IF @validcnt+ @nullcnt <> @numrows
         BEGIN
         SELECT @errmsg = 'Invalid Tax Code'
         GOTO error
         END
     END
 
 -- actual date closed
 SELECT @validcnt = count(*) FROM inserted i
 WHERE i.ContractStatus in (null,0,1) and i.ActualCloseDate is not NULL
 IF @validcnt <> 0
  	BEGIN
  	SELECT @errmsg = 'Contract is Open or Pending, Actual Close Date is not allowed'
  	GOTO error
  	END
 
 -- validate month closed
 SELECT @validcnt = count(*) FROM inserted
 WHERE MonthClosed is not NULL and MonthClosed<StartMonth
 IF @validcnt <> 0
  	BEGIN
  	SELECT @errmsg = 'Month Closed may not be earlier than the start month'
  	GOTO error
  	END
 
 -- validate Default Bill Type
 SELECT @validcnt = count(*) FROM inserted i WHERE i.DefaultBillType not in ('P','T','N','B')
 IF @validcnt <> 0
     BEGIN
     SELECT @errmsg = 'Invalid Default Bill Type'
     GOTO error
     END
 
 -- validate Contract Status
 SELECT @validcnt = count(*) FROM inserted i WHERE i.ContractStatus in (0,1,2,3)
 IF @validcnt <> @numrows
     BEGIN
     SELECT @errmsg = 'Invalid Contract Status'
     GOTO error
  	END
 
 -- validate
 if update(ProcessGroup)
 BEGIN
 	select @validcnt = count(*) from bJBPG h with (nolock)
 		JOIN inserted i on h.JBCo=i.JCCo and  h.ProcessGroup = i.ProcessGroup
 	select @nullcnt = count(*) from inserted where ProcessGroup is null
 	IF @validcnt + @nullcnt <> @numrows
 		begin
 		select @errmsg = 'Invalid Process Group '
 		goto error
 		end
 END
 
---- validate country
if update(BillCountry)
	begin
	select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.BillCountry=c.Country
	select @nullcnt = count(*) from inserted where BillCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Bill Country'
		goto error
		end
	end

---- validate country and state
if update(BillState)
	begin
	select @validcnt = count(*) from dbo.bHQST s with (nolock) join inserted i on i.BillCountry=s.Country and i.BillState=s.State
	select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
			join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.BillState
			where i.BillCountry is null and i.BillState is not null
	select @nullcnt = count(*) from inserted i where i.BillState is null
	if @validcnt + @validcnt2 + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country/State combination'
		goto error
		end
	end
 
---- Issue: #129897
---- validate Potential Project
if update(PotentialProject)
	begin
	select @validcnt = count(*) from dbo.PCPotentialWork p with (nolock) 
					   join inserted i on i.JCCo=p.JCCo and i.PotentialProject=p.PotentialProject
	select @nullcnt = count(*) from inserted where PotentialProject is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Potential Project'
		goto error
		end
	end
 
 ---- validate MaxRetgOpt - Issue #129894
 if update(MaxRetgOpt)
	begin
	select @validcnt = count(*) from inserted i where i.MaxRetgOpt in ('N', 'P', 'A')
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Maximum Retainage Option'
		goto error
  		end
  	end
 
  ---- validate MaxRetgDistStyle - Issue #129894
 if update(MaxRetgDistStyle)
	begin
	select @validcnt = count(*) from inserted i where i.MaxRetgDistStyle in ('C', 'I')
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Maximum Retainage Distribution Style'
		goto error
  		end
  	end
  		
 ----------------------------------------------------------------------
 -- update section - do validation above and updates below this point
 ----------------------------------------------------------------------
 
 -- write status to the job
 IF UPDATE(ContractStatus)
 BEGIN
 	-- update status to all jobs assigend to the contract
     update bJCJM set JobStatus=ContractStatus
     from inserted i join bJCJM j with (nolock) on j.JCCo=i.JCCo and j.Contract=i.Contract
 
---- 	-- if a contract has been hard or soft closed, delete that contract from JB Process groups
---- 	delete bJBGC
---- 	from inserted i join bJBGC b on i.JCCo=b.JBCo and i.Contract=b.Contract
---- 	where i.ContractStatus in (2,3)
 END
 
 -- write SIRegion to Contract Items
 IF UPDATE(SIRegion)
 BEGIN
     UPDATE bJCCI set SIRegion=i.SIRegion
     FROM inserted i join bJCCI c on c.JCCo=i.JCCo and c.Contract=i.Contract
 END
 
 
 -- update bJCID and bJCCD with changed start month for originals
 -- update Process group to bJBGC when changed
 -- update CurrentDays when OriginalDays changed
 IF update(StartMonth) or update(ProcessGroup) or update(OriginalDays)
 BEGIN
     -- @jcco
     select @jcco = min(JCCo) from inserted
     while @jcco is not null
     begin
     -- @contract
     select @contract=min(Contract) from inserted where JCCo=@jcco
     while @contract is not null
     begin
 
 	if update(OriginalDays)
 		begin
 		exec @retcode = dbo.bspJCCMCurrentDaysUpdate @jcco, @contract
 		end
 
 	if update(ProcessGroup)
 		begin
 		-- update the process group with contract information

 		select @processgroup = i.ProcessGroup, @oldprocessgroup = d.ProcessGroup
 		from inserted i join deleted d on d.JCCo=i.JCCo and d.Contract=i.Contract
 		where i.JCCo = @jcco and i.Contract = @contract
 		if isnull(@oldprocessgroup,'') = isnull(@processgroup,'') goto Start_Month
 
 		-- delete old process group from bJBGC if not null
 		if @oldprocessgroup is not null
 			begin
 			delete bJBGC where JBCo=@jcco and ProcessGroup=@oldprocessgroup and Contract=@contract
 			end
 
 		-- insert new process group in bJBGC if not exists
 		if @processgroup is not null
 			begin
 			-- since the JBGC trigger can update JCCM, make sure it doesn't already exist
 			if not exists(select top 1 1 from bJBGC with (nolock) where JBCo=@jcco 
 							and ProcessGroup=@processgroup and Contract = @contract)
 				begin
 				select @seq = isnull(max(Seq),0) + 1
 				from bJBGC with (nolock) where JBCo = @jcco and ProcessGroup = @processgroup
 				-- insert JBGC
 				insert into JBGC (JBCo, ProcessGroup, Seq, Contract)
 				values (@jcco, @processgroup, @seq, @contract)
 				end
 			end
 		end
 
 	Start_Month:
---- issue #132326 original estimates are now by the JCCI start month
-- 	if update(StartMonth)
-- 		begin
-- 	    select @startmonth=i.StartMonth, @oldstartmonth=d.StartMonth
-- 	    from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
-- 	    where i.JCCo=@jcco and i.Contract=@contract
-- 	    -- only update JCID & JCCD Original Estimates if StartMonth has changed
-- 	    if @startmonth=@oldstartmonth goto next_contract_startmonth
-- 	    -- create cursor on JCID to update original estimates for change in start month
-- 	    declare jcid_cursor cursor local fast_forward for
-- 	        select ItemTrans,Item,JCTransType,TransSource,Description,ContractAmt,ContractUnits,UnitPrice
-- 	        from bJCID with (nolock) where JCCo=@jcco and Contract=@contract and Mth=@oldstartmonth
-- 	        and TransSource='JC OrigEst' and JCTransType='OC'
-- 	
-- 	        open jcid_cursor
-- 	        select @openjcid = 1
-- 	
-- 	        jcid_cursor_loop:
-- 	        fetch next from jcid_cursor into @oldjcidtrans, @item, @jctranstype, @transsource,
-- 	                    @description,@contractamt,@contractunits,@unitprice
-- 	
-- 	        if @@fetch_status <> 0 goto jcid_cursor_end
-- 	
-- 	        -- insert JCID record for new start month
-- 	        exec @jcidtrans = bspHQTCNextTrans 'bJCID', @jcco, @startmonth, @errmsg output
-- 	        if @jcidtrans = 0 goto error
-- 	
-- 	        insert into bJCID (JCCo,Mth,ItemTrans,Contract,Item,JCTransType,TransSource,
-- 	            Description,PostedDate,ActualDate,ContractAmt,ContractUnits,UnitPrice,
-- 	            BilledUnits,BilledAmt,ReceivedAmt,CurrentRetainAmt,ReversalStatus)
-- 	        select @jcco,@startmonth,@jcidtrans,@contract,@item,@jctranstype,@transsource,@description,
-- 	            @startmonth,@startmonth,@contractamt,@contractunits,@unitprice,0,0,0,0,0
-- 	
-- 	        IF @@ERROR <> 0 goto error
-- 	
-- 	        -- delete JCID record for old start month
-- 	        delete bJCID where JCCo=@jcco and Contract=@contract and Item=@item
-- 	        and Mth=@oldstartmonth and ItemTrans=@oldjcidtrans
-- 	        if @@ERROR <> 0 goto error
-- 	
-- 	        goto jcid_cursor_loop
-- 	
-- 	        jcid_cursor_end:
-- 	            if @openjcid = 1
-- 	                begin
-- 	                close jcid_cursor
-- 	                deallocate jcid_cursor
-- 	                select @openjcid = 0
-- 	                end
-- 	
-- 	
-- 	        -- create cursor on JCCD to update original estimates for change in start month
-- 	        -- for all jobs that are assigned to the contract. Need to move all 'OE' records
-- 	        -- that are <= new start month to new start month
-- 	        if @oldstartmonth < @startmonth
-- 	            select @thrumonth = @startmonth
-- 	        else
-- 	            select @thrumonth = @oldstartmonth
-- 	
-- 	        declare jccd_cursor cursor local fast_forward for
-- 	            select a.Mth,a.CostTrans,a.Job,a.PhaseGroup,a.Phase,a.CostType,
-- 	                   a.JCTransType,a.Source,a.Description,a.UM,a.EstHours,a.EstUnits,a.EstCost,
-- 	                   a.PostedUM,a.JBBillStatus,a.JBBillMonth,a.JBBillNumber,a.PostedDate,b.Contract
-- 	     	from bJCCD a join bJCJM b on a.JCCo=b.JCCo and a.Job=b.Job
-- 	        where a.JCCo=@jcco and a.Mth<=@thrumonth and a.JCTransType='OE' and b.Contract=@contract
-- 	        and (a.Source='JC OrigEst' or a.Source='PM Intface')
-- 	
-- 	        open jccd_cursor
-- 	        select @openjccd = 1
-- 	
-- 	        jccd_cursor_loop:
-- 	        fetch next from jccd_cursor into @jccdmonth,@oldjccdtrans,@job,@phasegroup,@phase,@costtype,
-- 	                @jctranstype,@source,@description,@um,@esthours,@estunits,@estcost,@postedum,
-- 	                @jbbillstatus,@jbbillmonth,@jbbillnumber,@posteddate,@jobcontract
-- 	
-- 	        if @@fetch_status <> 0 goto jccd_cursor_end
-- 	
-- 	        -- get if month has changed
-- 	        if @jccdmonth=@startmonth goto jccd_cursor_loop
-- 	
-- 	        -- get next JCCD transaction
-- 	        exec @jccdtrans = bspHQTCNextTrans 'bJCCD', @jcco, @startmonth, @errmsg output
-- 	        if @jccdtrans = 0 goto error
-- 	
-- 	        -- insert JCCD record for new start month
-- 	        insert into bJCCD (JCCo,Mth,CostTrans,Job,PhaseGroup,Phase,CostType,PostedDate,
-- 	           ActualDate,JCTransType,Source,Description,ReversalStatus,UM,EstHours,EstUnits,
-- 	           EstCost,PostedUM,DeleteFlag,JBBillStatus,JBBillMonth,JBBillNumber)
-- 	        select @jcco,@startmonth,@jccdtrans,@job,@phasegroup,@phase,@costtype,@posteddate,
-- 	           @startmonth,@jctranstype,@source,@description,0,@um,@esthours,@estunits,
-- 	           @estcost,@postedum,'N',@jbbillstatus,@jbbillmonth,@jbbillnumber
-- 	
-- 	        IF @@ERROR <> 0 goto error
-- 	
-- 	        -- delete JCCD record for old start month
-- 	        delete from bJCCD where CostTrans=@oldjccdtrans and Mth=@jccdmonth and JCCo=@jcco
-- 	        if @@ERROR <> 0 goto error
-- 	
-- 	        goto jccd_cursor_loop
-- 	
-- 	        jccd_cursor_end:
-- 	            if @openjccd = 1
-- 	                begin
-- 	                close jccd_cursor
-- 	                deallocate jccd_cursor
-- 	                select @openjccd = 0
-- 	                end
-- 		end
 
 
     next_contract_startmonth:
     -- reset variables on every pass
     select @processgroup = null, @oldprocessgroup = null, @startmonth=null, 
 		   @oldstartmonth=null, @retcode=0, @retmsg=''
     select @contract=min(Contract) from inserted where JCCo=@jcco and Contract>@contract
     if @@rowcount=0 select @contract=null
     end
     select @jcco=min(JCCo) from inserted where JCCo>@jcco
     if @@rowcount=0 select @jcco=null
     end
 END




IF update(SecurityGroup)
	begin
 	--update security entries if security group changes.
  	declare JCCM_curs cursor fast_forward for
  	select i.JCCo, i.Contract, i.SecurityGroup, d.SecurityGroup
 	from inserted i with (nolock) 
 	join deleted d
 	on d.JCCo=i.JCCo and d.Contract=i.Contract
  
  	open JCCM_curs
  
  	fetch next from JCCM_curs into @jcco, @contract, @NewSecurityGroup, @OldSecurityGroup
  
  	while @@fetch_status = 0
  	begin
		----if new SecurityGroup is different than the old delete the old and insert the new security group
 		if isnull(@NewSecurityGroup,-1)<>isnull(@OldSecurityGroup,-1)
			begin
			delete dbo.vDDDS
			where Datatype='bContract' and Qualifier=@jcco and 
			Instance=@contract and SecurityGroup = @OldSecurityGroup
			and @OldSecurityGroup <>  (select DfltSecurityGroup from dbo.DDDTShared where Datatype = 'bContract')
 
			----Leave Security Check here and do not included it with the Update(SecurityGroup) statement
			----If Data Type Security is turned off on bContract the user has the option of clearing the Security Group
			----for all Contracts. If the statement below is move up to the update(SecurityGroup) statement then
			----that function will fail.
			if exists(select 1 from dbo.DDDTShared with (nolock) where Datatype = 'bContract' and Secure = 'Y')
				begin
				insert into dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
				select 'bContract', @jcco, @contract, @NewSecurityGroup
				where not exists(select 1 from dbo.vDDDS with (nolock) where Datatype = 'bContract'
						and Qualifier = @jcco and Instance = @contract and SecurityGroup = @NewSecurityGroup)
				end
			end
  		fetch next from JCCM_curs into @jcco, @contract, @NewSecurityGroup, @OldSecurityGroup
  	end
  
  	close JCCM_curs
  	deallocate JCCM_curs
 end


---- ISSUE: #129897 --
if update(PotentialProject)
	begin
	---- first we need to remove the contract from the old potential project
	----update dbo.vJCForecastMonth set Contract = null
	----from deleted d join dbo.vJCForecastMonth m on d.JCCo=m.JCCo and d.PotentialProject = m.PotentialProject
	----where d.PotentialProject is not null

	---- now update Potential Work and null out contract and set award flag
	update dbo.PCPotentialWork set Contract = null, Awarded = 'N', AllowForecast = 'Y', AwardedDate = null
	from deleted d join dbo.PCPotentialWork w on d.JCCo=w.JCCo and d.PotentialProject = w.PotentialProject
	where d.PotentialProject is not null

	---- now update Potential Work for new project
	update dbo.PCPotentialWork set Contract = i.Contract, Awarded = 'Y', AllowForecast = 'N', AwardedDate = GETDATE()
	from inserted i join dbo.PCPotentialWork w on i.JCCo=w.JCCo and i.PotentialProject = w.PotentialProject
	where i.PotentialProject is not null

	---- now insert JC Forecast Month detail for contracts only when no rows currently exist in JC Forecast Month
	insert dbo.vJCForecastMonth (JCCo, Contract, ForecastMonth, RevenuePct, CostPct, Notes)
	select p.JCCo, i.Contract, p.ForecastMonth, p.RevenuePct, p.CostPct, p.Notes
	from dbo.vPCForecastMonth p
	join inserted i on i.JCCo=p.JCCo and i.PotentialProject=p.PotentialProject
	where i.PotentialProject is not null
	and not exists(select top 1 1 from dbo.vJCForecastMonth m with (nolock) where m.JCCo=i.JCCo and m.Contract=i.Contract)
				
	end

-- -- -- now update bJCCI when UpdateJCCI flag is 'Y'. Columns to update:
-- -- -- Department, TaxCode, BillType, RetainagePct
-- -- -- example: if JCCM.Department is changed, and JCCI.Department is same 
-- -- -- as old JCCM.Department, then update JCCI.Department to JCCM.Department
if not exists(select top 1 1 from inserted i where i.UpdateJCCI = 'Y') goto Audit_Check

-- -- -- Department
update bJCCI set Department = i.Department
from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
join bJCCI v on v.JCCo=i.JCCo and v.Contract=i.Contract
where i.UpdateJCCI = 'Y' and isnull(i.Department,'') <> isnull(d.Department,'')
and isnull(v.Department, '') = isnull(d.Department, '')
-- -- -- TaxCode
----136920
update bJCCI set TaxGroup = i.TaxGroup, TaxCode = i.TaxCode
from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
join bJCCI v on v.JCCo=i.JCCo and v.Contract=i.Contract
where i.UpdateJCCI = 'Y' and isnull(i.TaxCode,'') <> isnull(d.TaxCode,'')
and isnull(v.TaxCode, '') = isnull(d.TaxCode, '')
-- -- -- BillType
update bJCCI set BillType = i.DefaultBillType
from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
join bJCCI v on v.JCCo=i.JCCo and v.Contract=i.Contract
where i.UpdateJCCI = 'Y' and isnull(i.DefaultBillType,'') <> isnull(d.DefaultBillType,'')
and isnull(v.BillType, '') = isnull(d.DefaultBillType, '')
-- -- -- RetainagePct
update bJCCI set RetainPCT = i.RetainagePCT
from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
join bJCCI v on v.JCCo=i.JCCo and v.Contract=i.Contract
where i.UpdateJCCI = 'Y' and isnull(i.RetainagePCT,'') <> isnull(d.RetainagePCT,'')
and isnull(v.RetainPCT, '') = isnull(d.RetainagePCT, '')
-- -- -- StartMonth
update bJCCI set StartMonth = i.StartMonth
from inserted i join deleted d on i.JCCo=d.JCCo and i.Contract=d.Contract
join bJCCI v on v.JCCo=i.JCCo and v.Contract=i.Contract
where i.UpdateJCCI = 'Y' and isnull(i.StartMonth,'') <> isnull(d.StartMonth,'')
and isnull(v.StartMonth, '') = isnull(d.StartMonth, '')

-- -- -- last set the JCCM.UpdateJCCI flag to 'N'
update bJCCM set UpdateJCCI = 'N'
from inserted i where i.UpdateJCCI = 'Y'



	
	
------ Set Values in Potential Work table and copy to the Forecast Month table
--IF UPDATE(PotentialProject)
--	BEGIN
--		SELECT @jcco = JCCo, @contract = Contract, @iPotentialProject = PotentialProject FROM INSERTED

--		-- UPDATE NEW Potential Project INFO --
--		IF @iPotentialProject IS NOT NULL 
--			BEGIN
--				SELECT @Awarded = Awarded FROM dbo.vJCPotentialWork p WITH (NOLOCK) 
--				 WHERE JCCo = @jcco AND PotentialProject = @iPotentialProject
				    
--					IF @Awarded = 'N'
--						BEGIN
--							UPDATE dbo.vJCPotentialWork
--							   SET Contract = @contract, @Awarded = 'Y', AllowForecast = 'N'
--							 WHERE JCCo = @jcco AND PotentialProject = @iPotentialProject
							 
--							UPDATE dbo.vJCForecastMonth
--							   SET Contract = @iPotentialProject
--							 WHERE JCCo = @jcco AND PotentialProject = @iPotentialProject 
--						END
--			END
			
--		-- CLEAN UP OLD/DELETED dPotentialProject --
--		SELECT @dPotentialProject = PotentialProject FROM DELETED
		
--		UPDATE dbo.vJCPotentialWork
--		   SET Contract = @contract, Awarded = 'N', AllowForecast = 'Y'
--		 WHERE JCCo = @jcco AND PotentialProject = @dPotentialProject
		 
--		UPDATE dbo.vJCForecastMonth
--		   SET Contract = NULL
--		 WHERE JCCo = @jcco AND PotentialProject = @dPotentialProject 

--	END	--IF UPDATE(PotentialProject)


Audit_Check:
-- Audit inserts
if not exists(select top 1 1 from inserted i join bJCCO c with (nolock) on i.JCCo=c.JCCo where c.AuditContracts = 'Y')
	goto Trigger_End
 
 
 IF UPDATE(Description)
 BEGIN
     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.Description,'')<>isnull(i.Description,'')
 END
 IF UPDATE(Department)
 BEGIN
     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'Department',  d.Department, i.Department, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.Department<>i.Department
 END
 IF UPDATE(OriginalDays)
 BEGIN
     INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'OriginalDays',  convert(varchar(30),d.OriginalDays), convert(varchar(30),i.OriginalDays), getdate(), SUSER_SNAME()
 	FROM inserted i
 	JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
 	JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
 	WHERE d.OriginalDays<>i.OriginalDays
  END
  IF UPDATE(ContractStatus)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ContractStatus',  convert(varchar(30),d.ContractStatus), convert(varchar(30),i.ContractStatus), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.ContractStatus<>i.ContractStatus
  END
  IF UPDATE(CurrentDays)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'CurrentDays',  convert(varchar(30),d.CurrentDays), convert(varchar(30),i.CurrentDays), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                  WHERE d.CurrentDays<>i.CurrentDays
  END
  IF UPDATE(StartMonth)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'StartMonth',  convert(varchar(30),d.StartMonth), convert(varchar(30),i.StartMonth), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.StartMonth<>i.StartMonth
  END
  IF UPDATE(MonthClosed)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'MonthClosed',  convert(varchar(30),d.MonthClosed), convert(varchar(30),i.MonthClosed), getdate(), SUSER_SNAME()
                      FROM inserted i
 
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                         WHERE isnull(d.MonthClosed,'')<>isnull(i.MonthClosed,'')
  END
  IF UPDATE(ProjCloseDate)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ProjCloseDate',  convert(varchar(30),d.ProjCloseDate), convert(varchar(30),i.ProjCloseDate), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.ProjCloseDate,'')<>isnull(i.ProjCloseDate,'')
  END
  IF UPDATE(ActualCloseDate)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ActualCloseDate',  convert(varchar(30),d.ActualCloseDate), convert(varchar(30),i.ActualCloseDate), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                    WHERE isnull(d.ActualCloseDate,'')<>isnull(i.ActualCloseDate,'')
  END
  IF UPDATE(CustGroup)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'CustGroup',  convert(varchar(30),d.CustGroup), convert(varchar(30),i.CustGroup), getdate(), SUSER_SNAME()
     FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.CustGroup,0)<>isnull(i.CustGroup,0)
  END
  IF UPDATE(Customer)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'Customer',  convert(varchar(30),d.Customer), convert(varchar(30),i.Customer), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.Customer,-255)<>isnull(i.Customer,-255)
  END
  IF UPDATE(PayTerms)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'PayTerms',  d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.PayTerms,'')<>isnull(i.PayTerms,'')
  END
  IF UPDATE(TaxInterface)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'TaxInterface',  d.TaxInterface, i.TaxInterface, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                          WHERE d.TaxInterface<>i.TaxInterface
  END
  IF UPDATE(TaxGroup)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'TaxGroup',  convert(varchar(30),d.TaxGroup), convert(varchar(30),i.TaxGroup), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.TaxGroup,0)<>isnull(i.TaxGroup,0)
  END
  IF UPDATE(TaxCode)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'TaxCode',  d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE isnull(d.TaxCode,'')<>isnull(i.TaxCode,'')
  END
  IF UPDATE(MaxRetgOpt)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'MaxRetgOpt',  d.MaxRetgOpt, i.MaxRetgOpt, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.MaxRetgOpt<>i.MaxRetgOpt
  END
  IF UPDATE(MaxRetgPct)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'MaxRetgPct',  convert(varchar(30),d.MaxRetgPct), convert(varchar(30),i.MaxRetgPct), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.MaxRetgPct<>i.MaxRetgPct
  END  
  IF UPDATE(MaxRetgAmt)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'MaxRetgAmt',  convert(varchar(30),d.MaxRetgAmt), convert(varchar(30),i.MaxRetgAmt), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.MaxRetgAmt<>i.MaxRetgAmt
  END  
  IF UPDATE(InclACOinMaxYN)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'InclACOinMaxYN',  d.InclACOinMaxYN, i.InclACOinMaxYN, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.InclACOinMaxYN<>i.InclACOinMaxYN
  END  
 IF UPDATE(MaxRetgDistStyle)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'MaxRetgDistStyle',  d.MaxRetgDistStyle, i.MaxRetgDistStyle, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.MaxRetgDistStyle<>i.MaxRetgDistStyle
  END
  IF UPDATE(RetainagePCT)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'RetainagePCT',  convert(varchar(30),d.RetainagePCT), convert(varchar(30),i.RetainagePCT), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                           WHERE d.RetainagePCT<>i.RetainagePCT
  END
  IF UPDATE(DefaultBillType)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'DefaultBillType',  d.DefaultBillType, i.DefaultBillType, getdate(), SUSER_SNAME()
                      FROM inserted i
                         JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
                          WHERE d.DefaultBillType<>i.DefaultBillType
  END
  IF UPDATE(SIRegion)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'SIRegion',  d.SIRegion, i.SIRegion, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.SIRegion,'')<>isnull(i.SIRegion,'')
  END
  IF UPDATE(SIMetric)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'SIMetric',  d.SIMetric, i.SIMetric, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.SIMetric,'')<>isnull(i.SIMetric,'')
  END
  IF UPDATE(ProcessGroup)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ProcessGroup',  d.ProcessGroup, i.ProcessGroup, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.ProcessGroup,'')<>isnull(i.ProcessGroup,'')
  END
  IF UPDATE(BillAddress)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillAddress',  d.BillAddress, i.BillAddress, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillAddress,'')<>isnull(i.BillAddress,'')
  END
  IF UPDATE(BillAddress2)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillAddress2',  d.BillAddress2, i.BillAddress2, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillAddress2,'')<>isnull(i.BillAddress2,'')
  END
  IF UPDATE(BillCity)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillCity',  d.BillCity, i.BillCity, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillCity,'')<>isnull(i.BillCity,'')
  END
  IF UPDATE(BillState)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillState',  d.BillState, i.BillState, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillState,'')<>isnull(i.BillState,'')
  END
  IF UPDATE(BillZip)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillZip',  d.BillZip, i.BillZip, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillZip,'')<>isnull(i.BillZip,'')
  END
  IF UPDATE(BillCountry)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillCountry',  d.BillCountry, i.BillCountry, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillCountry,'')<>isnull(i.BillCountry,'')
  END
  IF UPDATE(BillOnCompletionYN)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillOnCompletionYN',  d.BillOnCompletionYN, i.BillOnCompletionYN, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.BillOnCompletionYN<>i.BillOnCompletionYN
  END
  IF UPDATE(CustomerReference)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'CustomerReference',  d.CustomerReference, i.CustomerReference, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.CustomerReference,'')<>isnull(i.CustomerReference,'')
  END
  IF UPDATE(CompleteYN)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'CompleteYN',  d.CompleteYN, i.CompleteYN, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.CompleteYN<>i.CompleteYN
  END
  IF UPDATE(RoundOpt)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'RoundOpt',  d.RoundOpt, i.RoundOpt, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.RoundOpt<>i.RoundOpt
  END
  IF UPDATE(ReportRetgItemYN)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ReportRetgItemYN',  d.ReportRetgItemYN, i.ReportRetgItemYN, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.ReportRetgItemYN<>i.ReportRetgItemYN
  END
  IF UPDATE(ProgressFormat)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ProgressFormat',  d.ProgressFormat, i.ProgressFormat, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.ProgressFormat,'')<>isnull(i.ProgressFormat,'')
  END
  IF UPDATE(TMFormat)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'TMFormat',  d.TMFormat, i.TMFormat, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.TMFormat,'')<>isnull(i.TMFormat,'')
  END
  IF UPDATE(BillGroup)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillGroup',  d.BillGroup, i.BillGroup, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillGroup,'')<>isnull(i.BillGroup,'')
  END
  IF UPDATE(BillDayOfMth)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'BillDayOfMth',  d.BillDayOfMth, i.BillDayOfMth, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.BillDayOfMth,'')<>isnull(i.BillDayOfMth,'')
  END
  IF UPDATE(ArchitectName)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ArchitectName',  d.ArchitectName, i.ArchitectName, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.ArchitectName,'')<>isnull(i.ArchitectName,'')
  END
  IF UPDATE(ArchitectProject)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ArchitectProject',  d.ArchitectProject, i.ArchitectProject, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.ArchitectProject,'')<>isnull(i.ArchitectProject,'')
  END
  IF UPDATE(ContractForDesc)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'ContractForDesc',  d.ContractForDesc, i.ContractForDesc, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.ContractForDesc,'')<>isnull(i.ContractForDesc,'')
  END
  IF UPDATE(StartDate)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'StartDate',  convert(varchar(30),d.StartDate), convert(varchar(30),i.StartDate), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.StartDate,'')<>isnull(i.StartDate,'')
  END
  IF UPDATE(JBTemplate)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'JBTemplate',  d.JBTemplate, i.JBTemplate, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE isnull(d.JBTemplate,'')<>isnull(i.JBTemplate,'')
  END
  IF UPDATE(JBFlatBillingAmt)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'JBFlatBillingAmt',  convert(varchar(30),d.JBFlatBillingAmt), convert(varchar(30),i.JBFlatBillingAmt), getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.JBFlatBillingAmt<>i.JBFlatBillingAmt
  END
  IF UPDATE(JBLimitOpt)
  BEGIN
  INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Cntrct: ' + i.Contract, i.JCCo, 'C',
  	'JBLimitOpt',  d.JBLimitOpt, i.JBLimitOpt, getdate(), SUSER_SNAME()
                      FROM inserted i
                           JOIN deleted d  ON d.JCCo=i.JCCo  AND d.Contract=i.Contract
                           JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
          WHERE d.JBLimitOpt<>i.JBLimitOpt
  END
 IF UPDATE(RecType)
 BEGIN
 
 	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract, i.JCCo, 'C',
  	'RecType',  convert(varchar(10),d.RecType), convert(varchar(10),i.RecType), getdate(), SUSER_SNAME()
 	FROM inserted i
 	JOIN deleted d on d.JCCo=i.JCCo  AND d.Contract=i.Contract
 	JOIN bJCCO with (nolock) on i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
 	WHERE isnull(d.RecType,0) <> isnull(i.RecType,0)
 END
 
 IF UPDATE(SecurityGroup)
 BEGIN
 
 	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract, i.JCCo, 'C',
  	'Security Group',  convert(varchar(5),d.SecurityGroup), convert(varchar(5),i.SecurityGroup), getdate(), SUSER_SNAME()
 	FROM inserted i
 	JOIN deleted d on d.JCCo=i.JCCo  AND d.Contract=i.Contract
 	JOIN bJCCO with (nolock) on i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
 	WHERE isnull(d.SecurityGroup,-1) <> isnull(i.SecurityGroup,-1)
 END

 -- ISSUE: #129897 --
 IF UPDATE(PotentialProject)
 BEGIN
 	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bJCCM','JC Co#: ' + convert(char(3), i.JCCo) + ' Contract: ' + i.Contract, i.JCCo, 'C',
  	'Potential Project',  convert(varchar(5),d.PotentialProject), convert(varchar(5),i.PotentialProject), getdate(), SUSER_SNAME()
 	FROM inserted i
 	JOIN deleted d on d.JCCo=i.JCCo  AND d.Contract=i.Contract
 	JOIN bJCCO with (nolock) on i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
 	WHERE isnull(d.PotentialProject,-1) <> isnull(i.PotentialProject,-1)
 END




Trigger_End:
	return


error:
     if @openjcid = 1
         begin
         close jcid_cursor
         deallocate jcid_cursor
         select @openjcid = 0
         end
 
     if @openjccd = 1
         begin
         close jccd_cursor
         deallocate jccd_cursor
         select @openjccd = 0
         end
 
      SELECT @errmsg = @errmsg +  ' -  cannot update Contract!'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction








GO
CREATE UNIQUE CLUSTERED INDEX [biJCCM] ON [dbo].[bJCCM] ([JCCo], [Contract]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCM] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdCurrentMonth]', N'[dbo].[bJCCM].[StartMonth]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[TaxInterface]'
GO
EXEC sp_bindrule N'[dbo].[brBillType]', N'[dbo].[bJCCM].[DefaultBillType]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[SIMetric]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[BillOnCompletionYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[CompleteYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bJCCM].[CompleteYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[ReportRetgItemYN]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bJCCM].[ReportRetgItemYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCM].[ClosePurgeFlag]'
GO
