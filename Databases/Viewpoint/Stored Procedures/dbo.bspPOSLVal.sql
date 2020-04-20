SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPOSLVal]
   /***********************************************************
    * CREATED BY	: SE 4/9/97
    * MODIFIED BY	: SE 4/9/97
    *                GF 01/05/2001 - Added Tax code to output params
    *				  RT 08/20/03 - Issue #21582, add Address2 to output.
	*				DC 03/07/08 - Issue #127075:  Modify PO/RQ  for International addresses
	*
    *
    * USAGE:
    * validates PO shipping location.
    * an error is returned if can't find Location, otherwise description
    *
    * INPUT PARAMETERS
    *   POCo      PO Co to validate against
    *   ShipLoc   Shipping location
    *
    * OUTPUT PARAMETERS
    *   @Address  Address
    *   @City     City
    *   @State    State
    *   @Zip      Zip
    *   @taxcode  TaxCode
    *   @Address2 Additional Address
    *   @msg      error message if error occurs otherwise Description of Location
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State, and Zip are ''
    *****************************************************/
   (@poco bCompany = 0, @shiploc varchar(10), @address varchar(60) output,
    @city varchar(30) output, @state varchar(4) output, @zip bZip output,
    @taxcode bTaxCode = null output, @address2 varchar(60) output, 
	@country varchar(2) output,  --DC #127075
	@msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 1, @address='', @city='', @state='', @zip='', @address2='',
          @msg='Shipping Location ' + @shiploc + ' not setup.'
   
   select @rcode=0, @msg=isnull(Description,''), @address = isnull(Address,''),
          @city=isnull(City,''), @state=isnull(State,''), @zip=isnull(Zip,''),
          @taxcode=TaxCode, @address2=isnull(Address2,''),
		  @country=isnull(Country,'') --DC #127075
   from POSL where POCo=@poco and ShipLoc=@shiploc
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOSLVal] TO [public]
GO
