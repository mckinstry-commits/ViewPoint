SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPOCopyItemGrid]
  /*******************************************************************************************************
  * CREATED BY: 	 DC 09/20/06
  * MODIFIED By :  	 GF 7/27/2011 - TK-07144 changed to varchar(30)
  *
  * USAGE:  
  *		Used in POCopy to fill the items grid
  *
  * FORMS CURRENTLY USING THIS ROUTINE:
  *		frmPOCopy
  *
  *
  * INPUTS:
  *
  * OUTPUTS:
  *	@errmsg		
  *
  * RESULTS:
  *
  *******************************************************************************************************/
  @co bCompany, @po VARCHAR(30)
  as
  
  set nocount on
  
  declare @rcode int

  select @rcode = 0

	select 1 as Incl, 
			POItem, 
			case when ItemType=1 then '1-Job' 
				when ItemType=2 then '2-Inv' 
				when ItemType=3 then '3-Exp' 
				when ItemType=4 then '4-Equip' 
				when ItemType=5 then '5-WO' else '?' end as ItemType,
			Material, 
			Description, 
			OrigUnits, 
			UM, 
			OrigUnitCost 
	FROM POIT with (nolock) 
    WHERE POCo = @co and PO = @po
  
  bspexit:
  
  return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOCopyItemGrid] TO [public]
GO
