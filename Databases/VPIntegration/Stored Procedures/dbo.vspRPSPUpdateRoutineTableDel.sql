SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspRPSPUpdateRoutineTableDel] (@reportid INT, @msg VARCHAR(256)='' output)
AS
/**************************************
* Created by Nitor  01/13/2012
*
* Used in Module SSRSUpdateRoutine
*
* Clears table for updates
*
* Updated Store procedure for delete issue 02/09/2012
**************************************/
  SET NOCOUNT ON
  DECLARE @rcode INT
  SELECT @rcode = 0

  IF @reportid IS NULL
    BEGIN
        SELECT @msg = 'Missing Report ID!',
               @rcode = 1

        GOTO VSPEXIT
    END

  --VP tables 
  BEGIN
      DELETE FROM dbo.vRPSP
      WHERE  ReportID = @reportid
  END

  VSPEXIT:
  RETURN @rcode 
GO
GRANT EXECUTE ON  [dbo].[vspRPSPUpdateRoutineTableDel] TO [public]
GO
