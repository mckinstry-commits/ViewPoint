SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************/
   CREATE proc [dbo].[bspHQWFMergeFieldByType]
   /*********************************************
   * Created By:   GF 01/29/2004 - issue #18841 - routine to return field formatted to type
   * Modified By:  
   *				RM 03/26/04 - Issue# 23061 - Added IsNulls
   *				GF 10/10/2010 - issue #141664 use HQCO.ReportDateFormat to specify the style for dates.
   *				
   *
   *
   * Builds a column string differently depending on data type. Called from other SP's
   *
   *
   * Pass:
   *	@objectid
   *	@columnpart
   *	@alias
   *
   * Success returns:
   *	0 and Column String
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@objectid int, @columnpart varchar(30), @alias varchar(2), @column varchar(100) output,
    @msg varchar(255) OUTPUT, @PMCo INT = null)
   as
   set nocount on
   
   declare @rcode int, @xtype INT,
   		----#141664
		@Style INT, @ReportDateFormat TINYINT
		
		
   select @rcode = 0, @xtype = 0
   
   ----#141664
SET @Style = 101
SET @ReportDateFormat = 1

---- #141664 when @pmco is not null get HQCO report date format.
IF @PMCo IS NOT NULL
	BEGIN
	SELECT @ReportDateFormat = ReportDateFormat
	FROM dbo.bHQCO WHERE HQCo=@PMCo
	IF @@rowcount = 0 SET @ReportDateFormat = 1
	END
	
---- #141664 set style based on Report Date Format
IF @ReportDateFormat = 1 SET @Style = 101
IF @ReportDateFormat = 2 SET @Style = 103
IF @ReportDateFormat = 3 SET @Style = 111


   -- get the xtype for the column part being created
   select @xtype = d.xtype from systypes d join syscolumns c on c.xusertype=d.xusertype
   where c.name = @columnpart and c.id = @objectid
   if @@rowcount = 0 goto Other_Types
   
   -- if type is tinyint, smallint, int, bigint convert varchar(10)
   if @columnpart <> 'SLItem'
   	if @xtype in (48, 52, 56, 127)
   		begin
   		select @column = 'convert(varchar(10),' + isnull(@alias,'') + '.' + isnull(@columnpart,'') + ')'
   		goto bspexit
   		end
   
   -- if type is date, convert varchar(8) with format
   if @xtype = 58
   	BEGIN
   	---- #141664
   	select @column = 'convert(varchar(20),' + isnull(@alias,'') + '.' + isnull(@columnpart,'') + ', ' + CONVERT(VARCHAR(3),@Style) + ')'
   	goto bspexit
   	end
   
   -- if type is notes, then convert to varchar(max)
   if @xtype = 35
   	begin
   	select @column = 'convert(varchar(max),' + isnull(@alias,'') + '.' + isnull(@columnpart,'') + ')'
   	goto bspexit
   	end
   
   -- if type=bPct wrap in isnull and multiple by 100
   if exists(select t.name from systypes t join syscolumns c on c.usertype=t.usertype
   			where c.name = @columnpart and c.id = @objectid and t.name = 'bPct')
   	begin
   	select @column = 'isnull(' + isnull(@alias,'') + '.' + isnull(@columnpart,'') + ', 0)'
   	goto bspexit
   	end
   
   
   -- do other types
   Other_Types:
   select @column = isnull(@alias,'') + '.' + isnull(@columnpart,'')
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWFMergeFieldByType] TO [public]
GO
