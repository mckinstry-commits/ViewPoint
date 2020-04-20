CREATE TABLE [dbo].[bPMWS]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[Item] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NULL,
[Description] [dbo].[bItemDesc] NULL,
[Units] [dbo].[bUnits] NULL CONSTRAINT [DF_bPMWS_Units] DEFAULT ((0)),
[UM] [dbo].[bUM] NULL,
[UnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bPMWS_UnitCost] DEFAULT ((0)),
[ECM] [dbo].[bECM] NULL,
[Amount] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMWS_Amount] DEFAULT ((0)),
[WCRetgPct] [dbo].[bPct] NULL CONSTRAINT [DF_bPMWS_WCRetgPct] DEFAULT ((0)),
[ImportItem] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportPhase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportCostType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
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
[SMRetgPct] [dbo].[bPct] NULL CONSTRAINT [DF_bPMWS_SMRetgPct] DEFAULT ((0)),
[Supplier] [dbo].[bVendor] NULL,
[SendFlag] [dbo].[bYN] NULL CONSTRAINT [DF_bPMWS_SendFlag] DEFAULT ('Y'),
[TaxType] [tinyint] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[TaxGroup] [dbo].[bGroup] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMWSi    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWSi] on [dbo].[bPMWS] for INSERT as

/*--------------------------------------------------------------
     *  Insert trigger for PMWS
     *  Created By: GF 06/18/99
     *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, 
   		@importid varchar(10), @sequence int, @item bContractItem, @importitem varchar(30), 
   		@phasegroup bGroup, @phase bPhase, @pmco bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on 


if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @item=Item, @phasegroup=PhaseGroup, @phase=Phase
	from inserted
else
	begin
   	------ use a cursor to process each inserted row
   	declare bPMWS_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, ImportId, Sequence, Item, PhaseGroup, Phase
   	from inserted

   	open bPMWS_insert

	fetch next from bPMWS_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase

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
          
   	update bPMWS set Item=@item, ImportItem=@importitem
   	where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
   	end
   
   
   if @numrows > 1
   	begin
       fetch next from bPMWS_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase
   
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWS_insert
   		deallocate bPMWS_insert
   		end
   	end


   
   /*
   -- Pseudo cursor
   select @importid=min(ImportId) from inserted
   while @importid is not null
   begin
   select @sequence=min(Sequence) from inserted where ImportId=@importid
   while @sequence is not null
   begin
   
       select @item=Item, @phasegroup=PhaseGroup, @phase=Phase
       from bPMWS where ImportId=@importid and Sequence=@sequence
       if @item is null and @phase is not null
          begin
            select @item=Item, @importitem=ImportItem
            from bPMWP where ImportId=@importid and PhaseGroup=@phasegroup and Phase=@phase
          
            update bPMWS set Item=@item, ImportItem=@importitem
          		where ImportId=@importid and Sequence=@sequence
          end
          		
   select @sequence=min(Sequence) from inserted where ImportId=@importid and Sequence>@sequence
   end
   select @importid=min(ImportId) from inserted where ImportId>@importid
   end
   */
   
   
   
   return
   
   
   
   error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMWS'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWSu    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWSu] on [dbo].[bPMWS] for UPDATE as

/*--------------------------------------------------------------
    *  Update trigger for PMWS
    *  Created By: GF  06/20/99
    *
    *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int,
   		@importid varchar(10), @sequence int, @item bContractItem, @phasegroup bGroup, 
   		@phase bPhase, @costtype bJCCType, @importphase varchar(30), @importitem varchar(30),
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



if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @phasegroup=PhaseGroup, @phase=Phase, @costtype=CostType
	from inserted
else
	begin
   	------ use a cursor to process each inserted row
   	declare bPMWS_update cursor LOCAL FAST_FORWARD for select PMCo, ImportId, Sequence, PhaseGroup, Phase, CostType
   	from inserted

   	open bPMWS_update

	fetch next from bPMWS_update into @pmco, @importid, @sequence, @phasegroup, @phase, @costtype

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
   	if @@rowcount = 0
   		begin 
   		select @errmsg = 'Invalid Phase, not in PMWP.'
   		goto error
   		end

   	update bPMWS set Item=@item, ImportItem=@importitem, ImportPhase=@importphase
   	where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
   	end


if @numrows > 1
	begin
	fetch next from bPMWS_update into @pmco, @importid, @sequence, @phasegroup, @phase, @costtype
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWS_update
   		deallocate bPMWS_update
   		end
   	end



   return



error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot update PMWS'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction




GO
ALTER TABLE [dbo].[bPMWS] ADD CONSTRAINT [CK_bPMWS_ECM] CHECK (([ECM]='M' OR [ECM]='C' OR [ECM]='E' OR [ECM]=NULL))
GO
ALTER TABLE [dbo].[bPMWS] ADD CONSTRAINT [PK_bPMWS] PRIMARY KEY CLUSTERED  ([PMCo], [ImportId], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWS] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWS] WITH NOCHECK ADD CONSTRAINT [FK_bPMWS_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
