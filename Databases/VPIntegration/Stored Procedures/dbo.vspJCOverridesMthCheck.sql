SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJCOverridesMthCheck    Script Date: 8/28/99 9:34:44 AM ******/
CREATE procedure [dbo].[vspJCOverridesMthCheck]
/******************************************************
* Created By:	GF 01/25/2008 - issue #123528 
* Last Modified:
*
* USAGE: Used in JC Override projections to verify if month is open and display warning if not.
*
*
* calls bspGLMonthVal to validate a month - must be after
* last mth closed in GL and before or equal to last
* mth closed in subledgers + max open mths
*
* pass in GL Co#, and Month
* output closed month flag
* returns 0 if successfull, 1 and error msg if error
*******************************************************/
(@jcco bCompany, @glco bCompany, @mth bMonth, @closed_flag bYN = 'N' output,
 @msg varchar(60) output)
as 
set nocount on

declare @rcode int

select @rcode = 0, @closed_flag = 'N'

---- exit if missing values
if @jcco is null goto bspexit
if @glco is null goto bspexit
if @mth is null goto bspexit

---- verify month is in JCOverrides
----if not exists(select JCCo from JCOverrides where JCCo=@jcco and Month=@mth)
----	begin
----	select @msg = 'Invalid Month', @rcode = 1
----	goto bspexit
----	end

---- execute bspGLMonthVal for open month
exec @rcode = dbo.bspGLMonthVal @glco, @mth, @msg output
if @rcode <> 0
	begin
	select @closed_flag = 'Y', @rcode = 0
	goto bspexit
	end

select @rcode = 0


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCOverridesMthCheck] TO [public]
GO
