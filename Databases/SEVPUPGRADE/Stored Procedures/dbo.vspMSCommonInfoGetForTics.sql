SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*********************************************************/
CREATE proc [dbo].[vspMSCommonInfoGetForTics]
/***********************************************************
 * Created By:  GF 06/20/2007 6.x
 * Modified By:	GF 06/23/2008 - issue #128290 international tax
 *
 *
 *
 *
 * USAGE:
 * Gets MS company info for use in MS Ticket Entry program.
 *
 * Returns success, or error
 *
 * INPUT PARAMETERS
 * @msco - MS Company to use to get company info
 *
 * OUTPUT PARAMETERS
 * @apco				AP Co#
 * @arco				AR Co#
 * @glco				GL Co#
 * @taxopt				Tax default option
 * @ticwarn				Duplicate ticket # warning option
 * @limitchk			Check Customer limit with Ticket entry
 * @ticmatlvendor		Display Material Vendor on Ticket Entry form
 * @ticweights			Display Weights on Ticket Entry form
 * @ticemployee			Display Employee on Ticket Entry form
 * @ticdriver			Display Driver on Ticket Entry form
 * @tictimes			Display Start and Stop Times on Ticket Entry form
 * @ticloads			Display Loads on Ticket Entry form
 * @ticmiles			Display Miles on Ticket Entry form
 * @tichrs				Display Hours on Ticket Entry form
 * @ticzone				Display Zone on Ticket Entry form
 * @ticrev				Display EM Revenue info on Ticket Entry form
 * @ticpay				Display Hauler Pay info on Ticket Entry form
 * @tictax				Display Tax inputs on Ticket Entry form
 * @ticdisc				Display Discount inputs on Ticket Entry form
 * @ticreason			Display reason code on ticket entry form
 * @taxgroup			Tax Group assigned in bHQCO
 * @vendorgroup			Vendor Group assigned in bHQCO
 * @custgroup			Customer Group assigned in bHQCO
 * @matlgroup			Material Group assigned in bHQCO
 * @disctaxyn			Using Tax discounts
 * @autoapplycash		Auto Apply Payments to Cash Invoices
 * @intercoinv			MS Inter Company Invoice flag YN
 * @country				HQCO Country Code
 *
 *
 *	@errmsg				Error message
 *
 * RETURN VALUE
 *   0 - Success
 *   1 - Failure
 *
*****************************************************/
(@msco bCompany = 0, @apco bCompany output, @arco bCompany output, @glco bCompany output,
 @taxopt tinyint output, @ticwarn tinyint output, @limitchk bYN output, @ticmatlvendor bYN output,
 @ticweights bYN output, @ticemployee bYN output, @ticdriver bYN output, @tictimes bYN output,
 @ticloads bYN output, @ticmiles bYN output, @tichrs bYN output, @ticzone bYN output,
 @ticrev bYN output, @ticpay bYN output, @tictax bYN output, @ticdisc bYN output,
 @ticreason bYN output, @taxgroup tinyint output, @vendorgroup tinyint output,
 @custgroup tinyint output, @matlgroup tinyint output, @disctaxyn bYN output,
 @autoapply bYN output, @intercoinv bYN output, @country varchar(2) output,
 @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @inglco bCompany

select @rcode = 0

if @msco is null
	begin
   	select @errmsg = 'Missing MS Company!', @rcode = 1
   	goto bspexit
   	end

---- get MS company info
select @apco=APCo, @arco=ARCo, @glco=GLCo, @ticwarn=TicWarn, @limitchk=LimitChk,
		@ticmatlvendor=TicMatlVendor, @ticweights=TicWeights, @ticemployee=TicEmployee,
		@ticdriver=TicDriver, @tictimes=TicTimes, @ticloads=TicLoads, @ticmiles=TicMiles,
		@tichrs=TicHrs, @ticzone=TicZone, @ticrev=TicRev, @ticpay=TicPay, @tictax=TicTax,
		@ticdisc=TicDisc, @ticreason=TicReason, @taxopt=TaxOpt, @autoapply=AutoApplyCash,
		@intercoinv=InterCoInv
from MSCO with (nolock) where MSCo=@msco
if @@rowcount = 0
	begin
	select @errmsg = 'MS Company ' + convert(varchar(3), @msco) + ' is not setup!', @rcode = 1
	goto bspexit
	end

---- check APCo
if not exists(select 1 from APCO with (nolock) where APCo = @apco)
	begin
	select @errmsg = 'Unable to get AP Company Info!', @rcode = 1
	goto bspexit
	end

---- get AR Company Info
select @disctaxyn = DiscTax from ARCO with (nolock) where ARCo=@arco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to get AR Company Info!', @rcode = 1
	goto bspexit
	end

---- get IN Company GLCo
select @inglco = GLCo from INCO with (nolock) where INCo = @msco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to get IN Company Info!', @rcode = 1
	goto bspexit
	end

---- compare INCo.GLCo to MSCo.GLCo, must be same
if @inglco <> @glco
	begin
	select @errmsg = 'Inventory GL company does not match Material Sales GL company!', @rcode = 1
	goto bspexit
	end

---- get tax and material groups
select @taxgroup = TaxGroup, @matlgroup = MatlGroup, @country=DefaultCountry
from HQCO with (nolock) where HQCo = @msco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to get HQ Company Info!', @rcode = 1
	goto bspexit
	end
if @taxgroup is null
	begin
	select @errmsg = 'Tax group not setup for company ' + convert(varchar(3),isnull(@msco,'')) + '!', @rcode = 1
	goto bspexit
	end
if @matlgroup is null
	begin
	select @errmsg = 'Material group not setup for company ' + convert(varchar(3),isnull(@msco,'')) + '!', @rcode=1
	goto bspexit
	end

---- get vendor group
select @vendorgroup = VendorGroup from HQCO with (nolock) where HQCo = @apco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to get HQ Vendor Group!', @rcode = 1
	goto bspexit
	end
if @vendorgroup is null
	begin
	select @errmsg = 'Vendor group not setup for company ' + convert(varchar(3),isnull(@apco,'')) + '!', @rcode=1
	goto bspexit
	end

---- get customer group
select @custgroup = CustGroup from bHQCO with (nolock) where HQCo = @arco
if @@rowcount <> 1
	begin
	select @errmsg = 'Unable to get HQ Customer Group!', @rcode = 1
	goto bspexit
	end
if @custgroup is null
	begin
	select @errmsg = 'Customer group not setup for company ' + convert(varchar(3),isnull(@arco,'')) + '!', @rcode=1
	goto bspexit
	end



bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSCommonInfoGetForTics] TO [public]
GO
