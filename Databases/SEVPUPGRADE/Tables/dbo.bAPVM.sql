CREATE TABLE [dbo].[bAPVM]
(
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Vendor] [dbo].[bVendor] NOT NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Type] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[TempYN] [dbo].[bYN] NOT NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[URL] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[POAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[POCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[POState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[POZip] [dbo].[bZip] NULL,
[POAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Purge] [dbo].[bYN] NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[V1099YN] [dbo].[bYN] NOT NULL,
[V1099Type] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[V1099Box] [tinyint] NULL,
[TaxId] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[Prop] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ActiveYN] [dbo].[bYN] NOT NULL,
[EFT] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RoutingId] [varchar] (34) COLLATE Latin1_General_BIN NULL,
[BankAcct] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[AcctType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[LastInvDate] [dbo].[bDate] NULL,
[AuditYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[AddnlInfo] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AddendaTypeId] [tinyint] NULL,
[Reviewer] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[SeparatePayInvYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_SeparatePayInvYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[OverrideMinAmtYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_OverrideMinAmtYN] DEFAULT ('N'),
[MasterVendor] [dbo].[bVendor] NULL,
[APRefUnqOvr] [tinyint] NOT NULL CONSTRAINT [DF_bAPVM_APRefUnqOvr] DEFAULT ((0)),
[ICFirstName] [varchar] (28) COLLATE Latin1_General_BIN NULL,
[ICMInitial] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[ICLastName] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[ICSocSecNbr] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[ICStreetNbr] [varchar] (5) COLLATE Latin1_General_BIN NULL,
[ICStreetName] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[ICAptNbr] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ICCity] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[ICState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ICZip] [dbo].[bZip] NULL,
[ICLastRptDate] [dbo].[bDate] NULL,
[UpdatePMYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_UpdatePMYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AddRevToAllLinesYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_AddRevToAllLinesYN] DEFAULT ('N'),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[POCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ICCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[AUVendorEFTYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_AUVendorEFTYN] DEFAULT ('N'),
[AUVendorAccountNumber] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[AUVendorBSB] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[AUVendorReference] [varchar] (18) COLLATE Latin1_General_BIN NULL,
[IATYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_IATYN] DEFAULT ('N'),
[ISODestinationCountryCode] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[RDFIBankName] [varchar] (35) COLLATE Latin1_General_BIN NULL,
[BranchCountryCode] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[RDFIIdentNbrQualifier] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[GatewayOperatorRDFIIdent] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[CMAcct] [dbo].[bCMAcct] NULL,
[PayInfoDelivMthd] [char] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bAPVM_PayInfoDelivMthd] DEFAULT ('N'),
[T5FirstName] [varchar] (12) COLLATE Latin1_General_BIN NULL,
[T5MiddleInit] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[T5LastName] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[T5SocInsNbr] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[T5BusinessNbr] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[T5BusTypeCode] [char] (1) COLLATE Latin1_General_BIN NULL,
[T5PartnerFIN] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[AusBusNbr] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[AusCorpNbr] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PayControl] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CASubjToWC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_CASubjToWC] DEFAULT ('N'),
[CAClearanceCert] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CACertEffectiveDate] [dbo].[bDate] NULL,
[V1099AddressSeq] [tinyint] NULL,
[PayMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bAPVM_PayMethod] DEFAULT ('C'),
[SubjToOnCostYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bAPVM_SubjToOnCostYN] DEFAULT ('N'),
[CSEmail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[OnCostCostType] [dbo].[bJCCType] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udSubcontractorYN] [dbo].[bYN] NULL,
[udEntityType] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCVendor] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udEmployee] [dbo].[bEmployee] NULL,
[udPRCo] [dbo].[bCompany] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger dbo.btAPVMd    Script Date: 8/28/99 9:37:00 AM ******/
   CREATE     trigger [dbo].[btAPVMd] on [dbo].[bAPVM] for DELETE as
   

/*-----------------------------------------------------------------
    * Created: ???
    * Modified: GG 07/26/99 - Changed bAPPH check for Temporary Vendors
    *          GG 07/30/99 - Fixed to add only one row to bHQMA
    *		   MV 11/04/02 - added check for existing additional addresses
    *			MV 07/26/05 - #29253 - check for existing Unapproved Invoices for this vendor.
	*			MV 09/08/08 - #122196 - check for Supplier in APTL,APUL and APRL
	*			JVH 01/30/09 - Check for existing vPCQualifications for this vendor
    *
    *	This trigger restricts deletion of any APVM records if
    *	entries exist in APFT, APTH, APVA, APVC, APVH, APRH,
    *	APPH, POHD, SLHD or vPCQualifications.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   
   set nocount on
   
   if exists(select top 1 1 from bAPFT a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='AP 1099 Totals exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPTH a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='AP Transaction(s) exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPVA a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='AP Monthly Vendor Activity totals exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPVC a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Vendor Compliance entries exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPVH a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Vendor Hold Code(s) exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPRH a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='AP Recurring Invoice(s) exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPPH a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor
               and d.TempYN = 'N')
   	begin
   	select @errmsg='AP Payment History exists'
   	goto error
   	end
   if exists(select top 1 1 from bPOHD a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Purchase Order(s) exist'
   	goto error
   	end
   if exists(select top 1 1 from bSLHD a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Subcontract(s) exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPAA a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Additional Address entries exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPUI a join deleted d on a.VendorGroup=d.VendorGroup and a.Vendor=d.Vendor)
   	begin
   	select @errmsg='Unapproved Invoice entries exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPTL a join deleted d on a.VendorGroup=d.VendorGroup and a.Supplier=d.Vendor)
   	begin
   	select @errmsg='AP Transaction(s) Supplier entries exist'
   	goto error
   	end
   if exists(select top 1 1 from bAPRL a join deleted d on a.VendorGroup=d.VendorGroup and a.Supplier=d.Vendor)
   	begin
   	select @errmsg='AP Recurring Invoice(s) Supplier entries exist'
   	goto error
   	end
  if exists(select top 1 1 from bAPUL a join deleted d on a.VendorGroup=d.VendorGroup and a.Supplier=d.Vendor)
   	begin
   	select @errmsg='Unapproved Invoice Supplier entries exist'
   	goto error
   	end
  if exists(select top 1 1 from vPCQualifications a join deleted d on a.APVMKeyID=d.KeyID)
   	begin
   	select @errmsg='PC Qualification entries exist'
   	goto error
   	end
	
   
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT distinct 'bAPVM','Vendor Group: ' + convert(char(3), d.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6),d.Vendor), d.VendorGroup, 'D',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM deleted d
           join bHQCO h on h.VendorGroup = d.VendorGroup
           join bAPCO a on a.APCo = h.HQCo
           where a.AuditVendors = 'Y'
   return
   error:
   	select @errmsg = @errmsg + ' - cannot delete AP Vendor!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPVMi] on [dbo].[bAPVM] for INSERT as
/*-----------------------------------------------------------------
*  Created: GG 02/27/98
*  Modified: kb 8/7/98
*          GG 07/30/99 - Fixed to add only one row to bHQMA
*			MV 06/24/03 - #21583 make sortname uppercase
*			MV 03/11/08	- #127347 International addresses
*			CC 05/07/08 - #128132 Change Contry/State validation to allow State or Country, or State and Country
*			GG 10/08/08 - #130130 - fix State validation
*		TJL 02/04/09 - Issue #124739, Add CMAcct in APVM as default
*			EN 12/20/2011 TK-10795 add validation for new PayMethod field
*
* Validates Vendor Group, Type, State, PO State, Customer, Tax Code,
* Payment Terms, GL Company and Account, PayMethod, 1099 Type and Box # and EFT.
* If any AP Co# using this Vendor Master is  flagged for auditing,
* inserts HQ Master Audit entry .
*/----------------------------------------------------------------
   declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,	@validcnt2 int
   
SELECT @numrows = @@rowcount
IF @numrows = 0 return

SET nocount on

/* validate AP Vendor Group */
SELECT @validcnt = count(*) FROM bHQGP g with (nolock)
      JOIN inserted i with (nolock) ON i.VendorGroup = g.Grp
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Vendor Group '
	GOTO error
	END
/* validate Vendor Type */
select @validcnt = count(*) from inserted with (nolock)
   where Type in ('R','S')
IF @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Vendor Type - must be (R) or (S)'
	GOTO error
	END
  
/* validate Customer */
select @nullcnt = count(*) from inserted with (nolock) where Customer is null
select @validcnt = count(*) from inserted i with (nolock)
   join bARCM c with (nolock) on c.CustGroup = i.CustGroup and c.Customer = i.Customer
IF @nullcnt + @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Customer'
	GOTO error
	END
/* validate Tax Code */
select @nullcnt = count(*) from inserted with (nolock) where TaxCode is null
select @validcnt = count(*) from inserted i with (nolock)
   join bHQTX t with (nolock) on t.TaxGroup = i.TaxGroup and t.TaxCode = i.TaxCode
IF @nullcnt + @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Tax Code'
	GOTO error
	END
/* validate Payment Terms */
select @nullcnt = count(*) from inserted with (nolock) where PayTerms is null
select @validcnt = count(*) from inserted i with (nolock)
   join bHQPT p with (nolock) on p.PayTerms = i.PayTerms
IF @nullcnt + @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid Payment Terms'
	GOTO error
	END
/* validate GL Account  */
select @nullcnt = count(*) from inserted with (nolock) where GLAcct is null
SELECT @validcnt = count(*)
FROM bGLAC a with (nolock)
JOIN inserted i with (nolock) ON a.GLCo = i.GLCo and a.GLAcct = i.GLAcct
   where a.Active = 'Y' and a.AcctType <> 'H' and a.AcctType <> 'M'
   	and (a.SubType = 'P' or a.SubType is null)
IF @nullcnt + @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid GL Account: '
	GOTO error
	END
-- validate CM Account - Only one needs to exist in any CMCo
if update(CMAcct)
	begin
	select @nullcnt = count(*) from inserted where CMAcct is null
	select @validcnt = count(distinct(c.CMAcct))from bCMAC c
	join inserted i on c.CMAcct = i.CMAcct
	if @nullcnt + @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid CM Account - CM Account does not exist in any CM Company'
		goto error
		end
	end
/* validate 1099 Types */
select @nullcnt = count(*) from inserted with (nolock) where V1099Type is null
select @validcnt = count(*) from inserted i with (nolock)
   join bAPTT t with (nolock) on t.V1099Type = i.V1099Type
IF @nullcnt + @validcnt <> @numrows
	BEGIN
	SELECT @errmsg = 'Invalid 1099 Type'
	GOTO error
	END
/* validate 1099 Box # */
if exists(select 1 from inserted with (nolock) where V1099Box is not null and (V1099Box < 1 or V1099Box > 18))
   begin
   select @errmsg = 'Invalid 1099 Box #'
   goto error
   end
/* validate EFT */
if exists(select 1 from inserted with (nolock) where EFT not in ('A','N','P'))
   begin
   select @errmsg = 'Invalid EFT type'
   goto error
   end

/* Validate Country */
select @validcnt = count(1) 
from dbo.bHQCountry c with (nolock) 
join inserted i on i.Country=c.Country
select @nullcnt = count(1) from inserted where Country is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end
-- validate State - all State values must exist in bHQST
if exists(select top 1 1 from inserted i where [State] not in(select [State] from dbo.bHQST))
	begin
	select @errmsg = 'Invalid State'
	goto error
	end
-- validate Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from dbo.bHQST (nolock) s
join inserted i on i.Country = s.Country and i.State = s.State
select @nullcnt = count(1) from inserted where Country is null or State is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country and State combination'
	goto error
	end

/* Validate POCountry */
select @validcnt = count(1) 
from dbo.bHQCountry c with (nolock) 
join inserted i on i.POCountry=c.Country
select @nullcnt = count(1) from inserted where POCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid PO Country'
	goto error
	end
-- validate PO State - all State values must exist in bHQST
if exists(select top 1 1 from inserted i where POState not in(select [State] from dbo.bHQST))
	begin
	select @errmsg = 'Invalid PO State'
	goto error
	end
-- validate PO Country / PO State combinations
select @validcnt = count(1) -- Country/State combos are unique
from dbo.bHQST (nolock) s
join inserted i on i.POCountry = s.Country and i.POState = s.State
select @nullcnt = count(1) from inserted where POCountry is null or POState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid PO Country and State combination'
	goto error
	end

-- validate PayMethod
SELECT @validcnt = count(*) FROM inserted WHERE PayMethod = 'C' or PayMethod = 'E' or PayMethod = 'S'
IF @validcnt <> @numrows
BEGIN
	SELECT @errmsg = 'Invalid payment method'
	GOTO error
END
   


   /* convert lower case Sortname to upper case */
   update APVM set SortName = Upper (i.SortName) from inserted i 
   	join APVM v on i.VendorGroup= v.VendorGroup and i.Vendor=v.Vendor  
   
   /* Audit inserts */
   INSERT INTO bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT distinct 'bAPVM','Vendor Group: ' + convert(char(3), i.VendorGroup)
   		 + ' Vendor: ' + convert(varchar(6),i.Vendor), i.VendorGroup, 'A',
   		NULL, NULL, NULL, getdate(), SUSER_SNAME() FROM inserted i
           join bHQCO h on h.VendorGroup = i.VendorGroup
           join bAPCO a on a.APCo = h.HQCo
           where a.AuditVendors = 'Y'
   return
   
error:
	SELECT @errmsg = @errmsg +  ' - cannot insert AP Vendor!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btAPVMu] on [dbo].[bAPVM] for UPDATE as
/*-----------------------------------------------------------------
* Created: EN 7/31/98
* Modified: GG 10/13/98
*			JC 12/6/99 --changed the validation of vendor group from a 'count' to a 'if update'.
*           GG 01/13/00 - changed validation on GL Account
*			GH 1/17/02 - Issue #15944 changed box # validation to allow boxes 1-18
*		 	EN 1/29/02 - #16088 - fixed audit code for all non-null fields to write to HQMA if field is changed to or from null
*			EN 1/29/02 - #16088 - added audit code for AddnlInfo which I added awhile back
*			MV 1/29/02 - Added audit code for AddendaTypeId.
*           TV 1/30/02 - Added audit code for Reviewer
*           kb 2/12/2 - issue #16252
*			MV 08/05/02 - Added audit code for MasterVendor, APRefUnqOvr
*			MV 03/18/03 - #17124 added missing fields to audit
*			GF 08/12/2003 - issue #22112 - performance
*			MV 06/21/05 - #28465 6X conversion of AP to PM update
*			MV 11/11/05 - #30335 add space to audit key string between vendorgroup and vendor
*			MV 03/11/08 - #127347 International addresses/AP to PM update/auditing
*			CC 05/07/08 - #128132 Change Contry/State validation to allow State or Country, or State and Country
*			MV 08/26/08 - #127266 - audit changes to Australian EFT fields
*			GG 10/08/08 - #130130 - fix State validation
*		TJL 02/04/09 - Issue #124739, Add CMAcct in APVM as default
*			MV 02/25/09 - #129891 HQMA audit for new field 'PayInfoDelivMtd'
*			MV 19/12/11 - TK-08960 - add V1099AddressSeq to HQMA audit
*			EN 12/20/2011 TK-10795 add validation and HQMA audit for new PayMethod field
*			MV 01/10/2012 TK11518 add audit for SubjToOnCostYN
*			CHS	04/04/2012	B-09267 added OnCostCostType column
*				
* Validates Vendor Group, Type, State, PO State, Customer, Tax Code,
* Payment Terms, GL Company and Account, PayMethod, 1099 Type and Box # and EFT.
* If any AP Co# using this Vendor Master is  flagged for auditing,
* inserts HQ Master Audit entry .
*/----------------------------------------------------------------
 declare @errmsg varchar(255), @validcnt int, @numrows int, @nullcnt int,
	@validcnt2 int
 
 SELECT @numrows = @@rowcount
 IF @numrows = 0 return
 SET nocount on
 

 -- check for key changes
 if Update(VendorGroup)
   	begin
   	select @errmsg = 'Cannot change Vendor Group'
   	goto error
   	end
 if Update(Vendor)
   	begin
   	select @errmsg = 'Cannot change Vendor'
   	goto error
   	end
 
 -- validate AP Vendor Group
-- SELECT @validcnt = count(*) FROM bHQGP g with (nolock) JOIN inserted i ON i.VendorGroup = g.Grp
-- IF @validcnt <> @numrows
-- 	BEGIN
-- 	SELECT @errmsg = 'Invalid Vendor Group'
-- 	GOTO error
-- 	END
 
 -- validate Vendor Type
if update ([Type])
	begin
	select @validcnt = count(*) from inserted where [Type] in ('R','S')
	IF @validcnt <> @numrows
 		BEGIN
 		SELECT @errmsg = 'Invalid Vendor Type - must be (R) or (S)'
 		GOTO error
 		end
 	end
 
if update(Country)
	begin
	-- validate Country
	select @validcnt = count(1) from dbo.bHQCountry c (nolock) 
	join inserted i on i.Country = c.Country
	select @nullcnt = count(1) from inserted where Country is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country'
		goto error
		end
	end
if update(State)
	begin
	-- validate State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where [State] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid State'
		goto error
		end
	end
if update(Country) or update(State)
	begin
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from dbo.bHQST (nolock) s
	join inserted i on i.Country = s.Country and i.State = s.State
	select @nullcnt = count(1) from inserted where Country is null or State is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Country and State combination'
		goto error
		end
	end
if update(POCountry)
	begin
	-- validate Country
	select @validcnt = count(1) from dbo.bHQCountry c (nolock) 
	join inserted i on i.POCountry = c.Country
	select @nullcnt = count(1) from inserted where POCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid PO Country'
		goto error
		end
	end
if update(POState)
	begin
	-- validate State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where [POState] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid PO State'
		goto error
		end
	end
if update(POCountry) or update(POState)
	begin
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from dbo.bHQST (nolock) s
	join inserted i on i.POCountry = s.Country and i.POState = s.State
	select @nullcnt = count(1) from inserted where POCountry is null or POState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid PO Country and State combination'
		goto error
		end
	end
if update(ICCountry)
	begin
	-- validate Country
	select @validcnt = count(1) from dbo.bHQCountry c (nolock) 
	join inserted i on i.ICCountry = c.Country
	select @nullcnt = count(1) from inserted where ICCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid IC Country'
		goto error
		end
	end
if update(ICState)
	begin
	-- validate State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where [ICState] not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid IC State'
		goto error
		end
	end
if update(ICCountry) or update(ICState)
	begin
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from dbo.bHQST (nolock) s
	join inserted i on i.ICCountry = s.Country and i.ICState = s.State
	select @nullcnt = count(1) from inserted where ICCountry is null or ICState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid IC Country and State combination'
		goto error
		end
	end
	
 -- validate Customer
 if update(Customer)
     begin
     select @nullcnt = count(*) from inserted where Customer is null
     select @validcnt = count(*) from inserted i
     join bARCM c with (nolock) on c.CustGroup = i.CustGroup and c.Customer = i.Customer
     IF @nullcnt + @validcnt <> @numrows
 	   BEGIN
 	   SELECT @errmsg = 'Invalid Customer'
 	   GOTO error
 	   END
     end
 
 -- validate Tax Code
 if update(TaxCode)
     begin
     select @nullcnt = count(*) from inserted where TaxCode is null
     select @validcnt = count(*) from inserted i
 	join bHQTX t with (nolock) on t.TaxGroup = i.TaxGroup and t.TaxCode = i.TaxCode
     IF @nullcnt + @validcnt <> @numrows
 	   BEGIN
 	   SELECT @errmsg = 'Invalid Tax Code'
 	   GOTO error
 	   END
     end
 
 -- validate Payment Terms
 if update(PayTerms)
     begin
     select @nullcnt = count(*) from inserted where PayTerms is null
     select @validcnt = count(*) from inserted i join bHQPT p with (nolock) on p.PayTerms = i.PayTerms
     IF @nullcnt + @validcnt <> @numrows
 	   BEGIN
 	   SELECT @errmsg = 'Invalid Payment Terms'
 	   GOTO error
 	   END
     end
 
 -- validate GL Account
 if update(GLAcct) or update(GLCo)
     begin
     select @nullcnt = count(*) from inserted where GLAcct is null
     select @validcnt = count(*) FROM bGLAC a with (nolock) 
 	JOIN inserted i ON a.GLCo = i.GLCo and a.GLAcct = i.GLAcct
 	where a.Active = 'Y' and a.AcctType <> 'H' and a.AcctType <> 'M'
 	and (a.SubType = 'P' or a.SubType is null)
     IF @nullcnt + @validcnt <> @numrows
 	   BEGIN
 	   SELECT @errmsg = 'Invalid GL Account'
 	   GOTO error
 	   END
    end

-- validate CM Account - Only one needs to exist in any CMCo
if update(CMAcct)
	begin
	select @nullcnt = count(*) from inserted where CMAcct is null
	select @validcnt = count(distinct(c.CMAcct))from bCMAC c
	join inserted i on c.CMAcct = i.CMAcct
	if @nullcnt + @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid CM Account - CM Account does not exist in any CM Company'
		goto error
		end
	end

 -- validate 1099 Types
 if update(V1099Type)
     begin
     select @nullcnt = count(*) from inserted where V1099Type is null
     select @validcnt = count(*) from inserted i join bAPTT t with (nolock) on t.V1099Type = i.V1099Type
     IF @nullcnt + @validcnt <> @numrows
 	   BEGIN
 	   SELECT @errmsg = 'Invalid 1099 Type'
 	   GOTO error
 	   END
     end
 
 -- validate 1099 Box #
 if update(V1099Box)
     begin
     if exists(select * from inserted where V1099Box is not null and (V1099Box < 1 or V1099Box > 18))
         begin
         select @errmsg = 'Invalid 1099 Box #'
         goto error
         end
    end

 -- validate PayMethod
 IF UPDATE(PayMethod)
 BEGIN
	SELECT @validcnt = COUNT(*) FROM inserted WHERE PayMethod = 'C' OR PayMethod = 'E' OR PayMethod = 'S'
	IF @validcnt <> @numrows
	BEGIN
		SELECT @errmsg = 'Invalid payment method'
		GOTO error
	END
 END
   
 
-- -- -- #28465 now update bPMFM when UpdatePM flag is 'Y'. Columns to update:
if not exists(select top 1 1 from inserted i where i.UpdatePMYN = 'Y') goto PMUpdate_End

-- -- --  name - firm name
update bPMFM set FirmName = i.Name
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Name,'') <> isnull(d.Name,'')
and (v.FirmName is null or (isnull(v.FirmName,'') = isnull(d.Name,'')))
-- -- -- contact  - contact name
update bPMFM set ContactName = i.Contact
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Contact,'') <> isnull(d.Contact,'')
and (v.ContactName is null or (isnull(v.ContactName,'') = isnull(d.Contact,'')))
-- -- -- phone
update bPMFM set Phone = i.Phone
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Phone,'') <> isnull(d.Phone,'')
and (v.Phone is null or (isnull(v.Phone,'') = isnull(d.Phone,'')))
-- -- -- fax
update bPMFM set Fax = i.Fax
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Fax,'') <> isnull(d.Fax,'')
and (v.Fax is null or (isnull(v.Fax,'') = isnull(d.Fax,'')))
-- -- -- email
update bPMFM set EMail = i.EMail
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.EMail,'') <> isnull(d.EMail,'')
and (v.EMail is null or (isnull(v.EMail,'') = isnull(d.EMail,'')))
-- -- -- URL
update bPMFM set URL = i.URL
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.URL,'') <> isnull(d.URL,'')
and (v.URL is null or (isnull(v.URL,'') = isnull(d.URL,'')))
-- -- -- address - mail address
update bPMFM set MailAddress = i.Address
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Address,'') <> isnull(d.Address,'')
and (v.MailAddress is null or (isnull(v.MailAddress,'') = isnull(d.Address,'')))
-- -- -- address2 - mail address2
update bPMFM set MailAddress2 = i.Address2
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Address2,'') <> isnull(d.Address2,'')
and (v.MailAddress2 is null or (isnull(v.MailAddress2,'') = isnull(d.Address2,'')))
-- -- --  city - mail city
update bPMFM set MailCity = i.City
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.City,'') <> isnull(d.City,'')
and (v.MailCity is null or (isnull(v.MailCity,'') = isnull(d.City,'')))
-- -- --  state - mail state
update bPMFM set MailState = i.State
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.State,'') <> isnull(d.State,'')
and (v.MailState is null or (isnull(v.MailState,'') = isnull(d.State,'')))
-- -- -- zip - mail zip
update bPMFM set MailZip = i.Zip
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Zip,'') <> isnull(d.Zip,'')
and (v.MailZip is null or (isnull(v.MailZip,'') = isnull(d.Zip,'')))
-- -- -- Country - mail country
update bPMFM set MailCountry = i.Country
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.Country,'') <> isnull(d.Country,'')
and (v.MailCountry is null or (isnull(v.MailCountry,'') = isnull(d.Country,'')))
-- -- -- PO address - ship address
update bPMFM set ShipAddress = i.POAddress
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POAddress,'') <> isnull(d.POAddress,'')
and (v.ShipAddress is null or (isnull(v.ShipAddress,'') = isnull(d.POAddress,'')))
-- -- -- POAddress2 - ShipAddress2
update bPMFM set ShipAddress2 = i.POAddress2
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POAddress2,'') <> isnull(d.POAddress2,'')
and (v.ShipAddress2 is null or (isnull(v.ShipAddress2,'') = isnull(d.POAddress2,'')))
-- -- -- ShipCity - POCity
update bPMFM set ShipCity = i.POCity
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POCity,'') <> isnull(d.POCity,'')
and (v.ShipCity is null or (isnull(v.ShipCity,'') = isnull(d.POCity,'')))
-- -- -- ShipState - POState
update bPMFM set ShipState = i.POState
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POState,'') <> isnull(d.POState,'')
and (v.ShipState is null or (isnull(v.ShipState,'') = isnull(d.POState,'')))
-- -- -- ShipZip - POZip
update bPMFM set ShipZip = i.POZip
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POZip,'') <> isnull(d.POZip,'')
and (v.ShipZip is null or (isnull(v.ShipZip,'') = isnull(d.POZip,'')))
-- -- -- ShipCountry - POCountry
update bPMFM set ShipCountry = i.POCountry
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.POCountry,'') <> isnull(d.POCountry,'')
and (v.ShipCountry is null or (isnull(v.ShipCountry,'') = isnull(d.POCountry,'')))
-- -- -- sort name
update bPMFM set SortName = i.SortName
from inserted i join deleted d on i.VendorGroup=d.VendorGroup 
join bPMFM v on v.VendorGroup=i.VendorGroup and v.Vendor=i.Vendor
where i.UpdatePMYN = 'Y' and isnull(i.SortName,'') <> isnull(d.SortName,'')
and (v.SortName is null or (isnull(v.SortName,'') = isnull(d.SortName,'')))

-- -- -- last set the APVM.UpdatePMYN flag to 'N'
 update bAPVM set UpdatePMYN = 'N'
 from inserted i where i.UpdatePMYN = 'Y'
 
PMUpdate_End:
 
-- HQ Audits for changed Vendor values
if update(SortName)
	begin
  	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'SortName', d.SortName, i.SortName, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.SortName <> d.SortName and i.AuditYN = 'Y' 
  		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Name)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'Name', d.Name, i.Name, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Name,'') <> isnull(d.Name,'') and i.AuditYN = 'Y'
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Type)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Type', d.Type, i.Type, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.Type <> d.Type and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(TempYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'TempYN', d.TempYN, i.TempYN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.TempYN <> d.TempYN and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Contact)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Contact', d.Contact, i.Contact, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Contact,'') <> isnull(d.Contact,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Phone)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'Phone', d.Phone, i.Phone, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Phone,'') <> isnull(d.Phone,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Fax)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Fax', d.Fax, i.Fax, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Fax,'') <> isnull(d.Fax,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(EMail)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'EMail', d.EMail, i.EMail, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.EMail,'') <> isnull(d.EMail,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(URL)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'URL', d.URL, i.URL, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.URL,'') <> isnull(d.URL,'') and i.AuditYN = 'Y'
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Address)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Address', d.Address, i.Address, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Address,'') <> isnull(d.Address,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(City)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'City', d.City, i.City, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.City,'') <> isnull(d.City,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(State)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'State', d.State, i.State, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.State,'') <> isnull(d.State,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Zip)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Zip', d.Zip, i.Zip, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Zip,'') <> isnull(d.Zip,'') and i.AuditYN = 'Y'
  		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Country)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Country', d.Country, i.Country, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Country,'') <> isnull(d.Country,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Address2)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Addl Address', d.Address2, i.Address2, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Address2,'') <> isnull(d.Address2,'') and i.AuditYN = 'Y'
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POAddress)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'POAddress', d.POAddress, i.POAddress, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POAddress,'') <> isnull(d.POAddress,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POCity)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'POCity', d.POCity, i.POCity, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POCity,'') <> isnull(d.POCity,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POState)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'POState', d.POState, i.POState, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POState,'') <> isnull(d.POState,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POZip)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'POZip', d.POZip, i.POZip, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POZip,'') <> isnull(d.POZip,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POCountry)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'POCountry', d.POCountry, i.POCountry, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POCountry,'') <> isnull(d.POCountry,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(POAddress2)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'Addl PO Address', d.POAddress2, i.POAddress2, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.POAddress2,'') <> isnull(d.POAddress2,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Purge)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'Purge', d.Purge, i.Purge, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.Purge <> d.Purge and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(CustGroup)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'CustGroup', d.CustGroup, i.CustGroup, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.CustGroup,'') <> isnull(d.CustGroup,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Customer)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'Customer', d.Customer, i.Customer, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Customer,'') <> isnull(d.Customer,'') and i.AuditYN = 'Y'
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(TaxGroup)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'TaxGroup', d.TaxGroup, i.TaxGroup, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.TaxGroup,'') <> isnull(d.TaxGroup,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(TaxCode)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.TaxCode,'') <> isnull(d.TaxCode,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(PayTerms)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'PayTerms', d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.PayTerms,'') <> isnull(d.PayTerms,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(GLCo)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'GLCo', d.GLCo, i.GLCo, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.GLCo <> d.GLCo and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(GLAcct)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'GLAcct', d.GLAcct, i.GLAcct, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.GLAcct,'') <> isnull(d.GLAcct,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(V1099YN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'V1099YN', d.V1099YN, i.V1099YN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.V1099YN <> d.V1099YN and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(V1099Type)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'V1099Type', d.V1099Type, i.V1099Type, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.V1099Type,'') <> isnull(d.V1099Type,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(V1099Box)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'V1099Box', d.V1099Box, i.V1099Box, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.V1099Box,'') <> isnull(d.V1099Box,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(TaxId)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'TaxId', d.TaxId, i.TaxId, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.TaxId,'') <> isnull(d.TaxId,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Prop)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Prop', d.Prop, i.Prop, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Prop,'') <> isnull(d.Prop,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(ActiveYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'ActiveYN', d.ActiveYN, i.ActiveYN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.ActiveYN <> d.ActiveYN and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(EFT)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'EFT', d.EFT, i.EFT, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.EFT <> d.EFT and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
 if update(RoutingId)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'RoutingId', d.RoutingId, i.RoutingId, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.RoutingId,'') <> isnull(d.RoutingId,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(BankAcct)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'BankAcct', d.BankAcct, i.BankAcct, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.BankAcct,'') <> isnull(d.BankAcct,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(AcctType)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AcctType', d.AcctType, i.AcctType, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AcctType,'') <> isnull(d.AcctType,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(LastInvDate)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'LastInvDate', d.LastInvDate, i.LastInvDate, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.LastInvDate,'') <> isnull(d.LastInvDate,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(AddnlInfo)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AddnlInfo', d.AddnlInfo, i.AddnlInfo, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AddnlInfo,'') <> isnull(d.AddnlInfo,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(AddendaTypeId)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AddendaTypeId', d.AddendaTypeId, i.AddendaTypeId, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
   	where isnull(i.AddendaTypeId,'') <> isnull(d.AddendaTypeId,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(Reviewer)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C', 'Reviewer', d.Reviewer, i.Reviewer, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.Reviewer,'') <> isnull(d.Reviewer,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(SeparatePayInvYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'SeparatePayInvYN', d.SeparatePayInvYN, i.SeparatePayInvYN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.SeparatePayInvYN <> d.SeparatePayInvYN and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(MasterVendor)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'MasterVendor', d.MasterVendor, i.MasterVendor, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.MasterVendor,'') <> isnull(d.MasterVendor,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(APRefUnqOvr)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'APRefUnqOvr', d.APRefUnqOvr, i.APRefUnqOvr, getdate(), SUSER_SNAME()
	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.APRefUnqOvr,'') <> isnull(d.APRefUnqOvr,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end
if update(OverrideMinAmtYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C', 'Include in 1099 Processing', d.OverrideMinAmtYN, i.OverrideMinAmtYN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where i.OverrideMinAmtYN <> d.OverrideMinAmtYN and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
  	end

if update(AUVendorEFTYN)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AUVendorEFTYN', d.AUVendorEFTYN, i.AUVendorEFTYN, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AUVendorEFTYN,'') <> isnull(d.AUVendorEFTYN,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end

if update(AUVendorBSB)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AUVendorBSB', d.AUVendorBSB, i.AUVendorBSB, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AUVendorBSB,'') <> isnull(d.AUVendorBSB,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end

if update(AUVendorAccountNumber)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AUVendorAccountNumber', d.AUVendorAccountNumber, i.AUVendorAccountNumber, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AUVendorAccountNumber,'') <> isnull(d.AUVendorAccountNumber,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end

if update(AUVendorReference)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'AUVendorReference', d.AUVendorReference, i.AUVendorReference, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.AUVendorReference,'') <> isnull(d.AUVendorReference,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end
 
if update(CMAcct)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'CMAcct', d.CMAcct, i.CMAcct, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.CMAcct,'') <> isnull(d.CMAcct,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end

if update(PayInfoDelivMthd)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'Payment Info Delivery Mthd', d.PayInfoDelivMthd, i.PayInfoDelivMthd, getdate(), SUSER_SNAME()
  	from inserted i
  	join deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	where isnull(i.PayInfoDelivMthd,'') <> isnull(d.PayInfoDelivMthd,'') and i.AuditYN = 'Y' 
		and exists(select top 1 1 from dbo.bHQCO h (nolock)
  					join dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  					where h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y')
	end
IF UPDATE(V1099Box)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
		i.VendorGroup, 'C',	'V1099AddressSeq', d.V1099AddressSeq, i.V1099AddressSeq, getdate(), SUSER_SNAME()
	FROM inserted i
  	JOIN deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	WHERE isnull(i.V1099AddressSeq,'') <> isnull(d.V1099AddressSeq,'') and i.AuditYN = 'Y' 
		AND EXISTS
			(
				SELECT top 1 1
				FROM dbo.bHQCO h (nolock)
  				JOIN dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  				WHERE h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y'
  			)
END
IF UPDATE(PayMethod)
BEGIN
	INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor), 
		i.VendorGroup, 'C', 'PayMethod', d.PayMethod, i.PayMethod, GETDATE(), SUSER_SNAME()
	FROM inserted i
	JOIN deleted d ON i.VendorGroup = d.VendorGroup AND i.Vendor = d.Vendor
  	WHERE isnull(i.PayMethod,'') <> isnull(d.PayMethod,'') and i.AuditYN = 'Y' 
		AND EXISTS
			(
				SELECT top 1 1
				FROM dbo.bHQCO h (nolock)
  				JOIN dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  				WHERE h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y'
  			)
END

IF
UPDATE(SubjToOnCostYN)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'SubjToOnCostYN', d.SubjToOnCostYN, i.SubjToOnCostYN, getdate(), SUSER_SNAME()
  	FROM inserted i
  	JOIN deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	WHERE isnull(i.SubjToOnCostYN,'') <> isnull(d.SubjToOnCostYN,'') and i.AuditYN = 'Y' 
		AND EXISTS	(
						SELECT top 1 1
						FROM dbo.bHQCO h (nolock)
  						JOIN dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  						WHERE h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y'
  					)
END  
					
  					
IF  					
UPDATE(OnCostCostType)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	SELECT 'bAPVM', 'Vendor Group: ' + convert(varchar,i.VendorGroup) + ' Vendor: ' + convert(varchar,i.Vendor),
  		i.VendorGroup, 'C',	'OnCostCostType', d.OnCostCostType, i.OnCostCostType, getdate(), SUSER_SNAME()
  	FROM inserted i
  	JOIN deleted d on i.VendorGroup = d.VendorGroup and i.Vendor = d.Vendor
  	WHERE isnull(i.OnCostCostType,'') <> isnull(d.OnCostCostType,'') and i.AuditYN = 'Y' 
		AND EXISTS	(
						SELECT top 1 1
						FROM dbo.bHQCO h (nolock)
  						JOIN dbo.bAPCO a (nolock) on a.APCo = h.HQCo  
  						WHERE h.VendorGroup = i.VendorGroup and a.AuditVendors = 'Y'
  					)   					
END



return
 
error:
 	SELECT @errmsg = @errmsg +  ' - cannot update AP Vendor!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bAPVM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biAPVMSortName] ON [dbo].[bAPVM] ([VendorGroup], [SortName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biAPVM] ON [dbo].[bAPVM] ([VendorGroup], [Vendor]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[TempYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[V1099YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[ActiveYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[SeparatePayInvYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[OverrideMinAmtYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bAPVM].[UpdatePMYN]'
GO
