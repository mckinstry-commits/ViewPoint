SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROC [dbo].[bspMSPriceFindQuoteGet]
   /***********************************************************
    * Created By:  GF 11/03/2000
    * Modified By: GF 07/02/2001 - add hierarchal Quote search  - #13888
    *				GF 11/06/2003 - issue #18762 - use MSQH.PayTerms if not null else ARCM.PayTerms
*					GF 03/12/2008 - issue #127082 change state to varchar(4)
    *
    * USAGE:   This SP gets quote and template information
    *          for use in MSPriceFind.
    *
    * INPUT PARAMETERS
    *  MS Company, Sale Type, Customer Group, Customer, Customer Job,
    *  Customer PO, JCCo, Job, INCo, To Location, From Location
    *
    * OUTPUT PARAMETERS
    *  Quote
    *  Description
    *  Contact
    *  ShipTo Address
    *  Status
    *  Phone
    *  City
    *  Quoted by
    *  State
    *  Zip
    *  Quoted Date
    *  Expiration Date
    *  Discount Template
    *  Price Template
    *  @msg      error message if error occurs
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *****************************************************/
   (@msco bCompany = null, @custtype varchar(1) = null, @custgroup tinyint = null,
    @customer bCustomer = null, @custjob varchar(20) = null, @custpo varchar(20) = null,
    @jcco bCompany = null, @job bJob = null, @inco bCompany = null, @loc bLoc = null,
    @quote varchar(10) output, @quotedesc bDesc output, @contact bDesc output,
    @shipto bItemDesc output, @status bDesc output, @phone bPhone output, @city bDesc output,
    @quotedby bDesc output, @state varchar(4) output, @zip bZip output, @quotedate bDate output,
    @expdate bDate output, @disctemplate smallint output, @pricetemplate smallint output,
    @payterms bPayTerms output, @msg varchar(255) output)
   
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @arcm_payterms bPayTerms, @msqh_payterms bPayTerms
   
   select @rcode = 0, @status = null, @payterms = null
   
   if @msco is null
     	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @custtype is null
       begin
       select @msg = 'Missing Sales Type!', @rcode = 1
       goto bspexit
       end
   
   
   -- get quote and templates for customer sales type
   if @custtype = 'C'
   BEGIN
       if @custgroup is null or @customer is null goto bspexit
       -- look in ARCM first
       select @disctemplate=DiscTemplate, @pricetemplate=PriceTemplate, @arcm_payterms=PayTerms
       from bARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
       -- look for quote overrides - Customer/CustJob/CustPO
       select @quote=Quote, @quotedesc=Description, @contact=Contact, @phone=Phone,
              @shipto=ShipAddress, @city=City, @state=State, @zip=Zip, @disctemplate=DiscTemplate,
              @pricetemplate=PriceTemplate, @quotedby=QuotedBy, @quotedate=QuoteDate,
              @expdate=ExpDate, @status = case Active when 'Y' then 'Active' else 'Inactive' end,
   		   @msqh_payterms=PayTerms
       from bMSQH with (nolock)
       where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
   	and isnull(CustJob,'')=isnull(@custjob,'') and isnull(CustPO,'')=isnull(@custpo,'')
   	if @@rowcount = 0
   		begin
   	    -- look for quote overrides - Customer/CustJob
   	    select @quote=Quote, @quotedesc=Description, @contact=Contact, @phone=Phone,
   	           @shipto=ShipAddress, @city=City, @state=State, @zip=Zip, @disctemplate=DiscTemplate,
   	           @pricetemplate=PriceTemplate, @quotedby=QuotedBy, @quotedate=QuoteDate,
   	           @expdate=ExpDate, @status = case Active when 'Y' then 'Active' else 'Inactive' end,
   			   @msqh_payterms=PayTerms
   	    from bMSQH with (nolock)
   	    where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
   		and isnull(CustJob,'')=isnull(@custjob,'') and CustPO is null
   	    if @@rowcount = 0
   			begin
   		    -- look for quote overrides - Customer
   		    select @quote=Quote, @quotedesc=Description, @contact=Contact, @phone=Phone,

   		           @shipto=ShipAddress, @city=City, @state=State, @zip=Zip, @disctemplate=DiscTemplate,
   		           @pricetemplate=PriceTemplate, @quotedby=QuotedBy, @quotedate=QuoteDate,
   		           @expdate=ExpDate, @status = case Active when 'Y' then 'Active' else 'Inactive' end,
   				   @msqh_payterms=PayTerms
   		    from bMSQH with (nolock)
   		    where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
   		    and CustJob is null and CustPO is null
   			if @@rowcount = 0 goto bspexit
   			end
   		end
   	
   	set @payterms = isnull(@msqh_payterms, @arcm_payterms)
       goto bspexit
   END
   
   
   -- get quote and templates for job sales type
   if @custtype = 'J'
   BEGIN
       if @jcco is null or @job is null goto bspexit
       -- look in JCJM first
       select @pricetemplate=PriceTemplate from bJCJM with (nolock) where JCCo=@jcco and Job=@job
       -- look for quote overrides
       select @quote=Quote, @quotedesc=Description, @contact=Contact, @phone=Phone,
              @shipto=ShipAddress, @city=City, @state=State, @zip=Zip, @pricetemplate=PriceTemplate,
              @quotedby=QuotedBy, @quotedate=QuoteDate, @expdate=ExpDate,
              @status = case Active when 'Y' then 'Active' else 'Inactive' end
       from bMSQH with (nolock)
       where MSCo=@msco and QuoteType='J' and JCCo=@jcco and Job=@job
       goto bspexit
   END
   
   
   -- get quote and templates for location sales type
   if @custtype = 'I'
   BEGIN
       if @inco is null or @loc is null goto bspexit
       -- look in INLM first
       select @pricetemplate=PriceTemplate from bINLM with (nolock) where INCo=@inco and Loc=@loc
       -- look for quote overrides
       select @quote=Quote, @quotedesc=Description, @contact=Contact, @phone=Phone,
              @shipto=ShipAddress, @city=City, @state=State, @zip=Zip, @pricetemplate=PriceTemplate,
              @quotedby=QuotedBy, @quotedate=QuoteDate, @expdate=ExpDate,
              @status = case Active when 'Y' then 'Active' else 'Inactive' end
       from bMSQH with (nolock)
       where MSCo=@msco and QuoteType='I' and INCo=@inco and Loc=@loc
       goto bspexit
   END
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSPriceFindQuoteGet] TO [public]
GO
