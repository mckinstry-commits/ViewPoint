CREATE TABLE [dbo].[bPOCT]
(
[POCo] [dbo].[bCompany] NOT NULL,
[PO] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[CompCode] [dbo].[bCompCode] NOT NULL,
[Seq] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Description] [dbo].[bDesc] NULL,
[Verify] [dbo].[bYN] NOT NULL,
[ExpDate] [dbo].[bDate] NULL,
[Complied] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPOCT_PurgeYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btPOCTd] on [dbo].[bPOCT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: MV 03/20/03
    *  Modified: 
    *			
    *
    * Adds entry to HQ Master Audit if POCO.AuditPOCompliance = 'Y'
    * and bPOCT.PurgeYN='N'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit PO Compliance Code deletions */
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bPOCT', 'PO:' + d.PO + ' Comp Code: ' + convert(varchar(10),d.CompCode)
   		+ ' Seq: ' + convert(varchar(3),d.Seq), d.POCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    from deleted d
    join bPOCO c on d.POCo = c.POCo
    where c.AuditPOCompliance = 'Y' and d.PurgeYN='N'
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete PO Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btPOCTi    Script Date: 12/16/99 02:32:00 PM ******/
   
    CREATE    trigger [dbo].[btPOCTi] on [dbo].[bPOCT] for INSERT as
    

/*--------------------------------------------------------------
     *  Insert trigger for POCT - PO Compliance Tracking
     *  Created By: EN
     *  Date:       12/17/99
     *  Modified By: LM 01/04/00 - Changed for PM - A PO may be pending or open
     *					MV 03/06/03 - #20094 - allow insert for PO with status 'complete'.
     *					MV 03/20/03 - #20533 - PO Compliance auditing.
     *
     *  Validates PO, CompCode, Vendor Group and Vendor (if exist in POCT
     *  entry), and Vendor Group.
     *  Checks to make sure that Complied and ExpDate are set correctly for the
     *  Compliance Type (i.e. 'Date' or 'Flag').
     *--------------------------------------------------------------*/
    declare @numrows int, @validcnt int, @validcnt2 int, @errmsg varchar(255)
   
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    set nocount on
   
    -- validate PO
    select @validcnt = count(*)
    from bPOHD r
    JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
    if @validcnt <> @numrows
       begin
       select @errmsg = 'PO is Invalid '
       goto error
       end
   
    -- validate that PO is open
    -- #20094 - change to allow insert for any PO Status
    /*select @validcnt = count(*)
    from bPOHD r
    JOIN inserted i ON i.POCo = r.POCo and i.PO = r.PO
    where r.Status in (0,3)
    if @validcnt <> @numrows
       begin
       select @errmsg = 'PO is not Open or Pending '
       goto error
       end*/
   
    -- validate Compliance code
    select @validcnt2 = count(*) from inserted where CompCode is not null
   
    select @validcnt = count(*)
    from bHQCP r
    JOIN inserted i ON i.CompCode = r.CompCode
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Compliance Code is Invalid ' + convert(varchar(10),@validcnt2) + ' ' + convert(varchar(10),@validcnt)
       goto error
       end
   
    -- check Compliance type
    select @validcnt = count(*)
    from bHQCP r
    left JOIN inserted i ON i.CompCode = r.CompCode
    where r.CompType = 'D' and i.Complied is not null
    if @validcnt <> 0
       begin
       select @errmsg = 'No Compliance Flag allowed for Date type Compliance Code '
       goto error
       end
    select @validcnt = count(*)
    from bHQCP r
    JOIN inserted i ON i.CompCode = r.CompCode
    where r.CompType = 'F' and i.ExpDate is not null
    if @validcnt <> 0
       begin
       select @errmsg = 'No Compliance Date allowed for Flag type Compliance Code '
       goto error
       end
   
    -- validate Vendor Group
    select @validcnt2 = count(*)
    from inserted i
    where (i.VendorGroup is not null)
    select @validcnt = count(*)
    from bHQCO r
    JOIN inserted i ON i.POCo = r.HQCo and i.VendorGroup = r.VendorGroup
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Vendor Group is Invalid '
       goto error
       end
   
    -- validate Vendor Group/Vendor
    select @validcnt2 = count(*)
    from inserted i
    where (i.VendorGroup is not null and i.Vendor is not null)
    select @validcnt = count(*)
    from bAPVM r
    JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
    if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid Vendor Group/Vendor '
       goto error
       end
   
   -- HQ Auditing
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode)
   		+ ' Seq: ' + convert(varchar(3),i.Seq), i.POCo, 'A', null, null, null, getdate(), SUSER_SNAME()
    from inserted i
    join bPOCO c on i.POCo = c.POCo
    where c.AuditPOCompliance = 'Y'
   
    return
   
    error:
        select @errmsg = @errmsg + ' - cannot insert PO Compliance Tracking'
        RAISERROR(@errmsg, 11, -1);
        rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

/****** Object:  Trigger dbo.btPOCTu    Script Date: 8/28/99 9:38:06 AM ******/
CREATE    trigger [dbo].[btPOCTu] on [dbo].[bPOCT] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for POCT
 * Created By:	EN 12/17/99
 * Modified By: LM 01/04/00 - Changed for PM - A PO may be pending or open
 *					kb 9/18/1 - issue #14623
 *					MV 03/20/03 - #20533 - PO Compliance auditing.
 *					MV 04/23/03 - #20611 rej 1 fix - update POCT on closed POs
 *					GF 11/10/2010 - issue #141475 added vendor to HQMA audit
 *
 *
 *  Rejects any primary key changes.
 *  Validates PO, CompCode, Vendor Group and Vendor (if exist in POCT
 *  entry), and Vendor Group.
 *  Checks to make sure that Complied and ExpDate are set correctly for the
 *  Compliance Type (i.e. 'Date' or 'Flag').
 *--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @errno tinyint, @validcnt int,
		@validcnt2 int, @rcode tinyint

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
    /* check for key changes */
   /* select @validcnt = count(*) from deleted d, inserted i
    	where d.POCo = i.POCo and d.PO = i.PO and d.Seq = i.Seq
    if @numrows <> @validcnt*/
    if update(POCo) or update(PO) or update(Seq)
    	begin
    	select @errmsg = 'Cannot change Company, PO number or Sequence', @rcode = 1
    	goto error
    	end
   
   -- validate Vendor Group
   select @validcnt2 = count(*)
   from inserted i
   where (i.VendorGroup is not null)
   select @validcnt = count(*)
   from bHQCO r
   JOIN inserted i ON i.POCo = r.HQCo and i.VendorGroup = r.VendorGroup
   if @validcnt <> @validcnt2
      begin
      select @errmsg = 'Vendor Group is Invalid '
      goto error
      end
   
   -- validate Vendor Group/Vendor
   select @validcnt2 = count(*)
   from inserted i
   where (i.VendorGroup is not null and i.Vendor is not null)
   select @validcnt = count(*)
   from bAPVM r
   JOIN inserted i ON i.VendorGroup = r.VendorGroup and i.Vendor = r.Vendor
   if @validcnt <> @validcnt2
      begin
      select @errmsg = 'Invalid Vendor Group/Vendor '
      goto error
      end
   
/* Insert records into HQMA for changes made to audited fields */
----#141475
IF UPDATE(Vendor)
	BEGIN
	insert into bHQMA
	select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.POCo, 'C', 'Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.POCo = i.POCo and d.PO = i.PO
	and d.CompCode = i.CompCode and d.Seq=i.Seq
	join POCO a on a.POCo = i.POCo
	where ISNULL(d.Vendor,'') <> ISNULL(i.Vendor,'')
	and a.AuditPOCompliance = 'Y'
	END
IF UPDATE(Description)
	BEGIN
	insert into bHQMA
	select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.POCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.POCo = i.POCo and d.PO = i.PO
	and d.CompCode = i.CompCode and d.Seq=i.Seq
	join POCO a on a.POCo = i.POCo
	where ISNULL(d.Description,'') <> ISNULL(i.Description,'')
	and a.AuditPOCompliance = 'Y'
	END
IF UPDATE(Verify)
	BEGIN
	insert into bHQMA select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.POCo, 'C','Verify', d.Verify, i.Verify, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.POCo = i.POCo and d.PO = i.PO
	and d.CompCode = i.CompCode and d.Seq=i.Seq
	join POCO a on a.POCo = i.POCo
	where ISNULL(d.Verify,'') <> ISNULL(i.Verify,'')
	and a.AuditPOCompliance = 'Y'
	END
IF UPDATE(ExpDate)
	BEGIN
	insert into bHQMA select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.POCo, 'C', 'ExpDate', convert(varchar(8),d.ExpDate,1), convert(varchar(8),i.ExpDate,1), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.POCo = i.POCo and d.PO = i.PO
	and d.CompCode = i.CompCode and d.Seq=i.Seq
	join POCO a on a.POCo = i.POCo
	where ISNULL(d.ExpDate,'') <> ISNULL(i.ExpDate,'')
	and a.AuditPOCompliance = 'Y'
	END
IF UPDATE(Complied)
	BEGIN
	insert into bHQMA select 'bPOCT', 'PO:' + i.PO + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.POCo, 'C', 'Complied', d.Complied, i.Complied, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.POCo = i.POCo and d.PO = i.PO
	and d.CompCode = i.CompCode and d.Seq=i.Seq
	join POCO a on a.POCo = i.POCo
	where ISNULL(d.Complied,'') <> ISNULL(i.Complied,'') 
	and a.AuditPOCompliance = 'Y'
	END






return

error:
	select @errmsg = @errmsg + ' - cannot update PO Compliance Tracking'
	RAISERROR(@errmsg, 11, -1);

	rollback transaction
   
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPOCT] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPOCT] ON [dbo].[bPOCT] ([POCo], [PO], [CompCode], [Seq]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCT].[Verify]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCT].[Complied]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPOCT].[PurgeYN]'
GO
