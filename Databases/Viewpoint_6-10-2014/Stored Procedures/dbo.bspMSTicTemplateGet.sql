SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[bspMSTicTemplateGet]
/***********************************************************
 * Created By:  GF 07/11/2000
 * Modified By: GG 01/24/01 - initialized output parameters as null
 *              GF 07/02/2001 -  add hierarchal Quote search  - #13888
 *              GF 08/03/2001 - fix for null quote tax code - use purchaser
 *				GF 11/05/2003 - issue #18762 - use MSQH.PayTerms if quote exists and PayTerms not null
 *				GF 03/03/2008 - issue #127261 - added output parameter HQPT.DiscOpt
 *
 *
 * USAGE:   This SP gets default quote, discount, price templates,
 *          haul tax option, and purchaser tax code for use in MS TicEntry
 *
 * INPUT PARAMETERS
 *  @msco           MS Company
 *  @salestype      Sales Type (C/J/I)
 *  @custgroup      Customer Group
 *  @customer       Customer #
 *  @custjob        Customer Job
 *  @custpo         Customer PO
 *  @jcco           JC Company
 *  @job            Job
 *  @inco           Sell To IN Company
 *  @loc            Sell To Location
 *  @fromloc        Sell From Location
 *
 * OUTPUT PARAMETERS
 * @quote			MS Quote
 * @disctemplate	Discount Template
 * @pricetemplate	Price Template
 * @zone			Zone
 * @haultaxopt		Haul Tax Option
 * @taxcode			Purchaser Tax Code
 * @payterms		Payment Terms
 * @matldisc		HQPT Material Discount Flag
 * @discrate		HQPT Discount Rate
 * @discopt			HQPT Discount Option
 * @msg				error message if error occurs
 *
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *****************************************************/
(@msco bCompany = null, @salestype varchar(1) = null, @custgroup tinyint = null,
 @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
 @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @loc bLoc = null,
 @fromloc bLoc = null, @quote varchar(10) = null output, @disctemplate smallint = null output,
 @pricetemplate smallint = null output, @zone varchar(10) = null output, @haultaxopt tinyint = null output,
 @taxcode bTaxCode = null output, @payterms bPayTerms = null output, @matldisc bYN output,
 @discrate bPct = null output, @discopt tinyint = null output, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @validcnt int, @purchdisctemplate smallint, @purchpricetemplate smallint,
		@purchhaultaxopt tinyint, @purchtaxcode bTaxCode, @arcm_payterms bPayTerms,
   		@msqh_payterms bPayTerms

select @rcode = 0, @discopt = 3

if @msco is null
	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto bspexit
   	end

if @salestype is null
	begin
	select @msg = 'Missing Sales Type!', @rcode = 1
	goto bspexit
	end

---- get quote and templates for customer sales type
if @salestype = 'C'
   BEGIN
	if @custgroup is null or @customer is null goto bspexit
	---- look in ARCM first
	select @purchdisctemplate=DiscTemplate, @purchpricetemplate=PriceTemplate,
              @purchhaultaxopt=HaulTaxOpt, @purchtaxcode=TaxCode, @arcm_payterms=PayTerms
	from ARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
	---- look for quote overrides - Customer, CustJob, CustPO
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
	from MSQH with (nolock) 
	where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
	and isnull(CustJob,'')=isnull(@custjob,'') and isnull(CustPO,'')=isnull(@custpo,'') and Active='Y'
	if @@rowcount <> 0 goto gethaulzone
	-- look for quote overrides - Customer, CustJob
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
	from MSQH with (nolock) 
	where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
           and isnull(CustJob,'')=isnull(@custjob,'') and CustPO is null and Active='Y'
	if @@rowcount <> 0 goto gethaulzone
	-- look for quote overrides - Customer
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
	from MSQH with (nolock) 
	where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
	and CustJob is null and CustPO is null and Active='Y'
	goto gethaulzone
   END

---- get quote and templates for job sales type
if @salestype = 'J'
	BEGIN
	if @jcco is null or @job is null goto bspexit
	---- look in JCJM first
	select @purchpricetemplate=PriceTemplate, @purchhaultaxopt=HaulTaxOpt, @purchtaxcode=TaxCode
	from JCJM with (nolock) where JCCo=@jcco and Job=@job
	---- look for quote overrides
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from MSQH with (nolock) where MSCo=@msco and QuoteType='J' and JCCo=@jcco and Job=@job and Active='Y'
	goto gethaulzone
	END

---- get quote and templates for location sales type
if @salestype = 'I'
	BEGIN
	if @inco is null or @loc is null goto bspexit
	---- look in INLM first
	select @purchpricetemplate=PriceTemplate, @purchhaultaxopt=HaulTaxOpt, @purchtaxcode=TaxCode
	from INLM with (nolock) where INCo=@inco and Loc=@loc
	---- look for quote overrides
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from MSQH with (nolock) where MSCo=@msco and QuoteType='I' and INCo=@inco and Loc=@loc and Active='Y'
	goto gethaulzone
	END

gethaulzone: ---- get haul zone
if @quote is not null and @fromloc is not null
	begin
	select @zone=Zone
	from MSZD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc
	end

---- check for quote overrides
if @salestype = 'C'
	begin
	if @taxcode is null set @taxcode = @purchtaxcode
	if @disctemplate is null set @disctemplate = @purchdisctemplate
	if @pricetemplate is null set @pricetemplate = @purchpricetemplate
	if @haultaxopt is null set @haultaxopt = @purchhaultaxopt
   	set @payterms = isnull(@msqh_payterms, @arcm_payterms)
   	select @matldisc=MatlDisc, @discrate=DiscRate, @discopt=DiscOpt
	from HQPT with (nolock) where PayTerms=@payterms
   	if @@rowcount = 0
		begin
		select @matldisc = 'N', @discrate = null, @discopt = 3
		end
	end

if @salestype = 'J'
	begin
	if @taxcode is null set @taxcode = @purchtaxcode
	if @pricetemplate is null set @pricetemplate = @purchpricetemplate
	if @haultaxopt is null set @haultaxopt = @purchhaultaxopt
	end

if @salestype = 'I'
	begin
	if @taxcode is null set @taxcode = @purchtaxcode
	if @pricetemplate is null set @pricetemplate = @purchpricetemplate
	if @haultaxopt is null set @haultaxopt = @purchhaultaxopt
	end




bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicTemplateGet] TO [public]
GO
