SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspRPGetRpParameters] 
/*******************************************
* Created: Jim Emery 12/24/96
* Modified: GG 02/11/99 - SQL 7.0
*           JRE 03/02/00 - changed wherclause to F4Lookup
*           JRE 06/30/01 - changed usertype to xusrtype in systypes join     
* 		    	used by RPRun to setup the parameter inputs
* 		    kb 7/1/2 - issue #17364 changed to return '' for ReportLookup
*		    	will be resolved in RPRun cause will get datatype lookup
*		    	from DDDL with another stored proc
*		    allenn 08/23/02 - issue 17681. revised RPRP table with new columns 
*		    	to control the parameter inputs better on the RPRUN form. Access 
*		    	parameter input settings through the RPRT form.
*		    allenn 08/26/02 - issue 18374.
*		    allenn 11/14/02 - issue 17681.
*		    RBT 02/06/04 - issue 23183, new column 'Prec' for numeric precision.
*			RBT 06/16/04 - issue 24850, fix Precision to get from datatype if null in RPRP.
*			GG 01/23/06 - Mods for VP6.0 vRP tables
*			GG 10/16/07 - #125791 - fix for DDDTShared
*			TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*
* select the parameters needed to run a report including the 
* datatype so we know the length and type of data to be entered and
* information about formating and F4.  
* since F4's expect specific parameters (e.g. JCCo=? and Job=? ) 
*    we only provide a company parameter (e.g. JCCo=?)
*    because we can't force the user to include the other parameters
*********************************************************/
	(@Title varchar(40)=null)
 as
declare @rcode int
   set nocount on
   select @rcode=0
   
  select ParameterName, /* name of parameter in Cyrstal Reports */
      DisplaySeq=case when DisplaySeq=0 then 999 else DisplaySeq end, /* the order number of how parameters are to be displayed */
      ReportDatatype=r.ReportDatatype,
      d.Datatype, r.Description, ParameterDefault,  
 /*issue 18374*/
      InputType=case isnull(r.InputType,d.InputType)
			when 0 then 'String' /* INPUT_TEXT */
   			when 1 then 'Numeric' /* INPUT_NUMERIC */
   			when 2 then 'Date' /* INPUT_DATE */
   			when 3 then 'Month' /* INPUT_PERIOD */
 			when 4 then 'Time' /* INPUT_TIME */
 			when 5 then 'MultiPart' /* INPUT_MULTIPART */
 			when 6 then 'StringToNumeric'
 			else null
 			end,
 	--issue 17681: fixed InputMask value
      InputMask = case when r.Datatype is null then r.InputMask else d.InputMask end,
      InputLength = case when d.InputLength is null then
  						case when r.InputLength is null then
   	    					case r.ReportDatatype
   								when 'S' then 30 /* string */
   								when 'N' then 16 /* numeric */
   								when 'D' then 10
   								when 'M' then 6
 	    						end
  	  					else r.InputLength
 	  					end
 					else d.InputLength
  					end,
 	'ReportLookup' = '', --issue #17364 unrem this line and rem out the next
      --d.ReportLookup, /* name of the lookup */
      --WhereClause=isnull(r.Lookup,''),
          --case s.name when 'bCompany' then convert(varchar(30),c.name) else null end, /*only use the first parameter*/
      usertype= convert(varchar(30),s.name),  /* the parameter type of the where clause (probably bCompany) */ 
      isnull(r.Prec, isnull(d.Prec, 2)) as Prec	--issue #23183, now fixed for #24850
   from dbo.RPRPShared r (nolock)
	join RPRTShared t (nolock) on t.ReportID = r.ReportID
    Left JOIN dbo.DDDTShared d (nolock) ON r.Datatype = d.Datatype
    Left JOIN dbo.DDLHShared l (nolock) ON d.Lookup =l.Lookup  
    Left JOIN sys.syscolumns c (nolock)  ON c.id = object_id(l.FromClause) and c.colid=1
    Left JOIN sys.systypes s (nolock) ON c.type=s.type and c.xusertype=s.xusertype
   where  t.Title = @Title
   	/*and DisplaySeq>0*/
   	and (d.InputType in (0,1,2,3,4,5,6) or d.InputType is null)
   order by case when DisplaySeq=0 then 999 else DisplaySeq end


GO
GRANT EXECUTE ON  [dbo].[bspRPGetRpParameters] TO [public]
GO
