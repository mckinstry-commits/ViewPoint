CREATE TABLE [dbo].[bARCM]
(
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[SortName] [dbo].[bSortName] NOT NULL,
[TempYN] [dbo].[bYN] NOT NULL,
[Phone] [dbo].[bPhone] NULL,
[Fax] [dbo].[bPhone] NULL,
[EMail] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[URL] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Contact] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ContactExt] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BillState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BillZip] [dbo].[bZip] NULL,
[BillAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[RecType] [tinyint] NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[CreditLimit] [dbo].[bDollar] NOT NULL,
[SelPurge] [dbo].[bYN] NOT NULL,
[StmntPrint] [dbo].[bYN] NOT NULL,
[StmtType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[FCType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[FCPct] [dbo].[bPct] NOT NULL,
[MarkupDiscPct] [dbo].[bRate] NOT NULL,
[DateOpened] [dbo].[bDate] NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[PriceTemplate] [smallint] NULL,
[DiscTemplate] [smallint] NULL,
[HaulTaxOpt] [tinyint] NOT NULL CONSTRAINT [DF_bARCM_HaulTaxOpt] DEFAULT ((0)),
[InvLvl] [tinyint] NOT NULL CONSTRAINT [DF_bARCM_InvLvl] DEFAULT ((0)),
[BillFreq] [dbo].[bFreq] NULL,
[MiscOnInv] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCM_MiscOnInv] DEFAULT ('N'),
[MiscOnPay] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCM_MiscOnPay] DEFAULT ('N'),
[PrintLvl] [tinyint] NOT NULL CONSTRAINT [DF_bARCM_PrintLvl] DEFAULT ((1)),
[SubtotalLvl] [tinyint] NOT NULL CONSTRAINT [DF_bARCM_SubtotalLvl] DEFAULT ((1)),
[SepHaul] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCM_SepHaul] DEFAULT ('Y'),
[ExclContFromFC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bARCM_ExclContFromFC] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[BillCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ABN] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ACN] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udCGCCustomer] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
 
 /****** Object:  Trigger dbo.btARCMd    Script Date: 8/28/99 9:37:01 AM ******/
  CREATE trigger [dbo].[btARCMd] on [dbo].[bARCM] for DELETE as
  

/*-----------------------------------------------------------------
   *	This trigger rejects delete in bARCM (AR Customer Master) if any of
   *	the following error condition exists:
   *      Modified : 09/13/01 danf xml export of deleted records
   *    	04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup.
   *                              - Added code for HQMA entry (issue # 16840).
   * 		07/12/02 CMW - Fixed multiple entry problem (issue # 17902).
   * 		08/12/02 CMW - Fixed string/integer problem (issue # 18249).
   *  	09/30/02 DANF - Added Document Exporting (14550)
   *		12/29/04 TJL - Issue #26303, Fixed multiple entry problem
   *		TJL  11/10/05 - Issue #30333, Minor change to Audit String 'Cust Group#:, Cust:'
   *		AR	11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
   *
   *		ARTH entry exists
   *		ARMT entry exists
   *		ARBA entry exists
   *		JCCM entry exists
   */----------------------------------------------------------------
  declare @errmsg varchar(255), @numrows int
  if @@rowcount = 0 return
  select @numrows = @@rowcount
  
  set nocount on
  /* check for corresponding entries in ARTH */
  if exists (select * from deleted d, bARTH g
  	where g.CustGroup = d.CustGroup and g.Customer = d.Customer)
  	begin
  	select @errmsg = 'Entries exist in AR Transaction Header'
  	goto error
  	end
  /* check for corresponding entries in ARMT */
  if exists (select * from deleted d, bARMT g
  	where g.CustGroup = d.CustGroup and g.Customer = d.Customer)
  	begin
  	select @errmsg = 'Entries exist in AR Monthly Totals'
  	goto error
  	end
  /* check for corresponding entries in ARBA */
  if exists (select * from deleted d, bARBA g
  	where g.CustGroup = d.CustGroup and g.Customer = d.Customer)
  	begin
  	select @errmsg = 'Entries exist in AR Batch Audit'
  	goto error
  	end
  /* check for corresponding entries in JCCM */
  if exists (select * from deleted d, bJCCM g
  	where g.CustGroup = d.CustGroup and g.Customer = d.Customer)
  	begin
  	select @errmsg = 'Entries exist in JC Contract Master'
  	goto error
  	end
  
  /* Document exporting */
  declare @custgroup tinyint, @opencursor int, @customer int, @rcode int,
  		@stdxmlformat bYN, @userstoredrroc varchar(30), @hqco bCompany, @hqdxcursor int,
  		@sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)
  
  if exists (select top 1 i.CustGroup
  			from bARCM i 
  			join bHQCO c on i.CustGroup = c.CustGroup
  			where exists (select Co from bHQDX d 
  							where d.Co = c.HQCo and d.Package = 'Customers' and d.TriggerName = 'Delete' and d.Enable = 'Y')
  			)
  	begin
  
  	-- Execute Export document for each customer in Inserted
  	if @numrows = 1
  	    begin
  	    -- if only one row inserted, no cursor is needed
  	    select @custgroup = CustGroup, @customer = Customer
  		from deleted
  	
  		if @@rowcount = 0 goto btexit
  	    end
  	else
  	    begin
  	    -- use a cursor to process inserted rows
  	    declare bARCM_cursor cursor local fast_forward for
  	    select CustGroup, Customer
  	    from deleted
  	
  	    open bARCM_cursor
  	    select @opencursor = 1
  	
  	    -- get 1st row inserted
  	    fetch next from bARCM_cursor into @custgroup , @customer
  	    if @@fetch_status <> 0 goto btexit
  	    end
  		
  	ARCM_export:
  		-- Export Customer Document
  	    -- use a cursor to process inserted rows
  
  	    declare HQDExport cursor local fast_forward for
  	    select HQCo
  	    from bHQCO
  		where HQCo = @custgroup
  	
  	    open HQDExport
  	    select @hqdxcursor = 1
  	
  	    -- get 1st row inserted
  	    fetch next from HQDExport into @hqco
  	    if @@fetch_status <> 0 goto btexit
  				
  		HQDExport:
  			select @stdxmlformat=null, @userstoredrroc=null, @exportdirectory = null
  
  			select @stdxmlformat=StdXMLFormat, @userstoredrroc=UserStoredProc, @exportdirectory=ExportDirectory 
  			from bHQDX d 
  			where d.Co = @hqco and d.Package = 'Customers' and d.TriggerName = 'Delete' and d.Enable = 'Y'
  			
		 -- 129574 - sp_makewebtask is deprecated so removing call to proc
		 IF ISNULL(@stdxmlformat, '') <> 'Y' 
			BEGIN
				IF ISNULL(@userstoredrroc, '') <> '' 
					BEGIN
  							-- For @userstoredrroc pass customer, customer group, company, and export directory
						SELECT  @sql = 'declare @rcode int, @msg varchar(255) ',
								@sql = @sql + 'exec @rcode = ' + @userstoredrroc
								+ ' ' + @customer + ',' + @custgroup + ',' + @hqco
								+ ',''' + @exportdirectory + '''' + ', @msg',
								@sql = @sql
								+ 'if @rcode <> 0 insert bHQDXARCM (Co, CustGroup, Customer, TriggerName, ErrorDate, ErrorMessage) values (@hqco, @custgroup, @customer, ''Delete'', getdate(), @msg)'
						EXEC @sql
					END
			END
  
  	    	fetch next from HQDExport into @hqco
  	    	if @@fetch_status = 0 goto HQDExport
  
  			if @hqdxcursor = 1
  				begin
  				close HQDExport
  		    	deallocate HQDExport
  				end
  		
  		 	-- get next row
  		 	if @numrows > 1
  		    	begin
  		    	fetch next from bARCM_cursor into @custgroup , @customer
  		    	if @@fetch_status = 0 goto ARCM_export
  				end
  	end
  btexit:
  if @opencursor = 1
  	begin
  	close bARCM_insert
  	deallocate bARCM_insert
  	end
  /* End Document exporting */
  
  /* add HQ Master Audit entry */
  insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  select 'bARCM',  'Cust Group#: ' + isnull(convert(varchar(3),d.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),d.Customer),''),
  	d.CustGroup, 'D', null, null, null, getdate(), SUSER_SNAME() 
  from deleted d
  join  bHQCO h on d.CustGroup = h.CustGroup
  join  bARCO a on h.HQCo = a.ARCo
  where a.AuditCustomers = 'Y' 
  group by d.CustGroup, d.Customer
  
  return
  error:
  	select @errmsg = @errmsg +  ' - unable to delete AR Customer!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

CREATE trigger [dbo].[btARCMi] on [dbo].[bARCM] for INSERT as
/*-----------------------------------------------------------------
* Created:
* Modified: 04/22/99 GG    (SQL 7.0)
*			02/14/2000 GF
*           04/10/02 CMW - Replaced NULL for HQMA.Company with MaterialGroup.
*                          Replaced ' with ' (issue # 16840).
*			 07/11/02 CMW - fixed multiple entry problem (issue # 17902)
*           08/12/02 CMW - Fixed varchar/tinyint problem (issue # 18249).
*           08/16/02 CMW - Fixed message spacing (issue # 18279).
*           09/30/02 DANF - Added Document Exporting (14550)
*			02/05/04 DANF - Corrected update on SortName
*			TJL  11/10/05 - Issue #30333, Minor change to Audit String 'Cust Group#:, Cust:'
*			TJL 03/07/08 - Issue #127077, International Addresses
*			GG 06/03/08 - #128324 - fix Contry/State validation
*			GG 10/08/08 - #130130 - fix State validation
*			AR 11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
*
*	This trigger rejects insertion in bARCM (AR Customer Master)
*	if any of the following error conditions exist:
*
*		Invalid CustGroup vs HQGP
*		Invalid BillState vs HQST
*		Invalid State vs HQST
*		Invalid PayTerms vs HQPT
*		Invalid TaxGroup vs HQTX
*		Invalid TaxCode vs HQTX
*		Invalid Status - must be A, H or I
*
*	Audit inserts all transactions
*/----------------------------------------------------------------
  declare @numrows int, @validcnt int, @errmsg varchar(255), @nullcnt int,
		@validcnt2 int
  select @numrows = @@rowcount
  
  set nocount on
  /* Removed 3/12/98 because the integrity of the SortName is being checked by index biARCM2, bc
  validate SortName - No duplicates!
  select @validcnt = count(*) from bARCM a, inserted i
  	where a.SortName = upper(i.SortName) and a.CustGroup = i.CustGroup
  if @validcnt<>@numrows
  	begin
  	select @errmsg = 'Sortname already exists for group'
  	goto error
  	end*/
  /* validate CustGroup */
  select @validcnt = count(*) from bHQGP g, inserted i
  	where g.Grp = i.CustGroup
  select @nullcnt = count(*) from inserted i where i.CustGroup is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Customer Group'
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

/* Validate Bill Country */
select @validcnt = count(1) 
from dbo.bHQCountry c with (nolock) 
join inserted i on i.BillCountry=c.Country
select @nullcnt = count(1) from inserted where BillCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Bill Country'
	goto error
	end
-- validate Bill State - all State values must exist in bHQST
if exists(select top 1 1 from inserted i where BillState not in(select [State] from dbo.bHQST))
	begin
	select @errmsg = 'Invalid Bill State'
	goto error
	end
-- validate BillCountry/BillState combinations
select @validcnt = count(1) -- Country/State combos are unique
from dbo.bHQST (nolock) s
join inserted i on i.BillCountry = s.Country and i.BillState = s.State
select @nullcnt = count(1) from inserted where BillCountry is null or BillState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Bill Country and State combination'
	goto error
	end

  /* validate PayTerms */
  select @validcnt = count(*) from bHQPT g, inserted i
  	where g.PayTerms = i.PayTerms
  select @nullcnt = count(*) from inserted i where i.PayTerms is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Payment Terms'
  	goto error
  	end
  /* validate TaxGroup */
  select @validcnt = count(*) from bHQGP g, inserted i
  	where g.Grp = i.TaxGroup
  select @nullcnt = count(*) from inserted i where i.TaxGroup is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Tax Group'
  	goto error
  	end
  /* validate Tax Code */
  select @validcnt = count(*) from bHQTX g, inserted i
  	where g.TaxGroup = i.TaxGroup and g.TaxCode = i.TaxCode
  select @nullcnt = count(*) from inserted i where i.TaxCode is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Tax Code'
  	goto error
  	end
  /* validate Status */
  select @validcnt = count(*) from inserted i
  	where i.Status in ('A','H','I')
  select @nullcnt = count(*) from inserted i where i.Status is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Status - must be ''A'', ''H'' or ''I'' '
  	goto error
  	end
  /* validate Finance Charge Type*/
  select @validcnt = count(*) from inserted i
  	where i.FCType in ('I','A','R','N')
  select @nullcnt = count(*) from inserted i where i.FCType is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Finance Charge - must be ''Invoice'', ''On Account'', ''RecType'' or ''No Finance Charge'' '
  	goto error
  	end
  
  /*
  -- Validate PriceTemplate
  select @validcnt = count(*) from bMSTH r JOIN inserted i ON
   i.PriceTemplate = r.PriceTemplate
  select @nullcnt = count(*) from inserted i where i.PriceTemplate is null
  if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Price Template is Invalid '
     goto error
     end
  -- Validate DiscTemplate
  select @validcnt = count(*) from bMSDH r JOIN inserted i ON
   i.DiscTemplate = r.DiscTemplate
  select @nullcnt = count(*) from inserted i where i.DiscTemplate is null
  if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Discount Template is Invalid '
     goto error
     end
  */
  -- validate Haul Tax Option
  select @validcnt = count(*) from inserted i
  	where i.HaulTaxOpt in (0,1,2)
  select @nullcnt = count(*) from inserted i where i.HaulTaxOpt is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Haul Tax Option - must be 0, 1, 2'
  	goto error
  	end
  -- validate Invoice Level
  select @validcnt = count(*) from inserted i
  	where i.InvLvl in (0,1,2)
  select @nullcnt = count(*) from inserted i where i.InvLvl is null
  if @validcnt + @nullcnt <> @numrows
  	begin
  	select @errmsg = 'Invalid Invoice Level - must be 0, 1, 2'
  	goto error
  	end
  
  
  /* Document exporting */
  declare @custgroup tinyint, @opencursor int, @customer int, @rcode int,
  		@stdxmlformat bYN, @userstoredrroc varchar(30), @hqco bCompany, @hqdxcursor int,
  		@sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)
  
  if exists (select top 1 i.CustGroup
  			from bARCM i 
  			join bHQCO c on i.CustGroup = c.CustGroup
  			where exists (select Co from bHQDX d 
  							where d.Co = c.HQCo and d.Package = 'Customers' and d.TriggerName = 'Insert' and d.Enable = 'Y')
  			)
  	begin
  
  		-- Execute Export document for each customer in Inserted
  		if @numrows = 1
  		    begin
  		    -- if only one row inserted, no cursor is needed
  		    select @custgroup = CustGroup, @customer = Customer
  			from inserted
  		
  			if @@rowcount = 0 goto btexit
  		    end
  		else
  		    begin
  		    -- use a cursor to process inserted rows
  		    declare bARCM_insert cursor local fast_forward for  
  		    select CustGroup, Customer
  		    from inserted
  		
  		    open bARCM_insert
  		    select @opencursor = 1
  		
  		    -- get 1st row inserted
  		    fetch next from bARCM_insert into @custgroup , @customer
  		    if @@fetch_status <> 0 goto btexit
  		    end
  		
  		ARCM_export:
  			-- Export Customer Document
  			    -- use a cursor to process inserted rows
  
  			    declare HQDExport cursor local fast_forward for  
  			    select HQCo
  			    from bHQCO
  				where HQCo = @custgroup
  			
  			    open HQDExport
  			    select @hqdxcursor = 1
  			
  			    -- get 1st row inserted
  			    fetch next from HQDExport into @hqco
  			    if @@fetch_status <> 0 goto btexit
  				
  				HQDExport:
  					select @stdxmlformat=null, @userstoredrroc=null, @exportdirectory = null
  
  					select @stdxmlformat=StdXMLFormat, @userstoredrroc=UserStoredProc, @exportdirectory=ExportDirectory 
  					from bHQDX d 
  					where d.Co = @hqco and d.Package = 'Customers' and d.TriggerName = 'Insert' and d.Enable = 'Y'
  
  
  					-- 129574 - sp_makewebtask is deprecated so removing call to proc
  					IF ISNULL(@stdxmlformat,'') <> 'Y'
					 BEGIN
						IF ISNULL(@userstoredrroc, '') <> '' 
							BEGIN
			  
								SELECT  @sql = 'declare @rcode int, @msg varchar(255) '
								SELECT  @sql = @sql + 'exec @rcode = ' + @userstoredrroc
										+ ' ' + CONVERT(varchar(20), @customer) + ',' 
								SELECT  @sql = @sql + CONVERT(varchar(10), @custgroup)
										+ ',' + CONVERT(varchar(10), @hqco) + ','''
										+ ISNULL(@exportdirectory, '') + '''' + ', @msg  '
			  
								EXEC(@sql)
							END
					 END
			  
  
  			    	fetch next from HQDExport into @hqco
  			    	if @@fetch_status = 0 goto HQDExport
  
  					if @hqdxcursor = 1
  						begin
  						close HQDExport
  				    	deallocate HQDExport
  						end
  		
  		
  		 	-- get next row
  		 	if @numrows > 1
  		    	begin
  		    	fetch next from bARCM_insert into @custgroup , @customer
  		    	if @@fetch_status = 0 goto ARCM_export
  				end
  	end
  
  btexit:
  	if @opencursor = 1
  		begin
  		close bARCM_insert
      	deallocate bARCM_insert
  		end
  
  /* End Document exporting */
  
  -- Update Sort Name -- Note place any additional validation before the document export seciot above.
  select @validcnt=count(*) from inserted where SortName<>upper(SortName)
  if isnull(@validcnt,0)<>0
  begin
  	UPDATE bARCM set SortName=upper(a.SortName)
  	FROM bARCM a
  	join inserted i
  	on a.CustGroup=i.CustGroup AND a.Customer=i.Customer
  end
  
  /* add HQ Master Audit entry */
  insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
  	select 'bARCM',  'Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''),
  	h.CustGroup, 'A', null, null, null, getdate(), SUSER_SNAME() from inserted i, bARCO a, bHQCO h
  		where AuditCustomers = 'Y' and i.CustGroup = h.CustGroup and a.ARCo = h.HQCo
  		group by h.CustGroup  
  return
  error:
  	select @errmsg = @errmsg + ' - cannot insert AR Customer!'
  	RAISERROR(@errmsg, 11, -1);
  	rollback transaction
  
 
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btARCMu] on [dbo].[bARCM] for UPDATE as
/*-----------------------------------------------------------------
* Created: ??
* Modified: 04/22/99 GG    (SQL 7.0)
*    		02/14/2000 GILF
*			GG 09/28/00 - Added PrintLvl, SubtotalLvl, and SepHaul columns for MS
*  			CMW 04/10/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
*			CMW 07/11/02 - Fixed multiple entries per CustGroup (issue # 17902)
*   		CMW 08/12/02 - Fixed varchar/tinyint problem (issue # 18249).
*  			DANF 09/30/02 - Added Document Exporting (14550)
*			TJL 08/13/02 - Issue #22017, Include changes to 'Excl Cont Inv in FC' checkbox in Audit	
*			TJL 12/29/04 - Issue #26488, Not auditing some fields going from NULL to Something or Something to NULL
*			TJL 10/05/05 - Issue #29108, Added HQMA auditing for AddlAddress (Address2) and AddlBillAddress (BillAddress2)
*			TJL 03/07/08 - Issue #127077, International Addresses
*			GG 06/03/08 - #128324 - fix Contry/State validation
*			GG 10/08/08 - #130130 - fix State validation
*		TJL 10/21/08 - Issue #129355, Correct HQMA Audit error for CreditLimit Arithmetic OverFlow
*			AR 11/4/2010 -#129574 - sp_makewebtask is deprecated so removing call to proc
*			CHS 7/17/2011 TK-06741 added columns ABN and ACN
*
*
*	This trigger rejects update in bARCM (AR Customer Master)
*	if any of the following error conditions exist:
*
*		Cannot change primary key - CustGroup/Customer
*		BillState must exist in HQST
*		State must exist in HQST
*		PayTerms must exist in HQPT
*		TaxGroup must exist in HQTX
*		TaxCode must exist in HQTX
*		Status must bet A, I or H
*
*	Audit inserts if any AR Company has the AuditCustomers option set.
*/----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @nullcnt int,
		@validcnt2 int
   select @numrows = @@rowcount
      
   if @numrows = 0 return
   set nocount on
   
   /* reject key changes */
   select @validcnt = count(*) from deleted d, inserted i
   	where d.CustGroup = i.CustGroup and d.Customer = i.Customer
   if @numrows <> @validcnt
   	begin
   	select @errmsg = 'Cannot change Customer Group or Customer'
   	goto error
   	end
   /* Removed 3/12/98 because the integrity of the SortName is being checked by index biARCM2, bc
   validate Sort Name - no duplicates
   select @validcnt = count(*) from inserted i, bARCM a
   	where i.CustGroup = a.CustGroup and upper(i.SortName) = a.SortName
     if @numrows = @validcnt
   	begin
   	select @errmsg = 'Not a unique sort name'
   	goto error
   	end*/
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
if update(BillCountry)
	begin
	-- validate BillCountry
	select @validcnt = count(1) from dbo.bHQCountry c (nolock) 
	join inserted i on i.BillCountry = c.Country
	select @nullcnt = count(1) from inserted where BillCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Bill Country'
		goto error
		end
	end
if update(BillState)
	begin
	-- validate Bill State - all State values must exist in bHQST
	if exists(select top 1 1 from inserted i where BillState not in(select [State] from dbo.bHQST))
		begin
		select @errmsg = 'Invalid Bill State'
		goto error
		end
	end
if update(BillCountry) or update(BillState)
	begin
	-- validate Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from dbo.bHQST (nolock) s
	join inserted i on i.BillCountry = s.Country and i.BillState = s.State
	select @nullcnt = count(1) from inserted where BillCountry is null or BillState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Bill Country and State combination'
		goto error
		end
	end

   /* validate PayTerms */
   select @validcnt = count(*) from inserted i, bHQPT s
   	where i.PayTerms = s.PayTerms
   select @nullcnt = count(*) from inserted i where i.PayTerms is null
   if @validcnt + @nullcnt <>@numrows
   	begin
   	select @errmsg = 'Payment Terms do not exist in HQ Payment Terms'
   	goto error
   	end
   /* validate TaxGroup */
   select @validcnt = count(*) from inserted i, bHQGP s
   	where i.TaxGroup = s.Grp
   select @nullcnt = count(*) from inserted i where i.TaxGroup is null
   if @validcnt + @nullcnt <>@numrows
   	begin
   	select @errmsg = 'Tax Group does not exist in HQ Groups'
   	goto error
   	end
   /* validate TaxCode */
   select @validcnt = count(*) from inserted i, bHQTX s
   	where i.TaxGroup = s.TaxGroup and i.TaxCode = s.TaxCode
   select @nullcnt = count(*) from inserted i where i.TaxCode is null
   if @validcnt + @nullcnt <>@numrows
   	begin
   	select @errmsg = 'Tax Code does not exist in HQ Tax Codes for this Tax Group'
   	goto error
   	end
   /* validate Status */
   select @validcnt = count(*) from inserted i
   	where i.Status in('A','H','I')
   select @nullcnt = count(*) from inserted i where i.Status is null
   if @validcnt + @nullcnt <>@numrows
   	begin
   	select @errmsg = 'Status must be ''A'', ''H'' or ''I'' '
   	goto error
   	end
   /* validate Finance Charge Type*/
   select @validcnt = count(*) from inserted i
   	where i.FCType in('I','A','R','N')
   select @nullcnt = count(*) from inserted i where i.FCType is null
   if @validcnt + @nullcnt <>@numrows
   	begin
   	select @errmsg = 'Status must be ''Account'', ''Invoice'', ''RecType'' or ''No Finance Charge'' '
   	goto error
   	end
   
   /*
   -- Validate PriceTemplate
   select @validcnt = count(*) from bMSTH r JOIN inserted i ON
    i.PriceTemplate = r.PriceTemplate
   select @nullcnt = count(*) from inserted i where i.PriceTemplate is null
   if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Price Template is Invalid '
       goto error
       end
   -- Validate DiscTemplate
   select @validcnt = count(*) from bMSDH r JOIN inserted i ON
    i.DiscTemplate = r.DiscTemplate
   select @nullcnt = count(*) from inserted i where i.DiscTemplate is null
   if @validcnt + @nullcnt <> @numrows
      begin
      select @errmsg = 'Discount Template is Invalid '
      goto error
      end
   */
   -- validate Haul Tax Option
   select @validcnt = count(*) from inserted i
   	where i.HaulTaxOpt in (0,1,2)
   select @nullcnt = count(*) from inserted i where i.HaulTaxOpt is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Haul Tax Option - must be 0, 1, 2'
   	goto error
   	end
   -- validate Invoice Level
   select @validcnt = count(*) from inserted i
   	where i.InvLvl in (0,1,2)
   select @nullcnt = count(*) from inserted i where i.InvLvl is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Invoice Level - must be 0, 1, 2'
   	goto error
   	end
   -- validate Print  Level
   select @validcnt = count(*) from inserted where PrintLvl in (1,2)
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Print Level - must be 1 or 2'
   	goto error
   	end
   -- validate Subtotal  Level
   select @validcnt = count(*) from inserted where SubtotalLvl in (1,2,3,4,5,6)
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Subtotal Level - must be between 1 and 6'
   	goto error
   	end
   -- validate Separate Haul
   select @validcnt = count(*) from inserted where SepHaul in ('Y','N')
   if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Separate Haul value - must be Y or N'
   	goto error
   	end
   
   
   /* Document exporting */
   declare @custgroup tinyint, @opencursor int, @customer int, @rcode int,
   		@stdxmlformat bYN, @userstoredproc varchar(30), @hqco bCompany, @hqdxcursor int,
   		@sql varchar(300), @exportdirectory varchar(256), @msg varchar(255)
   
   if exists (select top 1 i.CustGroup
   			from bARCM i 
   			join bHQCO c on i.CustGroup = c.CustGroup
   			where exists (select Co from bHQDX d 
   							where d.Co = c.HQCo and d.Package = 'Customers' and d.TriggerName = 'Update' and d.Enable = 'Y')
   			)
   	begin
   
   		-- Execute Export document for each customer in Inserted
   		if @numrows = 1
   		    begin
   		    -- if only one row inserted, no cursor is needed
   		    select @custgroup = CustGroup, @customer = Customer
   			from inserted
   		
   			if @@rowcount = 0 goto btexit
   		    end
   		else
   		    begin
   		    -- use a cursor to process inserted rows
   		    declare bARCM_insert cursor local fast_forward for
   		    select CustGroup, Customer
   		    from inserted
   			--from bARCM
   		
   		    open bARCM_insert
   		    select @opencursor = 1
   		
   		    -- get 1st row inserted
   		    fetch next from bARCM_insert into @custgroup , @customer
   		    if @@fetch_status <> 0 goto btexit
   		    end
   		
   		ARCM_export:
   			-- Export Customer Document
   			    -- use a cursor to process inserted rows
   
   			    declare HQDExport cursor local fast_forward for
   			    select HQCo
   			    from bHQCO
   				where HQCo = @custgroup
   			
   			    open HQDExport
   			    select @hqdxcursor = 1
   			
   			    -- get 1st row inserted
   			    fetch next from HQDExport into @hqco
   			    if @@fetch_status <> 0 goto btexit
   				
   				HQDExport:
   					select @stdxmlformat=null, @userstoredproc=null, @exportdirectory = null
   
   					select @stdxmlformat=StdXMLFormat, @userstoredproc=UserStoredProc, @exportdirectory=ExportDirectory 
   					from bHQDX d 
   					where d.Co = @hqco and d.Package = 'Customers' and d.TriggerName = 'Update' and d.Enable = 'Y'
   
		 -- 129574 - sp_makewebtask is deprecated so removing call to proc
         IF ISNULL(@stdxmlformat, '') <> 'Y' 
            BEGIN
                IF ISNULL(@userstoredproc, '') <> '' 
                    BEGIN
   
                        SELECT  @sql = 'declare @xrcode int '
                        SELECT  @sql = @sql + 'exec @xrcode = '
                                + @userstoredproc + ' '
                        SELECT  @sql = @sql + CONVERT(varchar(300), @customer)
                                + ','
                        SELECT  @sql = @sql + CONVERT(varchar(300), @custgroup)
                                + ','
                        SELECT  @sql = @sql + CONVERT(varchar(300), @hqco)
                                + ','
                        SELECT  @sql = @sql + CHAR(39)
                                + ISNULL(@exportdirectory, '') + CHAR(39)
                                + ',' 
                        SELECT  @sql = @sql + CHAR(39) + '*' + CHAR(39)
   
                        EXEC(@sql)
                    END
            END
   
   
   			    	fetch next from HQDExport into @hqco
   			    	if @@fetch_status = 0 goto HQDExport
   
   					if @hqdxcursor = 1
   						begin
   						close HQDExport
   				    	deallocate HQDExport
   						end
   		
   		
   		 	-- get next row
   		 	if @numrows > 1
   		    	begin
   		    	fetch next from bARCM_insert into @custgroup , @customer
   		    	if @@fetch_status = 0 goto ARCM_export
   				end
   	end
   btexit:
   	if @opencursor = 1
   		begin
   		close bARCM_insert
       	deallocate bARCM_insert
   		end
   /* End Document exporting */
   
   
   /* update HQ Master Audit if any company using this Customer has auditing turned on */
   IF UPDATE(Name)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), convert(varchar(3), h.CustGroup), 'C',
   	'Name',  min(d.Name), min(i.Name), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Name, '') <> isnull(i.Name, '')
   	group by h.CustGroup
   END
   IF UPDATE(SortName)
   BEGIN
   UPDATE bARCM set SortName=upper(a.SortName)
   	FROM bARCM a, inserted i
   		WHERE a.CustGroup=i.CustGroup AND a.Customer=i.Customer and a.SortName<>upper(i.SortName)
   
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'SortName',  min(d.SortName), min(i.SortName), getdate(), SUSER_SNAME()
       FROM inserted i
            JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
            JOIN bHQCO h ON h.CustGroup=i.CustGroup
            JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
            WHERE isnull(upper(d.SortName), '') <> isnull(upper(i.SortName), '')
   		 group by h.CustGroup
   END
   IF UPDATE(TempYN)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'TempYN',  min(d.TempYN), min(i.TempYN), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.TempYN<>i.TempYN
   	group by h.CustGroup
   END
   IF UPDATE(Phone)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Phone',  min(d.Phone), min(i.Phone), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Phone, '') <> isnull(i.Phone, '')
   	group by h.CustGroup
   END
   IF UPDATE(Fax)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Fax',  min(d.Fax), min(i.Fax), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Fax, '') <> isnull(i.Fax, '')
   	group by h.CustGroup
   END
   IF UPDATE(EMail)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'EMail',  min(d.EMail), min(i.EMail), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.EMail, '') <> isnull(i.EMail, '')
   	group by h.CustGroup
   END
   IF UPDATE(URL)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'URL',  min(d.URL), min(i.URL), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.URL, '') <> isnull(i.URL, '')
       group by h.CustGroup
   END
   IF UPDATE(Contact)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Contact',  min(d.Contact), min(i.Contact), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Contact, '') <> isnull(i.Contact, '')
       group by h.CustGroup
   END
   IF UPDATE(ContactExt)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'ContactExt',  min(d.ContactExt), min(i.ContactExt), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.ContactExt, '') <> isnull(i.ContactExt, '')
       group by h.CustGroup
   END
   IF UPDATE(Address)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   
   	'Address', min(d.Address), min(i.Address), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Address, '') <> isnull(i.Address, '')
       group by h.CustGroup
   END
   IF UPDATE(City)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'City',  min(d.City), min(i.City), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.City, '') <> isnull(i.City, '')
       group by h.CustGroup
   END
   IF UPDATE(State)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'State', min(d.State), min(i.State), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.State, '') <> isnull(i.State, '')
       group by h.CustGroup
   END
   IF UPDATE(Zip)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Zip',  min(d.Zip), min(i.Zip), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Zip, '') <> isnull(i.Zip, '')
       group by h.CustGroup
   END
   IF UPDATE(Country)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Country',  min(d.Country), min(i.Country), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Country, '') <> isnull(i.Country, '')
       group by h.CustGroup
   END
   IF UPDATE(Address2)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
    	'AddlAddress', min(d.Address2), min(i.Address2), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.Address2, '') <> isnull(i.Address2, '')
       group by h.CustGroup
   END
   IF UPDATE(BillAddress)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'BillAddress',  min(d.BillAddress), min(i.BillAddress), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillAddress, '') <> isnull(i.BillAddress, '')
       group by h.CustGroup
   END
   IF UPDATE(BillCity)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'BillCity',  min(d.BillCity), min(i.BillCity), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillCity, '') <> isnull(i.BillCity, '')
       group by h.CustGroup
   END
   IF UPDATE(BillState)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'BillState',  min(d.BillState), min(i.BillState), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillState, '') <> isnull(i.BillState, '')
       group by h.CustGroup
   END
   IF UPDATE(BillZip)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'BillZip',  min(d.BillZip), min(i.BillZip), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillZip, '') <> isnull(i.BillZip, '')
       group by h.CustGroup
   END
   IF UPDATE(BillCountry)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'BillCountry',  min(d.BillCountry), min(i.BillCountry), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillCountry, '') <> isnull(i.BillCountry, '')
       group by h.CustGroup
   END
   IF UPDATE(BillAddress2)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'AddlBillAddress',  min(d.BillAddress2), min(i.BillAddress2), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillAddress2, '') <> isnull(i.BillAddress2, '')
       group by h.CustGroup
   END
   IF UPDATE(Status)
   BEGIN
    INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Status',  min(d.Status), min(i.Status), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.Status<>i.Status
       group by h.CustGroup
   END
   IF UPDATE(RecType)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'RecType',  convert(varchar(10),min(d.RecType)), convert(varchar(10),min(i.RecType)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.RecType, 0) <> isnull(i.RecType, 0)
       group by h.CustGroup
   END
   IF UPDATE(PayTerms)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'PayTerms',  min(d.PayTerms), min(i.PayTerms), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.PayTerms, '') <> isnull(i.PayTerms, '')
       group by h.CustGroup
   END
   IF UPDATE(TaxGroup)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'TaxGroup',  convert(varchar(10),min(d.TaxGroup)), convert(varchar(10),min(i.TaxGroup)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.TaxGroup <> i.TaxGroup
       group by h.CustGroup
   END
   IF UPDATE(TaxCode)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'TaxCode',  min(d.TaxCode), min(i.TaxCode), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.TaxCode, '') <> isnull(i.TaxCode, '')
       group by h.CustGroup
   
   END
   IF UPDATE(CreditLimit)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'CreditLimit',  convert(varchar,min(d.CreditLimit)), convert(varchar,min(i.CreditLimit)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.CreditLimit <> i.CreditLimit
       group by h.CustGroup
   END
   IF UPDATE(SelPurge)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'SelPurge',  min(d.SelPurge), min(i.SelPurge), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.SelPurge <> i.SelPurge
       group by h.CustGroup
   END
   IF UPDATE(MiscOnInv)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Misc On Invoice', min(d.MiscOnInv), min(i.MiscOnInv), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.MiscOnInv <> i.MiscOnInv
       group by h.CustGroup
   END
   IF UPDATE(MiscOnPay)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Misc On Payment', min(d.MiscOnPay), min(i.MiscOnPay), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.MiscOnPay <> i.MiscOnPay
       group by h.CustGroup
   END
   IF UPDATE(StmntPrint)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'StmntPrint',  min(d.StmntPrint), min(i.StmntPrint), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.StmntPrint <> i.StmntPrint
       group by h.CustGroup
   END
   IF UPDATE(StmtType)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'StmtType',  min(d.StmtType), min(i.StmtType), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.StmtType <> i.StmtType
       group by h.CustGroup
   END
   IF UPDATE(FCType)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'FCType',  min(d.FCType), min(i.FCType), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.FCType <> i.FCType
       group by h.CustGroup
   END
   IF UPDATE(FCPct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'FCPct',  convert(varchar(10),min(d.FCPct)), convert(varchar(10),min(i.FCPct)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.FCPct <> i.FCPct
       group by h.CustGroup
   END
   IF UPDATE(MarkupDiscPct)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'MarkupDiscPct',  convert(varchar(12),min(d.MarkupDiscPct)), convert(varchar(12),min(i.MarkupDiscPct)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.MarkupDiscPct <> i.MarkupDiscPct
       group by h.CustGroup
   END
   IF UPDATE(DateOpened)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'DateOpened',  min(d.DateOpened), min(i.DateOpened), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.DateOpened, '') <> isnull(i.DateOpened, '')
       group by h.CustGroup
   END
   IF UPDATE(MiscDistCode)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'MiscDistCode', min(d.MiscDistCode), min(i.MiscDistCode), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.MiscDistCode,'') <> isnull(i.MiscDistCode,'')
       group by h.CustGroup
   END
   IF UPDATE(PriceTemplate)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Price Template', convert(char(6),min(d.PriceTemplate)),convert(char(6),min(i.PriceTemplate)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.PriceTemplate,0) <> isnull(i.PriceTemplate,0)
       group by h.CustGroup
   END
   IF UPDATE(DiscTemplate)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Discount Template', convert(char(6),min(d.DiscTemplate)), convert(char(6),min(i.DiscTemplate)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.DiscTemplate,0) <> isnull(i.DiscTemplate,0)
       group by h.CustGroup
   END
   IF UPDATE(HaulTaxOpt)
   BEGIN
   
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Haul Tax Option', min(d.HaulTaxOpt), min(i.HaulTaxOpt), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.HaulTaxOpt <> i.HaulTaxOpt
       group by h.CustGroup
   END
   IF UPDATE(InvLvl)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Invoice Level', convert(char(4),min(d.InvLvl)), convert(char(4),min(i.InvLvl)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.InvLvl <> i.InvLvl
       group by h.CustGroup
   END
   IF UPDATE(BillFreq)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Bill Frequency', min(d.BillFreq), min(i.BillFreq), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.BillFreq,'') <> isnull(i.BillFreq,'')
       group by h.CustGroup
   END
   IF UPDATE(PrintLvl)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Print Level', convert(char(4),min(d.PrintLvl)), convert(char(4),min(i.PrintLvl)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.PrintLvl <> i.PrintLvl
       group by h.CustGroup
   END
   
   IF UPDATE(SubtotalLvl)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Subtotal Level', convert(char(4),min(d.SubtotalLvl)), convert(char(4),min(i.SubtotalLvl)), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.SubtotalLvl <> i.SubtotalLvl
       group by h.CustGroup
   END
   
   IF UPDATE(SepHaul)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Separate Haul', min(d.SepHaul), min(i.SepHaul), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.SepHaul <> i.SepHaul
       group by h.CustGroup
   END
   
   IF UPDATE(ExclContFromFC)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM','Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') + ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), h.CustGroup, 'C',
   	'Exclude Contract Inv from FC', min(d.ExclContFromFC), min(i.ExclContFromFC), getdate(), SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE d.ExclContFromFC <> i.ExclContFromFC
       group by h.CustGroup
   END

   IF UPDATE(ABN)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM',
   	'Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') 
   		+ ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), 
   	h.CustGroup, 
   	'C',
   	'ABN', 
   	min(d.ABN), 
   	min(i.ABN), 
   	getdate(), 
   	SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.ABN,'') <> isnull(i.ABN,'')
       group by h.CustGroup
   END
   
   IF UPDATE(ACN)
   BEGIN
   INSERT INTO bHQMA   (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bARCM',
   	'Cust Group#: ' + isnull(convert(varchar(3), h.CustGroup),'') 
   		+ ' Cust: ' + isnull(convert(varchar(10),min(i.Customer)),''), 
   	h.CustGroup, 
   	'C',
   	'ACN', 
   	min(d.ACN), 
   	min(i.ACN), 
   	getdate(), 
   	SUSER_SNAME()
    	FROM inserted i
   	JOIN deleted d  ON d.CustGroup=i.CustGroup AND d.Customer=i.Customer
   	JOIN bHQCO h ON h.CustGroup=i.CustGroup
   	JOIN bARCO a ON a.ARCo=h.HQCo and a.AuditCustomers='Y'
   	WHERE isnull(d.ACN,'') <> isnull(i.ACN,'')
       group by h.CustGroup
   END

   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot update AR Customer!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
  
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biARCM] ON [dbo].[bARCM] ([CustGroup], [Customer]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biARCMSortName] ON [dbo].[bARCM] ([CustGroup], [SortName]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bARCM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[TempYN]'
GO
EXEC sp_bindrule N'[dbo].[brARCustStatus]', N'[dbo].[bARCM].[Status]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARCM].[CreditLimit]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[SelPurge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[StmntPrint]'
GO
EXEC sp_bindrule N'[dbo].[brARStatementType]', N'[dbo].[bARCM].[StmtType]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARCM].[FCPct]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARCM].[MarkupDiscPct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[MiscOnInv]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[MiscOnPay]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[SepHaul]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bARCM].[ExclContFromFC]'
GO
