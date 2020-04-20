SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMPAVal    Script Date: 8/28/99 9:35:15 AM ******/
CREATE  proc [dbo].[bspPMPAVal]
/*************************************
* CREATED BY:	GF 10/30/98
* MODIFIED By:	GG 04/22/99    (SQL 7.0)
*				GF 03/21/2003 - Added total type to output parameters
*				GF 10/30/2003 - issue #22769 added Include to output parameters
*				GF 02/28/2008 - issue #127195 and #127210 add-on percent and basis cost type
*
* validates PMPA Addons
*
* Pass:
*	Company
*	Project
*   Addon
* Returns:
*	@Basis
*	@Percent
*	@Amount
* @totaltype
* @include
* @netcalclevel
* @basiscosttype
*
*	@msg error message if error occurs otherwise Description of Contract Item
* RETURN VALUE
*   0         success
*   1         Failure
**************************************/
(@PMCo bCompany = 0, @Project bJob = null, @Addon tinyint = 0, @Basis char(1) output,
 @Percent numeric(12,8) output, @Amount bDollar output, @totaltype varchar(1) output, 
 @include bYN output, @netcalclevel varchar(1) output, @basiscosttype bJCCType output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @PMCo is null
   	begin
   	select @msg = 'Missing PM Company!', @rcode = 1
   	goto bspexit
   	end

if @Project is null
   	begin
   	select @msg = 'Missing Project!', @rcode = 1
   	goto bspexit
   	end

if @Addon = 0
   	begin
   	select @msg = 'Missing AddOn Number!', @rcode = 1
   	goto bspexit
   	end

---- get defaults from the PMPA Project AddOn values
select @msg = Description, @Basis = Basis, @Percent = Pct, @Amount = Amount,
		@totaltype=TotalType, @include = Include, @netcalclevel = NetCalcLevel,
		@basiscosttype=BasisCostType
from PMPA with (nolock) where PMCo = @PMCo and Project = @Project and AddOn = @Addon
if @@rowcount = 0
   	begin
   	select @msg = 'Project addon not on file!', @rcode = 1
   	goto bspexit
   	end





bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMPAVal] TO [public]
GO
