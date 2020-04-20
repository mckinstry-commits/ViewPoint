
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[vspEMWOGetNextAvailable]
/*************************************************************************
* Created by:  TRL 11/20/2008 Issue 131082 
* Modified by:	TRL 08/03/2009 Issue 133975 Added code not allow same WO's by Shop
*				GF 07/30/2012 TK-16655 fix WO overflow error when all 10 characters used
*				GF 08/16/2012 TK-17080 always get next work order number from last.
*				GF 02/01/2013 TFS-8725 set @nextwo to 1 if empty
*
*
* USAGE: Gets Next Available and Formats Work Order based on DDDTShared bWO
*
* INPUT PARAMS:
*	@emco		EMCo
*	@nextwo		WorkOrder 
*	@errmsg			
*
* OUTPUT PARAMS:
*@rcode		Return code; 0 = success, 1 = failure
*@nextwo	bWO output, 
*@errmsg		Error message; # copied if success, error message if failure
*************************************************************************/
(@emco bCompany, @autoseqYN bYN, @autoseqopt varchar(1), @shopgroup bGroup, @shop varchar(20), 
 @nextwo bWO output,@errmsg varchar(255) output)
as
set nocount on 

declare @rcode int,
		/*Variables used to calculate the next work order*/
		@NumLeadingZeros tinyint,@NumLeadingSpaces tinyint, @newwo bWO,
		@newwoSave bWO, @verifywo bWO, @x tinyint
 
select @rcode = 0

IF @shopgroup IS NULL
	BEGIN
	SELECT @shopgroup = ShopGroup FROM dbo.HQCO WHERE HQCo=@emco 
	END

----TFS-8725
IF ISNULL(LTRIM(RTRIM(@nextwo)),'') = ''
	BEGIN
	SET @nextwo = '0'
	END
	  
--Check and/or re-format Work Order based on DDDTShared
exec @rcode = dbo.vspEMFormatWO @nextwo output, @errmsg output
If @rcode = 1
begin
	goto vspexit
end   

--Check to see if next work order already exists
--ShopWOCheck
----TK-17080 DO NOT NEED ALWAYS GET NEXT
--If isnull(@autoseqYN,'N') = 'Y' and isnull(@autoseqopt,'') = 'C' and
--			(exists (select top 1 1 from dbo.EMWH with(nolock) where ShopGroup = @shopgroup and Shop = @shop and WorkOrder = @nextwo)
--			or exists (select top 1 1 from dbo.EMWH h with(nolock)
--			inner join dbo.HQCO  c with(nolock)on c.HQCo=h.EMCo and c.ShopGroup=h.ShopGroup 
--			inner join dbo.EMCO e with(nolock)on  e.EMCo=h.EMCo
--			where  h.ShopGroup = @shopgroup 
--				and e.WOAutoSeq=@autoseqYN 
--				and e.WorkOrderOption=@autoseqopt 
--				and WorkOrder = @nextwo ))
--begin
--					goto CalcNextWO
--END

--Check to see if next work order already exists
--if exists (select top 1 1 from dbo.EMWH with(nolock) where EMCo = @emco and WorkOrder = @nextwo)
--	begin
--	goto CalcNextWO
--	end

--goto vspexit	

CalcNextWO:

--@newwo is variable that increments
--@verifywo is variable to check if properly formated wo exists in emwh
select @newwo = @nextwo, @verifywo = @nextwo

/*Store the number of leading zeros in @newwo since incrementing process
in loop will wipe them out and they need to be added back to the front of 
the string after the increment. 
Strip out any leading spaces from R justification. 
For WO values '      12' or 00000012 or '2004 11 or ' 12  9*/
select @NumLeadingZeros = 0, @NumLeadingSpaces = 0

while substring(@newwo, @NumLeadingSpaces + 1, 1) = ' '
	select @NumLeadingSpaces = @NumLeadingSpaces + 1	
	select @newwoSave = @newwo, @newwo = substring(@newwo, @NumLeadingSpaces + 1, len(@newwo))
	while substring(@newwo,@NumLeadingZeros+1,1) = '0'
		select @NumLeadingZeros = @NumLeadingZeros + 1	
		/*Replace internal spaces with 0, need to calc next wo number
		bWO input mask 4RN3RN and input length 7; 2004 11 to 2004011*/
		select @newwo = @newwoSave

----TK-17080
--If isnull(@autoseqYN,'N') = 'Y' and isnull(@autoseqopt,'') = 'C' and
--			(exists (select top 1 1 from dbo.EMWH with(nolock) where ShopGroup = @shopgroup and Shop = @shop and WorkOrder = @verifywo)
--			or exists (select top 1 1 from dbo.EMWH h with(nolock)
--			inner join dbo.HQCO  c with(nolock)on c.HQCo=h.EMCo and c.ShopGroup=h.ShopGroup 
--			inner join dbo.EMCO e with(nolock)on  e.EMCo=h.EMCo
--			 where  h.ShopGroup = @shopgroup and e.WOAutoSeq=@autoseqYN and e.WorkOrderOption=@autoseqopt  and WorkOrder = @verifywo ))
--	begin
--	goto GetNextAvailableWorkOrder
--	END
	
--IF exists (select top 1 1 from dbo.EMWH with(nolock) where EMCo = @emco and WorkOrder = @verifywo)
--	begin
--	goto GetNextAvailableWorkOrder
--	END
	
--goto  SaveNexWO

GetNextAvailableWorkOrder:

----TK-16655
BEGIN TRY	

	--If Work Exists, get next available Work Order in seq
	----TK-16655 need to use big int to add one overflow with integer
	SET @newwo = CONVERT(BIGINT, @newwo) + 1
	----select @newwo = @newwo + 1	
	
	/*Before formatting for 'R' justification add back any 
	leading zeros that were lost in the incrementing process.*/
	select @x = @NumLeadingZeros
	while @x > 0
	begin
		select @newwo = '0' + @newwo
		select @x = @x - 1
	end

	/* Issue 122308 */
	If Len(@newwo) = 2 and substring(@newwo,1,1) = '0'
	begin
		select @newwo =  substring(@newwo,2,1) 
	end

	select @verifywo = @newwo
	--Check and/or re-format Work Order based on DDDTShared
	exec @rcode = dbo.vspEMFormatWO @verifywo output, @errmsg output
	If @rcode = 1
	begin
		goto vspexit
	end   
		
--Check to see if next work order already exists
	--ShopWOCheck		
	If isnull(@autoseqYN,'N') = 'Y' and isnull(@autoseqopt,'') = 'C' and
				(exists (select top 1 1 from dbo.EMWH with(nolock) where ShopGroup = @shopgroup and Shop = @shop and WorkOrder = @verifywo)
				or exists (select top 1 1 from dbo.EMWH h with(nolock)
				inner join dbo.HQCO  c with(nolock)on c.HQCo=h.EMCo and c.ShopGroup=h.ShopGroup 
				inner join dbo.EMCO e with(nolock)on  e.EMCo=h.EMCo
				 where  h.ShopGroup = @shopgroup and e.WOAutoSeq=@autoseqYN and e.WorkOrderOption=@autoseqopt  and WorkOrder = @verifywo ))
	begin
						goto GetNextAvailableWorkOrder
	end
	IF exists (select top 1 1 from dbo.EMWH with(nolock) where EMCo = @emco and WorkOrder = @verifywo)
	begin
			goto GetNextAvailableWorkOrder
	end
	
	Select @nextwo=@verifywo

----TK-16655
END TRY

BEGIN CATCH
	-- RETURN FAILURE --
	SET @rcode = 1
	SET @errmsg = ERROR_MESSAGE()
	GOTO vspexit
END CATCH


SaveNexWO:
	Select @nextwo=@verifywo

vspexit:
Return @rcode

GO

GRANT EXECUTE ON  [dbo].[vspEMWOGetNextAvailable] TO [public]
GO
