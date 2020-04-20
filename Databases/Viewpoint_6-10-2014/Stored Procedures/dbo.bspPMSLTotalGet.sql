SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        proc [dbo].[bspPMSLTotalGet]
/********************************************************
* Created By:   GF 04/17/2000
* Modified By:  GF 11/24/2000 Restrict to not include pending c.o.
*				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
*
* USAGE:
* Retrieves the total cost for a Subcontract in PM.
* The total for a subcontract is the sum of the current cost in SLIT,
* and the sum of the non-interfaced detail from PMSL.
* Does not include backcharge items, PMSL records that have been
* interfaced, PMSL records flagged to not send, and PMSL change order
* records that are pending only.
*
* INPUT PARAMETERS:
* PMCo,Project,SLCo,SL
*
* OUTPUT PARAMETERS:
* Total subcontract amount for item types (1)Regular, (2)Change, and (4)Addon.
* Error Message, if one
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@pmco bCompany = null, @project bJob = null, @slco bCompany = null,
 @sl VARCHAR(30) = null, @amount bDollar output, @msg varchar(255) output)
as
set nocount on

declare @rcode int
   
    select @rcode = 0
   
    if @pmco is null
    	begin
    	select @msg = 'Missing SL Company', @rcode = 1
    	goto bspexit
    	end
   
    if @project is null
    	begin
    	select @msg = 'Missing Project', @rcode = 1
    	goto bspexit
    	end
   
    if @slco is null
    	begin
    	select @msg = 'Missing SL Company', @rcode = 1
    	goto bspexit
    	end
   
    if @sl is null
    	begin
    	select @msg = 'Missing Subcontract', @rcode = 1
    	goto bspexit
    	end
   
    select @amount = 0
   
   -- add in SLIT items
   select @amount = isnull(sum(CurCost),0) from bSLIT with (nolock) 
   where SLCo=@slco and SL=@sl and ItemType in (1,2,4)
   
   -- add in PMSL items
   select @amount=isnull(@amount,0) + isnull(sum(Amount),0) 
   from bPMSL with (nolock) 
   where PMCo=@pmco and SLCo=@slco and SL=@sl --and Project=@project
   and SLItemType in (1,2,4) and SendFlag='Y' and InterfaceDate is null
   and ((RecordType='O' and ACO is null) or (RecordType='C' and ACO is not null))
   
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMSLTotalGet] TO [public]
GO
