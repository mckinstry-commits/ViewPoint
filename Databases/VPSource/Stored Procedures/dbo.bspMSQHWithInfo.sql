SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE   PROC [dbo].[bspMSQHWithInfo]
/***********************************************************
* Created By:  GF 11/14/2000
* Modified By: GG 07/03/01 - add hierarchal Quote search  - #13888
*				GF 11/06/2003 - issue #18762 - use MSQH.PayTerms if not null else ARCM.PayTerms
*				GF 03/11/2008 - issue #127082 add country output
*
* USAGE:   This SP gets quote information for a customer/Job/PO.
*          Used in MS InvEdit
*
* INPUT PARAMETERS
*  MS Company, Customer Group, Customer, Customer Job, Customer PO
*
* OUTPUT PARAMETERS
*  Quote, Description, ShipAddress, City, State, Zip, Address2,
*  PrintLevel, SubtotalLevel, SepHaul
*  @msg      error message if error occurs
* RETURN VALUE
*   0         Success
*   1         Failure
*****************************************************/
   (@msco bCompany = null, @custgroup tinyint = null, @customer bCustomer = null,
    @custjob varchar(20) = null, @custpo varchar(20) = null, @quote varchar(10) output,
    @description bDesc output,  @shipaddress varchar(60) output, @shipaddress2 varchar(60) output,
    @city varchar(30) output, @state varchar(4) output, @zip bZip output, @printlvl char(1) output,
    @subtotallvl char(1) output, @sephaul bYN output, @payterms bPayTerms output, 
	@country char(2) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @arcm_payterms bPayTerms, @msqh_payterms bPayTerms
   
   select @rcode = 0
   
   if @msco is null
     	begin
   	select @msg = 'Missing Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @custgroup is null
       begin
       select @msg = 'Missing Customer Group!', @rcode = 1
       goto bspexit
       end
   
   if @customer is null
       begin
       select @msg = 'Missing Customer', @rcode = 1
       goto bspexit
       end
   
   -- get customer info
   select @printlvl=PrintLvl, @subtotallvl=SubtotalLvl, @sephaul=SepHaul, @arcm_payterms=PayTerms
   from bARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
   
   -- get quote info
   select @quote=Quote, @description=Description, @shipaddress=ShipAddress, @city=City,
          @state=State, @zip=Zip, @shipaddress2=ShipAddress2, @printlvl=PrintLvl,
          @subtotallvl=SubtotalLvl, @sephaul=SepHaul, @msqh_payterms=PayTerms,
		  @country=Country
   from bMSQH with (nolock) 
   where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
       and isnull(CustJob,'') = isnull(@custjob,'') and isnull(CustPO,'') = isnull(@custpo,'')
   if @@rowcount = 0
       begin
       -- if Quote not found at Cust PO level, check at Cust Job level
       select @quote=Quote, @description=Description, @shipaddress=ShipAddress, @city=City,
          @state=State, @zip=Zip, @shipaddress2=ShipAddress2, @printlvl=PrintLvl,
          @subtotallvl=SubtotalLvl, @sephaul=SepHaul, @msqh_payterms=PayTerms,
		  @country=Country
       from bMSQH with (nolock) 
       where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
           and isnull(CustJob,'') = isnull(@custjob,'') and CustPO is null
       if @@rowcount = 0
           begin
           -- if Quote not found at Cust Job level, check at Customer level
           select @quote=Quote, @description=Description, @shipaddress=ShipAddress, @city=City,
               @state=State, @zip=Zip, @shipaddress2=ShipAddress2, @printlvl=PrintLvl,
               @subtotallvl=SubtotalLvl, @sephaul=SepHaul, @msqh_payterms=PayTerms,
				@country=Country
           from bMSQH with (nolock)
           where MSCo=@msco and QuoteType='C' and CustGroup=@custgroup and Customer=@customer
               and CustJob is null and CustPO is null
--           if @@rowcount = 0
--               begin
--               select @msg = 'Missing quote', @rcode = 1
--               goto bspexit
--               end
           end
       end
   
   
   set @payterms = isnull(@msqh_payterms, @arcm_payterms)
   
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQHWithInfo] TO [public]
GO
