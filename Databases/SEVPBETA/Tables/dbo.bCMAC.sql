CREATE TABLE [dbo].[bCMAC]
(
[CMCo] [dbo].[bCompany] NOT NULL,
[CMAcct] [dbo].[bCMAcct] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NOT NULL,
[BankAcct] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ImmedDest] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ImmedOrig] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CompanyId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BankName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[DFI] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RoutingId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ServiceClass] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[AcctType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BatchHeader] [varchar] (94) COLLATE Latin1_General_BIN NULL,
[AssignBank] [varchar] (23) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AUAccountName] [varchar] (26) COLLATE Latin1_General_BIN NULL,
[AUBSB] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[AUBankShortName] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[AUCustomerNumber] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[AUReference] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[AUContraRequiredYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bCMAC_AUContraRequiredYN] DEFAULT ('N'),
[CADestDataCentre] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[CACurrencyCode] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[CAOriginatorId] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CACMRoutingNbr] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[Discretionary] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CAShortName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[CALongName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CAEFTFormat] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bCMAC_CAEFTFormat] DEFAULT ('HSBC'),
[CARBCFileDescriptor] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
CREATE trigger [dbo].[btCMACd] on [dbo].[bCMAC] for DELETE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: Danf 04/12/00 - Added deletion of data security
*			MarkH 3/15/03 - #23061
*			DanF 04/27/04 - #17370 - Use VA Purge Security Entries to purge security entries.
			AR 12/1/2010  - #142311 - adding foreign keys, removing trigger look ups
*
*	This trigger rejects delete in bCMAC (CM Accts) if any of
*	the following error conditions exist:
*		CMST entry exists
*		CMDT exists
*		CMTT exists
*
*	Adds HQ Master Audit entry
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
set nocount on
if @numrows = 0 return

/* check for corresponding entries in CMTT */
IF EXISTS ( SELECT  1
            FROM    dbo.bCMTT g ( NOLOCK )
                    JOIN deleted d ON ( g.FromCMCo = d.CMCo
                                        AND g.FromCMAcct = d.CMAcct
                                      )
                                      OR ( g.ToCMCo = d.CMCo
                                           AND g.ToCMAcct = d.CMAcct
                                         ) ) 
    BEGIN
        SELECT  @errmsg = 'CM Transfer Transaction entries exist'
        GOTO error
    END

/* Audit CM Account deletions */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bCMAC', 'CM Account: ' + convert(varchar(10),isnull(d.CMAcct, '')), d.CMCo, 'D',
		null, null, null, getdate(), SUSER_SNAME()
from deleted d
join dbo.bCMCO c (nolock) on d.CMCo = c.CMCo
where c.AuditAccts = 'Y'

return

error:
    select @errmsg = @errmsg +  ' - unable to delete CM Acct!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
    
    
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btCMACi] on [dbo].[bCMAC] for INSERT as
/*-----------------------------------------------------------------
* Created: ??
* Modified: MH 3/15/03 - #23061
(			GG 04/18/07 - #30116 - data security
			AR 12/6/2010  - #142311 - adding foreign keys, removing trigger look ups
*
*	This trigger rejects insertion in bCMAC (CM Acct) if any of
*	the following error conditions exist:
*		Invalid CM Company
*		GL Company in CMAC does not match one in CMCO
*		Invalid GL Account
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* check that GL Company matches entry in CM Company 
- #142311 - commenting out key
select @validcnt = count(*) from dbo.bCMCO c (nolock)
join inserted i on c.CMCo = i.CMCo and c.GLCo = i.GLCo

if @validcnt <> @numrows
	begin
	select @errmsg = 'GL Company does not match the one assigned in CM Company'
	goto error
	end	   */
/* validate GL Acct - must be Active, not a Memo or Heading Account, and Sub Ledger type C or null */
select @validcnt = count(*) from dbo.bGLAC g (nolock)
join inserted i on g.GLCo = i.GLCo and g.GLAcct = i.GLAcct
where g.Active = 'Y' and (g.AcctType <> 'M' and g.AcctType <> 'H') and (g.SubType = 'C' or g.SubType is null)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GL Acct for this CM Co'
	goto error
	end

/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bCMAC',  'CM Acct: ' + convert(varchar(4), isnull(i.CMAcct, '')), i.CMCo, 'A',
	null, null, null, getdate(), SUSER_SNAME()
from inserted i join dbo.bCMCO c (nolock) on i.CMCo = c.CMCo
where c.AuditAccts = 'Y'

--#30116 - initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bCMAcct' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bCMAcct', i.CMCo, i.CMAcct, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bCMAcct' and s.Qualifier = i.CMCo 
						and s.Instance = convert(char(30),i.CMAcct) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = @errmsg + ' - cannot insert CM Account!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btCMACu    Script Date: 8/28/99 9:37:04 AM ******/
   CREATE trigger [dbo].[btCMACu] on [dbo].[bCMAC] for UPDATE as
   

/*-----------------------------------------------------------------
	*	Modified by:	MV 08/26/08 - #126266 - audit changes to Australian EFT fields
	*					MV 01/15/09 - #127222 - audit changes to Canadian EFT fields
	*					DAN SO 08/26/09 - #135071 - audit Discretionary field
	*					MV 01/06/11 - #142768 - audit CA Sort Name and Long Name
	*					EN 2/17/2011 #143236  Audit CAEFTFormat (Canada EFT Format) field
	*					AR 12/6/2010  - #142311 - adding foreign keys, removing trigger look ups
	*					MV 07/24/11 - #144182 - audit CARBCFileDescriptor
    *	This trigger rejects update in bCMAC (CM Accounts) if any of the
    *	following error conditions exist:
    *
    *		Cannot change CM Company
    *		Cannot change CM Account
    *		Invalid GL Account
    *
    *	Adds old and updated values to HQ Master Audit where applicable.
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   /* check for primary key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.CMCo = i.CMCo and d.CMAcct = i.CMAcct
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change CM Co or CM Acct'
   	goto error
   	end
   /* check that GL Company matches entry in CM Company 
   select @validcnt = count(*) from bCMCO c, inserted i where c.CMCo = i.CMCo
   	and c.GLCo = i.GLCo
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'GL Co not setup for CM Co'
   	goto error
   	end			   
   	*/
   /* validate GL Acct - must be Active, not a Memo or Heading Account, and Sub Ledger type C or null */
   select @validcnt = count(*) from bGLAC g, inserted i where g.GLCo = i.GLCo and g.GLAcct = i.GLAcct
   	and g.Active = 'Y' and (g.AcctType <> 'M' and g.AcctType <> 'H') and (g.SubType = 'C' or g.SubType is null)
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid GL Acct for this CM Co'
   	goto error
   	end
   /* check for HQ Master Audit */
   if not exists(select * from bCMCO c, inserted i	where c.CMCo = i.CMCo and c.AuditAccts = 'Y') return
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),i.CMAcct), i.CMCo, 'C',
   	'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.Description <> d.Description
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'GL Company', convert(varchar(3),d.GLCo), convert(varchar(3),i.GLCo), getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.GLCo <> d.GLCo
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'GL Account', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.GLAcct <> d.GLAcct
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Bank Account', d.BankAcct, i.BankAcct, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.BankAcct <> d.BankAcct
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Immediate Destination', d.ImmedDest, i.ImmedDest, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.ImmedDest <> d.ImmedDest
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Immediate Origin', d.ImmedOrig, i.ImmedOrig, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.ImmedOrig <> d.ImmedOrig
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Company ID', d.CompanyId, i.CompanyId, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CompanyId <> d.CompanyId
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Bank Name', d.BankName, i.BankName, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.BankName <> d.BankName
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'DFI', d.DFI, i.DFI, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.DFI <> d.DFI
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Routing/Transit#', d.RoutingId, i.RoutingId, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.RoutingId <> d.RoutingId
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Service Class', d.ServiceClass, i.ServiceClass, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.ServiceClass <> d.ServiceClass
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Account Type', d.AcctType, i.AcctType, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AcctType <> d.AcctType

-- #135071 --
   insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'Company Discretionary', d.Discretionary, i.Discretionary, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.Discretionary <> d.Discretionary


insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUAccountName', d.AUAccountName, i.AUAccountName, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUAccountName <> d.AUAccountName

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUBSB', d.AUBSB, i.AUBSB, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUBSB <> d.AUBSB

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUBankShortName', d.AUBankShortName, i.AUBankShortName, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUBankShortName <> d.AUBankShortName

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUCustomerNumber', d.AUCustomerNumber, i.AUCustomerNumber, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUCustomerNumber <> d.AUCustomerNumber

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUReference', d.AUReference, i.AUReference, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUReference <> d.AUReference

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'AUContraRequiredYN', d.AUContraRequiredYN, i.AUContraRequiredYN, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.AUContraRequiredYN <> d.AUContraRequiredYN

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CAOriginatorId', d.CAOriginatorId, i.CAOriginatorId, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CAOriginatorId <> d.CAOriginatorId

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CADestDataCentre', d.CADestDataCentre, i.CADestDataCentre, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CADestDataCentre <> d.CADestDataCentre

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CACurrencyCode', d.CACurrencyCode, i.CACurrencyCode, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CACurrencyCode <> d.CACurrencyCode

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CACMRoutingNbr', d.CACMRoutingNbr, i.CACMRoutingNbr, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CACMRoutingNbr <> d.CACMRoutingNbr

insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CAShortName', d.CAShortName, i.CAShortName, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CAShortName <> d.CAShortName
   	
insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CALongName', d.CALongName, i.CALongName, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CALongName <> d.CALongName
   	
insert into bHQMA select  'bCMAC', 'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), i.CMCo, 'C',
   	'CARBCFileDescriptor', d.CARBCFileDescriptor, i.CARBCFileDescriptor, getdate(), SUSER_SNAME()
   	from inserted i, deleted d, bCMCO c
   	where i.CMCo = c.CMCo and c.AuditAccts = 'Y'
   	and i.CMCo = d.CMCo and i.CMAcct = d.CMAcct and i.CARBCFileDescriptor <> d.CARBCFileDescriptor

INSERT INTO bHQMA 
SELECT	'bCMAC', 
		'CM Acct: ' + convert(varchar(4),isnull(i.CMAcct, '')), 
		i.CMCo, 
		'C',
   		'CAEFTFormat', 
		d.CAEFTFormat, 
		i.CAEFTFormat, 
		GETDATE(), 
		SUSER_SNAME()
FROM inserted i
JOIN deleted d ON i.CMCo = d.CMCo AND i.CMAcct = d.CMAcct
JOIN bCMCO c ON i.CMCo = c.CMCo
WHERE i.CAEFTFormat <> d.CAEFTFormat 
	  AND c.AuditAccts = 'Y'

   	
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update CM Acct!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
ALTER TABLE [dbo].[bCMAC] ADD CONSTRAINT [PK_bCMAC_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biCMAC] ON [dbo].[bCMAC] ([CMCo], [CMAcct]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bCMAC] WITH NOCHECK ADD CONSTRAINT [FK_bCMAC_bCMCO_CMCo] FOREIGN KEY ([CMCo]) REFERENCES [dbo].[bCMCO] ([CMCo])
GO
EXEC sp_bindrule N'[dbo].[brCMAcct]', N'[dbo].[bCMAC].[CMAcct]'
GO
