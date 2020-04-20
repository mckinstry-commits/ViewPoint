CREATE TABLE [dbo].[bPMOA]
(
[PMCo] [dbo].[bCompany] NOT NULL,
[Project] [dbo].[bJob] NOT NULL,
[PCOType] [dbo].[bDocType] NOT NULL,
[PCO] [dbo].[bPCO] NOT NULL,
[PCOItem] [dbo].[bPCOItem] NOT NULL,
[AddOn] [int] NOT NULL,
[Basis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[AddOnPercent] [numeric] (12, 6) NULL,
[AddOnAmount] [dbo].[bDollar] NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOA_Status] DEFAULT ('Y'),
[TotalType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOA_TotalType] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[Include] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMOA_Include] DEFAULT ('N'),
[NetCalcLevel] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMOA_NetCalcLevel] DEFAULT ('T'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BasisCostType] [dbo].[bJCCType] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[RevACOItemId] [bigint] NULL,
[RevACOItemAmt] [dbo].[bDollar] NULL,
[AmtNotRound] [dbo].[bDollar] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************************/
CREATE trigger [dbo].[btPMOAd] on [dbo].[bPMOA] for DELETE as
/*--------------------------------------------------------------
* Delete trigger for PMOA
* Created By:	GF 08/23/2000
* Modified By:	GF 11/09/2004 - issue #22768 cleanup changed from pseudo to local cursor
*				GF 02/29/2008 - issue #127195 #127210 changed to use vspPMOACalcs
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, 
		@retcode int, @opencursor tinyint, @pmco bCompany, @project bJob,
		@pcotype bPCOType, @pco bPCO, @pcoitem bPCOItem

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

set @opencursor = 0
   
   
   -- -- -- declare cursor on delete to re-calculate pending amount
   if @numrows = 1
   	select @pmco=PMCo, @project=Project, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem
   	from deleted
   else
   	begin
   	-- use a cursor to process each row
   	declare bPMOA_delete cursor LOCAL FAST_FORWARD
   	for select PMCo, Project, PCOType, PCO, PCOItem
   	from deleted
   
   	open bPMOA_delete
   	set @opencursor = 1
   	
   	fetch next from bPMOA_delete into @pmco, @project, @pcotype, @pco, @pcoitem
   	
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   bPMOA_delete:
   -- -- -- if a PCO-PCOitem then re-calculate pending amount
   if isnull(@pco,'') <> '' and isnull(@pcoitem,'') <> ''
   	begin
   	-- re-calculate addons if not purging job
   	if exists(select JCCo from bJCJM where JCCo=@pmco and Job=@project and ClosePurgeFlag <> 'Y')
   		begin
       	exec @retcode = dbo.vspPMOACalcs @pmco, @project, @pcotype, @pco, @pcoitem
   		end
   	end
   
   
   if @numrows > 1
   	begin
   	fetch next from bPMOA_delete into @pmco, @project, @pcotype, @pco, @pcoitem
    	if @@fetch_status = 0
    		goto bPMOA_delete
    	else
    		begin
    		close bPMOA_delete
    		deallocate bPMOA_delete
   		set @opencursor = 0
    		end
    	end
   
   
   
   
   
   return
   
   
   
   error:
   	if @opencursor = 1
    		begin
    		close bPMOA_delete
    		deallocate bPMOA_delete
   		set @opencursor = 0
    		end
   
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete from PMOA'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************************/
CREATE  trigger [dbo].[btPMOAi] on [dbo].[bPMOA] for INSERT as
/*--------------------------------------------------------------
* Insert trigger for PMOA
* Created By:	GF 11/27/2000
* Modified By:	DANF 09/06/02 - 17738 Added Phase Group to bspJCADDCOSTTYPE
*
*
*
*  For each add-on being inserted, verify JCJP and JCCH to see if
*  add-on phase & cost type are valid. If not, then insert into
*  tables. If the change order item has a contract item assigned
*  then use that contract item, else use first item found for the
*  contract.
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @opencursor tinyint, @rcode int,
		@pmco bCompany, @project bJob, @pcotype bPCOType, @pco bPCO, @pcoitem bPCOItem,
   		@um bUM, @override char(1), @addon int, @phasegroup bGroup, @phase bPhase, 
   		@costtype bJCCType, @jobcontract bContract, @addonitem bContractItem, 
   		@coitem bContractItem, @contractitem bContractItem
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- insert add-on phase and cost type into JCJP and JCCH if needed
   if @numrows = 1
       begin
       -- if only one row inserted, no cursor is needed
       select @pmco=PMCo, @project=Project, @pcotype=PCOType, @pco=PCO, @pcoitem=PCOItem, @addon=AddOn
       from inserted
       end
   else
       begin
       -- use a cursor to process all inserted rows
       declare bPMOA_insert cursor for select PMCo, Project, PCOType, PCO, PCOItem, AddOn
       from inserted
   
       open bPMOA_insert
       set @opencursor = 1
   
       -- get 1st row inserted
       fetch next from bPMOA_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @addon
   
       if @@fetch_status <> 0
           begin
           select @errmsg = 'Cursor error '
           goto error
           end
       end
   
   ADDON_Process:
   
set @contractitem = null
-- get needed job data
select @jobcontract=Contract from bJCJM where JCCo=@pmco and Job=@project
if @@rowcount = 0 goto next_cursor_row

-- get PCO item contract item
select @coitem=ContractItem from bPMOI 
where PMCo=@pmco and Project=@project and PCOType=@pcotype and PCO=@pco and PCOItem=@pcoitem
if @@rowcount = 0 goto next_cursor_row

---- get needed addon data
select @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType, @addonitem=Item
from bPMPA where PMCo=@pmco and Project=@project and AddOn=@addon
if @@rowcount = 0
	begin
	select @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType, @addonitem=Item
	from bPMCA where PMCo=@pmco and Addon=@addon
	if @@rowcount = 0 goto next_cursor_row
	end

-- use addon contract item is valid, else use pco item contract item if valid
if @addonitem is not null
	begin
	if exists(select * from bJCCI where JCCo=@pmco and Contract=@jobcontract and Item=@addonitem)
	select @contractitem=@addonitem
	end
if @coitem is not null and @contractitem is null
	begin
	if exists(select * from bJCCI where JCCo=@pmco and Contract=@jobcontract and Item=@coitem)
	select @contractitem=@coitem
	end

if @phase is not null
	begin
	-- validate standard phase - if it doesnt exist in JCJP try to add it
	exec @rcode = dbo.bspJCADDPHASE @pmco, @project, @phasegroup, @phase,'Y',@contractitem, @errmsg output
	if @rcode <> 0 goto next_cursor_row

	-- validate Cost Type - if JCCH doesnt exist try to add it
	exec @rcode = dbo.bspJCADDCOSTTYPE @jcco=@pmco, @job=@project, @phasegroup=@phasegroup, 
	@phase=@phase, @costtype=@costtype, @um='LS',@override='P', @msg=@errmsg output
	if @rcode <> 0 goto next_cursor_row
	end


next_cursor_row:

if @numrows > 1
   	begin
       fetch next from bPMOA_insert into @pmco, @project, @pcotype, @pco, @pcoitem, @addon
   	if @@fetch_status = 0
   		goto ADDON_Process
   	else
   		begin
   		close bPMOA_insert
   		deallocate bPMOA_insert
   		set @opencursor = 0
   		end
   	end
   
   
   return
   
   
   
   error:
       if @opencursor = 1
   		begin
   		close bPMOA_insert
   		deallocate bPMOA_insert
   		set @opencursor = 0
   		end
   
       select @errmsg = isnull(@errmsg,'') +  ' - cannot insert into PMOA!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMOAu    Script Date: 8/28/99 9:37:56 AM ******/
CREATE  trigger [dbo].[btPMOAu] on [dbo].[bPMOA] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMOA
 * Created By:	GF 01/15/2007 - 6.x document history enhancement
 * Modified By:	GF 02/26/2008 - issue #127195 audit change for pct
 *
 *
 *
 *
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- PMDH inserts
if not exists(select top 1 1 from inserted i join bPMCO c with (nolock) on i.PMCo=c.PMCo and isnull(c.DocHistPCO,'N') = 'Y')
	begin
  	goto trigger_end
	end

if update(Basis)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C',
			'Basis', d.Basis, i.Basis, SUSER_SNAME(),
			'AddOn: ' + convert(varchar(10),i.AddOn) + ' basis has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType
	and d.PCO=i.PCO and d.PCOItem=i.PCOItem and d.AddOn=i.AddOn
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(d.Basis,'') <> isnull(i.Basis,'') and isnull(c.DocHistPCO,'N') = 'Y'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.AddOn, i.Basis, d.Basis
	end
if update(AddOnPercent)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C',
			'AddOnPercent', convert(varchar(20),d.AddOnPercent), convert(varchar(20),i.AddOnPercent), SUSER_SNAME(),
			'AddOn: ' + convert(varchar(10),i.AddOn) + ' percentage has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType
	and d.PCO=i.PCO and d.PCOItem=i.PCOItem and d.AddOn=i.AddOn
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.AddOnPercent),'') <> isnull(convert(varchar(20),i.AddOnPercent),'')
	and isnull(c.DocHistPCO,'N') = 'Y' and i.Basis in ('P','C')
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.AddOn, i.Basis, i.AddOnPercent, d.AddOnPercent
	end
if update(AddOnAmount)
	begin
	insert into bPMDH (PMCo, Project, Seq, DocCategory, DocType, Document, Rev, ActionDateTime,
			FieldType, FieldName, OldValue, NewValue, UserName, Action, PCOItem)
	select i.PMCo, i.Project, isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.PMCo ASC, i.Project ASC, i.PCOType ASC),
			'PCO', i.PCOType, i.PCO, null, getdate(), 'C',
			'AddOnAmount', convert(varchar(20),d.AddOnAmount), convert(varchar(20),i.AddOnAmount), SUSER_SNAME(),
			'AddOn: ' + convert(varchar(10),i.AddOn) + ' amount has been changed', i.PCOItem
	from inserted i join deleted d on d.PMCo=i.PMCo and d.Project=i.Project and d.PCOType=i.PCOType
	and d.PCO=i.PCO and d.PCOItem=i.PCOItem and d.AddOn=i.AddOn
	left join bPMDH h on h.PMCo=i.PMCo and h.Project=i.Project and h.DocCategory='PCO'
	join bPMCO c with (nolock) on i.PMCo=c.PMCo
	where isnull(convert(varchar(20),d.AddOnAmount),'') <> isnull(convert(varchar(20),i.AddOnAmount),'')
	and isnull(c.DocHistPCO,'N') = 'Y' and i.Basis = 'A'
	group by i.PMCo, i.Project, i.PCOType, i.PCO, i.PCOItem, i.AddOn, i.Basis, i.AddOnAmount, d.AddOnAmount
	end


trigger_end:

return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMOA'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[bPMOA] ADD CONSTRAINT [PK_bPMOA] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bPMOA_PMCoProjectPCOType] ON [dbo].[bPMOA] ([PMCo], [Project], [PCOType], [PCO], [PCOItem], [AddOn]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMOA] WITH NOCHECK ADD CONSTRAINT [FK_bPMOA_bPMDT] FOREIGN KEY ([PCOType]) REFERENCES [dbo].[bPMDT] ([DocType])
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMOA].[Include]'
GO
