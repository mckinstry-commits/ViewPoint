CREATE TABLE [dbo].[bJCTI]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[InsTemplate] [smallint] NOT NULL,
[PhaseGroup] [tinyint] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[InsCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCTIi    Script Date: 8/28/99 9:37:48 AM ******/
   CREATE  trigger [dbo].[btJCTIi] on [dbo].[bJCTI] for INSERT as
   

declare @errmsg varchar(255), @errno int, @numrows int, 
   	@validcnt int
   	
   /*-----------------------------------------------------------------
    *	This trigger rejects insertion in bJCTI (JC Insurance Templates) if the
    *	following error condition exists:
    *         Invalid JCCo/InsTemplate Combination
    *         Invalid PhaseGroup/Phase Combination
    *         invalid Insurance Code
    */----------------------------------------------------------------
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   /* validate JCCo */
   select @validcnt = count(*) from bJCCO j, inserted i where i.JCCo=j.JCCo
   
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Invalid JC Company.'
   	goto error
   	end
   
   
   /* validate PhaseGroup/Phase */
   /*select @validcnt = count(*) from bJCPM p, inserted i where 
          i.PhaseGroup=p.PhaseGroup and i.Phase=p.Phase
   
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Invalid Phase.'
   	goto error
   	end */
   
   
   /* validate Insurance Template */
   select @validcnt = count(*) from bJCTN t, inserted i where 
          i.JCCo=t.JCCo and i.InsTemplate=t.InsTemplate
   
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Invalid Insurance Template.'
   	goto error
   	end
   
   /* validate Insurance Template */
   select @validcnt = count(*) from bHQIC c, inserted i where 
          c.InsCode=i.InsCode
   
   if @validcnt <> @numrows 
   	begin
   	select @errmsg = 'Invalid Insurance Code.'
   	goto error
   	end
   
   return
   
   error:
   	
   	select @errmsg = @errmsg + ' - cannot insert JC Insurance Template detail!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCTIu    Script Date: 8/28/99 9:37:49 AM ******/
CREATE  trigger [dbo].[btJCTIu] on [dbo].[bJCTI] for UPDATE as
/*-----------------------------------------------------------------
*	Modified:	CHS	12/15/2008 - #131438
*
*	This trigger rejects inserts in bJCTI (JC Insurance templated detail) if any
*	of the following error conditions exist:
*
*		Cannot change JCCo
*		Cannot change PhaseGroup
*		Cannot change Phase
*		Cannot change Insurance template
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int    

   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
	-- Check for changes to key fields
   if UPDATE(JCCo) or UPDATE(PhaseGroup) or UPDATE(Phase) or UPDATE(InsTemplate)
       begin
       select @errmsg = 'Key fields may not be updated'
       goto error
       end

   
   if update(InsCode)
      begin
       /* validate Insurance Template */
       select @validcnt = count(*) from inserted i join bHQIC on bHQIC.InsCode=i.InsCode
	   if @validcnt <> @numrows
			begin
			select @errmsg = 'Invalid Insurance Code.'
			goto error
			end
		end

   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update Insurance Template!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biJCTI] ON [dbo].[bJCTI] ([JCCo], [InsTemplate], [PhaseGroup], [Phase]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCTI] ([KeyID]) ON [PRIMARY]
GO
