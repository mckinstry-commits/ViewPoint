SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE      proc [dbo].[vspINLMInfoGet]

  /*************************************
  * CREATED BY:		TRL 09/21/05
  * Modified By:	GP	07/18/08 - Issue 127257 Initialize by Physical Location. Altered select
  *									statement to include PhyLoc from INMT when @IncludePhyLoc = 'Y'.
  *
  * Gets the INLM Location information
  * Used by and INPhyCountInit
  *
  * Pass:
  *		INCo - Inventory Company  
  *		Source Location
  *		Category
  *		Material
  *		IncludePhyLoc - checkbox value YN
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (	@inco bCompany = null, @sourceloc varchar(10) = null, @category varchar(10) = null, 
	@material varchar(20) = null, @IncludePhyLoc bYN = null, @msg varchar(256) output)
  as
  set nocount on
  
  declare @rcode int, @Loc bLoc, @Desc bDesc
  
  select @rcode = 0
  
  if @inco is null
  	begin
  	select @msg = 'Missing IN Company!', @rcode = 1
  	goto vspexit
  	end

--Used by INPhyCountInit
IF @sourceloc is  null and @material is  null  and @category is null 
	--source location, material and category parameters not required.
BEGIN
	IF @IncludePhyLoc = 'Y'
	BEGIN
		SELECT DISTINCT m.Loc, m.Description, t.PhyLoc
		FROM INLM m with(nolock) 
			join INMT t on m.INCo = t.INCo and m.Loc = t.Loc
		WHERE m.INCo = @inco 
		IF @@rowcount = 0
		BEGIN
 			SELECT @msg='No IN Locations to list.', @rcode=1
      		GOTO vspexit
		END		
	END
	ELSE
	BEGIN
		SELECT Loc, Description, null FROM INLM with(nolock) WHERE INCo = @inco
		IF @@rowcount = 0
		BEGIN
 			SELECT @msg='No IN Locations to list.', @rcode=1
      		GOTO vspexit
		END	
	END
END

vspexit:
   	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINLMInfoGet] TO [public]
GO
