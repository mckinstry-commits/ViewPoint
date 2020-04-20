CREATE TABLE [dbo].[vHQRG]
(
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ResponsiblePerson] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ReviewerGroupType] [tinyint] NOT NULL CONSTRAINT [DF_vHQRG_ReviewerGroupType] DEFAULT ((1)),
[ActionOnChangedData] [tinyint] NOT NULL CONSTRAINT [DF_vHQRG_ActionOnChangedData] DEFAULT ((1)),
[AllowUpLevelApproval] [tinyint] NOT NULL CONSTRAINT [DF_vHQRG_AllowUpLevelApproval] DEFAULT ((1)),
[EmailOptOnRejOriginator] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRG_EmailOptOnRejOriginator] DEFAULT (N'N'),
[EmailOptOnRejResponsiblePerson] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRG_EmailOptOnRejResponsiblePerson] DEFAULT (N'N'),
[EmailOptOnRejReviewerApproved] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRG_EmailOptOnRejReviewerApproved] DEFAULT (N'N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ApplyThreshToLineYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRG_ApplyThreshToLineYN] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     trigger [dbo].[vtHQRGd] on [dbo].[vHQRG] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: MV 11/08/07
    * Modified: 
    *
    *	This trigger restricts deletion of any vHQRG records if
    *	entries exist in bAPUR where APMth and APTrans are null
	*	(unposted unapproveds) or if the Reviewer Group exists in 
	*	any APUI, APUL, JCJM, GLAC, EMDM or INLM recs.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if exists(select 1 from bAPUR r with (nolock) Join deleted d on r.ReviewerGroup=d.ReviewerGroup
	where r.Line <> -1 and r.APTrans is null and r.ExpMonth is null)
	begin
   	select @errmsg='Cannot delete Reviewer Group, there are unposted Unapproved Lines with this Reviewer Group.'
   	goto error
   	end

	if exists(select 1 from bAPUI i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are Unapproved Headers with this Reviewer Group.'
   	goto error
   	end

	if exists(select 1 from bAPUL i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are Unapproved Lines with this Reviewer Group.'
   	goto error
   	end

	if exists(select 1 from bJCJM i with (nolock) Join deleted d on i.RevGrpInv=d.ReviewerGroup)
	begin
   	select @errmsg='There are Jobs with this Reviewer Group.'
   	goto error
   	end
	   
	if exists(select 1 from bGLAC i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are GL Accounts with this Reviewer Group.'
   	goto error
   	end
	
	if exists(select 1 from bEMDM i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are Equipment Dept recs with this Reviewer Group.'
   	goto error
   	end	

	if exists(select 1 from bINLM i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are Inventory Locations with this Reviewer Group.'
   	goto error
   	end

	if exists(select 1 from bGLAC i with (nolock) Join deleted d on i.ReviewerGroup=d.ReviewerGroup)
	begin
   	select @errmsg='There are GL Accts with this Reviewer Group.'
   	goto error
   	end

   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete Reviewer Group!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      trigger [dbo].[vtHQRGi] on [dbo].[vHQRG] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: MV 11/08/07
    *  Modified: 
    *          
    *
    * Validates Responsible Person,ReviewerGroupType,ActionOnChangedData,AllowUPlevelApproval
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
   SELECT @numrows = @@rowcount
   IF @numrows = 0 return
   SET nocount on
	/* validate ResponsiblePerson */
   select @validcnt = count(*) from inserted i with (nolock)
       join bHQRV c with (nolock) on c.Reviewer = i.ResponsiblePerson
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid ResponsiblePerson'
   	GOTO error
   	END
	/* validate ReviewerGroupType */
   select @validcnt = count(*) from inserted with (nolock)
       where ReviewerGroupType in (1,2,3)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid ReviewerGroupType must be 1-Invoice, 2-PO or 3-Both.'
   	GOTO error
   	END
	/* validate ActionOnChangedData */
   select @validcnt = count(*) from inserted with (nolock)
       where ActionOnChangedData in (1,2,3)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid ActionOnChangedData must be 1-Nothing, 2-ClLear prior approval on amount change or 3-Clear prior approval on data change.'
   	GOTO error
   	END
/* validate AllowUpLevelApproval */
   select @validcnt = count(*) from inserted with (nolock)
       where AllowUpLevelApproval in (1,2)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AllowUpLevelApproval must be 1-View and approve self only or 2-View and approve self and lower levels.'
   	GOTO error
   	END


   return
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert HQ Reviewer Group!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[vtHQRGu] on [dbo].[vHQRG] for UPDATE as
 

/*-----------------------------------------------------------------
  *  Created: MV 11/08/07
  *  Modified: 
  *				
  * Validates Responsible Person,ReviewerGroupType,ActionOnChangedData,AllowUPlevelApproval
  */----------------------------------------------------------------
 declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int
 
 SELECT @numrows = @@rowcount
 IF @numrows = 0 return
 SET nocount on

 -- check for key changes
 if Update(ReviewerGroup)
   	begin
   	select @errmsg = 'Cannot change ReviewerGroup'
   	goto error
   	end
 
/* validate ReviewerGroupType */
   select @validcnt = count(*) from inserted with (nolock)
       where ReviewerGroupType in (1,2,3)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid ReviewerGroupType must be 1-Invoice, 2-PO or 3-Both.'
   	GOTO error
   	END
	/* validate ActionOnChangedData */
   select @validcnt = count(*) from inserted with (nolock)
       where ActionOnChangedData in (1,2,3)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid ActionOnChangedData must be 1-Nothing, 2-ClLear prior approval on amount change or 3-Clear prior approval on data change.'
   	GOTO error
   	END
/* validate AllowUpLevelApproval */
   select @validcnt = count(*) from inserted with (nolock)
       where AllowUpLevelApproval in (1,2)
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid AllowUpLevelApproval must be 1-View and approve self only or 2-View and approve self and lower levels.'
   	GOTO error
   	END
 
 
 return
 
 
 
 error:
 	SELECT @errmsg = @errmsg +  ' - cannot update HQ Reviewer Group!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction

GO
ALTER TABLE [dbo].[vHQRG] ADD CONSTRAINT [PK_vHQRG] PRIMARY KEY CLUSTERED  ([ReviewerGroup]) ON [PRIMARY]
GO
