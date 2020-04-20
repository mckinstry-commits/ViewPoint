CREATE TABLE [dbo].[bJCCT]
(
[PhaseGroup] [tinyint] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Abbreviation] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TrackHours] [dbo].[bYN] NULL,
[LinkProgress] [dbo].[bJCCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[JBCostTypeCategory] [char] (1) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCCTd    Script Date: 8/28/99 9:37:42 AM ******/
   CREATE  trigger [dbo].[btJCCTd] on [dbo].[bJCCT] for DELETE as
   

declare @errmsg varchar(255), @validcnt int 
   
   /*-----------------------------------------------------------------
    *	This trigger rejects delete in bJCCT (JC Cost Types) if  
    *	the following error condition exists:
    *
    *		entries exist in JCPC
    *		entries exist in JCCH - 
    *		entries exist in JCDC
    *
    */----------------------------------------------------------------
    
   if @@rowcount = 0 return
   set nocount on
   
   /* check JCPC */
   if exists(select * from deleted d, bJCPC p where d.PhaseGroup = p.PhaseGroup and d.CostType=p.CostType)
   	begin
   	select @errmsg = 'Entries exist in JC Phase Cost Types'
   	goto error
   	end
   
   /* Check JCCH */
   if exists(select * from deleted d JOIN bJCCH o ON
    d.PhaseGroup = o.PhaseGroup
    and d.CostType = o.CostType)
      begin
      select @errmsg = 'Entries exist in JC Cost Header'
      goto error
      end
   
   /* check JCDC */
   if exists(select * from deleted d, bJCDC c where d.PhaseGroup = c.PhaseGroup and d.CostType=c.CostType)
   	begin
   	select @errmsg = 'Entries exist in JC Department Cost Types'
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot delete Cost Type!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btJCCTi    Script Date: 8/28/99 9:37:42 AM ******/
   CREATE  trigger [dbo].[btJCCTi] on [dbo].[bJCCT] for INSERT as
   
/*-----------------------------------------------------------------
* Last Modified: CHS 01/28/08 -- issue #120085
*
*	This trigger rejects insertion in bJCCT (JC Cost Types) if the
*	following error condition exists:
*
*		Invalid Cost Type (not between 1 - 255)
*		Invalid Phase Group
*		Invalid Link Progress Cost Type
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @errno int, @numrows int,
   	@validcnt int, @validcnt2 int

   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   
   /* validate Cost Type */
   select @validcnt = count(*) from inserted i where i.CostType >= 1 and i.CostType <= 255
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid JC Cost Type'
   	goto error
   	end
   
   /* validate Phase Group */
   select @validcnt = count(*) from bHQGP p, inserted i where p.Grp = i.PhaseGroup
   
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Phase Group'
   	goto error
   	end
   
   /* validate Link Progress Cost Type */
--   select @validcnt = count(*)
--   from inserted i, bJCCT c
--   where i.PhaseGroup = c.PhaseGroup and i.LinkProgress = c.CostType and c.LinkProgress is null
--   
--   select @validcnt2 = count(*)
--   from inserted i
--   where i.LinkProgress is null
--   

   
-- ** validate Link Progress Cost Type **

-- validate 'Link Progress Cost Type' is not already linked to another Cost Type AND ... 
--		that this Cost Type hasn't already been linked to
	select @validcnt = count(*)
		from inserted i with (nolock) join bJCCT c on 
			i.PhaseGroup = c.PhaseGroup 
			and i.LinkProgress = c.CostType 
			and c.LinkProgress is null
			and not exists(select 1 from JCCT c with (nolock) where c.PhaseGroup = i.PhaseGroup and c.LinkProgress = i.CostType)

-- count the rest
   select @validcnt2 = count(*)
   from inserted i
   where i.LinkProgress is null
   
   
   if (@validcnt + @validcnt2)   <> @numrows
   	begin
   	select @errmsg = 'Invalid Link Progress Cost Type'
   	goto error
   	end



   return
   
   error:
   
   	select @errmsg = @errmsg + ' - cannot insert JC Cost Type!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btJCCTu    Script Date: 8/28/99 9:37:43 AM ******/
   CREATE  trigger [dbo].[btJCCTu] on [dbo].[bJCCT] for UPDATE as
   
/*-----------------------------------------------------------------
* Last Modified: CHS 01/28/08 -- issue #120085
*
*	This trigger rejects update in bJCCT (JC Cost Types) if any
*	of the following error conditions exist:
*
*		Cannot change Phase Group
*		Cannot change Cost Type
*		Cannot change Link Progress Cost Type to a Cost Type already linked
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int 
   	    
   select @numrows = @@rowcount
   if @numrows = 0 return 
   set nocount on
   
   /* check for changes to Phase Group */
   if update(PhaseGroup)
   	begin
   	select @errmsg = 'Cannot change Phase Group'
   	goto error
   	end 
   
   /* check for changes to Cost Type */
   
   if update(CostType)
   	begin
   	select @errmsg = 'Cannot change Cost Type'
   	goto error
   
   	end
   
--   /* validate Link Progress Cost Type */
--   select @validcnt = count(*) from inserted i, bJCCT c 
--           where i.PhaseGroup = c.PhaseGroup 
--           and i.LinkProgress = c.CostType
--   	and c.LinkProgress is null

-- ** validate Link Progress Cost Type **

-- validate 'Link Progress Cost Type' is not already linked to another Cost Type AND ... 
--		that this Cost Type hasn't already been linked to
	select @validcnt = count(*)
		from inserted i with (nolock) join bJCCT c on 
			i.PhaseGroup = c.PhaseGroup 
			and i.LinkProgress = c.CostType 
			and c.LinkProgress is null
			and not exists(select 1 from JCCT c with (nolock) where c.PhaseGroup = i.PhaseGroup and c.LinkProgress = i.CostType)

-- count the rest   	 
   select @validcnt2 = count(*) from inserted i where i.LinkProgress is null
   
   if @validcnt + @validcnt2 <> @numrows 
   	begin
   	select @errmsg = 'Invalid Link Progress Cost Type'
   
   	goto error
   	end
   
   return
   
   error:
       select @errmsg = @errmsg + ' - cannot update Cost Types!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCCT] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJCCT] ON [dbo].[bJCCT] ([PhaseGroup], [CostType]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCCT].[TrackHours]'
GO
