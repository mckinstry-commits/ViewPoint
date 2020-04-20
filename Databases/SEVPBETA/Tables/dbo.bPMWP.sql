CREATE TABLE [dbo].[bPMWP]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Sequence] [int] NOT NULL,
[Item] [dbo].[bContractItem] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NULL,
[Description] [dbo].[bItemDesc] NULL,
[ImportItem] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportPhase] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImportMisc3] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Errors] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMWP_ActiveYN] DEFAULT ('Y'),
[InsCode] [dbo].[bInsCode] NULL,
[ProjMinPct] [dbo].[bPct] NULL CONSTRAINT [DF_bPMWP_ProjMinPct] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWPd    Script Date: 8/28/99 9:38:05 AM ******/
CREATE trigger [dbo].[btPMWPd] on [dbo].[bPMWP] for DELETE as

/*--------------------------------------------------------------
* Delete trigger for PMWP
* Created By: GF 06/17/99
* Modified By: GF 10/05/2009 - issue #135846 - change logic when checking for cost types in PMWD.
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

declare @phase bPhase

---- Check bPMWD for Cost Types assigned. Only want check to occur when deleting
---- from the phase worksheet grid, that is why looking for one row only
---- #135846
if @numrows = 1
	BEGIN
	select @phase = min(d.Phase) from deleted d
	---- now check if we only have one occurance of the phase. If more than one, we can allow delete.
	IF (SELECT COUNT(*) FROM dbo.bPMWP p WITH (NOLOCK) JOIN DELETED d ON d.PMCo=p.PMCo
			AND d.ImportId=p.ImportId AND d.Item=p.Item AND d.Phase=p.Phase) = 0
		begin
		if exists(select * from deleted d JOIN bPMWD o ON d.PMCo=o.PMCo
				and d.ImportId = o.ImportId and d.Item=o.Item and d.Phase=o.Phase)
			begin
			select @errmsg = 'Cost Types exist in bPMWD for Phase: ' + isnull(@phase,'')
			goto error
			end
		end
	end


return



error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot delete from PMWP'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMWPu    Script Date: 8/28/99 9:38:05 AM ******/
CREATE  trigger [dbo].[btPMWPu] on [dbo].[bPMWP] for UPDATE as

/*--------------------------------------------------------------
 * Update trigger for PMWP
 * Created By: GF 06/17/99
 *	Modified By:	GF 05/12/2003 - issue #21238 check for phase count, update all items
 *					if only one phase.
 *					GF 03/13/2006 - issue #120481 include phase when updating detail for item changed. 
 *
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @rcode int, @validcnt int, @importid varchar(10),
        @sequence int, @item bContractItem, @olditem bContractItem, @oldimportitem varchar(30),
        @phase bPhase, @oldphase bPhase, @oldimportphase varchar(30), @pmco bCompany

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- -- -- check for changes to Sequence
   if update(Sequence)
      begin
      select @errmsg = 'Cannot change Sequence'
      goto error
      end
      
-- -- -- check for changes to ImportId
   if update(ImportId)
      begin
      select @errmsg = 'Cannot change ImportId'
      goto error
      end



------ use a cursor to process each inserted row
if @numrows = 1
	select @pmco=PMCo, @importid=ImportId, @sequence=Sequence, @item=Item, @phase=Phase
	from inserted
else
	begin
   	declare bPMWP_insert cursor LOCAL FAST_FORWARD
   	for select PMCo, ImportId, Sequence, Item, Phase
   	from inserted

   	open bPMWP_insert

	fetch next from bPMWP_insert into @pmco, @importid, @sequence, @item, @phase

	if @@fetch_status <> 0
		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
	end


insert_check:
select @olditem=Item, @oldimportitem=ImportItem, @oldphase=Phase, @oldimportphase=ImportPhase
from deleted where PMCo=@pmco and ImportId=@importid and Sequence=@sequence

------ get count of phases
select @validcnt = count(*) from inserted where PMCo=@pmco and ImportId=@importid and Phase=@phase

------ update item for phase
if update(Item)
	begin
	------ cost types
	update bPMWD set Item=@item
	where PMCo=@pmco and ImportId=@importid and ImportItem=@oldimportitem
	and Phase=@oldphase and (Item is null or Item='' or Item=@olditem)
	------ update PMWD detail items with new item when only one phase exists
	if @validcnt = 1
		begin
		update bPMWD set Item=@item
		where PMCo=@pmco and ImportId=@importid and Phase=@phase
		end

	------ subcontract detail
	update bPMWS set Item=@item
	where PMCo=@pmco and ImportId=@importid and ImportItem=@oldimportitem
	and Phase=@oldphase and (Item is null or Item='' or Item=@olditem)
	------ update PMWS detail items with new item when only one phase existst
	if @validcnt = 1
		begin
		update bPMWS set Item=@item
		where PMCo=@pmco and ImportId=@importid and Phase=@phase
		end

	------ material detail
	update bPMWM set Item=@item
	where PMCo=@pmco and ImportId=@importid and ImportItem=@oldimportitem
	and Phase=@oldphase and (Item is null or Item='' or Item=@olditem)
	------ update PMWS detail items with new item when only one phase exists
	if @validcnt = 1
		begin
		update bPMWM set Item=@item
		where PMCo=@pmco and ImportId=@importid and Phase=@phase
		end
	end

------ update detail for phase when changed
if update(Phase)
	begin
	update bPMWD set Phase=@phase
	where PMCo=@pmco and ImportId=@importid and ImportPhase=@oldimportphase
	and ImportItem=@oldimportitem and (Phase is null or Phase='' or Phase=@oldphase)
   
	update bPMWS set Phase=@phase
	where PMCo=@pmco and ImportId=@importid and ImportPhase=@oldimportphase and ImportItem=@oldimportitem
	and (Phase is null or Phase='' or Phase=@oldphase)
                  
	update bPMWM set Phase=@phase
	where PMCo=@pmco and ImportId=@importid and ImportPhase=@oldimportphase and ImportItem=@oldimportitem
	and (Phase is null or Phase='' or Phase=@oldphase)        
	end


if @numrows > 1
   	begin
	fetch next from bPMWP_insert into @pmco, @importid, @sequence, @item, @phase
   	if @@fetch_status = 0
   		goto insert_check
   	else
   		begin
   		close bPMWP_insert
   		deallocate bPMWP_insert
   		end
   	end


return


error:
     select @errmsg = isnull(@errmsg,'') + ' - cannot update PMWP'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction







GO
ALTER TABLE [dbo].[bPMWP] ADD CONSTRAINT [PK_bPMWP] PRIMARY KEY CLUSTERED  ([PMCo], [ImportId], [Sequence]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWP] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWP] WITH NOCHECK ADD CONSTRAINT [FK_bPMWP_bPMWH] FOREIGN KEY ([PMCo], [ImportId]) REFERENCES [dbo].[bPMWH] ([PMCo], [ImportId]) ON DELETE CASCADE
GO
