SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE       procedure [dbo].[vspRPCRUpdateRoutineGetPath]
( @reportid int, @reportpath varchar(512) =null output, @msg varchar (256) = null output)
 as
/*
   * Created:   TRL 07/11/2005'
   *
   *Used in forms: CRUpdateRoutine
   * 
   *
   *
*/
set nocount on

Declare @rcode int 

select @rcode =0

If Isnull(@reportid,0) = 0
	Begin
		Select @msg='Missing Report ID!'
		Goto vspexit
	End

--VP tables
if @reportid <=9999
	Begin
		Select @reportpath = RPRL.Path + '\'+RPRT.FileName
		From dbo.RPRT with (nolock)
		Left Join dbo.RPRL with (nolock) on RPRL.Location =RPRT.Location
		Where RPRT.ReportID = @reportid  and Right(RPRT.FileName,4) ='.rpt'
		If @@rowcount = 0
			Begin
				Select @msg ='Report ID: '+convert(varchar,isnull(@reportid,0)) + ' is missing or not a valid report', @rcode = 6
				Goto vspexit
			End
	End

--Custom tables
If @reportid >= 10000
	Begin
		Select  @reportpath = RPRL.Path + '\'+RPRTc.FileName
		From dbo.RPRTc with (nolock)
		Left Join dbo.RPRL with (nolock) on RPRL.Location = RPRTc.Location
		Where RPRTc.ReportID  = @reportid   and Right(RPRTc.FileName,4) ='.rpt'
		If @@rowcount = 0
			Begin
				Select @msg ='Report ID: '+convert(varchar,isnull(@reportid,0)) + ' is missing or not a valid report', @rcode = 6
				Goto vspexit
			End
	End

vspexit:
--	If @rcode <> 0 
--		Select @msg = @msg + ' [vspRPCRUpdateRoutineGetPath]'
	return @rcode







GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRoutineGetPath] TO [public]
GO
