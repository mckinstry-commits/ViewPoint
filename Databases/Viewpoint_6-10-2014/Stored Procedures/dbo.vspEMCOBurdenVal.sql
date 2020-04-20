SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[vspEMCOBurdenVal] 
/************************************************
*Created By TV 12/7/05
*
*Validates Burden type against Burden Rate and 
*Addon Rate
*If Burden Type = A-Burden Rate must be 0
*If Burden Type = R-AddonRate must be 0
*
*************************************************/
(@burdentype char(1), @burdenrate bRate, @addonrate bRate, @errmsg varchar(255)output)

as

set nocount on 

declare @rcode int 

select @rcode = 0

if @burdentype = 'A' and @burdenrate <> 0
	begin 
	select @errmsg = 'Invalid Burden Rate,  must be 0.00 when Burden Type is A.', @rcode = 1
	goto vspexit
	end

if @burdentype = 'R' and @addonrate <> 0
	begin 
	select @errmsg = 'Invalid Addon Rate,  must be 0.00 when Burden Type is R.', @rcode = 1
	goto vspexit
	end


vspexit:

if @rcode <> 0 select @errmsg=isnull(@errmsg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspEMCOBurdenVal] TO [public]
GO
