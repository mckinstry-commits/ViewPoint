CREATE TABLE [dbo].[vHQRD]
(
[ReviewerGroup] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL,
[ApprovalSeq] [tinyint] NOT NULL CONSTRAINT [DF_vHQRD_ApprovalSeq] DEFAULT ((1)),
[ApproveWithoutData] [dbo].[bYN] NOT NULL CONSTRAINT [DF_vHQRD_ApproveWithoutData] DEFAULT ('Y'),
[ThresholdAmount] [decimal] (18, 2) NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[vHQRD] ADD 
CONSTRAINT [PK_vHQRD] PRIMARY KEY CLUSTERED  ([ReviewerGroup], [Reviewer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     trigger [dbo].[vtHQRDd] on [dbo].[vHQRD] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: MV 11/08/07
    * Modified: 
    *
    *	This trigger restricts deletion of any vHQRD records if
    *	entries exist in bAPUR for this reviewer where APMth and APTrans are null
	*	(unposted unapproveds)
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if exists(select * from bAPUR r Join deleted d on r.ReviewerGroup=d.ReviewerGroup and r.Reviewer=d.Reviewer
	where r.Line <> -1 and r.APTrans is null and r.ExpMonth is null)
	begin
   	select @errmsg='There are Unapproved Lines with this Reviewer Group and Reviewer.'
   	goto error
   	end
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete Reviewer Group Detail!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           trigger [dbo].[vtHQRDi] on [dbo].[vHQRD] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created:		MV 11/08/07 #29702
    *  Modified: 
    *
    * Insert trigger for HQ Reviewer Group Detail
    *
    */----------------------------------------------------------------
   
   declare @errmsg varchar(255), @validcnt int, @numrows int, @apco bCompany, @uimth bMonth,
   	@uiseq int, @line int, @jcco bCompany, @job bJob, @emco bCompany, @equip bEquip,
    	@vendorgroup bGroup,@vendor bVendor, @linetype tinyint, @inco bCompany, @loc bLoc
   
   SELECT @numrows = Count(*)from Inserted
   IF @numrows = 0 return
  
   SET nocount on
   
   /* check Reviewer Group Header */
   SELECT @validcnt = count(*) FROM vHQRG r
   	JOIN inserted i ON r.ReviewerGroup=i.ReviewerGroup
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Reviewer Group Header does not exist.'
   	GOTO error
   	END
  /* validate Reviewer */
   select @validcnt = count(*) from inserted i with (nolock)
       join bHQRV c with (nolock) on c.Reviewer = i.Reviewer
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Reviewer'
   	GOTO error
   	END 
   
   
   return
   
   error:
       SELECT @errmsg = @errmsg +  ' - cannot insert Reviewer Group Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   trigger [dbo].[vtHQRDu] on [dbo].[vHQRD] for UPDATE as
 

/*-----------------------------------------------------------------
  *  Created: MV 11/08/07
  *  Modified: 
  *				
  * Validates ReviewerGroup,Responsible Person,
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
 
/* validate Reviewer */
   select @validcnt = count(*) from inserted i with (nolock)
       join bHQRV c with (nolock) on c.Reviewer = i.Reviewer
   IF @validcnt <> @numrows
   	BEGIN
   	SELECT @errmsg = 'Invalid Reviewer'
   	GOTO error
   	END

 
 return
 
 
 
 error:
 	SELECT @errmsg = @errmsg +  ' - cannot update HQ Reviewer Group Detail!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction

GO
