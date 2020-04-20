CREATE TABLE [dbo].[bPMWI]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[Item] [dbo].[bContractItem] NULL,
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[SICode] [varchar] (16) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[UM] [dbo].[bUM] NULL,
[RetainPCT] [dbo].[bPct] NULL CONSTRAINT [DF_bPMWI_RetainPCT] DEFAULT ((0)),
[Amount] [dbo].[bDollar] NULL CONSTRAINT [DF_bPMWI_Amount] DEFAULT ((0)),
[Units] [dbo].[bUnits] NULL CONSTRAINT [DF_bPMWI_Units] DEFAULT ((0)),
[UnitCost] [dbo].[bUnitCost] NULL CONSTRAINT [DF_bPMWI_UnitCost] DEFAULT ((0)),
[ImportItem] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportUM] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc3] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Errors] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[Dept] [dbo].[bDept] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BillDescription] [dbo].[bItemDesc] NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[BillType] [dbo].[bBillType] NULL CONSTRAINT [DF_bPMWI_BillType] DEFAULT ('B'),
[InitAsZero] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWI_InitAsZero] DEFAULT ('N'),
[InitSubs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWI_InitSubs] DEFAULT ('Y'),
[MarkUpRate] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bPMWI_MarkUpRate] DEFAULT ((0)),
[StartMonth] [dbo].[bMonth] NULL,
[TaxCode] [dbo].[bTaxCode] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMWI] ADD 
CONSTRAINT [PK_bPMWI] PRIMARY KEY CLUSTERED  ([PMCo], [ImportId], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

ALTER TABLE [dbo].[bPMWI] WITH NOCHECK ADD
CONSTRAINT [FK_bPMWI_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMWId    Script Date: 8/28/99 9:38:04 AM ******/
CREATE trigger [dbo].[btPMWId] on [dbo].[bPMWI] for DELETE as 


/*--------------------------------------------------------------
    *
    *  Delete trigger for PMWI
    *  Created By: GF 06/16/99
    *  Modified By: JayR 03/29/2012 Tk-00000 Remove gotos
    *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on



---- Check bPMWP for phases
if exists(select * from deleted d join bPMWP o on d.PMCo=o.PMCo and d.ImportId=o.ImportId and d.Item=o.Item)
      begin
      RAISERROR('Phases exist in bPMWP.', 11, -1)
      rollback TRANSACTION
      RETURN
      end


---- Check bPMWD for Cost Types 
if exists(select * from bPMWD o join deleted d ON d.PMCo=o.PMCo and d.ImportId=o.ImportId and d.Item=o.Item)
      begin
      RAISERROR('Cost Types exist in bPMWD', 11, -1)
      rollback TRANSACTION
      RETURN
      end


RETURN 
   
   
  
 









GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMWIu    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWIu] on [dbo].[bPMWI] for UPDATE as

/*--------------------------------------------------------------
    *  Update trigger for PMWI
    *  Created By: GF 06/12/99
    *
    *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int,
		@pmco bCompany, @importid varchar(10), @sequence int, @item bContractItem,
		@olditem bContractItem, @rcode int, @oldimportitem varchar(30)

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
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @item=Item
	from inserted
else
	begin
   	declare bPMWI_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, ImportId, Sequence, Item
   	from inserted

   	open bPMWI_insert

	fetch next from bPMWI_insert into @pmco, @importid, @sequence, @item

	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
select @olditem=Item, @oldimportitem=ImportItem
from deleted where PMCo=@pmco and ImportId=@importid and Sequence=@sequence
if update(Item)
	begin
	update bPMWP set Item=@item
	where PMCo=@pmco and ImportId=@importid and ImportItem=@oldimportitem 
	and (Item is null or Item='' or Item=@olditem)
	end


if @numrows > 1
   	begin
	fetch next from bPMWI_insert into @pmco, @importid, @sequence, @item
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWI_insert
   		deallocate bPMWI_insert
   		end
   	end




return



error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot update PMWI'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction





GO
