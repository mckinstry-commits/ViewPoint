CREATE TABLE [dbo].[bPMWM]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[Item] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NULL,
[MatlDescription] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[UM] [dbo].[bUM] NULL,
[Units] [dbo].[bUnits] NULL CONSTRAINT [DF_bPMWM_Units] DEFAULT ((0)),
[UnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bPMWM_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL CONSTRAINT [DF_bPMWM_ECM] DEFAULT ('E'),
[Amount] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMWM_Amount] DEFAULT ((0)),
[ImportItem] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportPhase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportCostType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMaterial] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportVendor] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportUM] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc3] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Errors] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MatlOption] [char] (1) COLLATE Latin1_General_BIN NULL,
[RecvYN] [dbo].[bYN] NULL CONSTRAINT [DF_bPMWM_RecvYN] DEFAULT ('N'),
[Location] [dbo].[bLoc] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxType] [tinyint] NULL,
[SendFlag] [dbo].[bYN] NULL CONSTRAINT [DF_bPMWM_SendFlag] DEFAULT ('Y'),
[MSCo] [dbo].[bCompany] NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[INCo] [dbo].[bCompany] NULL,
[Supplier] [dbo].[bVendor] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWMi    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWMi] on [dbo].[bPMWM] for INSERT as

/*--------------------------------------------------------------
     *  Insert trigger for PMWM
     *  Created By: GF  06/18/99
	 *
	 *
     *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int,
		@importid varchar(10), @sequence int, @item bContractItem, @importitem varchar(30),
		@phasegroup bGroup, @phase bPhase, @pmco bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on 

------ use a cursor to process each inserted row
if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @item=Item, @phasegroup=PhaseGroup, @phase=Phase
	from inserted
else
	begin
   	declare bPMWM_insert cursor LOCAL FAST_FORWARD for select PMCo, ImportId, Sequence, Item, PhaseGroup, Phase
   	from inserted

   	open bPMWM_insert

	fetch next from bPMWM_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase

	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
if @item is null and @phase is not null
	begin
	select @item=Item, @importitem=ImportItem
	from bPMWP where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase
	------ update PMWM
	update bPMWM set Item=@item, ImportItem=@importitem
	where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	end


if @numrows > 1
   	begin
	fetch next from bPMWM_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWM_insert
   		deallocate bPMWM_insert
   		end
   	end


return



error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMWM'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWMu    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWMu] on [dbo].[bPMWM] for UPDATE as

/*--------------------------------------------------------------
    *
    *  Update trigger for PMWM
    *  Created By: GF 06/20/99
    *
    *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @importid varchar(10),
		@sequence int, @item bContractItem, @phasegroup bGroup, @phase bPhase,
		@costtype bJCCType, @importitem varchar(30), @importphase varchar(30),
		@pmco bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

------ check for changes to Sequence
if update(Sequence)
	begin
	select @errmsg = 'Cannot change Sequence'
	goto error
	end

------ check for changes to ImportId
if update(ImportId)
	begin
	select @errmsg = 'Cannot change ImportId'
	goto error
	end


------ use a cursor to process each inserted row
if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType
	from inserted
else
	begin
   	declare bPMWM_insert cursor LOCAL FAST_FORWARD for select PMCo, ImportId, Sequence, PhaseGroup, Phase, CostType
   	from inserted

   	open bPMWM_insert

	fetch next from bPMWM_insert into @pmco, @importid, @sequence, @phasegroup, @phase, @costtype

	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
if update(Phase)
	begin
	select @item=Item, @importitem=ImportItem, @importphase=ImportPhase
	from bPMWP where PMCo=@pmco and ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase
	if @@rowcount=0
		begin 
		select @errmsg = 'Invalid Phase, not in PMWP.'
		goto error
		end
	------ update PMWM
	update bPMWM set Item=@item, ImportItem=@importitem, ImportPhase=@importphase
	where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	end

if @numrows > 1
   	begin
	fetch next from bPMWM_insert into @pmco, @importid, @sequence, @phasegroup, @phase, @costtype
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWM_insert
   		deallocate bPMWM_insert
   		end
   	end




return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMWM'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction




GO
ALTER TABLE [dbo].[bPMWM] ADD CONSTRAINT [CK_bPMWM_ECM] CHECK (([ECM]='M' OR [ECM]='C' OR [ECM]='E' OR [ECM]=NULL))
GO
ALTER TABLE [dbo].[bPMWM] ADD CONSTRAINT [PK_bPMWM] PRIMARY KEY CLUSTERED  ([PMCo], [ImportId], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWM] WITH NOCHECK ADD CONSTRAINT [FK_bPMWM_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
