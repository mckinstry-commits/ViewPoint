SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspSLCloseGridFill]
  /*******************************************************************************************************
  * CREATED BY: 	 DC 10/6/2006
  * MODIFIED By :		DC 07/01/08 - #128435  Add Tax to the remaining cost
  *
  * USAGE:  Used in SLClose to return a recordset of subcontracts that can be closed
  *
  *
  * FORMS CURRENTLY USING THIS ROUTINE:  frmSLClose.vb
  *
  *
  *******************************************************************************************************/
  @co bCompany, @mth bMonth, @batchid int, @errmsg varchar(1020) output
  as
  
  set nocount on
  
  declare @rcode int

  select @rcode = 0

	SELECT SLXB.JCCo, 
			SLXB.Job, 
			SLXB.SL, 
			SLXB.Description, 
			SLXB.Vendor, 
			(sum(isnull(SLIT.CurCost,0))-sum(isnull(SLIT.InvCost,0)))+(sum(isnull(SLIT.CurTax,0))-sum(isnull(SLIT.InvTax,0))) as Remaining
	FROM SLXB left join SLIT on SLIT.SLCo=SLXB.Co and SLIT.SL=SLXB.SL 
	WHERE Co = @co and
			Mth = @mth and 
			BatchId = @batchid
	GROUP BY SLXB.SL, SLXB.Description, SLXB.Vendor, SLXB.JCCo, SLXB.Job order by SLXB.JCCo,SLXB.Job
	
	  
  bspexit:
  
  return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLCloseGridFill] TO [public]
GO
