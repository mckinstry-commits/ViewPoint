CREATE TABLE [dbo].[bMSQD]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[FromLoc] [dbo].[bLoc] NOT NULL,
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[QuoteUnits] [dbo].[bUnits] NOT NULL,
[UnitPrice] [dbo].[bUnitCost] NOT NULL,
[ECM] [dbo].[bECM] NOT NULL,
[ReqDate] [dbo].[bDate] NULL,
[Status] [tinyint] NOT NULL,
[OrderUnits] [dbo].[bUnits] NOT NULL,
[SoldUnits] [dbo].[bUnits] NOT NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Seq] [smallint] NOT NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[VendorGroup] [dbo].[bGroup] NULL,
[MatlVendor] [dbo].[bVendor] NULL,
[UnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bMSQD_UnitCost] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biMSQD] ON [dbo].[bMSQD] ([MSCo], [Quote], [FromLoc], [MatlGroup], [Material], [UM], [PhaseGroup], [Phase], [VendorGroup], [MatlVendor]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSQD] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biMSQDSeq] ON [dbo].[bMSQD] ([MSCo], [Quote], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE trigger [dbo].[btMSQDd] on [dbo].[bMSQD] for DELETE as
   

/*-----------------------------------------------------------------
    * Created By:  GF 03/28/2000
    * Modified By: GF 02/22/2002 - Added delete from PMMF for MSQD if exists
    *				GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *				GF 02/22/2005 - issue #27175 reset audit flag to 'Y' at end of trigger
    *
    *
    * Validates and inserts HQ Master Audit entry.
    *  Updates INMT with Allocated Units.
    *  If Quotes flagged for auditing, inserts HQ Master Audit entry.
    *
    */----------------------------------------------------------------
   declare @numrows int, @validcnt int, @nullcnt int, @errmsg varchar(255), @opencursor tinyint,
   		@rcode int, @msco bCompany, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM,
   		@stdum bUM, @umconv bUnitCost, @oldstatus tinyint, @oldorderunits bUnits,
   		@oldsoldunits bUnits, @oldremainunits bUnits, @newremainunits bUnits
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- update Allocated Units in bINMT
   if @numrows = 1
       begin
       -- if only one row deleted, no cursor is needed
       select @msco=MSCo, @fromloc=FromLoc, @matlgroup=MatlGroup, @material=Material, @um=UM,
              @oldstatus=Status, @oldorderunits=OrderUnits, @oldsoldunits=SoldUnits
       from deleted
       end
   else
       begin
       -- use a cursor to process all deleted rows
       declare bMSQD_delete cursor LOCAL FAST_FORWARD
   	for select MSCo, FromLoc, MatlGroup, Material, UM, Status, OrderUnits, SoldUnits
       from deleted
   
       open bMSQD_delete
       set @opencursor = 1
   
       -- get 1st row deleted
       fetch next from bMSQD_delete into @msco, @fromloc, @matlgroup, @material, @um,
   			@oldstatus, @oldorderunits, @oldsoldunits
   
       if @@fetch_status <> 0
           begin
           select @errmsg = 'Cursor error '
           goto error
           end
       end
   
       if @oldstatus = 0 or @oldstatus = 2 goto next_cursor_row
   
   
   INMT_update:
   -- validate Material, get conversion for posted unit of measure
   exec @rcode = dbo.bspHQStdUMGet @matlgroup,@material,@um,@umconv output,@stdum output,@errmsg output
   if @rcode <> 0 goto error
   -- calculate old remaining units
   if @umconv <> 0
   	select @oldremainunits = (@oldorderunits*@umconv) - (@oldsoldunits*@umconv)
   else
   	select @oldremainunits = @oldorderunits - @oldsoldunits
   -- calculate new remaining units
   select @newremainunits = 0
   
   -- update INMT only if a variance
   if @oldremainunits <> @newremainunits
   	begin
   	update bINMT set Alloc=Alloc-@oldremainunits+@newremainunits, AuditYN='N'
   	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   	-- -- -- set audit flag to 'Y' #27175
   	update bINMT set AuditYN='Y'
   	where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   	end
   
   
   next_cursor_row:
   -- get next row
   if @numrows > 1
       begin
       fetch next from bMSQD_delete into @msco, @fromloc, @matlgroup, @material, @um,
   			@oldstatus, @oldorderunits, @oldsoldunits
   
       if @@fetch_status = 0 goto INMT_update
   
       close bMSQD_delete
       deallocate bMSQD_delete
       set @opencursor = 0
       end
   
   
   -- remove PM Materials - PMMF
   delete bPMMF
   from bPMMF p
   join deleted d on p.MSCo=d.MSCo and p.Quote=d.Quote and p.Location=d.FromLoc
   and p.MaterialCode=d.Material and p.UM=d.UM
   
   
   -- Audit deletions
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSQD', ' Key: ' + convert(varchar(3),d.MSCo) + '/' + d.Quote + '/'
       + isnull(d.FromLoc,'') + '/' + convert(varchar(3),d.MatlGroup) + '/' 
   	+ isnull(d.Material,'') + '/' + isnull(d.UM,''),
   	d.MSCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   from deleted d join bMSCO p on p.MSCo = d.MSCo
   where d.MSCo = p.MSCo and p.AuditQuotes='Y'
   
   
   return
   
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MSQD!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /*****************************************************************/
   CREATE trigger [dbo].[btMSQDi] on [dbo].[bMSQD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/28/2000
    *  Modified By: allenn 05/14/02 - issue 17283, allow negative unit prices
    *				 GF 03/11/2003 - issue #20699 - for auditing wrap columns in isnull's
    *				 GF 02/22/2005 - issue #27175 reset audit flag to 'Y' at end of trigger
	*				 GP 06/06/2008 - Issue #127986, do not update inventory if Material Vendor is null
	*				 GF 12/21/2008 - issue #131530 missing MatlVendor from select into causing cursor error.
    *		
    *
    *  Validates MSQD columns.
    *  Updates INMT with Allocated Units.
    *  If Quotes flagged for auditing, inserts HQ Master Audit entry.
    *
    */----------------------------------------------------------------
   declare @numrows int, @validcnt int, @errmsg varchar(255), @opencursor tinyint,
   		@rcode int, @msco bCompany, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM,
   		@stdum bUM, @umconv bUnitCost, @newstatus tinyint, @neworderunits bUnits,
   		@newsoldunits bUnits, @oldremainunits bUnits, @newremainunits bUnits, @matlvendor bVendor -- Issue #127986
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid MS company!'
      goto error
      end
   
   -- validate Quote
   select @validcnt = count(*) from inserted i join bMSQH c on
       c.MSCo = i.MSCo and c.Quote=i.Quote
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid Quote!'
      goto error
      end
   
   -- validate Material Group
   select @validcnt = count(*) from inserted i join bHQGP g on g.Grp = i.MatlGroup
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Material Group'
   	goto error
   	end
   
   -- validate IN From Location
   select @validcnt = count(*) from inserted i join bINLM c on
       c.INCo = i.MSCo and c.Loc = i.FromLoc
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid From Location!'
      goto error
      end
   
   -- validate HQ Material
   select @validcnt = count(*) from inserted i join bHQMT c on
       c.MatlGroup = i.MatlGroup and c.Material = i.Material
   if @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Material!'
      goto error
      end
   
   -- validate HQ Unit of Measure
   select @validcnt = count(*) from inserted i join bHQUM c on c.UM = i.UM
   IF @validcnt <> @numrows
      begin
      select @errmsg = 'Invalid HQ Unit of Measure!'
      goto error
      end
   
   -- check for 'LS' unit of measure
   select @validcnt = count(*) from inserted where UM='LS'
   if @validcnt > 0
      begin
      select @errmsg = 'Invalid, unit of measure cannot be equal to (LS)'
      goto error
      end
   
   -- validate ECM Flag
   select @validcnt = Count(*) from inserted where ECM in ('E','C','M')
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid ECM, must be (E,C,M)!'
       goto error
       end
   
   -- validate Status
   select @validcnt = Count(*) from inserted where Status in (0,1,2)
   if @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Status, must be (0,1,2)!'
       goto error
       end
   
   -- update Allocated Units in bINMT
   if @numrows = 1
       begin
       -- if only one row inserted, no cursor is needed
       select @msco=MSCo, @fromloc=FromLoc, @matlgroup=MatlGroup, @material=Material,
              @um=UM, @newstatus=Status, @neworderunits=OrderUnits, @newsoldunits=SoldUnits,
			  @matlvendor = MatlVendor -- Issue #127986
       from inserted
       end
   else
       begin
       -- use a cursor to process all inserted rows
       declare bMSQD_insert cursor LOCAL FAST_FORWARD
   			for select MSCo, FromLoc, MatlGroup, Material, UM, Status, OrderUnits, SoldUnits, MatlVendor -- Issue #127986
       from inserted
   
       open bMSQD_insert
       set @opencursor = 1
   
       -- get 1st row inserted
       fetch next from bMSQD_insert into @msco, @fromloc, @matlgroup, @material, @um,
           	@newstatus, @neworderunits, @newsoldunits, @matlvendor -- Issue #127986
   
       if @@fetch_status <> 0
           begin
           select @errmsg = 'Cursor error '
           goto error
           end
       end
   
       if @newstatus = 0 or @newstatus = 2 goto next_cursor_row
   
   
   INMT_update:
       -- validate Material, get conversion for posted unit of measure
       exec @rcode = dbo.bspHQStdUMGet @matlgroup,@material,@um,@umconv output,@stdum output,@errmsg output
       if @rcode <> 0 goto error
       -- calculate old remaining units
       select @oldremainunits = 0
       -- calculate new remaining units
       if @umconv <> 0
           select @newremainunits = (@neworderunits*@umconv) - (@newsoldunits*@umconv)
       else
           select @newremainunits = @neworderunits - @newsoldunits
   
       -- update INMT only if a variance
       if @oldremainunits <> @newremainunits
           begin
           update bINMT set Alloc=Alloc-@oldremainunits+@newremainunits, AuditYN='N'
           where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   		-- -- -- set audit flag to 'Y' #27175
   		update bINMT set AuditYN='Y'
           where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
           end
   
   
   next_cursor_row:
   -- get next row
   if @numrows > 1
       begin
       fetch next from bMSQD_insert into @msco, @fromloc, @matlgroup, @material, @um,
           	@newstatus, @neworderunits, @newsoldunits, @matlvendor -- Issue #127986
   
		if @@fetch_status = 0 and @matlvendor is null -- Issue #127986
		begin
			goto INMT_update
		end
   
       close bMSQD_insert
       deallocate bMSQD_insert
       set @opencursor = 0
       end
   
   
   -- Audit inserts
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   select 'bMSQD', ' Key: ' + convert(char(3), i.MSCo) + '/' + i.Quote + '/' + isnull(i.FromLoc,'') + '/'
       + convert(varchar(3),i.MatlGroup) + '/' + isnull(i.Material,'') + '/' + isnull(i.UM,''),
       i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   from inserted i join bMSCO c on c.MSCo = i.MSCo
   where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'
   
   return
   
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert into MSQD!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /**************************************************************/
   CREATE  trigger [dbo].[btMSQDu] on [dbo].[bMSQD] for UPDATE as
   

/*--------------------------------------------------------------
    * Created By:  GF 03/28/2000
    * Modified By: GF 02/08/2001 - fixed alloc update to IN if old-new status = 0,2
    *				allenn 05/14/02 - issue 17283, allow negative unit prices
    *				GF 12/03/2003 - issue #23147 changes for ansi nulls and isnull
    *				GF 02/22/2005 - issue #27175 reset INMT audit flag to 'Y' 
	*				GP 06/06/2008 - Issue #127986, do not update inventory if Material Vendor is null
	*				GP 11/21/2008 - Issue #131178, add MatlVendor to cursor get 1st row.
	*				GF 12/21/2008 - issue #131530 missing MatlVendor from select into causing cursor error
    *
    *
    *  Update trigger for MSQD
    *  Updates INMT with Allocated Units.
    *  If Quotes flagged for auditing, inserts HQ Master Audit entry.
    *
    *--------------------------------------------------------------*/
   declare @numrows int, @validcnt int, @errmsg varchar(255), @opencursor tinyint,
   		@rcode int, @msco bCompany, @fromloc bLoc, @matlgroup bGroup, @material bMatl, @um bUM,
   		@stdum bUM, @umconv bUnitCost, @oldstatus tinyint, @oldorderunits bUnits,
   		@oldsoldunits bUnits, @newstatus tinyint, @neworderunits bUnits, @newsoldunits bUnits,
   		@oldremainunits bUnits, @newremainunits bUnits, @matlvendor bVendor -- Issue #127986
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- check for key changes
   IF UPDATE(MSCo)
       begin
       select @errmsg = 'MSCo may not be updated'
       goto error
       end
   
   IF UPDATE(Quote)
       begin
       select @errmsg = 'Quote may not be updated'
       goto error
       end
   
   IF UPDATE(FromLoc)
       begin
       select @errmsg = 'From Location may not be updated'
       goto error
       end
   
   IF UPDATE(MatlGroup)
   	begin
   	select @errmsg = 'Material Group may not be updated'
   	goto error
   	end
   
   IF UPDATE(Material)
       begin
       select @errmsg = 'Material may not be updated'
       goto error
       end
   
   IF UPDATE(UM)
       begin
       select @errmsg = 'Unit of measure may not be updated'
       goto error
       end
   
   -- validate ECM
   IF UPDATE(ECM)
   BEGIN
       select @validcnt = count(*) from inserted where ECM in ('E','C','M')
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid ECM, must be (E,C,M).'
           goto error
           end
   END
   
   -- validate status
   IF UPDATE(Status)
   BEGIN
       select @validcnt = count(*) from inserted where Status in (0,1,2)
       if @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Status, must be (0,1,2).'
           goto error
           end
   END
   
   -- update Allocated Units in bINMT
   if @numrows = 1
       begin
       -- if only one row updated, no cursor is needed
       select @msco=i.MSCo, @fromloc=i.FromLoc, @matlgroup=i.MatlGroup, @material=i.Material,
              @um=i.UM, @oldstatus=d.Status, @oldorderunits=d.OrderUnits, @oldsoldunits=d.SoldUnits,
              @newstatus=i.Status, @neworderunits= i.OrderUnits, @newsoldunits=i.SoldUnits,
			  @matlvendor=i.MatlVendor
       from inserted i join deleted d on
       i.MSCo=d.MSCo and i.Quote=d.Quote and i.FromLoc=d.FromLoc and i.MatlGroup=d.MatlGroup
       and i.Material=d.Material and i.UM=d.UM
       end
   else
       begin
       -- use a cursor to process all updated rows
       declare bMSQD_update cursor LOCAL FAST_FORWARD
   	for select i.MSCo, i.FromLoc, i.MatlGroup, i.Material, i.UM, d.Status, d.OrderUnits, 
   			d.SoldUnits, i.Status, i.OrderUnits, i.SoldUnits, i.MatlVendor -- Issue #127986
       from inserted i join deleted d on
       i.MSCo=d.MSCo and i.Quote=d.Quote and i.FromLoc=d.FromLoc and i.MatlGroup=d.MatlGroup
       and i.Material=d.Material and i.UM=d.UM
   
       open bMSQD_update
       set @opencursor = 1
   
       -- get 1st row updated
       fetch next from bMSQD_update into @msco, @fromloc, @matlgroup, @material, @um,
   			@oldstatus, @oldorderunits, @oldsoldunits, @newstatus, @neworderunits, @newsoldunits,
			@matlvendor
   
       if @@fetch_status <> 0
           begin
           select @errmsg = 'Cursor error '
           goto error
           end
       end
   
       if @oldstatus = 0 and @newstatus = 2 goto next_cursor_row
       if @oldstatus = 2 and @newstatus = 0 goto next_cursor_row
       if @oldstatus = 0 and @newstatus = 0 goto next_cursor_row
       if @oldstatus = 2 and @newstatus = 2 goto next_cursor_row
   
   
   INMT_update:
       -- validate Material, get conversion for posted unit of measure
       exec @rcode = dbo.bspHQStdUMGet @matlgroup,@material,@um,@umconv output,@stdum output,@errmsg output
       if @rcode <> 0 goto error
       -- calculate old remaining units
       if @umconv <> 0
          select @oldremainunits = (@oldorderunits*@umconv) - (@oldsoldunits*@umconv)
       else
          select @oldremainunits = @oldorderunits - @oldsoldunits
       if @oldstatus = 0 select @oldremainunits = 0
       if @oldstatus = 2 and @newstatus = 1 select @oldremainunits = 0
       -- calculate new remaining units
       if @umconv <> 0
           select @newremainunits = (@neworderunits*@umconv) - (@newsoldunits*@umconv)
       else
           select @newremainunits = @neworderunits - @newsoldunits
       if @newstatus = 2 select @newremainunits = 0
       if @oldstatus = 1 and @newstatus = 0 select @newremainunits = 0
   
       -- update INMT only if a variance
       if @oldremainunits <> @newremainunits
           begin
           update bINMT set Alloc=Alloc-@oldremainunits+@newremainunits, AuditYN='N'
           where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
   		-- -- -- set audit flag to 'Y'
   		update bINMT set AuditYN='Y'
           where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
           end
   
   
   next_cursor_row:
   -- get next row
   if @numrows > 1
       begin
       fetch next from bMSQD_update into @msco, @fromloc, @matlgroup, @material, @um,
   			@oldstatus, @oldorderunits, @oldsoldunits, @newstatus, @neworderunits, @newsoldunits,
			@matlvendor -- Issue #127986
   
        if @@fetch_status = 0 and @matlvendor is null -- Issue #127986
		begin
			goto INMT_update
		end
   
       close bMSQD_update
       deallocate bMSQD_update
       set @opencursor = 0
       end
   
   -- Audit updates
   -- no auditing if turned off in MSCo
   if not exists(select top 1 1 from inserted i join bMSCO c with (nolock) on c.MSCo=i.MSCo and c.AuditQuotes = 'Y')
   	return
   
   IF UPDATE(FromLoc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Location',  d.FromLoc, i.FromLoc, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.FromLoc,'') <> isnull(i.FromLoc,'')
   
   IF UPDATE(MatlGroup)
       INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material Group', convert(varchar(3),d.MatlGroup),
       convert(varchar(3),i.MatlGroup), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MatlGroup,'') <> isnull(i.MatlGroup,'')
   
   IF UPDATE(Material)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Material', d.Material, i.Material, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Material,'') <> isnull(i.Material,'')
   
   IF UPDATE(UM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Unit of Measure', d.UM, i.UM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.UM,'') <> isnull(i.UM,'')
   
   IF UPDATE(QuoteUnits)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Quote Units', convert(varchar(13),d.QuoteUnits),
       convert(varchar(13), i.QuoteUnits), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.QuoteUnits,'') <> isnull(i.QuoteUnits,'')
   
   IF UPDATE(UnitPrice)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Unit Price', convert(varchar(13),d.UnitPrice),
       convert(varchar(13), i.UnitPrice), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.UnitPrice,'') <> isnull(i.UnitPrice,'')
   
   IF UPDATE(ECM)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Per ECM', d.ECM, i.ECM, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.ECM,'') <> isnull(i.ECM,'')
   
   IF UPDATE(ReqDate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
    	'Required Date', convert(varchar(30),d.ReqDate), convert(varchar(30),i.ReqDate),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d  ON d.MSCo=i.MSCo  AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.ReqDate,'') <> isnull(i.ReqDate,'')
   
   IF UPDATE(Status)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Quote Status', convert(varchar(1),d.Status),
       convert(varchar(1),i.Status), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Status,'') <> isnull(i.Status,'')
   
   IF UPDATE(OrderUnits)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Ordered Units', convert(varchar(13),d.OrderUnits),
       convert(varchar(13), i.OrderUnits), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.OrderUnits,'') <> isnull(i.OrderUnits,'')
   
   IF UPDATE(SoldUnits)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQD', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote,
       i.MSCo, 'C', 'Sold Units', convert(varchar(13),d.SoldUnits),
       convert(varchar(13), i.SoldUnits), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.SoldUnits,'') <> isnull(i.SoldUnits,'') and i.AuditYN='Y'
   
   
   
   return
   
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSQD'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
  
 



GO

EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bMSQD].[ECM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bMSQD].[AuditYN]'
GO
