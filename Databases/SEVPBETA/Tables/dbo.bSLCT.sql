CREATE TABLE [dbo].[bSLCT]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CompCode] [dbo].[bCompCode] NOT NULL,
[Seq] [smallint] NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[Vendor] [dbo].[bVendor] NULL,
[Description] [dbo].[bItemDesc] NULL,
[Verify] [dbo].[bYN] NOT NULL,
[ExpDate] [dbo].[bDate] NULL,
[Complied] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ReceiveDate] [dbo].[bDate] NULL,
[Limit] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLCT_Limit] DEFAULT ((0)),
[PurgeYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bSLCT_PurgeYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[APRef] [dbo].[bAPReference] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  trigger [dbo].[btSLCTd] on [dbo].[bSLCT] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: MV 03/20/03
    *  Modified: 
    *			
    *
    * Adds entry to HQ Master Audit if SLCO.AuditSLCompliance = 'Y'
    * and bSLCT.PurgeYN='N'.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   /* Audit SL Compliance Code deletions */
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bSLCT', 'SL:' + d.SL + ' Comp Code: ' + convert(varchar(10),d.CompCode)
   		+ ' Seq: ' + convert(varchar(3),d.Seq), d.SLCo, 'D', null, null, null, getdate(), SUSER_SNAME()
    from deleted d
    join bSLCO c on d.SLCo = c.SLCo
    where c.AuditSLCompliance = 'Y' and d.PurgeYN='N'
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete SL Compliance Code!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btSLCTi    Script Date: 8/28/99 9:38:17 AM ******/
   
    CREATE    trigger [dbo].[btSLCTi] on [dbo].[bSLCT] for INSERT as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
    /*--------------------------------------------------------------
     *
     *  Insert trigger for SLCT
     *  Created By: EN  12/29/99
     *  Modified by: EN 4/12/00 - VendorGroup validation not fully allowing for null VendorGroup
     *					MV 03/06/03 - #20094 allow insert for any SL status.
     *					MV 03/20/03 - #20533 SL Compliance auditing.
     *
     *  Validate SL and verify that is is open in bSLHD.
     *  CompCode must exist in bHQCP.
     *  Vendor Group and Vendor must both be null or a valid Vendor in bAPVM.
     *  Vendor Group must be correct one for Company from bHQCO.
     *  If CompType from bHQCP is 'D' then Complied must be null.
     *  If CompType is 'F', then ExpDate must be null.
     *--------------------------------------------------------------*/
     select @numrows = @@rowcount
     if @numrows = 0 return
     set nocount on
   
    /*validate SL Company */
    select @validcnt = count(*) from bSLCO r
       JOIN inserted i on i.SLCo = r.SLCo
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL company '
    	goto error
    	end
   
    /*validate SL */
    select @validcnt = count(*) from bSLHD r
       JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid SL '
    	goto error
    	end
   
    /*verify SL Status (=Open) */
    -- #20094 - allow insert for any SL status.
   /* select @validcnt = count(*) from bSLHD r
       JOIN inserted i on i.SLCo = r.SLCo and i.SL = r.SL
       where r.Status = 0 or r.Status = 3
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'SL must be open or pending '
    	goto error
    	end*/
   
    /*validate CompCode */
    select @validcnt = count(*) from bHQCP r
       JOIN inserted i on i.CompCode = r.CompCode
    if @validcnt <> @numrows
    	begin
    	select @errmsg = 'Invalid Compliance Code '
    	goto error
    	end
   
    -- validate Vendor Group in bHQCO
    select @validcnt2 = count(*) from inserted i where i.VendorGroup is not null
    select @validcnt = count(*) from bHQCO r JOIN inserted i ON i.SLCo = r.HQCo and i.VendorGroup = r.VendorGroup
       where i.VendorGroup is not null
    if @validcnt <> @validcnt2
      begin
      select @errmsg = 'Vendor Group is Invalid '
      goto error
      end
   
    -- validate Vendor in bAPVM
    select @validcnt = count(*) from inserted where Vendor is null
    select @validcnt2 = count(*) from inserted i
       join bAPVM r on r.VendorGroup = i.VendorGroup and r.Vendor = i.Vendor
       where i.Vendor is not null
    if @validcnt + @validcnt2 <> @numrows
       begin
   	select @errmsg='Invalid Vendor '
   	goto error
   	end
   
    -- if CompType from bHQCP is 'D' then Complied must be null
    select @validcnt = count(*)
    from bHQCP r
    JOIN inserted i ON i.CompCode = r.CompCode
    where r.CompType = 'D' and i.Complied is not null
    if @validcnt <> 0
      begin
      select @errmsg = 'No Compliance Flag allowed for Date type Compliance Code '
      goto error
      end
    -- if CompType from bHQCP is 'F' then ExpDate must be null
    select @validcnt = count(*)
    from bHQCP r
    JOIN inserted i ON i.CompCode = r.CompCode
    where r.CompType = 'F' and i.ExpDate is not null
    if @validcnt <> 0
      begin
      select @errmsg = 'No Compliance Date allowed for Flag type Compliance Code '
      goto error
      end
   
   -- HQ Auditing
    insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode)
   		+ ' Seq: ' + convert(varchar(3),i.Seq), i.SLCo, 'A', null, null, null, getdate(), SUSER_SNAME()
    from inserted i
    join bSLCO c on i.SLCo = c.SLCo
    where c.AuditSLCompliance = 'Y'
   
    return
   
    error:
       select @errmsg = @errmsg + ' - cannot insert into SL Compliance Tracking'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btSLCTu    Script Date: 8/28/99 9:38:18 AM ******/
CREATE   trigger [dbo].[btSLCTu] on [dbo].[bSLCT] for UPDATE as
/*--------------------------------------------------------------
*  Update trigger for SLCT
*  Created By: EN  12/30/99
*  Modified by: EN 4/12/00 - needed to reject changes to CompCode as key field
*               EN 4/12/00 - straightened out VendorGroup and Vendor validation to be like insert trigger
*				MV 03/20/03 - #20533 - SL Compliance auditing.
*				GF 05/10/2010 - issue #138050 - wrapped isnull in auditing where clause
*
*
*
*  Reject changes to SLCo, SL, CompCode or Seq.
*  Vendor Group and Vendor must both be null or a valid Vendor in bAPVM.
*  Vendor Group must be correct one for Company from bHQCO.
*  If CompType from bHQCP is 'D' then Complied must be null.
*  If CompType is 'F', then ExpDate must be null.
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return

select @validcnt=0

set nocount on

---- check for key changes
select @validcnt = count(*) from deleted d, inserted i
where d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq = i.Seq
if @numrows <> @validcnt
	begin
	select @errmsg = 'Cannot change Company, SL number, CompCode or Sequence'
	goto error
	end
   
---- validate Vendor Group in bHQCO
select @validcnt2 = count(*) from inserted i
where i.VendorGroup is not null
select @validcnt = count(*) from dbo.bHQCO r JOIN inserted i ON i.SLCo = r.HQCo and i.VendorGroup = r.VendorGroup
where i.VendorGroup is not null
if @validcnt <> @validcnt2
	begin
	select @errmsg = 'Vendor Group is Invalid '
	goto error
	end

---- validate Vendor in bAPVM
select @validcnt = count(*) from inserted i
where i.Vendor is null
select @validcnt2 = count(*) from inserted i join dbo.bAPVM r on r.VendorGroup = i.VendorGroup and r.Vendor = i.Vendor
where i.Vendor is not null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg='Invalid Vendor '
	goto error
	end

---- if CompType from bHQCP is 'D' then Complied must be null
select @validcnt = count(*)
from dbo.bHQCP r JOIN inserted i ON i.CompCode = r.CompCode
where r.CompType = 'D' and i.Complied is not null
if @validcnt <> 0
	begin
	select @errmsg = 'No Compliance Flag allowed for Date type Compliance Code '
	goto error
	end
	
---- if CompType from bHQCP is 'F' then ExpDate must be null
select @validcnt = count(*)
from dbo.bHQCP r JOIN inserted i ON i.CompCode = r.CompCode
where r.CompType = 'F' and i.ExpDate is not null
if @validcnt <> 0
	begin
	select @errmsg = 'No Compliance Date allowed for Flag type Compliance Code '
	goto error
	end


---- #138050
---- Insert records into HQMA for changes made to audited fields
if UPDATE(Vendor)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Vendor', convert(varchar(10),d.Vendor), convert(varchar(10),i.Vendor), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.Vendor,0) <> isnull(i.Vendor,0) and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(Description)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.Description,'') <> isnull(i.Description,'') and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(Verify)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Verify', d.Verify, i.Verify, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.Verify,'') <> isnull(i.Verify,'') and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(ExpDate)
	begin	
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'ExpDate', convert(varchar(30),d.ExpDate), convert(varchar(30),i.ExpDate), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.ExpDate,'') <> isnull(i.ExpDate,'') and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(Complied)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Complied', d.Complied, i.Complied, getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.Complied,'') <> isnull(i.Complied,'') and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(ReceiveDate)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Receive Date', convert(varchar(30),d.ReceiveDate), convert(varchar(30),i.ReceiveDate), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.ReceiveDate,'') <> isnull(i.ReceiveDate,'') and a.AuditSLCompliance = 'Y'
	end
	
if UPDATE(Limit)
	begin
	insert into bHQMA select 'bSLCT', 'SL:' + i.SL + ' Comp Code: ' + convert(varchar(10),i.CompCode) + ' Seq: ' + convert(varchar(3),i.Seq),
			i.SLCo, 'C', 'Limit', convert(varchar(20),d.Limit), convert(varchar(20),i.Limit), getdate(), SUSER_SNAME()
	from inserted i
	join deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.CompCode = i.CompCode and d.Seq=i.Seq
	join SLCO a on a.SLCo = i.SLCo
	where isnull(d.Limit,0) <> isnull(i.Limit,0) and a.AuditSLCompliance = 'Y'
	end
---- #138050


return


error:
	select @errmsg = @errmsg + ' - cannot update into SL Compliance Tracking'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLCT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLCT] ON [dbo].[bSLCT] ([SLCo], [SL], [CompCode], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCT].[Verify]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCT].[Complied]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLCT].[PurgeYN]'
GO
