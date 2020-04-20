SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************************************/
   CREATE   proc [dbo].[bspMSQuoteCopy]
   /****************************************************************************
   * Created By:   GF 05/09/2000
   * Modified By:  GG 05/22/00 - changed source type input parameter
   *               GF 10/05/2000 - additional columns
   *               GF 08/09/2001 - Fix for Haul codes MSHX was not checking the correct copy flag.
   *				GF 01/09/2002 - Issue #19910 - set tocustjob, tocustpo to null if empty. Bullet proofing.
   *				DC 5/09/03 - Issue 21179 - Quote copy copies all header info regardless if customer number is changed.
   *				GF 11/05/2003 - issue #18762 - added MSQH.PayTerms to quote copy.
   *				GF 03/15/2004 - issue #24036 - added MSQO haul code overrides to quote copy
   *				GF 03/11/2008 - issue #127082 - added MSQH.Country to copy
   *				DAN SO 06/09/2008 - issue 128003 - added PayMinAmt to bMSPX insert statement
   *				GP 06/12/2008 - Issue #127986 - added VendorGroup, MatlVendor, and UnitCost to
   *									bMSQD insert statement.
   *				TRL 03/03/2010 Issue 129350 add copy option for MSSurcharges
   *				GF 03/12/2010 - issue #138542 added escalation factor, surcharge group to MSQH copy
   *				GF 08/23/2012 TK-17337 option to copy HSQH custom fields
   *
   *
   * USAGE:
   * 	Copies Quote header and quote detail tables.
   *   Restricts to company and quote.
   *
   * INPUT PARAMETERS:
   *   MSCompany, QuoteType, QuoteSource, FromCustomer, FromCustomerJob,
   *   FromCustomerPO, FromJCCo, FromJob, FromINCo, FromLocation, FromQuote,
   *   ToCustomer, ToCustomerJob, ToCustomerPO, ToJCCo, ToJob, ToINCo, ToLocation,
   *   ToQuote, MSQDYN, MSMDYN, MSDXYN, MSHXYN, MSZDYN, MSPXYN, MSQHNotes, CustGroup
   *
   * OUTPUT PARAMETERS:
   *	None
   *
   * RETURN VALUE:
   * 	0 	    Success
   *	1 & message Failure
   *
   *****************************************************************************/
   (@msco bCompany = null, @quotetype varchar(1) = null, @quotesrc varchar(1) = null,
    @fromcust bCustomer = null, @fromcustjob varchar(20) = null, @fromcustpo varchar(20) = null,
    @fromjcco bCompany = null, @fromjob bJob = null, @frominco bCompany = null,
    @fromloc bLoc = null, @fromquote varchar(10) = null, @tocust bCustomer = null,
    @tocustjob varchar(20) = null, @tocustpo varchar(20) = null, @tojcco bCompany = null,
    @tojob bJob = null, @toinco bCompany = null, @toloc bLoc = null, @toquote varchar(10) = null,
    @msqdyn bYN = 'Y', @msmdyn bYN = 'Y', @msdxyn bYN = 'Y', @mshxyn bYN = 'Y', @mszdyn bYN = 'Y',
    @mspxyn bYN = 'Y', @msqhnotes bYN = 'Y', @custgroup bGroup = null, @mshoyn bYN = 'Y',
    ----TK-17337
    @mssurcharges bYN = 'Y', @MSQHMemos CHAR(1) = 'Y',
    @msg varchar(255) output)
   
as
set nocount on
   
declare @rcode integer, @initcount int, @validcnt int, @srcquote varchar(10),
		@tocustcontact varchar(30),@tocustphone  bPhone,@tocustadd varchar(60),
		@tocustcity varchar(30), @tocuststate varchar(4), @tocustzip bZip,
		@tocustadd2 varchar(60), @phasegroup bGroup, @tocustcountry varchar(2)
		----TK-0000
		,@MSQH_UDFlag CHAR(1), @QuoteCreated CHAR(1), @Joins VARCHAR(MAX), @Where VARCHAR(MAX)


select @rcode=0, @initcount=0, @validcnt=0

---- TK-17337 set the user memo flag for the MSQH table if any exist
SET @MSQH_UDFlag = 'N'
if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bMSQH'))
	BEGIN
  	SET @MSQH_UDFlag = 'Y'
	END
	
   -- issue #19910 - possible blanks instead of null for to values
   if @tocustjob is not null
   	begin
   	if ltrim(rtrim(@tocustjob)) = '' select @tocustjob = null
   	end
   
   if @tocustpo is not null
   	begin
   	if ltrim(rtrim(@tocustpo)) = '' select @tocustpo = null
   	end
   
   if @tojob is not null
   	begin
   	if ltrim(rtrim(@tojob)) = '' select @tojob = null
   	end
   
   if @toloc is not null
   	begin
   	if ltrim(rtrim(@toloc)) = '' select @toloc = null
   	end
   
   if @msco is null
   	begin
   	select @msg = 'Missing MS Company number!', @rcode = 1
   	goto bspexit
   	end
   
   if @custgroup is null
       begin
       select @msg = 'Missing customer group!', @rcode = 1
       goto bspexit
       end
   
   if @quotetype not in ('C','I','J')
       begin
       select @msg = 'Invalid Quote Type!', @rcode = 1
       goto bspexit
       end
   
   if @quotesrc not in ('1','2')
       begin
       select @msg = 'Invalid source, must be (Q)uote or (T)ype!', @rcode = 1
       goto bspexit
       end
   
   -- check source variables
   if @quotesrc = '1'
       begin
       select @srcquote = @fromquote
       if @fromquote is null
           begin
           select @msg = 'Missing source quote!', @rcode = 1
           goto bspexit
           end
       select @validcnt=count(*) from dbo.MSQH with (nolock) where MSCo=@msco and QuoteType=@quotetype and Quote=@fromquote
       if @validcnt = 0
           begin
           select @msg = 'Source quote not found!', @rcode =1
           goto bspexit
           end
       end
   
   if @quotesrc = '2'
       begin
       if @quotetype = 'C'
           begin
           if @fromcust is null
               begin
               select @msg = 'Missing source customer!', @rcode = 1
               goto bspexit
               end
           select @srcquote=min(Quote) from dbo.MSQH with (nolock)
           where MSCo=@msco and QuoteType=@quotetype and CustGroup=@custgroup
           and Customer=@fromcust and CustJob=@fromcustjob and CustPO=@fromcustpo
           if @@rowcount = 0
               begin
               select @msg = 'Source customer/job/po not found!', @rcode = 1
               goto bspexit
               end
           end
       if @quotetype = 'J'
           begin
           if @fromjcco is null
               begin
               select @msg = 'Missing source JC company!', @rcode = 1
               goto bspexit
               end
           if @fromjob is null
               begin
               select @msg = 'Missing source Job!', @rcode = 1
               goto bspexit
               end
           select @srcquote=min(Quote) from dbo.MSQH with (nolock)
           where MSCo=@msco and QuoteType=@quotetype and JCCo=@fromjcco and Job=@fromjob
           if @@rowcount = 0
               begin
               select @msg = 'Source jc company/job not found!', @rcode = 1
               goto bspexit
               end
           end
       if @quotetype = 'I'
           begin
               if @frominco is null
               begin
               select @msg = 'Missing source IN company!', @rcode = 1
               goto bspexit
               end
           if @fromloc is null
               begin
               select @msg = 'Missing source IN location!', @rcode = 1
               goto bspexit
               end
   
           select @srcquote=min(Quote)from dbo.MSQH with (nolock)
           where MSCo=@msco and QuoteType=@quotetype and INCo=@frominco and Loc=@fromloc
           if @@rowcount = 0
               begin
               select @msg = 'Source in company/location not found!', @rcode = 1
               goto bspexit
               end
           end
       end
   
   -- check destination variables
   if @srcquote is null
       begin
       select @msg = 'Unable to locate source quote!', @rcode = 1
       goto bspexit
       end
   
   select @validcnt=count(*) from dbo.MSQH with (nolock) where MSCo=@msco and Quote=@toquote
   if @validcnt <> 0
       begin
       select @msg = 'Invalid destination quote, in use!', @rcode = 1
       goto bspexit
       end
   
   if @quotetype = 'C'
       begin
       if @tocust is null
           begin
           select @msg = 'Missing destination customer!', @rcode = 1
           goto bspexit
           end
       select @validcnt=count(*) from dbo.MSQH with (nolock) where MSCo=@msco and QuoteType=@quotetype
       and CustGroup=@custgroup and Customer=@tocust and CustJob=@tocustjob
       and CustPO=@tocustpo
       if @validcnt <> 0
           begin
           select @msg = 'Invalid destination customer/job/po, in use!', @rcode = 1
           goto bspexit
           end
       end
   if @quotetype = 'J'
       begin
       if @tojcco is null
           begin
           select @msg = 'Missing destination JC company!', @rcode = 1
           goto bspexit
           end
       if @tojob is null
           begin
           select @msg = 'Missing destination Job!', @rcode = 1
           goto bspexit
           end
       select @validcnt=count(*) from dbo.MSQH with (nolock)
       where MSCo=@msco and QuoteType=@quotetype and JCCo=@tojcco and Job=@tojob
       if @validcnt <> 0
           begin
           select @msg = 'Invalid destination JC company/job, in use!', @rcode = 1
           goto bspexit
           end
       end
   if @quotetype = 'I'
       begin
       if @toinco is null
           begin
           select @msg = 'Missing destination IN company!', @rcode = 1
           goto bspexit
           end
       if @toloc is null
           begin
           select @msg = 'Missing destination IN location!', @rcode = 1
           goto bspexit
           end
       select @validcnt=count(*) from dbo.MSQH with (nolock)
       where MSCo=@msco and QuoteType=@quotetype and INCo=@toinco and Loc=@toloc
       if @validcnt <> 0
           begin
           select @msg = 'Invalid destination IN company/location, in use!', @rcode = 1
           goto bspexit
           end
       end
   
   -- verify that none of the to fields are empty
   if isnull(@tocust,'') = '' select @tocust = null
   if isnull(@tocustjob,'') = '' select @tocustjob = null
   if isnull(@tocustpo,'') = '' select @tocustpo = null
   if isnull(@tojob,'') = '' select @tojob = null
   if isnull(@toloc,'') = '' select @toloc = null
   
--DC Issue 21179 ----------Start -----------------------------

select @tocustcontact = Contact, @tocustphone = Phone,@tocustadd = Address,
		@tocustcity = City, @tocuststate = State, @tocustzip = Zip,
		@tocustadd2 = Address2, @tocustcountry = Country
from ARCM with (nolock)
where CustGroup = @custgroup and Customer = @tocust
   
   --DC Issue 21179 ----------End -----------------------------
   
   if @quotetype = 'J'
   	select @phasegroup=PhaseGroup from dbo.HQCO with (nolock)where HQCo=@tojcco
   else
   	set @phasegroup = null

----TK-17337
SET @QuoteCreated = 'N'

-- start copy Quote process
begin transaction
-- copy Quote header MSQH
if @msqhnotes='N'
	begin
	---- #138542
	insert into dbo.MSQH(MSCo,Quote,QuoteType,CustGroup,Customer,CustJob,CustPO,JCCo,
			Job,INCo,Loc,Description,Contact,Phone,ShipAddress,City,State,Zip,ShipAddress2,
			PriceTemplate,DiscTemplate,TaxGroup,TaxCode,HaulTaxOpt,Active,QuotedBy,
			QuoteDate,ExpDate,SepInv,BillFreq,PrintLvl,SubtotalLvl,SepHaul,MiscDistCode,PurgeYN,Notes, 
			UseUMMetricYN, PayTerms, Country, ApplyEscalators, BidIndexDate, ApplySurchargesYN, 
			SurchargeGroup, EscalationFactor)
	select @msco,@toquote,@quotetype,@custgroup,@tocust,@tocustjob,@tocustpo,@tojcco,
			@tojob,@toinco,@toloc,a.Description,@tocustcontact,@tocustphone,@tocustadd,@tocustcity,@tocuststate,
			@tocustzip,@tocustadd2,a.PriceTemplate,a.DiscTemplate,a.TaxGroup,a.TaxCode,a.HaulTaxOpt,
			a.Active,null,null,null,a.SepInv,a.BillFreq,a.PrintLvl,a.SubtotalLvl,a.SepHaul,
			a.MiscDistCode,'N',Null, isnull(a.UseUMMetricYN,'N'), a.PayTerms, @tocustcountry,
			a.ApplyEscalators, a.BidIndexDate, a.ApplySurchargesYN, a.SurchargeGroup, a.EscalationFactor
	---- #138542
	from dbo.MSQH a with (nolock) where a.MSCo=@msco and a.Quote=@srcquote
	if @@rowcount = 0
		begin
		select @msg = 'Unable to insert MSQH record, copy aborted!', @rcode=1
		rollback
		goto bspexit
		END
	----TK-17337
	SET @QuoteCreated = 'Y'
	end
Else
	begin
	---- #138542
	insert into dbo.MSQH(MSCo,Quote,QuoteType,CustGroup,Customer,CustJob,CustPO,JCCo,
			Job,INCo,Loc,Description,Contact,Phone,ShipAddress,City,State,Zip,ShipAddress2,
			PriceTemplate,DiscTemplate,TaxGroup,TaxCode,HaulTaxOpt,Active,QuotedBy,
			QuoteDate,ExpDate,SepInv,BillFreq,PrintLvl,SubtotalLvl,SepHaul,MiscDistCode,PurgeYN,Notes,
			UseUMMetricYN, PayTerms, Country, ApplyEscalators, BidIndexDate, ApplySurchargesYN, 
			SurchargeGroup, EscalationFactor)
	select @msco,@toquote,@quotetype,@custgroup,@tocust,@tocustjob,@tocustpo,@tojcco,
			@tojob,@toinco,@toloc,a.Description,@tocustcontact,@tocustphone,@tocustadd,@tocustcity,@tocuststate,
			@tocustzip,@tocustadd2,a.PriceTemplate,a.DiscTemplate,a.TaxGroup,a.TaxCode,a.HaulTaxOpt,
			a.Active,null,null,null,a.SepInv,a.BillFreq,a.PrintLvl,a.SubtotalLvl,a.SepHaul,
			a.MiscDistCode,'N', a.Notes, isnull(a.UseUMMetricYN,'N'), a.PayTerms, @tocustcountry,
			a.ApplyEscalators, a.BidIndexDate, a.ApplySurchargesYN, a.SurchargeGroup, a.EscalationFactor
	---- #138542
	from dbo.MSQH a with (nolock) where a.MSCo=@msco and a.Quote=@srcquote
	if @@rowcount = 0
		begin
		select @msg = 'Unable to insert MSQH record, copy aborted!', @rcode=1
		rollback
		goto bspexit
		END
	----TK-17337
	SET @QuoteCreated = 'Y'
	end

----TK-17337 if quote create and has user memos then copy the user memos to new quote
IF @QuoteCreated = 'Y' AND @MSQH_UDFlag = 'Y' AND @MSQHMemos = 'Y'
	BEGIN
	-- build joins and where clause
	SELECT @Joins = ' FROM MSQH JOIN MSQH z on z.MSCo = ' + convert(varchar(3),@msco)
					+ ' AND z.Quote = ' + CHAR(39) + @srcquote + CHAR(39)
	SELECT @Where = ' WHERE MSQH.MSCo = ' + convert(varchar(3),@msco) 
					+ ' AND MSQH.Quote = ' + CHAR(39) + @toquote + CHAR(39)
	-- execute user memo update
	exec @rcode = dbo.bspPMProjectCopyUserMemos 'MSQH', @Joins, @Where, @msg output
	END
	

   -- copy quote detail
   if @msqdyn = 'Y'
       begin
       insert into dbo.MSQD(MSCo, Quote, FromLoc, MatlGroup, Material, UM, QuoteUnits, UnitPrice,
   			ECM, ReqDate, Status, OrderUnits, SoldUnits, AuditYN, Notes, Seq, PhaseGroup, Phase,
			VendorGroup, MatlVendor, UnitCost)
       select @msco, @toquote, a.FromLoc, a.MatlGroup, a.Material, a.UM, 0, a.UnitPrice,
   			a.ECM, null, 0, 0, 0, 'Y', a.Notes, a.Seq, 
   			case when @quotetype = 'J' then @phasegroup else null end, 
   			case when @quotetype = 'J' then a.Phase else null end,
			a.VendorGroup, a.MatlVendor, a.UnitCost
       from dbo.MSQD a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   -- copy quote material pricing
   if @msmdyn = 'Y'
       begin
       insert into dbo.MSMD(MSCo, Quote, Seq, LocGroup, Loc, MatlGroup, Category, UM, Rate,
   			UnitPrice, ECM, MinAmt, PhaseGroup, Phase)
       select @msco, @toquote, a.Seq, a.LocGroup, a.Loc, a.MatlGroup, a.Category, a.UM, a.Rate,
   			a.UnitPrice, a.ECM, a.MinAmt, 
   			case when @quotetype = 'J' then @phasegroup else null end, 
   			case when @quotetype = 'J' then a.Phase else null end
       from dbo.MSMD a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   -- copy quote discounts
   if @msdxyn = 'Y'
       begin
       insert into dbo.MSDX(MSCo, Quote, Seq, LocGroup,Loc,MatlGroup,Category,Material,UM,PayDiscRate)
       select @msco,@toquote,a.Seq,a.LocGroup,a.Loc,a.MatlGroup,a.Category,a.Material,a.UM,a.PayDiscRate
       from dbo.MSDX a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   -- copy quote haul codes
   if @mshxyn = 'Y'
       begin
       insert into dbo.MSHX(MSCo, Quote, Seq, LocGroup, FromLoc, MatlGroup, Category,Material,
           TruckType, UM, HaulCode) -- --, Override, HaulRate, MinAmt)
       select @msco, @toquote, a.Seq, a.LocGroup, a.FromLoc, a.MatlGroup, a.Category, a.Material,
           a.TruckType, a.UM, a.HaulCode -- --,a.Override,a.HaulRate,a.MinAmt
       from dbo.MSHX a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   -- copy quote haul zones
   if @mszdyn = 'Y'
       begin
       insert into dbo.MSZD(MSCo,Quote,FromLoc,Zone)
       select @msco,@toquote,a.FromLoc,a.Zone
       from dbo.MSZD a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   if @mspxyn = 'Y'
       begin
       insert into dbo.MSPX(MSCo,Quote,Seq,LocGroup,FromLoc,MatlGroup,Category,Material,
           TruckType,VendorGroup,Vendor,Truck,UM,PayCode,Override,PayRate, PayMinAmt)
       select @msco,@toquote,a.Seq,a.LocGroup,a.FromLoc,a.MatlGroup,a.Category,a.Material,
           a.TruckType,a.VendorGroup,a.Vendor,a.Truck,a.UM,a.PayCode,a.Override,a.PayRate, a.PayMinAmt
       from dbo.MSPX a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   if @mshoyn = 'Y'
       begin
       insert into dbo.MSHO(MSCo, Quote, Seq, LocGroup, FromLoc, MatlGroup, Category,Material,
   			TruckType, UM, HaulCode, HaulRate, MinAmt, PhaseGroup, Phase)
       select @msco, @toquote, a.Seq, a.LocGroup, a.FromLoc, a.MatlGroup, a.Category, a.Material,
   			a.TruckType, a.UM, a.HaulCode, a.HaulRate, a.MinAmt,
   			case when @quotetype = 'J' then @phasegroup else null end, 
   			case when @quotetype = 'J' then a.Phase else null end
       from dbo.MSHO a with(nolock) where a.MSCo=@msco and a.Quote=@srcquote
       end
       /*129350*/
   	   if @mssurcharges = 'Y'
       begin
       insert into dbo.MSSurchargeOverrides(MSCo, Quote, Seq, LocGroup, FromLoc, MatlGroup, Category,Material,
   			TruckType, UM, PayCode,SurchargeCode,SurchargeRate,MinAmt)
   	  select @msco, @toquote, a.Seq, a.LocGroup, a.FromLoc, a.MatlGroup, a.Category, a.Material,
   			a.TruckType, a.UM, a.PayCode, a.SurchargeCode,a.SurchargeRate, a.MinAmt
       from dbo.MSSurchargeOverrides a with(nolock)  where a.MSCo=@msco and a.Quote=@srcquote
       end
   
   commit transaction
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteCopy] TO [public]
GO
