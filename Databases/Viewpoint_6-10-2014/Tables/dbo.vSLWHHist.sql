CREATE TABLE [dbo].[vSLWHHist]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[APRef] [dbo].[bAPReference] NULL,
[InvDescription] [dbo].[bDesc] NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[HoldCode] [dbo].[bHoldCode] NULL,
[ReadyYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vSLWHHist_ReadyYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SLKeyID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.vtSLWHHisti    Script Date:  ******/
CREATE trigger [dbo].[vtSLWHHisti] on [dbo].[vSLWHHist] for INSERT as

/***  basic declares for SQL Triggers ****/
declare @numrows int, @validcnt int, @validcnt2 int, @errmsg varchar(255)
   
/*--------------------------------------------------------------
*  Insert trigger for SLWHHist
*
*  Created By:  TJL 03/06/09 - Issue #129889, SL Claims and Certifications
*  Modified: 
*
*
*
*  Duplicated Validation as in bSLWH insert
*  
* 
*--------------------------------------------------------------*/
   
 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
   
/* validate SL Company */
select @validcnt = count(*) from bHQCO c join inserted i on c.HQCo = i.SLCo
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid SL Company#'
   	goto error
   	end
   
/* validate SL */
select @validcnt = count(*) from bSLHD c join inserted i on c.SLCo = i.SLCo and c.SL = i.SL
   where (c.Status = 0 or c.Status = 3)
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Subcontract.  Must be open or pending  '
   	goto error
   	end
   
/* match job and vendor to bSLHD */
select @validcnt = count(*) from bSLHD c join inserted i on c.SLCo = i.SLCo and c.SL = i.SL
   and c.JCCo = i.JCCo and c.Job = i.Job and c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Job and Vendor must match subcontract header  '
   	goto error
   	end

/* validate CM Company */
select @validcnt = count(*) from bHQCO c join inserted i on c.HQCo = i.CMCo
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CM Company# '
   	goto error
   	end
   
   -- validate CM Account
/* Removed per Issue #132290 - Some explanation is required. 
   Explanation:
	1)	This is more consistent with MS under similar circumstances.
	2)	Because of the addition of a CMAcct to the AP Vendor Master it is possible that we could end up with
		a CMAcct default that does not exist in the CMCo as defaulted.  (Has to do with Vendor Groups being 
		shared by multiple AP Companys).  If this occurs then ultimately this will be discovered either by
		SL Worksheet CMAcct field validation (If the record gets changed by user) or will be caught in bspAPHBVal
		during Validation of the AP Entry Transaction.  If caught in AP Entry validation, user will easily be able
		verify the sequence and correct the account. (This is also consistent with MS).  Regardless, the SLWH
		trigger is not a great place to catch this since it disrupts the Worksheet initialization without 
		adequately identifying the specific vendor causing the problem.

	In any case we will remove for now (again to be consistent with MS) and see what happens. 

	Update trigger does not need to be adjusted since the Initialization process never does a SLWH update
	and any updates to a specific worksheet entry would be caught by CMAcct field validation in advance of
	the trigger error. */

--   select @validcnt2 = count(*) from inserted where CMAcct is not null
--   select @validcnt = count(*) from bCMAC c join inserted i on c.CMCo = i.CMCo and c.CMAcct = i.CMAcct
--       where i.CMAcct is not null
--   if @validcnt <> @validcnt2
--       begin
--       select @errmsg = 'Invalid CM Account '
--       goto error
--       end
   
-- validate Hold Code
select @validcnt2 = count(*) from inserted where HoldCode is not null
select @validcnt = count(*) from bHQHC c join inserted i on c.HoldCode = i.HoldCode
   where i.HoldCode is not null
if @validcnt <> @validcnt2
   begin
   select @errmsg = 'Invalid Hold Code '
   goto error
   end

return
   
error:
   select @errmsg = @errmsg + ' - cannot insert SL Worksheet Header History'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.vtSLWHHistu    Script Date: ******/
CREATE trigger [dbo].[vtSLWHHistu] on [dbo].[vSLWHHist] for UPDATE as
   
/*--------------------------------------------------------------
*  Update trigger for SLWHHist
*
*  Created By:  TJL 03/06/09 - Issue #129889, SL Claims and Certifications
*  Modified: 
*
*
*
*  Duplicated Validation as in bSLWH update
*  
* 
*--------------------------------------------------------------*/
   
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- check for key changes
select @validcnt = count(*) from deleted d
	join inserted i on i.SLCo=d.SLCo and i.SL=d.SL
if @validcnt <> @numrows
	begin
	select @errmsg = 'Cannot change Primary key'
	goto error
	end
   
/* match job and vendor to bSLHD */
select @validcnt = count(*) from inserted i left join bSLHD c on c.SLCo = i.SLCo and c.SL = i.SL
	and c.JCCo = i.JCCo and c.Job = i.Job and c.VendorGroup = i.VendorGroup and c.Vendor = i.Vendor
if @validcnt <> @numrows
	begin
	select @errmsg = 'Job and Vendor must match subcontract header  ' + convert(varchar(10),@validcnt)
	goto error
	end
   
/* validate CM Company */
select @validcnt = count(*) from bHQCO c join inserted i on c.HQCo = i.CMCo
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid CM Company# '
   	goto error
   	end
   
-- validate CM Account
select @validcnt2 = count(*) from inserted where CMAcct is not null
select @validcnt = count(*) from bCMAC c join inserted i on c.CMCo = i.CMCo and c.CMAcct = i.CMAcct
	where i.CMAcct is not null
if @validcnt <> @validcnt2
	begin
	select @errmsg = 'Invalid CM Account '
	goto error
	end
   
-- validate Hold Code
select @validcnt2 = count(*) from inserted where HoldCode is not null
select @validcnt = count(*) from bHQHC c join inserted i on c.HoldCode = i.HoldCode
	where i.HoldCode is not null
if @validcnt <> @validcnt2
	begin
	select @errmsg = 'Invalid Hold Code '
	goto error
	end

return
   
error:
  select @errmsg = @errmsg + ' - cannot update SL Worksheet Header History'
  RAISERROR(@errmsg, 11, -1);
  rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [viKeyID] ON [dbo].[vSLWHHist] ([KeyID]) ON [PRIMARY]
GO
