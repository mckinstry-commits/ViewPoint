SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE procedure [dbo].[vspPMRecordRelateAutoAdd]
/************************************************************************
* CREATED By:	GF 12/21/2010 - issue #141957 
* MODIFIED By: 
*
* Main routine to add record associations from PM forms.
* Called from PM Common routines. Currently only called from RFI
* when adding via a project issue.
*
* Inputs
* @FromFormTable		From Form Table Name
* @RECID				From Form KeyID
* @LinkFormTable		Link To Form Table Name
* @LINKID				Link To Form KeyID
*
* Outputs
*	@rcode		- 0 = successfull - 1 = error
*	@msg		- Error Message
*
*************************************************************************/
(@FromFormTable VARCHAR(128) = NULL, @RECID BIGINT = NULL,
 @LinkFormTable VARCHAR(128) = NULL, @LINKID BIGINT = NULL,
 @msg varchar(255) output)

----with execute as 'viewpointcs'

AS
SET NOCOUNT ON

DECLARE @rcode	int

SET @rcode = 0


-------------------------------
---- INSERT RECORD RELATIONS --
-------------------------------	
INSERT dbo.PMRelateRecord ( RecTableName , RECID , LinkTableName , LINKID)
SELECT @FromFormTable, @RECID, @LinkFormTable, @LINKID
WHERE NOT EXISTS(SELECT 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName=@FromFormTable
		AND v.RECID=@RECID AND v.LinkTableName=@LinkFormTable AND v.LINKID=@LINKID)



vspExit:
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelateAutoAdd] TO [public]
GO
