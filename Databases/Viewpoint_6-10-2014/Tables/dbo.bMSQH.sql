CREATE TABLE [dbo].[bMSQH]
(
[MSCo] [dbo].[bCompany] NOT NULL,
[Quote] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[QuoteType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[Customer] [dbo].[bCustomer] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[JCCo] [dbo].[bCompany] NULL,
[Job] [dbo].[bJob] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Contact] [dbo].[bDesc] NULL,
[Phone] [dbo].[bPhone] NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PriceTemplate] [smallint] NULL,
[DiscTemplate] [smallint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[HaulTaxOpt] [tinyint] NOT NULL,
[Active] [dbo].[bYN] NOT NULL,
[QuotedBy] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[QuoteDate] [dbo].[bDate] NULL,
[ExpDate] [dbo].[bDate] NULL,
[SepInv] [dbo].[bYN] NOT NULL,
[BillFreq] [dbo].[bFreq] NULL,
[PrintLvl] [tinyint] NULL,
[SubtotalLvl] [tinyint] NULL,
[SepHaul] [dbo].[bYN] NULL,
[MiscDistCode] [char] (10) COLLATE Latin1_General_BIN NULL,
[PurgeYN] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UseUMMetricYN] [dbo].[bYN] NULL CONSTRAINT [DF_bMSQH_UseUMMetricYN] DEFAULT ('N'),
[PayTerms] [dbo].[bPayTerms] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[ApplyEscalators] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSQH_ApplyEscalators] DEFAULT ('N'),
[BidIndexDate] [dbo].[bDate] NULL,
[ApplySurchargesYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bMSQH_ApplySurchargesYN] DEFAULT ('N'),
[SurchargeGroup] [smallint] NULL,
[EscalationFactor] [dbo].[bRate] NOT NULL CONSTRAINT [DF_bMSQH_EscalationFactor] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE trigger [dbo].[btMSQHd] on [dbo].[bMSQH] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created By:  GF 03/08/2000
    *  Modified By: GF 02/22/2002 - Added Update of PMMF if Quote exists - set to null
    *				 GF 03/16/2004 - issue #24036 - new table bMSHO for haul code overrides
    *
    *
    * Validates and inserts HQ Master Audit entry.  Rolls back
    * deletion if one of the following conditions is met.
    *
    * No detail records in MSQD,MSDX,MSPX,MSMD,MSHX,MSJP,MSZD.
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   select @numrows = @@rowcount
   set nocount on
   if @numrows = 0 return
   
   -- check MSQD - Quote Detail
   select @validcnt = count(*)
   from bMSQD, deleted d
   where bMSQD.MSCo=d.MSCo and bMSQD.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Detail exists'
      goto error
      end
   
   -- check MSDX - Quote Discount Templates
   select @validcnt = count(*)
   from bMSDX, deleted d
   where bMSDX.MSCo=d.MSCo and bMSDX.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Discount Templates exists'
      goto error
      end
   
   -- check MSPX - Quote Pay Codes
   select @validcnt = count(*)
   from bMSPX, deleted d
   where bMSPX.MSCo=d.MSCo and bMSPX.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Pay Codes exists'
      goto error
      end
   
   -- check MSMD - Quote Price Templates
   select @validcnt = count(*)
   from bMSMD, deleted d
   where bMSMD.MSCo=d.MSCo and bMSMD.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Price Templates exists'
      goto error
      end
   
   -- check MSHX - Quote Haul Codes
   select @validcnt = count(*)
   from bMSHX, deleted d
   where bMSHX.MSCo=d.MSCo and bMSHX.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Haul Code Defaults exists'
      goto error
      end
   
   -- check MSJP - Quote Job Phases
   select @validcnt = count(*)
   from bMSJP, deleted d
   where bMSJP.MSCo=d.MSCo and bMSJP.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Job Phases exists'
      goto error
      end
   
   -- check MSZD - Quote Haul Zones
   select @validcnt = count(*)
   from bMSZD, deleted d
   where bMSZD.MSCo=d.MSCo and bMSZD.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Haul Zones exists'
      goto error
      end
   
   -- check MSHO - Quote Haul Code Overrides
   select @validcnt = count(*)
   from bMSHO, deleted d
   where bMSHO.MSCo=d.MSCo and bMSHO.Quote=d.Quote
   if @validcnt > 0
      begin
      select @errmsg = 'Quote Haul Code Overrides exists'
      goto error
      end
   
   
   -- when MSQD rows are deleted, PM Material entries are removed, but when a Quote Header is deleted
   -- bPMMF entries are not, only the Quote are set to null in bPMMF
   update bPMMF set Quote = null
   from bPMMF p join deleted d on p.MSCo = d.MSCo and p.Quote = d.Quote
   
   
   -- Audit HQ deletions
   INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   SELECT 'bMSQH',' Quote:' + d.Quote, d.MSCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
   FROM deleted d JOIN bMSCO c ON d.MSCo=c.MSCo
   where c.AuditQuotes = 'Y'
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot delete MS Quote!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***************************************************************/
CREATE trigger [dbo].[btMSQHi] on [dbo].[bMSQH] for INSERT as
/*-----------------------------------------------------------------
* Created By:	GF 03/30/2000
* Modified By:	GF 08/08/2001 - Added check for CustJob or CustPo not null if customer null
*				allenn 05/24/02 - Added check for UseUMMetricYN for issue 17381
*				GF 11/05/2003 - issue #18762 - added pay terms validation
*				GF 03/10/2008 - issue #127082 country and state validation
*				gf 07/05/2010 - ISSUE #140452 country/state validate state may be empty
*
*
*  Validates MS Quote Header Columns.
*  Verify that quote is unique for quote type.
*  If Quotes flagged for auditing, inserts HQ Master Audit entry .
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @validcnt int, @validcnt2 int, @numrows int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
   -- validate MS Company
   select @validcnt = count(*) from inserted i join bMSCO c with (nolock) on c.MSCo = i.MSCo
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid MS company!'
       goto error
       end
   
   -- validate Quote Type
   select @validcnt = count(*) from inserted where QuoteType in ('C','J','I')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Quote Type, must be (C,J,I)!'
       goto error
       end
   
   -- validate active flag
   select @validcnt = count(*) from inserted where Active in ('Y','N')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Active flag must be (Y) or (N)!'
       goto error
       end
   
   -- validate separate invoice flag
   select @validcnt = count(*) from inserted where SepInv in ('Y','N')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Separate Invoice flag must be (Y) or (N)!'
       goto error
       end
   
   -- validate Purge flag
   select @validcnt = count(*) from inserted where PurgeYN in ('Y','N')
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Purge flag must be (Y) or (N)!'
       goto error
       end
   
   -- validate Haul Tax Option
   select @validcnt = count(*) from inserted where HaulTaxOpt in (0,1,2)
   IF @validcnt <> @numrows
       begin
       select @errmsg = 'Invalid Haul Tax Option, must be (0,1,2)!'
       goto error
       end
   
   -- validate Price Templates
   select @validcnt = count(*) from inserted i join bMSTH c with (nolock) on
       c.MSCo = i.MSCo and c.PriceTemplate = i.PriceTemplate
   select @nullcnt = count(*) from inserted where PriceTemplate is null
   IF @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Price Template!'
       goto error
       end
   
   -- validate Discount Templates
   select @validcnt = count(*) from inserted i join bMSDH c with (nolock) on
       c.MSCo = i.MSCo and c.DiscTemplate = i.DiscTemplate
   select @nullcnt = count(*) from inserted where DiscTemplate is null
   IF @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Invalid Discount Template!'
       goto error
       end
   
   -- validate Customer Group
   select @validcnt = count(*) from inserted i join bHQGP g with (nolock) on g.Grp = i.CustGroup
   select @nullcnt = count(*) from inserted where CustGroup is null
   if @validcnt + @nullcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Customer Group'
   	goto error
   	end
   
   -- validate Tax group
   select @validcnt = count(*) from inserted i join bHQGP g with (nolock) on g.Grp = i.TaxGroup
   select @nullcnt = count(*) from inserted where TaxGroup is null
   if @validcnt + @nullcnt <> @numrows
       begin
   	select @errmsg = 'Invalid Tax Group'
   	goto error
   	end
   
   -- validate PayTerms
   select @validcnt = count(*) from inserted i join bHQPT g with (nolock) on g.PayTerms = i.PayTerms
   select @nullcnt = count(*) from inserted where PayTerms is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Payment Terms'
   	goto error
   	end
   
   
   -- validate Tax Code
   select @validcnt=count(*) from inserted i join bHQTX h with (nolock) on h.TaxGroup=i.TaxGroup and h.TaxCode=i.TaxCode
   select @nullcnt=count(*) from inserted where TaxCode is null
   if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Tax Code'
   	goto error
   	end
   
   -- validate custjob, custpo are null if customer is null
   select @validcnt=count(*) from inserted
   where QuoteType='C' and Customer is null and (CustJob is not null or CustPO is not null)
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid Quote, must have customer assigned with Customer Job or Customer PO'
       goto error
       end
   
   -- validate Customer for Customer Quote Type
   select @validcnt=count(*) from inserted i join bARCM a with (nolock) on
       a.CustGroup=i.CustGroup and a.Customer=i.Customer and i.Customer is not null
   select @validcnt2=count(*) from inserted where QuoteType='C' and Customer is not null
   if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid Customer'
       goto error
       end
   
   -- validate Quote Unique for customer
   select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.CustGroup=i.CustGroup and a.Customer=i.Customer and
       isnull(a.CustPO,'')=isnull(i.CustPO,'') and isnull(a.CustJob,'')=isnull(i.CustJob,'')
       and a.Quote<>i.Quote and i.Customer is not null
   if @validcnt2 > 0
       begin
       select @errmsg = 'Quote must be unique for Customer/Job/PO combination'
       goto error
       end
   
   -- validate JC Company for Job Quote Type
   select @validcnt=count(*) from inserted i join bJCCO c with (nolock) on
       c.JCCo=i.JCCo and i.JCCo is not null and i.Job is not null
   select @validcnt2=count(*) from inserted where QuoteType='J'
   if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid JC Company'
       goto error
       end
   
   -- validate JC Job for Job Quote Type
   select @validcnt=count(*) from inserted i join bJCJM c with (nolock) on
       c.JCCo=i.JCCo and c.Job=i.Job and i.JCCo is not null and i.Job is not null
   if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid JC Job'
       goto error
       end
   
   -- validate Quote Unique for Job
   select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.JCCo=i.JCCo and a.Job=i.Job and a.Quote<>i.Quote and
       i.JCCo is not null and i.Job is not null
   if @validcnt2 > 0
       begin
       select @errmsg = 'Quote must be unique for JC Company/Job combination'
       goto error
       end
   
   -- validate IN Company for IN Quote Type
   select @validcnt=count(*) from inserted i join bINCO c with (nolock) on
       c.INCo=i.INCo and i.INCo is not null and i.Loc is not null
   select @validcnt2=count(*) from inserted where QuoteType='I'
   if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid IN Company'
       goto error
       end
   
   -- validate IN Location for IN Quote Type
   select @validcnt=count(*) from inserted i join bINLM c with (nolock) on
       c.INCo=i.INCo and c.Loc=i.Loc and i.INCo is not null and i.Loc is not null
   if @validcnt <> @validcnt2
       begin
       select @errmsg = 'Invalid IN Location'
       goto error
       end
   
   -- validate Quote Unique for Location
   select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.INCo=i.INCo and a.Loc=i.Loc and a.Quote<>i.Quote and
       i.INCo is not null and i.Loc is not null
   if @validcnt2 > 0
       begin
       select @errmsg = 'Quote must be unique for IN Company/Location combination'
       goto error
       end

---- validate country
select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.Country=c.Country
select @nullcnt = count(*) from inserted where Country is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end

---- validate state
select @validcnt = count(*) from dbo.bHQST s with (nolock)
	join inserted i on i.Country=s.Country and i.State=s.State
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.MSCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.State
	where i.Country is null and i.State is not null
----#140452
select @nullcnt = count(*) from inserted i where ISNULL(i.State,'') = ''
if @validcnt + @validcnt2 + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country/State combination'
	goto error
	end


-- Audit inserts
INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bMSQH',' Quote: ' + i.Quote, i.MSCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM inserted i join bMSCO c with (nolock) on c.MSCo = i.MSCo
where i.MSCo = c.MSCo and c.AuditQuotes = 'Y'


return


	error:
	SELECT @errmsg = @errmsg +  ' - cannot insert MS Quote!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**************************************************************/
CREATE trigger [dbo].[btMSQHu] on [dbo].[bMSQH] for UPDATE as
/*--------------------------------------------------------------
* Created By:  GF 03/30/2000
* Modified By: GG 09/27/00 - Added PrintLvl, SubtotalLvl, and SepHaul columns
*              GF 08/08/2001 - Added check for CustJob, CustPO not null if Customer is null
*				allenn 05/24/02 - Added check for UseUMMetricYN for issue 17381
*				GF 10/05/2003 - issue #18762 added pay terms validation
*				GF 12/04/2003 - issue #23147 changes for ansi nulls and isnull
*				GF 03/10/2008 - issue #127082 country and state validation
*				GF 03/25/2009 - issue #129409 added auditing for columns ApplyEscalators and BidIndexDate
*				DAN SO 09/02/2009 - Issue #135177 - added i.QuoteType='C' to @validcnt2
*
*
*  Update trigger for MSQH
*  Verify that quote is unique for quote type.
*  If status is changed from active to inactive, need to update
*  bMSQD and if status is active changed to completed and update
*  remaining allocated units.
*  If Quotes flagged for auditing, inserts HQ Master Audit entry .
*
*--------------------------------------------------------------*/
declare @numrows int, @validcnt int, @validcnt2 int, @nullcnt int, @msco bCompany,
		@opencursor tinyint, @active bYN, @oldactive bYN, @quote varchar(10),
		@errmsg varchar(255)
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   set @opencursor = 0
   
   -- check for key changes
   if UPDATE(MSCo)
       begin
       select @errmsg = 'MSCo may not be updated'
       goto error
       end
   
   if UPDATE(Quote)
       begin
       select @errmsg = 'Quote may not be updated'
       goto error
       end
   
   -- check CustJob, CustPO not null if customer is null
   select @validcnt=count(*) from inserted
   where QuoteType='C' and Customer is null and (CustJob is not null or CustPO is not null)
   if @validcnt > 0
       begin
       select @errmsg = 'Invalid Quote, must have customer assigned with Customer Job or Customer PO'
       goto error
       end
   
   -- validate Quote Type
   IF UPDATE(QuoteType)
   BEGIN
       select @validcnt = count(*) from inserted where QuoteType in ('C','J','I')
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Quote Type, must be (C,J,I)!'
           goto error
           end
   END


   -- validate Haul Tax Option
   IF UPDATE(HaulTaxOpt)
   BEGIN
       select @validcnt = count(*) from inserted where HaulTaxOpt in (0,1,2)
       IF @validcnt <> @numrows
           begin
           select @errmsg = 'Invalid Haul Tax Option, must be (0,1,2)!'
           goto error
           end
   END
   -- validate Price Templates
   IF UPDATE(PriceTemplate)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSTH c with (nolock) on
       c.MSCo = i.MSCo and c.PriceTemplate = i.PriceTemplate
       select @nullcnt = count(*) from inserted where PriceTemplate is null
       IF @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Price Template!'
           goto error
           end
   END
   -- validate Discount Templates
   IF UPDATE(DiscTemplate)
   BEGIN
       select @validcnt = count(*) from inserted i join bMSDH c with (nolock) on
       c.MSCo = i.MSCo and c.DiscTemplate = i.DiscTemplate
       select @nullcnt = count(*) from inserted where DiscTemplate is null
       IF @validcnt + @nullcnt <> @numrows
           begin
           select @errmsg = 'Invalid Discount Template!'
           goto error
           end
   END

   -- validate Customer Group
   IF UPDATE(CustGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g with (nolock) on g.Grp = i.CustGroup
       select @nullcnt = count(*) from inserted where CustGroup is null
       if @validcnt + @nullcnt <> @numrows
           begin
   	   select @errmsg = 'Invalid Customer Group'
   	   goto error
   	   end
   END
   -- validate Tax group
   IF UPDATE(TaxGroup)
   BEGIN
       select @validcnt = count(*) from inserted i join bHQGP g with (nolock) on g.Grp = i.TaxGroup
       select @nullcnt = count(*) from inserted where TaxGroup is null
       if @validcnt + @nullcnt <> @numrows
           begin
   	   select @errmsg = 'Invalid Tax Group'
   	   goto error
   	   end
   END
   -- validate Tax Code
   IF UPDATE(TaxCode)
   BEGIN
       select @validcnt=count(*) from inserted i join bHQTX h with (nolock) on h.TaxGroup=i.TaxGroup and h.TaxCode=i.TaxCode
       select @nullcnt=count(*) from inserted where TaxCode is null
       if @validcnt + @nullcnt <> @numrows
   	   begin
   	   select @errmsg = 'Invalid Tax Code'
   	   goto error
   	   end
   END
   
   -- validate PayTerms
   IF UPDATE(PayTerms)
   BEGIN
   	select @validcnt = count(*) from inserted i join bHQPT g with (nolock) on g.PayTerms = i.PayTerms
   	select @nullcnt = count(*) from inserted where PayTerms is null
   	if @validcnt + @nullcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Payment Terms'
   		goto error
   		end
   END
   
   -- validate Customer for Customer Quote Type
   IF UPDATE(Customer)
   BEGIN
       select @validcnt=count(*) from inserted i join bARCM a with (nolock) on
       a.CustGroup=i.CustGroup and a.Customer=i.Customer and i.Customer is not null
       --select @nullcnt=count(*) from inserted where Customer is null
       select @validcnt2=count(*) from inserted where QuoteType='C' and Customer is not null
       if @validcnt <> @validcnt2
           begin
           select @errmsg = 'Invalid Customer'
           goto error
           end
   END
   -- validate Quote Unique for customer
   IF UPDATE(Customer) or UPDATE(CustJob) OR UPDATE(CustPO)
   BEGIN
       select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.CustGroup=i.CustGroup and a.Customer=i.Customer and
       isnull(a.CustPO,'')=isnull(i.CustPO,'') and isnull(a.CustJob,'')=isnull(i.CustJob,'')
       and a.Quote<>i.Quote and i.Customer is not null
       if @validcnt2 > 0
           begin
           select @errmsg = 'Quote must be unique for Customer/Job/PO combination'
           goto error
           end
   END
   -- validate JC Company for Job Quote Type
   select @validcnt2=count(*) from inserted where QuoteType='J'
   IF UPDATE(JCCo)
   BEGIN
       select @validcnt=count(*) from inserted i join bJCCO c with (nolock) on
       c.JCCo=i.JCCo and i.JCCo is not null
       if @validcnt <> @validcnt2
           begin
           select @errmsg = 'Invalid JC Company'
           goto error
           end
   END
   -- validate JC Job for Job Quote Type
   IF UPDATE(Job)
   BEGIN
       select @validcnt=count(*) from inserted i join bJCJM c with (nolock) on
       c.JCCo=i.JCCo and c.Job=i.Job and i.JCCo is not null and i.Job is not null
       if @validcnt <> @validcnt2
           begin
           select @errmsg = 'Invalid JC Job'
           goto error
           end
   END
   -- validate Quote Unique for Job
   IF UPDATE(JCCo) OR UPDATE(Job)
   BEGIN
       select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.JCCo=i.JCCo and a.Job=i.Job and a.Quote<>i.Quote and
       i.JCCo is not null and i.Job is not null
       if @validcnt2 > 0
           begin
           select @errmsg = 'Quote must be unique for JC Company/Job combination'
           goto error
           end
   END
   -- validate IN Company for IN Quote Type
   select @validcnt2=count(*) from inserted where QuoteType='I'
   IF UPDATE(INCo)
   BEGIN
       select @validcnt=count(*) from inserted i join bINCO c with (nolock) on
       c.INCo=i.INCo and i.INCo is not null
       if @validcnt <> @validcnt2
           begin
           select @errmsg = 'Invalid IN Company'
           goto error
           end
   END
   -- validate IN Location for IN Quote Type
   IF UPDATE(Loc)
   BEGIN
       select @validcnt=count(*) from inserted i join bINLM c with (nolock) on
       c.INCo=i.INCo and c.Loc=i.Loc and i.INCo is not null and i.Loc is not null
       if @validcnt <> @validcnt2
           begin
           select @errmsg = 'Invalid IN Location'
           goto error
           end
   END
   -- validate Quote Unique for Location
   IF UPDATE(INCo) OR UPDATE(Loc)
   BEGIN
       select @validcnt2=count(*) from inserted i join bMSQH a with (nolock) on
       a.MSCo=i.MSCo and a.INCo=i.INCo and a.Loc=i.Loc and a.Quote<>i.Quote and
       i.INCo is not null and i.Loc is not null
       if @validcnt2 > 0
           begin
           select @errmsg = 'Quote must be unique for IN Company/Location combination'
           goto error
           end
   END


---- validate country
select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.Country=c.Country
select @nullcnt = count(*) from inserted where Country is null 
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country'
	goto error
	end

---- validate state - Issue: #135177
select @validcnt = count(*) from dbo.bHQST s with (nolock)
	join inserted i on i.Country=s.Country and i.State=s.State and i.QuoteType='C'
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.MSCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.State
	where i.Country is NULL and i.State is not NULL and i.QuoteType='C'
select @nullcnt = count(*) from inserted i where i.State is null or i.QuoteType <> 'C'
if @validcnt + @validcnt2 + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Country/State combination'
	goto error
	end






-- validate active flag
IF UPDATE(Active)
	BEGIN
	select @validcnt = count(*) from inserted where Active in ('Y','N')
	IF @validcnt <> @numrows
		begin
		select @errmsg = 'Active flag must be (Y) or (N)!'
		goto error
		end


	-- update status in bMSQD if 1-Active, set to 2-Completed if Active flag changed to 'N'
	-- use a cursor to process all updated rows
	begin
	declare msqh_cursor cursor LOCAL FAST_FORWARD
	for select i.MSCo, i.Quote, i.Active, d.Active
	from inserted i join deleted d on i.MSCo=d.MSCo and i.Quote=d.Quote

	open msqh_cursor
	set @opencursor = 1

	msqh_loop:
	fetch next from msqh_cursor into @msco, @quote, @active, @oldactive

	if @@fetch_status <> 0 goto msqh_close

	-- check if MSQD update needed
	if @active = 'Y' goto msqh_loop

	Update bMSQD set Status = 2
	where MSCo=@msco and Quote=@quote and Status = 1
	goto msqh_loop

	msqh_close:
	close msqh_cursor
	deallocate msqh_cursor
	set @opencursor = 0
	end
	END
   
   
   AuditInserts: -- Audit inserts
   IF UPDATE(QuoteType)
   	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Quote Type',  d.QuoteType,i.QuoteType, getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.QuoteType,'') <> isnull(i.QuoteType,'')
   
   IF UPDATE(CustGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Customer Group', convert(varchar(3),d.CustGroup), convert(varchar(3),i.CustGroup),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.CustGroup,'') <> isnull(i.CustGroup,'')
   
   IF UPDATE(Customer)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Customer', convert(varchar(8),d.Customer), convert(varchar(8),i.Customer),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Customer,0)<>isnull(i.Customer,0)
   
   IF UPDATE(CustJob)
    INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Customer Job',  d.CustJob,i.CustJob, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.CustJob,'')<>isnull(i.CustJob,'')
   
   IF UPDATE(CustPO)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Customer PO',  d.CustPO,i.CustPO, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.CustPO,'')<>isnull(i.CustPO,'')
   
   IF UPDATE(JCCo)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' JC Company', convert(varchar(3),d.JCCo), convert(varchar(3),i.JCCo),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.JCCo,0)<>isnull(i.JCCo,0)
   
   IF UPDATE(Job)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' JC Job',  d.Job,i.Job, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
   	JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Job,'')<>isnull(i.Job,'')
   
   IF UPDATE(INCo)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' IN Company', convert(varchar(3),d.INCo), convert(varchar(3),i.INCo),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.INCo,0)<>isnull(i.INCo,0)
   
   IF UPDATE(Loc)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' IN Location',  d.Loc,i.Loc, getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Loc,'')<>isnull(i.Loc,'')
   
   IF UPDATE(Description)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Description',  d.Description,i.Description, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Description,'')<>isnull(i.Description,'')
   
   IF UPDATE(Contact)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Contact',  d.Contact,i.Contact, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Contact,'')<>isnull(i.Contact,'')
   
   IF UPDATE(Phone)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Phone',  d.Phone,i.Phone, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Phone,'')<>isnull(i.Phone,'')
   
   IF UPDATE(ShipAddress)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Ship Address',  d.ShipAddress,i.ShipAddress, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.ShipAddress,'')<>isnull(i.ShipAddress,'')
   
   IF UPDATE(City)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' City',  d.City,i.City, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.City,'')<>isnull(i.City,'')
   
   IF UPDATE(State)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' State',  d.State,i.State, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.State,'')<>isnull(i.State,'')
   
   IF UPDATE(Zip)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Zip Code',  d.Zip,i.Zip, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Zip,'')<>isnull(i.Zip,'')
   
   IF UPDATE(ShipAddress2)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Ship Address2',  d.ShipAddress2,i.ShipAddress2, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.ShipAddress2,'')<>isnull(i.ShipAddress2,'')
   
   IF UPDATE(PriceTemplate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Price Template', convert(varchar(4),d.PriceTemplate), convert(varchar(4),i.PriceTemplate),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.PriceTemplate,0)<>isnull(i.PriceTemplate,0)
   
  
   IF UPDATE(DiscTemplate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Discount Template', convert(varchar(4),d.DiscTemplate), convert(varchar(4),i.DiscTemplate),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.DiscTemplate,0)<>isnull(i.DiscTemplate,0)
   
   IF UPDATE(TaxGroup)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Tax Group', convert(varchar(4),d.TaxGroup), convert(varchar(4),i.TaxGroup),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.TaxGroup,'') <> isnull(i.TaxGroup,'')
   
   IF UPDATE(TaxCode)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Tax Code',  d.TaxCode,i.TaxCode, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.TaxCode,'')<>isnull(i.TaxCode,'')
   
   IF UPDATE(HaulTaxOpt)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Haul Tax Option', convert(varchar(1),d.HaulTaxOpt), convert(varchar(1),i.HaulTaxOpt),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.HaulTaxOpt,'') <> isnull(i.HaulTaxOpt,'')
   
   IF UPDATE(Active)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Active',  d.Active,i.Active, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.Active,'') <> isnull(i.Active,'')
   
   IF UPDATE(QuotedBy)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Quote By',  d.QuotedBy,i.QuotedBy, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.QuotedBy,'')<>isnull(i.QuotedBy,'')
   
   IF UPDATE(QuoteDate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
    	' Quote Date', convert(varchar(30),d.QuoteDate), convert(varchar(30),i.QuoteDate),
       getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d  ON d.MSCo=i.MSCo  AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.QuoteDate,'')<>isnull(i.QuoteDate,'')
   
   IF UPDATE(ExpDate)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
    	' Expiration Date', convert(varchar(30),d.ExpDate), convert(varchar(30),i.ExpDate),
       getdate(), SUSER_SNAME()
   	FROM inserted i JOIN deleted d  ON d.MSCo=i.MSCo  AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.ExpDate,'')<>isnull(i.ExpDate,'')
   
   IF UPDATE(SepInv)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Separate Invoice',  d.SepInv,i.SepInv, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.SepInv,'') <> isnull(i.SepInv,'')
   
   IF UPDATE(BillFreq)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Bill Frequency',  d.BillFreq,i.BillFreq, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.BillFreq,'')<>isnull(i.BillFreq,'')
   
   IF UPDATE(PrintLvl)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Print Level',  convert(char(1),d.PrintLvl),convert(char(1),i.PrintLvl), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.PrintLvl,0)<>isnull(i.PrintLvl,0)
   
   IF UPDATE(SubtotalLvl)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Subtotal Level',  convert(char(1),d.SubtotalLvl),convert(char(1),i.SubtotalLvl), getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.SubtotalLvl,0)<>isnull(i.SubtotalLvl,0)
   
   IF UPDATE(SepHaul)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Separate Haul Info',  d.SepHaul,i.SepHaul, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.SepHaul,'')<>isnull(i.SepHaul,'')
   
   IF UPDATE(MiscDistCode)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Misc Distribution Code', d.MiscDistCode,i.MiscDistCode, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.MiscDistCode,'')<>isnull(i.MiscDistCode,'')
   
   IF UPDATE(PayTerms)
       INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
       ' Pay Terms:', d.PayTerms,i.PayTerms, getdate(), SUSER_SNAME()
       FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
       JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
       WHERE isnull(d.PayTerms,'')<>isnull(i.PayTerms,'')

if Update(Country)
	begin
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
	' Country:', d.Country,i.Country, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
	JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
	WHERE isnull(d.Country,'')<>isnull(i.Country,'')
	end

IF UPDATE(ApplyEscalators)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
	'Apply Escalators',  d.ApplyEscalators,i.ApplyEscalators, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d ON d.MSCo=i.MSCo AND d.Quote=i.Quote
	JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
	WHERE isnull(d.ApplyEscalators,'')<>isnull(i.ApplyEscalators,'')

IF UPDATE(BidIndexDate)
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bMSQH', 'MS Co#: ' + convert(varchar(3), i.MSCo) + ' Quote: ' + i.Quote, i.MSCo, 'C',
	'Bid Index Date', convert(varchar(30),d.BidIndexDate), convert(varchar(30),i.BidIndexDate),
	getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.MSCo=i.MSCo  AND d.Quote=i.Quote
	JOIN bMSCO with (nolock) ON i.MSCo=bMSCO.MSCo and bMSCO.AuditQuotes='Y'
	WHERE isnull(d.BidIndexDate,'')<>isnull(i.BidIndexDate,'')




return
   
   
   error:
      select @errmsg = @errmsg + ' - cannot update into MSQH'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
  
 



GO
ALTER TABLE [dbo].[bMSQH] WITH NOCHECK ADD CONSTRAINT [CK_bMSQH_Active] CHECK (([Active]='Y' OR [Active]='N'))
GO
ALTER TABLE [dbo].[bMSQH] WITH NOCHECK ADD CONSTRAINT [CK_bMSQH_Purge] CHECK (([PurgeYN]='Y' OR [PurgeYN]='N'))
GO
ALTER TABLE [dbo].[bMSQH] WITH NOCHECK ADD CONSTRAINT [CK_bMSQH_SepHaul] CHECK (([SepHaul]='Y' OR [SepHaul]='N'))
GO
ALTER TABLE [dbo].[bMSQH] WITH NOCHECK ADD CONSTRAINT [CK_bMSQH_SepInv] CHECK (([SepInv]='Y' OR [SepInv]='N'))
GO
ALTER TABLE [dbo].[bMSQH] WITH NOCHECK ADD CONSTRAINT [CK_bMSQH_UseUMMetricYN] CHECK (([UseUMMetricYN]='Y' OR [UseUMMetricYN]='N'))
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bMSQH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biMSQH] ON [dbo].[bMSQH] ([MSCo], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSQHCustomer] ON [dbo].[bMSQH] ([MSCo], [QuoteType], [CustGroup], [Customer], [CustJob], [CustPO], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSQHLocation] ON [dbo].[bMSQH] ([MSCo], [QuoteType], [INCo], [Loc], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biMSQHJob] ON [dbo].[bMSQH] ([MSCo], [QuoteType], [JCCo], [Job], [Quote]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
