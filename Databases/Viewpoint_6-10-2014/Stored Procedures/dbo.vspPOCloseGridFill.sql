SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPOCloseGridFill]
  /*******************************************************************************************************
  * CREATED BY: 	 kb 6/24/5
  * MODIFIED By :  
  *
  * USAGE:  
  *
  * TO ADD TO THIS PROCEDURE:
  * 1) Modify the next available (@alternate) input to correct Name and Datatype
  * 2) Modify only those forms required.  Pass in New Input.  
  *
  * FORMS CURRENTLY USING THIS ROUTINE:
  *
  * LIST OF CURRENT UPFRONT VALIDATION CHECKS:
  *
  * INPUTS:
  *
  * OUTPUTS:
  *	@errmsg		
  *
  * RESULTS:
  *
  *******************************************************************************************************/
  @co bCompany, @mth bMonth, @batchid int, @errmsg varchar(1020) output
  as
  
  set nocount on
  
  declare @rcode int

  select @rcode = 0

  Select POXB.PO, POXB.Description, POXB.Vendor, POXB.JCCo, POXB.Job,
	convert(numeric(12,2),sum(case when POIT.UM = 'LS' then POIT.BOCost else 
	(POIT.BOUnits * POIT.CurUnitCost)/case POIT.CurECM when 'E' then 1 
	when 'C' then 100 when 'M' then 1000 end end )) 
	from POXB left join POIT on POIT.POCo=POXB.Co and POIT.PO=POXB.PO
	where Co = @co and Mth = @mth and BatchId = @batchid
	group by POXB.PO, POXB.Description, POXB.Vendor, POXB.JCCo, POXB.Job 
  
  bspexit:
  
  return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOCloseGridFill] TO [public]
GO
