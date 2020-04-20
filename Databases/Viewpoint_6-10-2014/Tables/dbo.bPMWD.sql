CREATE TABLE [dbo].[bPMWD]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[Item] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[UM] [dbo].[bUM] NULL,
[BillFlag] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMWD_BillFlag] DEFAULT ('C'),
[ItemUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWD_ItemUnitFlag] DEFAULT ('N'),
[PhaseUnitFlag] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWD_PhaseUnitFlag] DEFAULT ('N'),
[Hours] [dbo].[bHrs] NULL CONSTRAINT [DF_bPMWD_Hours] DEFAULT ((0)),
[Units] [dbo].[bUnits] NULL CONSTRAINT [DF_bPMWD_Units] DEFAULT ((0)),
[Costs] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMWD_Costs] DEFAULT ((0)),
[ImportItem] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportPhase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportCostType] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportUM] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc3] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Errors] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWD_ActiveYN] DEFAULT ('Y'),
[BuyOutYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWD_BuyOutYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPMWDd    Script Date: 8/28/99 9:38:04 AM ******/
CREATE trigger [dbo].[btPMWDd] on [dbo].[bPMWD] for DELETE as

/*--------------------------------------------------------------
    *
    *  Delete trigger for PMWD
    *  Created By: GF 06/18/99
    *  Modified By: JayR 03/28/2012
    *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


------ check bPMWS for Cost Type
if not exists(select * from deleted d JOIN bPMWD o ON d.PMCo=o.PMCo 
				and d.ImportId=o.ImportId and d.Item=o.Item and d.Phase=o.Phase
				and d.CostType=o.CostType)
	begin
	if exists(select * from deleted d JOIN bPMWS s ON d.PMCo=s.PMCo
				and d.ImportId=s.ImportId and d.Item=s.Item and d.Phase=s.Phase
				and d.CostType=s.CostType)
		begin
		RAISERROR('Cost Type exist in bPMWS - cannot delete from PMWD', 11, -1)
		rollback TRANSACTION
		RETURN
		end
	end


------ check bPMWM for Cost Type
if not exists(select * from deleted d JOIN bPMWD o ON d.PMCo=o.PMCo
				and d.ImportId=o.ImportId and d.Item=o.Item and d.Phase=o.Phase
				and d.CostType=o.CostType)
	begin
	if exists(select * from deleted d JOIN bPMWM m ON d.PMCo=m.PMCo
				and d.ImportId=m.ImportId and d.Item=m.Item and d.Phase=m.Phase
				and d.CostType=m.CostType)
		begin
		RAISERROR('Cost Type exist in bPMWM - cannot delete from PMWD', 11, -1)
		rollback TRANSACTION
		RETURN
		end
	end

RETURN 





GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWDi    Script Date: 8/28/99 9:38:04 AM ******/
CREATE trigger [dbo].[btPMWDi] on [dbo].[bPMWD] for INSERT as

/*--------------------------------------------------------------
     *  Insert trigger for PMWD
     *  Created By: GF 06/16/99
	 *
	 *
     *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @importid varchar(10),
		@sequence int, @item bContractItem, @importitem varchar(30), @phase bPhase,
		@phasegroup bGroup, @pmco bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


------ use a cursor to process each inserted row
if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @item=Item, @phasegroup=PhaseGroup, @phase=Phase
	from inserted
else
	begin
   	declare bPMWD_insert cursor LOCAL FAST_FORWARD for select PMCo, ImportId, Sequence, Item, PhaseGroup, Phase
   	from inserted

   	open bPMWD_insert

	fetch next from bPMWD_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase

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
   
	update bPMWD set Item=@item, ImportItem=@importitem
	where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
	end


if @numrows > 1
   	begin
	fetch next from bPMWD_insert into @pmco, @importid, @sequence, @item, @phasegroup, @phase
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWD_insert
   		deallocate bPMWD_insert
   		end
   	end



return



error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into PMWD'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMWDu    Script Date: 8/28/99 9:38:04 AM ******/
CREATE trigger [dbo].[btPMWDu] on [dbo].[bPMWD] for UPDATE as

/*--------------------------------------------------------------
    *  Update trigger for PMWD
    *  Created By: GF 06/17/99
    *
    *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on


------ check for changes to Sequence 
if update(Sequence)
	begin
	RAISERROR('Cannot change Sequence - cannot update PMWD', 11, -1)
	rollback TRANSACTION
	RETURN
	end


------ check for changes to ImportId
if update(ImportId)
	begin
	RAISERROR('Cannot change ImportId - cannot update PMWD', 11, -1)
	rollback TRANSACTION
	RETURN
	end


RETURN 




GO
ALTER TABLE [dbo].[bPMWD] WITH NOCHECK ADD CONSTRAINT [CK_bPMWD_ItemUnitFlag] CHECK (([ItemUnitFlag]='N' OR [ItemUnitFlag]='Y'))
GO
ALTER TABLE [dbo].[bPMWD] WITH NOCHECK ADD CONSTRAINT [CK_bPMWD_PhaseUnitFlag] CHECK (([PhaseUnitFlag]='N' OR [PhaseUnitFlag]='Y'))
GO
ALTER TABLE [dbo].[bPMWD] ADD CONSTRAINT [PK_bPMWD] PRIMARY KEY CLUSTERED  ([PMCo], [ImportId], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWD] WITH NOCHECK ADD CONSTRAINT [FK_bPMWD_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[bPMWD] NOCHECK CONSTRAINT [FK_bPMWD_bPMWH]
GO
