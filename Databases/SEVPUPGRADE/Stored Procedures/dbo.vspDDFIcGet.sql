SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDTVal    Script Date: 8/28/99 9:34:19 AM ******/
  CREATE proc [dbo].[vspDDFIcGet]
  /***************************************
  * Created: JRK 10/25/06
  * Modified: JRK 9/21/07 - Added the ComboType field to the selection list.
  *
  * Retrieve most fields of DDFIc to populate the HQUDAdd wizard.
  *
  **************************************/
  	(@form varchar(30) = null, @colname varchar(256) = null,
	 @msg varchar(60) output)
  
  as
  set nocount on
  
  declare @rcode int
  select @rcode = 0
  
if @form is null
    	begin
  	select @msg = 'Missing Form!', @rcode = 1
  	goto bspexit
  	end

if @colname is null
    	begin
  	select @msg = 'Missing ColumnName!', @rcode = 1
  	goto bspexit
  	end
  
  select Seq, Description, Datatype, InputType, InputMask, InputLength, Prec,
	StatusText, Tab, Req, ValProc, ValParams, ValLevel,
	ControlType, ComboType, DefaultType, DefaultValue, Label,
	MinValue, MaxValue, ValExpression, ValExpError, GridColHeading
  from DDFIc (nolock)
  where Form = @form and ColumnName = @colname
  if @@rowcount = 0
  	begin
  	select @msg = 'Column Name is not setup in DDFIc!', @rcode = 1
  	end
  
  bspexit:
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDFIcGet] TO [public]
GO
