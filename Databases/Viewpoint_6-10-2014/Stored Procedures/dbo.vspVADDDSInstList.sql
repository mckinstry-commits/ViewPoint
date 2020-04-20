SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[vspVADDDSInstList]
   /************************************************************************
   * Object:  Based on Stored Procedure dbo.bspVADDDSInstList
   *
   * Created: ???
   * Modified: RBT 07/25/03 - Issue #17312, sort by instance.
   *
   *************************************************************************  
   * displays security set up in vDDDS for a given Datatype, Qualifier & Instance
   * ordered by Security Group
   * input:  'datatype, qualifier, securitygrp, instancetable, instancecol, instancedesc, qualifycol, instancetype, msg
   * output: instance, Description, SecGrant(None,Full)
   * 10/16/96 LM 
   * 11/14/02 DANF Fixed Quouted Identifiers.
   * 03/19/04 DANF Expanded Security Group
   * 11/27/06 JRK  Port to VP6x
   *	TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
   **************************************************************************/
   	(@datatype varchar(30), @qualifier tinyint, @securitygrp int,  
   	 @instancetable varchar(30), @instancecol varchar(30), @instancedesc varchar(30),  
            @qualifycol varchar(30), @msg varchar(512) output) as
   
   set nocount on 
   declare @rcode integer, @tsql1 varchar(255), @tsql2 varchar(255), @tsql3 varchar(255)
   select @rcode = 0, @tsql1 = null, @tsql2 = null, @tsql3 = null
   
   begin
   
   if (select count(*) from dbo.vDDDT with (nolock) where  Datatype = @datatype)<>1
   	begin
   		select @msg = 'Datatype not in DDDT!', @rcode = 1
   		goto bspexit
   	end
   
   if @instancedesc = ''
      begin
   		select @tsql1='select i.' + @instancecol + ', Description = '''', SecGrant= ' +
   			'case (case isnull(count(d.Instance), -2) ' + 
   			'when -2 then -1  when 0 then -1 else 0 end) ' +
   			'when -1 then ''True'' ' +
   			'when 0 then ''False'' ' +
   			'end'
   
		select @tsql2=' from ' + @instancetable + ' i LEFT OUTER JOIN dbo.vDDDS d with (nolock) ' +
         	'on d.Datatype=''' + @datatype + ''' ' +
         	'and convert(varchar(30),i.' + '' + @qualifycol + '' + ')=convert(varchar(30),d.Qualifier) ' +
         	'and convert(varchar(5),d.SecurityGroup)=' + '' + convert(varchar(5),@securitygrp) + ''
   
        select @tsql3=' and i.' + @instancecol + '=d.Instance ' +
         	'where convert(varchar(30),i.' + @qualifycol + ')=' + ''+ convert(varchar(3),@qualifier) + 
   			'' + ' Group by i.' + @instancecol + ' Order by i.' + @instancecol
      end
   else
      begin
   
   		select @tsql1='select i.' + @instancecol + ', Description = i.'+ @instancedesc + ', SecGrant= ' +
   			'case (case isnull(count(d.Instance), -2) ' + 
   			'when -2 then -1  when 0 then -1 else 0 end) ' +
   			'when -1 then ''True'' ' +
   			'when 0 then ''False'' ' +
   			'end'
   
        select @tsql2=' from ' + @instancetable + ' i LEFT OUTER JOIN dbo.vDDDS d with (nolock)' +
         	'on d.Datatype=''' +  @datatype  + ''' ' +
         	'and convert(varchar(30),i.' + '' + @qualifycol + '' + ')=convert(varchar(30),d.Qualifier)' +
         	'and convert(varchar(5),d.SecurityGroup)=' + '' + convert(varchar(5),@securitygrp) + ''
   
        select @tsql3=' and i.' + @instancecol + '=d.Instance ' +
         	'where convert(varchar(30),i.' + @qualifycol + ')=' + ''+ convert(varchar(5),@qualifier) + 
   		'' + ' Group by i.' + @instancecol + ', i.' + @instancedesc + 
         	' order by ' + @instancecol
       
      end
	
    exec (@tsql1 + @tsql2 + @tsql3)

   bspexit:
   	return @rcode    
   end


GO
GRANT EXECUTE ON  [dbo].[vspVADDDSInstList] TO [public]
GO
