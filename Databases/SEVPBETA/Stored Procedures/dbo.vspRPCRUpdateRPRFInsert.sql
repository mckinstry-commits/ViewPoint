SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE      Procedure [dbo].[vspRPCRUpdateRPRFInsert]
(@ReportID int  =0,  @Seq int = 0, @ReportType varchar (20),@FieldType varchar(20) = '', @Name varchar(60) = '', @Descr varchar(60),
@ReportText varchar(4000) = '' ,  @msg varchar(256) ='' output)
as
/*
 * Created By:	TRL  07/15/2005
 * Modified By: 
 *
 * Called from CRUpdateRoutine.
 *
 *
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *
 **************************************/
set nocount on

declare @rcode int
select @rcode = 0

If @ReportID <= 0 
	begin
		set @msg = 'Report ID cannot be equal to or less than zero.' 
		set  @rcode = 1
		goto vspexit
	end
if @Seq <= 0 
	begin 
		set @msg= 'Sequence cannot be equal to or less than  zero.' 
		set @rcode = 1
		goto vspexit
	end

Update dbo.RPRF
Set  ReportType=@ReportType,  FieldType = @FieldType , Name=@Name, Description=@Descr,ReportText=@ReportText
Where ReportID = @ReportID and Seq=@Seq
If @@rowcount = 0 
	begin 
		Insert into dbo.RPRF Values(@ReportID,@Seq, @FieldType, @Name, @Descr,@ReportText,@ReportType)
	end
vspexit:
  	return @rcode













GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRPRFInsert] TO [public]
GO
