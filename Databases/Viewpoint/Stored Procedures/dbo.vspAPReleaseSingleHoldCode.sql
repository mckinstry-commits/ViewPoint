SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspAPReleaseSingleHoldCode]
/***********************************************************
* CREATED:		MV 03/10/09 - #127179 
* MODIFIED: 
*			
* USAGE:
* This procedure is called from AP Pay Workfile header and detail
* It releases a single hold code from a transaction.
* If there is more than one hold code or it is a retainage hold code
* it returns a conditional error so the form can launch Additional Pay Control Functions.
*
*  INPUT PARAMETERS
*   @apco	AP company number
*   @mth	expense month of trans (null for all)
*   @trans	transaction to restrict by (null for all)
*   @line	line to restrict by (null for all)
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0   success
*   1   fail
**************************************************************/
	( @apco bCompany = 0,@mth bMonth, @aptrans bTrans,
      @apline smallint = null, @msg varchar(200) output)
          
as
set nocount on

declare @rcode int,@retholdcode bHoldCode

select @rcode=0

if @apline = 0 select @apline = null
     
-- select retainage pay type and hold code from bAPCO
select @retholdcode = RetHoldCode
from dbo.bAPCO (nolock) where APCo=@apco


/* validate inputs */
if @apco is null
	begin
	select @msg = 'Missing APCo!', @rcode=1
	goto vspExit
	end
if @mth is null
	begin
	select @msg = 'Missing Month!', @rcode=1
	goto vspExit
	end
if @apco is null
	begin
	select @msg = 'Missing AP Trans!', @rcode=1
	goto vspExit
	end



--get retainage holdcode
select @retholdcode = RetHoldCode from dbo.APCO (NOLOCK) where APCo=@apco

--Release for all lines
if @apline is null 
begin
	-- check for retainage holdcode on lines  
	if exists (select * from dbo.APHD
			where APCo=@apco and Mth=@mth and APTrans=@aptrans
			and HoldCode=@retholdcode)
	begin
	select @rcode=5
	goto vspExit
	end
	-- check for more than one holdcode on lines
	if exists(select count(*)
			from dbo.APHD  
			where APCo=@apco and Mth=@mth and APTrans=@aptrans
			group by APCo, Mth, APTrans,APLine
			having count (*) > 1)
		begin
		select @rcode=5
		goto vspExit
		end
	else
		begin
		--delete single hold code for all lines
		delete from dbo.APHD
		where APCo=@apco and Mth=@mth and APTrans=@aptrans
		if @@rowcount = 0 
			begin
			select @rcode = 1,
			@msg = 'hold code was not released!'
			goto vspExit 
			end
		end
end

-- release by APLine	
if @apline is not null 
begin
	-- check for retainage holdcode on lines  
	if exists (select * from dbo.APHD
			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline
			and HoldCode=@retholdcode)
	begin
	select @rcode=5
	goto vspExit
	end
	-- check for more than one holdcode on lines
	if exists(select count(*)
			from dbo.APHD  
			where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline
			group by APCo, Mth, APTrans,APLine
			having count (*) > 1)
		begin
		select @rcode=5
		goto vspExit
		end
	else
		begin
		--delete single hold code for all lines
		delete from dbo.APHD
		where APCo=@apco and Mth=@mth and APTrans=@aptrans and APLine=@apline
		if @@rowcount = 0 
			begin
			select @rcode = 1,
			@msg = 'hold code was not released!'
			goto vspExit 
			end
		end
end
   
     
     			
vspExit:
      		
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPReleaseSingleHoldCode] TO [public]
GO
