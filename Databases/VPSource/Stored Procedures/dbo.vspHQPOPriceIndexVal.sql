SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQPOPriceIndexVal]
/*************************************
* Created by:  TRL 03/12/09 Issue 129049
* Modified by: JVH 8/18/09 Issue 135030 Change price index to not be an output parameter and @state to varchar(4)
*
* validates HQ Escalation Price Index
*
* Passes: Country, State, Price Index
*
* Success returns:	0 and Description from bHQMT
*
* Error returns:
*	1 and error message
**************************************/
(@country varchar(2) = null, @state varchar(4) = null, @priceindex varchar(20)=null, @errmsg varchar(255) output)

as 
 
set nocount on

declare @rcode int

select @rcode = 0
   	
if IsNull(@country,'') = ''
begin
	select @errmsg = 'Missing Country', @rcode = 1
	goto vspexit
end

if IsNull(@state,'') =''
begin
	select @errmsg = 'Missing State', @rcode = 1
	goto vspexit
end

if IsNull(@priceindex,'') =''
begin
	select @errmsg = 'Missing Escalation Price Index', @rcode = 1
	goto vspexit
end

select @errmsg = Description from dbo.HQPO with(nolock) 
where Country = @country and State = @state and PriceIndex=@priceindex
if @@rowcount = 0
begin
	select @errmsg = 'Invalid Escalation Price Index', @rcode = 1
end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQPOPriceIndexVal] TO [public]
GO
