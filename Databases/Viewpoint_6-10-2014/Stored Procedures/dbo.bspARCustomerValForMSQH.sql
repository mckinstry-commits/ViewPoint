SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROC [dbo].[bspARCustomerValForMSQH]
   /***********************************************************
    * Created By:  GF 12/19/2000
    * Modified By:  TJL 03/06/08 - Issue #127077, International Addresses
    *
    * USAGE:
    * 	Validates Customer
    *	Returns Name, Phone, Contact for Customer
    *
    * INPUT PARAMETERS
    *   Company	Company
    *   CustGroup	Customer Group
    *   Customer	Customer to validate
    *
    * OUTPUT PARAMETERS
    *  @Phone         ARCM.Phone
    *  @Contact       ARCM.Contact
    *  @custoutput    An output of bspARCustomerVal
    *  @pricetemplate
    *  @disctemplate
    *  @shipaddress
    *  @shipaddress2
    *  @shipcity
    *  @shipstate
    *  @shipzip
    *  @msg      		error message if error occurs, or ARCM.Name
    * RETURN VALUE
    *   0	Success
    *   1	Failure
   *****************************************************/
   (@Company bCompany, @CustGroup bGroup = null, @Customer bSortName = null,
    @Phone bPhone = null output, @Contact varchar(30) = null output, @custoutput bCustomer = null output,
    @pricetemplate smallint output, @disctemplate smallint output, @shipaddress varchar(60) output,
    @shipaddress2 varchar(60) output, @shipcity varchar(30) output, @shipstate varchar(4) output,
    @shipzip bZip output, @shipcountry char(2) output, @msg varchar(60) = null output)
   as
   set nocount on
   
   declare @rcode int, @option char(1)
   
   select @rcode = 0, @option = null
   
   if @Company is null
       begin
      	select @msg = 'Missing Company!', @rcode = 1
      	goto bspexit
      	end
   
   if @CustGroup is null
       begin
      	select @msg = 'Missing Customer Group!', @rcode = 1
      	goto bspexit
      	end
   
   if @Customer is null
       begin
      	select @msg = 'Missing Customer!', @rcode = 1
      	goto bspexit
      	end
   
   exec @rcode =  bspARCustomerVal @CustGroup, @Customer, @option, @custoutput output, @msg output
   if @rcode = 1 goto bspexit
   
   -- Need to get other customer info
   select @Phone=Phone, @Contact=Contact, @msg=Name, @pricetemplate=PriceTemplate, @disctemplate=DiscTemplate,
          @shipaddress=Address, @shipaddress2=Address2, @shipcity=City, @shipstate=State, @shipzip=Zip, @shipcountry=Country
   from ARCM with (nolock) where CustGroup = @CustGroup and Customer = @custoutput
   
   bspexit:
       if @rcode<>0 select @msg=@msg	--+ char(13) + char(10) + '[bspARCustomerValForMSQH]'
      	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARCustomerValForMSQH] TO [public]
GO
