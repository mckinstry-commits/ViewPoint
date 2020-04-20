SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[vspSLWorksheetUDUpdateBuild]
/***********************************************************
* Created By:	GF 11/14/2012 TK-19330 SL Claims change how update ud columns are done from SL worksheets
* Modified By:	
*
*
*
* USAGE:
* Creates an user memo update string based on passed in source and destination views.
* The update statement will be used in SL Worksheet update to APEntry and APUnapproved
* Invoices for user memos.
*
*
* INPUT:
* @Source		Source view
* @Destination	Destination view
*
* OUTPUT:
* @UD_Exists	Ud columns exists in source / destination to update
* @Update		update statement
*
* OUTPUT:
* @ErrMsg     if something went wrong
* 
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@Source varchar(128), @Destination varchar(128),
 @UD_Exists bYN OUTPUT, @Update VARCHAR(4000) OUTPUT, 
 @ErrMsg VARCHAR(255) OUTPUT)
AS
SET NOCOUNT ON
   
DECLARE @rcode int, @openusermemo int, @columnname varchar(30), @srcobject_id int, @dstobject_id int
   
SET @rcode = 0
SET @openusermemo = 0
SET @UD_Exists = 'N'
   
if isnull(@Source,'') = ''
	begin
	select @ErrMsg = 'Missing source object.', @rcode = 1
	goto vspexit
	end
   
if isnull(@Destination,'') = ''
	begin
	select @ErrMsg = 'Missing destination object.', @rcode = 1
	goto vspexit
	end
   
---- get object id for source from sysobjects
select @srcobject_id = id from sysobjects where name = @Source and xtype in ('U','V')
if @@rowcount = 0
	begin
	select @ErrMsg = 'Missing source object_id in sysobjects.', @rcode = 1
	goto vspexit
	end
   
---- get object id for destination from sysobjects
select @dstobject_id = id from sysobjects where name = @Destination and xtype in ('U','V')
if @@rowcount = 0
	begin
	select @ErrMsg = 'Missing destination object_id in sysobjects.', @rcode = 1
	goto vspexit
	end



---- set the user memo flags for the tables that have user memos
if exists(select name from syscolumns where id = @srcobject_id and name like 'ud%')
    BEGIN
     	  	
	-- declare cursor on User Memos that exist in source and destination objects
    declare UserMemo cursor LOCAL FAST_FORWARD for select name
    from syscolumns c where c.id = @srcobject_id and c.name like 'ud%'
		and exists(select * from syscolumns t where t.name = c.name
		and t.id = @dstobject_id)
     
    -- open user memo cursor
    open UserMemo
    set @openusermemo = 1
     
    -- process through all entries in batch
    UserMemo_loop:
    fetch next from UserMemo into @columnname
     
    if @@fetch_status = -1 goto UserMemo_end
    if @@fetch_status <> 0 goto UserMemo_loop
     
    set @UD_Exists = 'Y'
    if @Update is null
     	select @Update = 'update ' + @Destination + ' set ' + @columnname + ' = ' + @Source + '.' + @columnname
    else
     	select @Update = @Update + ', ' + @columnname + ' = ' + @Source + '.' + @columnname
     
    goto UserMemo_loop
     
    UserMemo_end:
     	close UserMemo
     	deallocate UserMemo
     	select @openusermemo = 0
     		
	END
  

---- if @UD_Exists = 'Y' add from to update statement
if @UD_Exists = 'N'
	BEGIN
	SET @Update = NULL
	GOTO vspexit
	END


---- create join clause and where clause
IF @Source = 'SLWH' AND @Destination = 'APHB'
	BEGIN
	SELECT @Update = @Update + ' FROM ' + @Source + ' ' + @Source
				+ ' JOIN ' + @Destination + ' ' + @Destination + ' ON '
				+ @Source + '.SLCo = ' + @Destination + '.Co '
	END

---- create join clause and where clause
IF @Source = 'SLWI' AND @Destination = 'APLB'
	BEGIN
	SELECT @Update = @Update + ' FROM ' + @Source + ' ' + @Source
				+ ' JOIN ' + @Destination + ' ' + @Destination + ' ON '
				+ @Source + '.SLCo = ' + @Destination + '.Co '
	END


---- create join clause and where clause
IF @Source = 'SLWH' AND @Destination = 'APUI'
	BEGIN
	SELECT @Update = @Update + ' FROM ' + @Source + ' ' + @Source
				+ ' JOIN ' + @Destination + ' ' + @Destination + ' ON '
				+ @Source + '.SLCo = ' + @Destination + '.APCo '
	END

---- create join clause and where clause
IF @Source = 'SLWI' AND @Destination = 'APUL'
	BEGIN
	SELECT @Update = @Update + ' FROM ' + @Source + ' ' + @Source
				+ ' JOIN ' + @Destination + ' ' + @Destination + ' ON '
				+ @Source + '.SLCo = ' + @Destination + '.APCo '
	END



vspexit:
    return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspSLWorksheetUDUpdateBuild] TO [public]
GO
