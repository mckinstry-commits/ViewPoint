SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
CREATE   PROC [dbo].[bspMSHaulLineInfoGet]
/***********************************************************
 * Created By:  GF 12/22/2000
 * Modified By: GF 01/07/2001
 *              GF 07/02/2001 - Changed quote find to look for quote using hierarchical levels #13888
 *				GF 11/05/2003 - issue #18762 - use MSQH.PayTerms if quote exists and PayTerms not null
 *
 * USAGE:   This SP gets needed information for use in MS HaulEntryLines
 *
 * INPUT PARAMETERS
 *  MS Company, Sales Type, Customer Group, Customer, Customer Job,
 *  Customer PO, JCCo, Job, INCo, To Location, Loc Group, From Location,
 *  Matl Group, Material, Phase Group
 *
 * OUTPUT PARAMETERS
 *  MS Quote
 *  Discount Template
 *  Price Template
 *  Zone
 *  Haul Tax Option
 *  Purchaser Tax Code
 *  Quote Haul Phase
 *  Quote Haul Cost Type
 *	Pay Terms
 * @matldisc		HQPT Material Discount Flag
 * @discrate		HQPT Discount Rate
 *  @msg      error message if error occurs
 * RETURN VALUE
 *   0         Success
 *   1         Failure
 *****************************************************/
(@msco bCompany = null, @saletype varchar(1) = null, @custgroup tinyint = null,
 @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
 @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @toloc bLoc = null,
 @locgroup bGroup = null, @fromloc bLoc = null, @matlgroup bGroup = null, @material bMatl = null,
 @phasegroup bGroup = null, @quote varchar(10) output, @disctemplate smallint output,
 @pricetemplate smallint output, @zone varchar(10) output, @haultaxopt tinyint output,
 @taxcode bTaxCode output, @haulphase bPhase output, @haulct bJCCType output, 
 @payterms bPayTerms output, @matldisc bYN output, @discrate bPct = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @validcnt int, @category varchar(10), @tmphaulphase bPhase,
   		@tmphaulct bJCCType, @tmpmatlphase bPhase, @tmpmatlct bJCCType, @tmpmsg varchar(255),
   		@arcm_payterms bPayTerms, @msqh_payterms bPayTerms

select @rcode = 0, @payterms = null

if @msco is null
	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto bspexit
   	end

---- get quote and templates for customer sales type
if @saletype = 'C'
	begin
	if @custgroup is null or @customer is null goto bspexit
	---- look in ARCM first
	select @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @arcm_payterms=PayTerms
	from ARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
	---- look for quote overrides - Customer, CustJob, CustPO
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
	from MSQH with (nolock) where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
	and isnull(CustJob,'')=isnull(@custjob,'') and isnull(CustPO,'')=isnull(@custpo,'') and Active='Y'
   	if @@rowcount = 0
		begin
		---- look for quote overrides - Customer, CustJob
   	    select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
   	           @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
   	    from MSQH with (nolock) where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
   	    and isnull(CustJob,'')=isnull(@custjob,'') and CustPO is null and Active='Y'
   		if @@rowcount = 0
   			begin
   		    ---- look for quote overrides - Customer
   		    select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
   		           @haultaxopt=HaulTaxOpt, @taxcode=TaxCode, @msqh_payterms=PayTerms
   		    from MSQH with (nolock) where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
   		    and CustJob is null and CustPO is null and Active='Y'
   			if @@rowcount = 0 goto gethaulzone
   			end
   		end

	select @payterms = isnull(@msqh_payterms, @arcm_payterms)
   	select @matldisc=MatlDisc, @discrate=DiscRate
	from HQPT with (nolock) where PayTerms=@payterms
   	if @@rowcount = 0
		begin
		select @matldisc = 'N', @discrate = null
		end
   	goto gethaulzone
	end


-- get quote and templates for job sales type
if @saletype = 'J'
	begin
	if @jcco is null or @job is null goto bspexit
	---- look in JCJM first
	select @pricetemplate=PriceTemplate, @haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from JCJM with (nolock) where JCCo=@jcco and Job=@job
	---- look for quote overrides
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
              @haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from MSQH with (nolock) where MSCo=@msco and QuoteType='J' and JCCo=@jcco and Job=@job and Active='Y'
	goto gethaulzone
	end

---- get quote and templates for location sales type
if @saletype = 'I'
	begin
	if @inco is null or @toloc is null goto bspexit
	--- look in INLM first
	select @pricetemplate=PriceTemplate, @haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from INLM with (nolock) where INCo=@inco and Loc=@toloc
	---- look for quote overrides
	select @quote=Quote, @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate,
			@haultaxopt=HaulTaxOpt, @taxcode=TaxCode
	from MSQH with (nolock) where MSCo=@msco and QuoteType='I' and INCo=@inco and Loc=@toloc and Active='Y'
	goto gethaulzone
	end



gethaulzone: ---- get haul zone
if @quote is not null and @fromloc is not null
	begin
	select @zone=Zone
	from MSZD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc
	end

---- get material category
select @category=Category
from HQMT with (nolock) where MatlGroup=@matlgroup and Material=@material

---- get haul phase and cost type from quote for Sales Type = (J)ob
if @quote is not null and @saletype = 'J'
	begin
	if @locgroup is not null and @category is not null and @phasegroup is not null
		begin
		exec @retcode = bspMSTicMatlPhaseGet @msco,@matlgroup,@material,@category,@locgroup,
                           @fromloc,@phasegroup,@quote,@tmpmatlphase output,@tmpmatlct output,
                           @tmphaulphase output,@tmphaulct output, @tmpmsg output
		if @retcode = 0
			begin
			select @haulphase=@tmphaulphase, @haulct=@tmphaulct
			end
		end
	end






bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSHaulLineInfoGet] TO [public]
GO
