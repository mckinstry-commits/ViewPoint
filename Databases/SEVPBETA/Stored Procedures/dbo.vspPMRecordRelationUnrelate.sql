SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************************/
CREATE procedure [dbo].[vspPMRecordRelationUnrelate]
/************************************************************************
* Created By:	GF 11/30/2010   
* Modified By: 
*
* This stored procedure will remove relationship between a from and to table.
* The delete will occur for both sides of the relationship, since we do not know
* how record was related. Called from vspPMRecordAssocRelGetUnRel
*
* 1. Delete relationship where @FromFormTable=RecTableName and @FromKeyID=RECID
*	 and LinkTableName=@ToTableName and LINKID=@ToKeyID
*
* 2. Delete relationship where @ToTableName=RecTableName and @ToKeyID=RECID
*	 and LinkTableName=@FromFormTable and LINKID=@FromKeyID
*
*	
* Inputs
* @FromKeyID	- From Form Key KeyID
* @FromFormName	- From Form Name to get table
* @ToKeyID		- To Table Key ID
* @ToTable		- To Table Name
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @errmsg		- Error Message
*
*************************************************************************/
(@FromKeyID BIGINT = NULL, @FromFormName NVARCHAR(128) = NULL, 
 @ToKeyID BIGINT = NULL, @ToFormName NVARCHAR(128) = NULL,
 @msg varchar(255) output)

AS
SET NOCOUNT ON


DECLARE @rcode INT, @FromFormTable NVARCHAR(128), @ToFormTable NVARCHAR(128)

SET @rcode = 0	

-------------------------------
-- CHECK INCOMING PARAMETERS --	
-------------------------------
IF @FromKeyID IS NULL
	BEGIN
	SET @msg = 'Missing From Form Key ID'
	SET @rcode = 1
	GOTO vspExit
	END
	
IF @FromFormName IS NULL
	BEGIN
	SET @msg = 'Missing From Form Name'
	SET @rcode = 1
	GOTO vspExit
	END

IF @ToKeyID IS NULL
	BEGIN
	SET @msg = 'Missing To Form Key ID'
	SET @rcode = 1
	GOTO vspExit
	END
	
IF @ToFormName IS NULL
	BEGIN
	SET @msg = 'Missing To Form Name'
	SET @rcode = 1
	GOTO vspExit
	END


---- execute SP to get the from form table
SET @FromFormTable = NULL
EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @FromFormName, @FromFormTable output, @msg output

---- must have a form name
IF @FromFormTable IS NULL
	BEGIN
	SELECT @msg = 'Missing From Form Table for related records!', @rcode = 1
	GOTO vspExit
	END


---- execute SP to get the to form table
SET @ToFormTable = NULL
EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @ToFormName, @ToFormTable output, @msg output

---- must have a form name
IF @ToFormTable IS NULL
	BEGIN
	SELECT @msg = 'Missing From Form Table for related records!', @rcode = 1
	GOTO vspExit
	END


--SET @msg = ISNULL(@FromFormName,'') + ',' + ISNULL(@ToFormName,'') + ',' + ISNULL(CONVERT(VARCHAR,@FromKeyID),'') + ',' + ISNULL(CONVERT(VARCHAR,@ToKeyID),'')
--SET @rcode = 1
--GOTO vspExit

---------------------
-- REMOVE RELATION --
---------------------
---- possible that the from record is either the record table and key
---- or the link table and key. We need to remove under both conditions


---- delete side one where form table = record table
---- where statement record table name, record id, link table name, and link id
DELETE FROM dbo.PMRelateRecord
WHERE RecTableName = @FromFormTable AND RECID = @FromKeyID
AND LinkTableName = @ToFormTable AND LINKID = @ToKeyID


---- delete side one where form table = link table
---- where statement record table name, record id, link table name, and link id
DELETE FROM dbo.PMRelateRecord
WHERE RecTableName = @ToFormTable AND RECID = @ToKeyID
AND LinkTableName = @FromFormTable AND LINKID = @FromKeyID


	
vspExit:
     RETURN @rcode



GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelationUnrelate] TO [public]
GO
