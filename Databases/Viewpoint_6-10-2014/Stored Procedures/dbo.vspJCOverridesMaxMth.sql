SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCOverridesMaxMth    Script Date: 8/28/99 9:34:44 AM ******/
CREATE procedure [dbo].[vspJCOverridesMaxMth]
/******************************************************
* Created By:	GF 02/18/2008 - issue #123528 
* Last Modified:
*
* USAGE: Called from the AfterFormLoad event in JC Override projections to get the maximum
* month to use as the initial default month after form loads. From either JCOP or JCOR.
*
* INPUTS:
* JC Company
* 
* output maximum month from JCOR or JCOP
* returns 0 if successfull, 1 and error msg if error
*******************************************************/
(@jcco bCompany, @maxmonth bMonth = null output, @msg varchar(255) output)
as 
set nocount on

declare @rcode int, @jcop_mth bMonth, @jcor_mth bMonth

select @rcode = 0, @maxmonth = null

---- exit if missing JCCo
if @jcco is null goto bspexit

---- get max month from JCOP
select @jcop_mth = max(Month) from JCOP with (nolock) where JCCo=@jcco
if @@rowcount = 0 select @jcop_mth = null
---- get max month from JCOR
select @jcor_mth = max(Month) from JCOR with (nolock) where JCCo=@jcco
if @@rowcount = 0 select @jcor_mth = null

if @jcor_mth is null and @jcop_mth is null goto bspexit

if @jcor_mth is null and @jcop_mth is not null
	begin
	select @maxmonth = @jcop_mth
	goto bspexit
	end

if @jcop_mth is null and @jcor_mth is not null
	begin
	select @maxmonth = @jcor_mth
	goto bspexit
	end

if @jcop_mth < @jcor_mth
	begin
	select @maxmonth = @jcor_mth
	end
else
	begin
	select @maxmonth = @jcop_mth
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCOverridesMaxMth] TO [public]
GO
