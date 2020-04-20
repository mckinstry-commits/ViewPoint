CREATE TABLE [dbo].[bRQVQ]
(
[RQCo] [dbo].[bCompany] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[Quote] [int] NOT NULL,
[Vendor_Group] [dbo].[bGroup] NULL,
[SentDate] [dbo].[bDate] NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   CREATE  trigger [dbo].[btRQVQd] on [dbo].[bRQVQ] for DELETE as
    

/* ERwin Builtin Wed Feb 11 13:54:02 2004 */
    /* DELETE trigger on bRQVQ */
    begin
      declare  @errmsg  varchar(255)
        /* ERwin Builtin Wed Feb 11 13:54:02 2004 */
        /* bRQVQ R/65 bRQWQ ON PARENT DELETE RESTRICT */
        if exists (
          select * from deleted,bRQWQ
          where
            /*  %JoinFKPK(bRQWQ,deleted," = "," and") */
            bRQWQ.Vendor = deleted.Vendor and
            bRQWQ.RQCo = deleted.RQCo and
            bRQWQ.Quote = deleted.Quote
        )
        begin
          select @errmsg = 'Cannot DELETE bRQVQ because bRQWQ exists.'
          goto error
        end
    
    
        /* ERwin Builtin Wed Feb 11 13:54:02 2004 */
        return
    error:
        RAISERROR(@errmsg, 11, -1)
        rollback transaction
    end
    
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE   trigger [dbo].[btRQVQi] on [dbo].[bRQVQ] for INSERT as
     

/* ERwin Builtin Wed Feb 11 13:54:03 2004 */
     /* INSERT trigger on bRQVQ */
     begin
       declare  @numrows int,
                @nullcnt int,
                @validcnt int,
                @errmsg  varchar(255)
     
       select @numrows = @@rowcount
       /* ERwin Builtin Wed Feb 11 13:54:02 2004 */
       /* bRQQH R/73 bRQVQ ON CHILD INSERT RESTRICT */
       if
         /* %ChildFK(" or",update) */
         update(RQCo) or
         update(Quote)
       begin
         select @nullcnt = 0
         select @validcnt = count(*)
           from inserted,bRQQH
             where
               /* %JoinFKPK(inserted,bRQQH) */
               inserted.RQCo = bRQQH.RQCo and
               inserted.Quote = bRQQH.Quote
         /* %NotnullFK(inserted," is null","select @nullcnt = count(*) from inserted where"," and") */
         
         if @validcnt + @nullcnt <> @numrows
         begin
           select @errmsg = 'Cannot INSERT bRQVQ because bRQQH does not exist.'
           goto error
         end
       end
     
     
       /* ERwin Builtin Wed Feb 11 13:54:03 2004 */
       return
     error:
         RAISERROR(@errmsg, 11, -1)
         rollback transaction
     end
     
    
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE   trigger [dbo].[btRQVQu] on [dbo].[bRQVQ] for UPDATE as
     

/* ERwin Builtin Wed Feb 11 13:54:03 2004 */
     /* UPDATE trigger on bRQVQ */
     begin
       declare  @numrows int,
                @nullcnt int,
                @validcnt int,
                @insVendor bVendor, 
                @insRQCo bCompany, 
                @insQuote int,
                @errmsg  varchar(255)
     
       select @numrows = @@rowcount
       /* ERwin Builtin Wed Feb 11 13:54:03 2004 */
       /* bRQVQ R/65 bRQWQ ON PARENT UPDATE RESTRICT */
       if
         /* %ParentPK(" or",update) */
         update(Vendor) or
         update(RQCo) or
         update(Quote)
       begin
         if exists (
           select * from deleted,bRQWQ
           where
             /*  %JoinFKPK(bRQWQ,deleted," = "," and") */
             bRQWQ.Vendor = deleted.Vendor and
             bRQWQ.RQCo = deleted.RQCo and
             bRQWQ.Quote = deleted.Quote
         )
         begin
           select @errmsg = 'Cannot UPDATE bRQVQ because bRQWQ exists.'
           goto error
         end
       end
     
       /* ERwin Builtin Wed Feb 11 13:54:03 2004 */
       /* bRQQH R/73 bRQVQ ON CHILD UPDATE RESTRICT */
       if
         /* %ChildFK(" or",update) */
         update(RQCo) or
         update(Quote)
       begin
         select @nullcnt = 0
         select @validcnt = count(*)
           from inserted,bRQQH
             where
               /* %JoinFKPK(inserted,bRQQH) */
               inserted.RQCo = bRQQH.RQCo and
               inserted.Quote = bRQQH.Quote
         /* %NotnullFK(inserted," is null","select @nullcnt = count(*) from inserted where"," and") */
         
         if @validcnt + @nullcnt <> @numrows
         begin
           select @errmsg = 'Cannot UPDATE bRQVQ because bRQQH does not exist.'
           goto error
         end
       end
     
     
       /* ERwin Builtin Wed Feb 11 13:54:03 2004 */
       return
     error:
         RAISERROR(@errmsg, 11, -1)
         rollback transaction
     end
     
    
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bRQVQ] ADD CONSTRAINT [biRQVQ] PRIMARY KEY CLUSTERED  ([Vendor], [RQCo], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
