CREATE TABLE [dbo].[bJCTH]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[LiabTemplate] [smallint] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCTHd    Script Date: 8/28/99 9:37:48 AM ******/
CREATE  trigger [dbo].[btJCTHd] on [dbo].[bJCTH] for DELETE as
/*-----------------------------------------------------------------
* This trigger rejects delete in bJCTH (JC Dept Liability Template Headers)
* if the following error condition exists:
*
* entries exist in JCTL (Liability Template Details)
* Modified: JVH 2/15/10 - 136066 Updated auditing
*
*
*********************************************************************/
    
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

begin

/* check JCTL */
if exists(select * from deleted, bJCTL
where bJCTL.JCCo = deleted.JCCo and bJCTL.LiabTemplate = deleted.LiabTemplate)
	begin
	select @errmsg = 'Entries exist in JC Liability Template Details'
	goto error
	end
	
/* Audit inserts */
INSERT INTO dbo.bHQMA
SELECT 'bJCTH', 'LiabTemplate: ' + CAST(DELETED.LiabTemplate AS VARCHAR), DELETED.JCCo, 'D', NULL, NULL, NULL, GETDATE(), SUSER_SNAME()
FROM DELETED INNER JOIN bJCCO WITH (NOLOCK) ON DELETED.JCCo = bJCCO.JCCo 
WHERE bJCCO.AuditLiabilityTemplate = 'Y'

return

error:
   select @errmsg = @errmsg + ' - cannot delete Liability Template Header!'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
end
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCTHi    Script Date: 8/28/99 9:37:48 AM ******/
   CREATE  trigger [dbo].[btJCTHi] on [dbo].[bJCTH] for INSERT as
   
   

declare @errmsg varchar(255), @errno int, @numrows int,
   	@validcnt int
   
   /*-----------------------------------------------------------------
    *	This trigger rejects insertion in bJCTN (JC Liab Template Headers)
    *	if the following error condition exists:
    *         Invalid JCCo
    *
	*	Modified: JVH 2/15/10 - 136066 Added auditing
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* validate Company */
   select @validcnt = count(*) from bJCCO j, inserted i where i.JCCo=j.JCCo
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid JC Company.'
   	goto error
   	end
   
	---- Audit inserts
	INSERT INTO dbo.bHQMA
	SELECT 'bJCTH','LiabTemplate: ' + CAST(INSERTED.LiabTemplate AS VARCHAR), INSERTED.JCCo, 'A', NULL, NULL, NULL, GETDATE(), SUSER_SNAME() 
	FROM INSERTED INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo
	WHERE bJCCO.AuditLiabilityTemplate = 'Y'
   
   return
   
   error:
   
   	select @errmsg = @errmsg + ' - cannot insert JC Liability Template!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCTHu    Script Date: 8/28/99 9:37:48 AM ******/
   CREATE  trigger [dbo].[btJCTHu] on [dbo].[bJCTH] for update as
   

declare @errmsg varchar(255), @validcnt int, @msgstart char(12)
   /*-----------------------------------------------------------------
    * Created: ?
    * Modified: GG 6/17/98
    *			JVH 2/15/2010 #136066 - Updated auditing
    *
    *	This trigger rejects update in bJCTH (JC Liability Template Headers)
    *	 if the following error condition exists:
    *
    *		cannot revise LiabTemplate (key)
    */
   declare  @errno int, @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   if @numrows > 1
   	select @msgstart = 'At least 1 '
   else
   	select @msgstart = ''
   begin
    if update(LiabTemplate)
     begin
        select @validcnt = count(*) from deleted d, inserted i where d.JCCo = i.JCCo
        	and d.LiabTemplate = i.LiabTemplate
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change Liability Template'
   		goto error
   		end
     end
   /*----------------------------*/

   /* Audit inserts */
    IF NOT EXISTS(SELECT TOP 1 1 FROM INSERTED INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo WHERE bJCCO.AuditLiabilityTemplate = 'Y')
		RETURN
   
   /* Description audit into HQMA */
	IF UPDATE(Description)
	BEGIN
   		INSERT INTO dbo.bHQMA 
		SELECT 'bJCTH', 'LiabTemplate: ' + CAST(INSERTED.LiabTemplate AS VARCHAR), INSERTED.JCCo, 'C', 'Description', DELETED.Description, INSERTED.Description, GETDATE(), SUSER_SNAME()
   		FROM INSERTED INNER JOIN DELETED ON INSERTED.JCCo = DELETED.JCCo AND INSERTED.LiabTemplate = DELETED.LiabTemplate
   			INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo
   		WHERE bJCCO.AuditLiabilityTemplate = 'Y' AND ISNULL(INSERTED.Description, '') <> ISNULL(DELETED.Description, '')
	END
   -- Phase Group
   	IF UPDATE(PhaseGroup)
	BEGIN
		INSERT INTO dbo.bHQMA 
		SELECT 'bJCTH', 'LiabTemplate: ' + CAST(INSERTED.LiabTemplate AS VARCHAR), INSERTED.JCCo, 'C', 'PhaseGroup', CAST(DELETED.PhaseGroup AS VARCHAR), CAST(INSERTED.PhaseGroup AS VARCHAR), GETDATE(), SUSER_SNAME()
   		FROM INSERTED INNER JOIN DELETED ON INSERTED.JCCo = DELETED.JCCo AND INSERTED.LiabTemplate = DELETED.LiabTemplate
   			INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo
   		WHERE bJCCO.AuditLiabilityTemplate = 'Y' AND ISNULL(INSERTED.PhaseGroup, '') <> ISNULL(DELETED.PhaseGroup, '')
   	END
   -- Phase
    IF UPDATE(Phase)
	BEGIN
		INSERT INTO dbo.bHQMA 
		SELECT 'bJCTH', 'LiabTemplate: ' + CAST(INSERTED.LiabTemplate AS VARCHAR), INSERTED.JCCo, 'C', 'Phase', DELETED.Phase, INSERTED.Phase, GETDATE(), SUSER_SNAME()
   		FROM INSERTED INNER JOIN DELETED ON INSERTED.JCCo = DELETED.JCCo AND INSERTED.LiabTemplate = DELETED.LiabTemplate
   			INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo
   		WHERE bJCCO.AuditLiabilityTemplate = 'Y' AND ISNULL(INSERTED.Phase, '') <> ISNULL(DELETED.Phase, '')
    END	
   -- Cost Type
    IF UPDATE(CostType)
	BEGIN
   		INSERT INTO dbo.bHQMA 
		SELECT 'bJCTH', 'LiabTemplate: ' + CAST(INSERTED.LiabTemplate AS VARCHAR), INSERTED.JCCo, 'C', 'CostType', CAST(DELETED.CostType AS VARCHAR), CAST(INSERTED.CostType AS VARCHAR), GETDATE(), SUSER_SNAME()
   		FROM INSERTED INNER JOIN DELETED ON INSERTED.JCCo = DELETED.JCCo AND INSERTED.LiabTemplate = DELETED.LiabTemplate
   			INNER JOIN bJCCO WITH (NOLOCK) ON INSERTED.JCCo = bJCCO.JCCo
   		WHERE bJCCO.AuditLiabilityTemplate = 'Y' AND ISNULL(INSERTED.CostType, '') <> ISNULL(DELETED.CostType, '')
    END	
   /*----------*/
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Liability Template Header!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCTH] ON [dbo].[bJCTH] ([JCCo], [LiabTemplate]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCTH] ([KeyID]) ON [PRIMARY]
GO
