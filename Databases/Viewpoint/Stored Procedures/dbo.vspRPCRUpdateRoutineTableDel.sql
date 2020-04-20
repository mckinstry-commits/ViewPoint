SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE       procedure [dbo].[vspRPCRUpdateRoutineTableDel]
(@reportid int , @msg varchar(256)='' output) as
/*
   * Created by TRL  07/11/2005'
   *
   *Used in Module CRUpdateRountie.
   *
   *Clears table for updates
*/
set nocount on

Declare @rcode int

select @rcode =0

--VP tables 
Begin
	Delete From dbo.vRPRF Where ReportID =@reportid 
end

Begin
 	Delete From dbo.vRPTP Where ReportID =@reportid 
End








GO
GRANT EXECUTE ON  [dbo].[vspRPCRUpdateRoutineTableDel] TO [public]
GO
