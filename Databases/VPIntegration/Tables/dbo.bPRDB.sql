CREATE TABLE [dbo].[bPRDB]
(
[PRCo] [dbo].[bCompany] NOT NULL,
[DLCode] [dbo].[bEDLCode] NOT NULL,
[EDLCode] [dbo].[bEDLCode] NOT NULL,
[SubjectOnly] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[EDLType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF__bPRDB__EDLType__51E20B31] DEFAULT ('E')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRDBd] ON [dbo].[bPRDB] 
   FOR DELETE 
   AS
   
/*-----------------------------------------------------------------
*	Created: RM  issue 12693
* 	Modified: EN 9/4/07  issue 120214 - table add/delete not being audited in bHQMA
*				CHS 10/15/2010 - issue #140541
*
*	This trigger validates insertion in bPRDB (PR Dedn/Liab Basis)
*/----------------------------------------------------------------
   
   /* add HQ Master Audit entry */
   insert into dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 select 'bPRDB',  'PR Co#: ' + convert(varchar(10), d.PRCo) + ' DLCode: ' + convert(varchar(10), d.DLCode) + 
	 ' EDL Type: ' + convert(varchar(10), d.EDLType) + ' EDL Code: ' + convert(varchar(10), d.EDLCode), d.PRCo, 'D',
   	 null, null, null, getdate(), SUSER_SNAME() from deleted d join dbo.PRCO a with (nolock) on d.PRCo=a.PRCo
        where a.AuditDLs='Y'
   
   
   



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRDBi] ON [dbo].[bPRDB] 
   FOR INSERT
   as
   
/*-----------------------------------------------------------------
*	Created:	RM  issue 12693
* 	Modified:	EN 9/4/07  issue 120214 - table add/delete not being audited in bHQMA
*				CHS 10/15/2010 - issue #140541    
*
*	This trigger validates insertion in bPRDB (PR Dedn/Liab Basis)
*/----------------------------------------------------------------

DECLARE @errmsg VARCHAR(255), @numrows INT, @validcnt INT, @cnt INT

SELECT @numrows = @@rowcount
IF @numrows = 0 RETURN

SET NOCOUNT ON
   
   
   
-- validate EDL Type
SELECT @validcnt = count(*) FROM INSERTED WHERE EDLType in ('E','D')
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid Type.  Must be ''E'' or ''D'''
	GOTO error
END

-- validate Earnings Codes
SELECT @cnt = count(*) FROM INSERTED WHERE EDLType = 'E'
SELECT @validcnt = count(*) FROM INSERTED i
join dbo.bPREC e WITH (NOLOCK) ON e.PRCo = i.PRCo and e.EarnCode = i.EDLCode
WHERE i.EDLType = 'E'
IF @validcnt <> @cnt
BEGIN
	SELECT @errmsg = 'Invalid Earnings code'
	GOTO error
END

-- validate Pre Tax Dedn Codes
SELECT @cnt = count(*) FROM INSERTED WHERE EDLType = 'D'
SELECT @validcnt = count(*) FROM INSERTED i
join dbo.bPRDL d WITH (NOLOCK) ON d.PRCo = i.PRCo and d.DLCode = i.EDLCode
WHERE i.EDLType = 'D' and d.PreTax = 'Y'
IF @validcnt <> @cnt
BEGIN
	SELECT @errmsg = 'Invalid Deduction code'
	GOTO error
END

 --validate Target (Parent) Dedn Code
SELECT @cnt = count(*) FROM INSERTED WHERE EDLType = 'D'
SELECT @validcnt = count(*) FROM INSERTED i
join dbo.bPRDL d WITH (NOLOCK) ON d.PRCo = i.PRCo and d.DLCode = i.DLCode
WHERE i.EDLType = 'D' AND d.CalcCategory in ('F', 'S', 'L', 'E', 'I') AND d.Method IN ('G', 'R')
IF @validcnt <> @cnt
BEGIN
	SELECT @errmsg = 'Invalid target (parent) Deduction code. Must be category F, S, L, E or I and method G or R'
	GOTO error
END  	
  
  
   /* add HQ Master Audit entry */
   INSERT INTo dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	 SELECT 'bPRDB',  'PR Co#: ' + convert(VARCHAR(10), i.PRCo) + ' DLCode: ' + convert(VARCHAR(10), i.DLCode) + 
	 ' EDL Type: ' + convert(VARCHAR(10), i.EDLType) + ' EDL Code: ' + convert(VARCHAR(10), i.EDLCode), i.PRCo, 'A',
   	 null, null, null, getdate(), SUSER_SNAME() FROM INSERTed i join dbo.PRCO a WITH (NOLOCK) ON i.PRCo=a.PRCo
        WHERE a.AuditDLs='Y'


RETURN
   
   error:
   	SELECT @errmsg = isnull(@errmsg,'') + ' - cannot insert PR Deduction Basis! - (bPRDB)'

   	RAISERROR(@errmsg, 11, -1);
   	ROLLBACK TRANSACTION
     
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   CREATE  TRIGGER [dbo].[btPRDBu] ON [dbo].[bPRDB] 
   FOR UPDATE 
   AS
   
/*-----------------------------------------------------------------
*	Created: 
* 	Modified: CHS 10/15/2010 - issue #140541
*/----------------------------------------------------------------   

declare @rcode int,@errmsg varchar(255)
   
   if update(DLCode)
   begin
   	select @rcode = 1,@errmsg = 'Cannot update DLCode.'
   	raiserror(@errmsg,9,-1)
   	return
   end
   
   
   --Audit PR DedLiab info on update
    insert dbo.bHQMA select 'bPRDB', ' PRCo: ' + convert(varchar(10), i.PRCo) + ' DLCode: ' + convert(varchar(10), i.DLCode) + ' EDL Code: ' + convert(varchar(10), i.EDLCode),
            i.PRCo, 'C', 'EDL Code', convert(char(8),d.EDLCode), convert(char(8),i.EDLCode), getdate(), SUSER_SNAME()
        from inserted i
        join deleted d on d.PRCo = i.PRCo and d.DLCode = i.DLCode and d.EDLCode = i.EDLCode
        join dbo.bPRCO c with (nolock) on c.PRCo = i.PRCo
        where d.EDLCode <> i.EDLCode and c.AuditDLs = 'Y'
   
    insert dbo.bHQMA select 'bPRDB', ' PRCo: ' + convert(varchar(10), i.PRCo) + ' DLCode: ' + convert(varchar(10), i.DLCode) + ' EDL Code: ' + convert(varchar(10), i.EDLCode),
            i.PRCo, 'C', 'SubjectOnly', convert(char(8),d.SubjectOnly), convert(char(8),i.SubjectOnly), getdate(), SUSER_SNAME()
        from inserted i
        join deleted d on d.PRCo = i.PRCo and d.DLCode = i.DLCode and d.EDLCode = i.EDLCode
        join dbo.bPRCO c with (nolock) on c.PRCo = i.PRCo
        where d.SubjectOnly <> i.SubjectOnly and c.AuditDLs = 'Y'
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPRDB] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [IX_bPRDB_EDL] ON [dbo].[bPRDB] ([PRCo], [DLCode], [EDLType], [EDLCode]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPRDB].[SubjectOnly]'
GO
